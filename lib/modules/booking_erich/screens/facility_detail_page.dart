import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

// --- IMPORTS (Sesuaikan jika ada yang merah) ---
import 'package:srve_mobile/modules/reviews/screens/edit_facility_review.dart';
import '../../reviews/screens/create_facility_review.dart'; 
import '../models/facility.dart';
import '../models/slot.dart';
import '../providers/booking_provider.dart';
import '../utils/formatters.dart';
import 'booking_success_page.dart';
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';

class FacilityDetailPage extends StatefulWidget {
  final Facility facility;
  const FacilityDetailPage({super.key, required this.facility});

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  // --- STATE BOOKING ---
  late DateTime _selectedDate;
  Slot? _selectedSlot;
  bool _loadingSlots = true;
  String? _slotsError;
  List<Slot> _slots = [];

  // --- STATE REVIEW ---
  bool _loadingReviews = true;
  List<dynamic> _reviews = [];
  bool _userHasReviewed = false; 

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
      _loadReviews();
    });
  }

  // ================== HELPER FUNCTIONS ==================

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
    return (eh * 60 + em) <= (sh * 60 + sm);
  }

  // Gunakan ini agar tidak error merah saat parsing rating
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ================== API CALLS ==================

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

  Future<void> _loadReviews() async {
    final request = context.read<CookieRequest>();
    if (mounted) setState(() => _loadingReviews = true);

    try {
      // Pastikan URL backend benar
      final response = await request.get('http://10.0.2.2:8000/reviews/api/facility/${widget.facility.id}/'); 
      if (!mounted) return;
      
      setState(() {
        _reviews = response['reviews'] ?? [];
        _userHasReviewed = response['user_has_reviewed'] ?? false;
        _loadingReviews = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        'http://10.0.2.2:8000/reviews/delete-flutter/$reviewId/', 
        {}
      );
      if (response['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review deleted")));
        _loadReviews(); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _bookSelected() async {
    final request = context.read<CookieRequest>();
    final prov = context.read<BookingProvider>();

    if (!request.loggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final chosenSlot = _selectedSlot;
    if (chosenSlot == null) return;

    if (_isPastSlot(_selectedDate, chosenSlot) || _isInvalidCrossDayOrReverse(chosenSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot tidak valid.")));
      return;
    }

    final res = await prov.bookSlot(
      request,
      facilityId: widget.facility.id,
      dateIso: _dateIso,
      startHHmm: slot.start,
    );

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? "Booking gagal")));
    }
  }

  // ================== UI BUILD ==================

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final prov = context.watch<BookingProvider>();
    final request = context.watch<CookieRequest>();

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
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. INFO FACILITY
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(f.sportDisplay, style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Text(" • "),
                          Text(f.city),
                          const Text(" • "),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5D7C4),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              f.indoor ? "INDOOR" : "OUTDOOR",
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("${BookingFormat.rupiah(f.pricePerHour)} / jam",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF556047)),
                      ),
                    ],
                  ),
                ),

                // 2. TANGGAL
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final d = days[i];
                      final isSelected = BookingFormat.dateIso(d) == _dateIso;
                      return ChoiceChip(
                        label: Text(BookingFormat.dateIso(d)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF556047).withOpacity(0.2),
                        backgroundColor: const Color(0xFFE5D7C4),
                        onSelected: (_) async {
                          setState(() => _selectedDate = d);
                          await _loadSlots();
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 3. SLOTS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text("Select Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                
                _loadingSlots
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : _slotsError != null
                        ? Padding(padding: const EdgeInsets.all(16), child: Text(_slotsError!, style: const TextStyle(color: Colors.red)))
                        : _slots.isEmpty
                            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada slot.")))
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shrinkWrap: true, 
                                physics: const NeverScrollableScrollPhysics(), 
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, 
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 2.2,
                                ),
                                itemCount: _slots.length,
                                itemBuilder: (context, i) {
                                  final s = _slots[i];
                                  final isSelected = _selectedSlot?.start == s.start && _selectedSlot?.end == s.end;
                                  final disabled = s.booked || _isPastSlot(_selectedDate, s) || _isInvalidCrossDayOrReverse(s);

                                  return InkWell(
                                    onTap: disabled ? null : () => setState(() => _selectedSlot = s),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isSelected ? const Color(0xFF556047) : Colors.black12),
                                        color: disabled ? Colors.black12 : (isSelected ? const Color(0xFF556047).withOpacity(0.15) : Colors.white),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        s.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: disabled ? Colors.black38 : (isSelected ? const Color(0xFF556047) : Colors.black87),
                                          decoration: s.booked ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                const SizedBox(height: 30),
                const Divider(thickness: 4, color: Color(0xFFF5F5F5)),
                const SizedBox(height: 20),

                // 4. REVIEWS SECTION
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Reviews",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A4633)),
                          ),
                        
                          GestureDetector(
                            onTap: () async {
                              if (!request.loggedIn) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                  return;
                              }

                              if (_userHasReviewed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("You have already reviewed this facility!"),
                                    backgroundColor: Colors.red, // Warna merah agar terlihat warning
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return; 
                              }
                            
                              final result = await Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => FacilityReviewForm(
                                    facilityId: widget.facility.id, 
                                    facilityName: widget.facility.name
                                  )
                                )
                              );

                              if (result == true) {
                                _loadReviews();
                              }
                            },

                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF556047), // Warna Hijau
                                borderRadius: BorderRadius.circular(8), // Kotak dengan sudut lengkung
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
                          // ======================================================
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black12, height: 1),
                      const SizedBox(height: 16),

                      _loadingReviews 
                        ? const Center(child: CircularProgressIndicator())
                        : _reviews.isEmpty
                          ? const Text("No reviews yet.", style: TextStyle(color: Colors.grey))
                          : ListView.separated(
                              shrinkWrap: true,
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
                // Padding tambahan agar tidak tertutup tombol sticky bawah
                const SizedBox(height: 100), 
              ],
            ),
          ),

          // 5. STICKY BOTTOM BUTTON
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedSlot != null ? "Selected Slot:" : "Price", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _selectedSlot != null 
                              ? "${_selectedSlot!.label} (${BookingFormat.rupiah(f.pricePerHour)})"
                              : "${BookingFormat.rupiah(f.pricePerHour)} / jam",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF556047),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: (_selectedSlot == null || prov.bookingSubmitting) ? null : _bookSelected,
                    child: prov.bookingSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text("Book Now"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final String authorName = review['author_username'] ?? "User";
  
    final double rating = _safeParseDouble(review['rating']);
    final double cleanliness = _safeParseDouble(review['cleanliness']);
    final double fieldCondition = _safeParseDouble(review['field_condition']);
    final String comment = review['comment'] ?? "";
    final bool isMyReview = review['is_my_review'] ?? false; 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5D7C4), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A4633).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A4633))),
              Row(
                children: [
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$comment"', style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF4B3B2B))),
          ],
          const SizedBox(height: 8),
          Text("Cleanliness: $cleanliness • Field: $fieldCondition", style: const TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
          
          if (isMyReview) 
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditFacilityReviewForm(
                            reviewId: review['id'],
                            initialCleanliness: cleanliness,
                            initialFieldCondition: fieldCondition,
                            initialComment: review['comment'] ?? "",
                            facilityName: widget.facility.name, 
                          ),
                        ),
                      );
                      if (result == true) _loadReviews(); 
                    },
                    child: const Text("Edit", style: TextStyle(color: Color(0xFF556047), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Delete Review"),
                            content: const Text("Are you sure you want to delete this review?"),
                            actions: [
                              // Tombol Cancel
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); 
                                },
                                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                              ),
                              // Tombol Yes, Delete
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); 
                                  _deleteReview(review['id']); 
                                },
                                child: const Text(
                                  "Yes, delete",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.red, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}