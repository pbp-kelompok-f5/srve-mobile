import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/modules/reviews/screens/create_facility_review.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../providers/booking_provider.dart';
import '../utils/formatters.dart';
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';
import 'booking_success_page.dart';

// ⚠️ Pastikan import ini sesuai dengan lokasi file form review kamu
// import 'package:srve_mobile/modules/review/screens/facility_review_form.dart'; 
// Jika belum ada file-nya, kamu perlu buat atau sesuaikan import-nya. 
// Di bawah saya asumsikan nama class-nya FacilityReviewForm.
import '../../reviews/screens/create_facility_review.dart';

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

  // State untuk Reviews
  bool _loadingReviews = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    
    // Load data setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
      _loadReviews(); // Load review saat masuk halaman
    });
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

  // --- LOGIKA LOAD REVIEWS ---
  Future<void> _loadReviews() async {
    final request = context.read<CookieRequest>();
    setState(() => _loadingReviews = true);
    
    try {
      final response = await request.get('http://10.0.2.2:8000/reviews/api/facility/${widget.facility.id}/reviews/');
      
      if (!mounted) return;
      setState(() {
        _reviews = response; 
        _loadingReviews = false;
      });
    } catch (e) {
      print("Error loading reviews: $e");
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  // --- LOGIKA BOOKING ---
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

    final slot = _selectedSlot;
    if (slot == null) return;

    final res = await prov.bookSlot(
      request,
      facilityId: widget.facility.id,
      dateIso: _dateIso,
      startHHmm: slot.start,
    );

    // refresh slots setelah booking
    prov.clearSlotCacheForFacilityDay(widget.facility.id, _dateIso);
    await _loadSlots(force: true);

    if (!mounted) return;

    if (res.ok) {
      final slot2 = slot;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            bookingId: res.bookingId,
            facilityName: widget.facility.name,
            sportDisplay: widget.facility.sportDisplay,
            city: widget.facility.city,
            dateIso: _dateIso,
            slotLabel: slot2.label,
            pricePerHour: widget.facility.pricePerHour,
          ),
        ),
      );
    } else {
      final msg = res.error ?? "Booking gagal";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _facilityBanner(Facility f) {
    final url = f.resolvedImageUrl;
    final w = MediaQuery.of(context).size.width;
    final bannerHeight = w >= 900 ? 260.0 : (w >= 600 ? 220.0 : 180.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: url == null
              ? Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.black38, size: 40),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.black12,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.black38, size: 40),
                  ),
                ),
        ),
      ),
    );
  }

  // Widget Card Review Sederhana
  Widget _buildReviewCard(dynamic review) {
    // Parsing data review (sesuaikan key JSON dari Django)
    final String username = review['author'] ?? "Anonymous";
    final double rating = double.tryParse(review['rating'].toString()) ?? 0.0;
    final String comment = review['comment'] ?? "";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(comment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final prov = context.watch<BookingProvider>();
    final request = context.watch<CookieRequest>(); // Listen request untuk cek login

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
      // MENGUBAH BODY MENJADI SINGLECHILDSCROLLVIEW AGAR BISA SCROLL SAMPAI REVIEW
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar
            _facilityBanner(f),
            const SizedBox(height: 10),

            // 2. Info Facility
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text("${f.sportDisplay} • ${f.city} • ${f.indoor ? "Indoor" : "Outdoor"}"),
                  const SizedBox(height: 6),
                  Text("${BookingFormat.rupiah(f.pricePerHour)} / jam • Slot ${f.defaultSlotMinutes} menit"),
                ],
              ),
            ),

            // 3. Date Chips
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

            // 4. Slots Grid (Diubah agar tidak error dalam SingleChildScrollView)
            _loadingSlots
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                : _slotsError != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Error: $_slotsError"),
                      )
                    : _slots.isEmpty
                        ? const SizedBox(height: 100, child: Center(child: Text("Tidak ada slot.")))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            shrinkWrap: true, // PENTING: Agar grid mengikuti tinggi konten
                            physics: const NeverScrollableScrollPhysics(), // Disable scroll grid, ikut scroll utama
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
                                      decoration: disabled ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

            // ==========================================
            // BAGIAN BARU: REVIEWS SECTION
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Divider(thickness: 2, color: Colors.black12),
            ),
            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5D7C4).withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Review & Tombol Write Review
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reviews",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A4633)),
                      ),
                      
                      // Tombol Hijau Kotak "Write a Review"
                      GestureDetector(
                        onTap: () async {
                          if (!request.loggedIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            return;
                          }
                          
                          // Pindah ke halaman form review
                          // Pastikan FacilityReviewForm sudah diimport
                          final result = await Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => FacilityReviewForm(
                                facilityId: widget.facility.id, 
                                facilityName: widget.facility.name
                              )
                            )
                          );

                          // Jika kembali membawa hasil true (berhasil submit), reload list
                          if (result == true) {
                            _loadReviews();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF556047), // Warna Hijau
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Write a Review",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 16),

                  // List Reviews
                  _loadingReviews 
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                      ? const Text("No reviews yet.", style: TextStyle(color: Colors.grey))
                      : ListView.separated(
                          shrinkWrap: true, // Agar tidak error di dalam SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildReviewCard(_reviews[index]);
                          },
                        ),
                ],
              ),
            ),
            
            // Jarak agar tombol Booking tidak menutupi konten paling bawah
            const SizedBox(height: 100),
          ],
        ),
      ),

      // ==========================================
      // BAGIAN BARU: BOTTOM NAVIGATION BAR (Sticky)
      // ==========================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected slot summary bar
            if (_selectedSlot != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7E5A).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B7E5A).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Selected: ${_selectedSlot!.label}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_selectedSlot == null || prov.bookingSubmitting) ? null : _bookSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF556047), // Sesuaikan tema hijau
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: prov.bookingSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _selectedSlot == null ? "Pilih slot terlebih dahulu" : "Book Now - ${BookingFormat.rupiah(f.pricePerHour)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}