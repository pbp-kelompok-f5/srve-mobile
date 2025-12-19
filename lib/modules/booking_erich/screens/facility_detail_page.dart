import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../services/booking_api_service.dart';

import 'package:srve_mobile/modules/booking_erich/screens/booking_list_page.dart';



class FacilityDetailPage extends StatefulWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  final _service = const BookingApiService();

  late DateTime _selectedDate;
  bool _loading = true;
  String? _error;
  List<Slot> _slots = [];

  Slot? _selectedSlot;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAvailability();
  }

  String _toIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _prettyDate(DateTime d) {
    // format sederhana (tanpa intl)
    const months = [
      "Jan","Feb","Mar","Apr","Mei","Jun","Jul","Agu","Sep","Okt","Nov","Des"
    ];
    return "${d.day.toString().padLeft(2,'0')} ${months[d.month - 1]} ${d.year}";
  }

  Future<void> _loadAvailability() async {
    final request = context.read<CookieRequest>();
    setState(() {
      _loading = true;
      _error = null;
      _slots = [];
      _selectedSlot = null;
    });

    try {
      final slots = await _service.fetchAvailability(
        request,
        facilityId: widget.facility.id,
        dateIso: _toIso(_selectedDate),
      );
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _bookSelected() async {
    if (_selectedSlot == null) return;

    final request = context.read<CookieRequest>();
    setState(() => _booking = true);

    try {
      final res = await _service.bookSlot(
        request,
        facilityId: widget.facility.id,
        dateIso: _toIso(_selectedDate),
        startHHmm: _selectedSlot!.start,
      );

      if (!mounted) return;

      if (res.ok) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Booking berhasil"),
            content: Text(
              "${widget.facility.name}\n"
              "${_prettyDate(_selectedDate)}\n"
              "${_selectedSlot!.label}\n"
              "Booking ID: ${res.bookingId ?? '-'}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingListPage()));
                },
                child: const Text("View Bookings"),
              ),
            ],
          ),
        );

        // refresh availability (slot jadi booked)
        await _loadAvailability();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? "Booking gagal")),
        );
        await _loadAvailability();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;

    final days = List.generate(14, (i) {
      final d = DateTime.now().add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return Scaffold(
      appBar: AppBar(title: Text(f.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info ringkas facility
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("${f.sportDisplay} • ${f.city} • ${f.indoor ? "Indoor" : "Outdoor"}"),
                const SizedBox(height: 6),
                Text("Rp ${f.pricePerHour} / jam • Slot ${f.defaultSlotMinutes} menit"),
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
                final selected = _toIso(d) == _toIso(_selectedDate);

                return ChoiceChip(
                  label: Text(_prettyDate(d)),
                  selected: selected,
                  onSelected: (_) async {
                    setState(() => _selectedDate = d);
                    await _loadAvailability();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Body slots
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Gagal memuat slot.", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadAvailability,
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
                              final isSelected = _selectedSlot?.start == s.start &&
                                  _selectedSlot?.end == s.end;

                              final disabled = s.booked;

                              return InkWell(
                                onTap: disabled
                                    ? null
                                    : () {
                                        setState(() => _selectedSlot = s);
                                      },
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
                                      decoration: disabled ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Book button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedSlot == null || _booking) ? null : _bookSelected,
                child: _booking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_selectedSlot == null
                        ? "Pilih slot terlebih dahulu"
                        : "Book ${_selectedSlot!.label}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
