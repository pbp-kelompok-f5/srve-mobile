import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../providers/booking_provider.dart';
import '../utils/formatters.dart';
import 'booking_list_page.dart';
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';
import 'booking_success_page.dart';


class FacilityDetailPage extends StatefulWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  late DateTime _selectedDate;
  Slot? _selectedSlot;

  bool _loadingSlots = true;
  String? _slotsError;
  List<Slot> _slots = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
  }

  String get _dateIso => BookingFormat.dateIso(_selectedDate);

  DateTime _combineDateAndHHmm(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = (parts.length > 1) ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  bool _isPastSlot(DateTime selectedDate, Slot s) {
    final now = DateTime.now();
    final startDt = _combineDateAndHHmm(selectedDate, s.start);
    return startDt.isBefore(now);
  }

  bool _isInvalidCrossDayOrReverse(Slot s) {
    final startParts = s.start.split(':');
    final endParts = s.end.split(':');

    final sh = int.tryParse(startParts[0]) ?? 0;
    final sm = int.tryParse(startParts.length > 1 ? startParts[1] : "0") ?? 0;

    final eh = int.tryParse(endParts[0]) ?? 0;
    final em = int.tryParse(endParts.length > 1 ? endParts[1] : "0") ?? 0;

    final startMin = sh * 60 + sm;
    final endMin = eh * 60 + em;

    return endMin <= startMin;
  }


  Future<void> _loadSlots({bool force = false}) async {
    final request = context.read<CookieRequest>();
    final prov = context.read<BookingProvider>();

    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _selectedSlot = null;
    });

    try {
      final data = await prov.loadSlots(
        request,
        facilityId: widget.facility.id,
        dateIso: _dateIso,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _slots = data;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = e.toString();
        _loadingSlots = false;
      });
    }
  }

  
  Future<void> _bookSelected() async {
    final request = context.read<CookieRequest>();
    final prov = context.read<BookingProvider>();

    if (!request.loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final chosenSlot = _selectedSlot;
    if (chosenSlot == null) return;

    // (opsional tapi bagus) double-check kalau slot sudah jadi invalid/past
    if (_isPastSlot(_selectedDate, chosenSlot) || _isInvalidCrossDayOrReverse(chosenSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slot sudah tidak valid. Silakan pilih slot lain.")),
      );
      setState(() => _selectedSlot = null);
      return;
    }

    final res = await prov.bookSlot(
      request,
      facilityId: widget.facility.id,
      dateIso: _dateIso,
      startHHmm: chosenSlot.start,
    );

    // refresh slot (biar slot ke-update)
    prov.clearSlotCacheForFacilityDay(widget.facility.id, _dateIso);
    await _loadSlots(force: true);

    if (!mounted) return;

    if (res.ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            bookingId: res.bookingId,
            facilityName: widget.facility.name,
            sportDisplay: widget.facility.sportDisplay,
            city: widget.facility.city,
            dateIso: _dateIso,
            slotLabel: chosenSlot.label,
            pricePerHour: widget.facility.pricePerHour,
          ),
        ),
      );
    } else {
      final msg = res.error ?? "Booking gagal";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final prov = context.watch<BookingProvider>();

    final days = List.generate(14, (i) {
      final d = DateTime.now().add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
        actions: [
          IconButton(
            onPressed: () => _loadSlots(force: true),
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh slots",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("${f.sportDisplay} • ${f.city} • ${f.indoor ? "Indoor" : "Outdoor"}"),
                const SizedBox(height: 6),
                Text("${BookingFormat.rupiah(f.pricePerHour)} / jam • Slot ${f.defaultSlotMinutes} menit"),
              ],
            ),
          ),

          // Date chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected = BookingFormat.dateIso(d) == _dateIso;
                return ChoiceChip(
                  label: Text(BookingFormat.dateIso(d)),
                  selected: selected,
                  onSelected: (_) async {
                    setState(() => _selectedDate = d);
                    await _loadSlots();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Slots grid
          Expanded(
            child: _loadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _slotsError != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Gagal memuat slot.", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(_slotsError!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _loadSlots(force: true),
                              child: const Text("Coba lagi"),
                            ),
                          ],
                        ),
                      )
                    : _slots.isEmpty
                        ? const Center(child: Text("Tidak ada slot untuk tanggal ini."))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.8,
                            ),
                            itemCount: _slots.length,
                            itemBuilder: (context, i) {
                              final s = _slots[i];
                              final isSelected = _selectedSlot?.start == s.start && _selectedSlot?.end == s.end;
                              final disabled = s.booked || _isPastSlot(_selectedDate, s) || _isInvalidCrossDayOrReverse(s);

                              return InkWell(
                                onTap: disabled ? null : () => setState(() => _selectedSlot = s),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                    color: disabled
                                        ? Colors.black12
                                        : isSelected
                                            ? const Color(0xFF6B7E5A).withOpacity(0.15)
                                            : Colors.white,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: disabled ? Colors.black38 : Colors.black87,
                                      decoration: s.booked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Selected slot summary bar
          if (_selectedSlot != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7E5A).withOpacity(0.10),
                border: const Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Text(
                "Selected: ${_selectedSlot!.label} • ${BookingFormat.rupiah(f.pricePerHour)}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          // Book button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedSlot == null || prov.bookingSubmitting) ? null : _bookSelected,
                child: prov.bookingSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_selectedSlot == null ? "Pilih slot terlebih dahulu" : "Book ${_selectedSlot!.label}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
