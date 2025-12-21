import 'dart:ui'; // Diperlukan untuk ImageFilter (Blur effect)
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/review_services.dart';

class FacilityReviewForm extends StatefulWidget {
  final int facilityId;
  final String facilityName;

  const FacilityReviewForm({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  State<FacilityReviewForm> createState() => _FacilityReviewFormState();
}

class _FacilityReviewFormState extends State<FacilityReviewForm> {
  final _formKey = GlobalKey<FormState>();

  // State nilai rating (Default 0 atau 5 terserah, di sini 0 biar user harus pilih)
  int _cleanliness = 0;
  int _fieldCondition = 0;
  bool _isLoading = false; // Untuk loading state tombol

  final TextEditingController _commentController = TextEditingController();

  // Widget Helper untuk membuat Bintang
  Widget _buildStarRating(String label, int value, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w500, 
            color: Colors.white70 // text-white/90
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.star,
                  size: 40, // Ukuran bintang besar
                  color: starIndex <= value 
                      ? const Color(0xFFFBBF24) // Warna Kuning Emas (#fbbf24)
                      : Colors.grey.shade600,   // Warna abu gelap untuk yang belum dipilih
                ),
              ),
            );
          }),
        ),
        // Error message placeholder jika validasi gagal (opsional)
        if (value == 0) 
           const Padding(
             padding: EdgeInsets.only(top: 4.0),
             child: Text("*Required", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
           ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      // Extend body agar background full screen di belakang appbar/status bar
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          // LAYER 1: Background Image Full Screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/SRVEreviews.jpg', // Pastikan path ini benar
              fit: BoxFit.cover,
            ),
          ),

          // LAYER 2: Overlay Warna (Supaya teks terbaca)
          // style="background: rgba(229, 215, 196, 0.65);" dicampur hitam sedikit
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5), 
            ),
          ),

          // LAYER 3: Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button (Mirip link 'Back to Courts')
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    label: const Text(
                      "Back to Courts", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD GLASSMORPHISM
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), // rounded-2xl
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // backdrop-blur-lg
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 500), // max-w-lg
                          decoration: BoxDecoration(
                            // bg-black/20 border border-white/20
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Text
                                const Text(
                                  "Leave a Review for",
                                  style: TextStyle(
                                    fontSize: 24, // text-3xl
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45)]
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.facilityName,
                                  style: const TextStyle(
                                    fontSize: 22, // text-2xl
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF86EFAC), // text-green-300
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // INPUT 1: Cleanliness (Star Rating)
                                _buildStarRating(
                                  "Cleanliness", 
                                  _cleanliness, 
                                  (val) => setState(() => _cleanliness = val)
                                ),

                                const SizedBox(height: 24),

                                // INPUT 2: Field Condition (Star Rating)
                                _buildStarRating(
                                  "Field Condition", 
                                  _fieldCondition, 
                                  (val) => setState(() => _fieldCondition = val)
                                ),

                                const SizedBox(height: 24),

                                // INPUT 3: Comment
                                const Text(
                                  "Comment",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w500, 
                                    color: Colors.white70
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _commentController,
                                  style: const TextStyle(color: Color(0xFF1F2937)), // Text color gelap
                                  decoration: InputDecoration(
                                    hintText: "Write your comment here...",
                                    hintStyle: const TextStyle(color: Colors.black38),
                                    filled: true,
                                    // background-color: rgba(255, 255, 255, 0.9);
                                    fillColor: Colors.white.withOpacity(0.9), 
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF556047), width: 2),
                                    )
                                  ),
                                  maxLines: 4,
                                  validator: (value) => (value == null || value.isEmpty) 
                                      ? 'Comment cannot be empty' 
                                      : null,
                                ),

                                const SizedBox(height: 32),

                                // TOMBOL SUBMIT
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      // bg-[#556047]/90
                                      backgroundColor: const Color(0xFF556047),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 4,
                                    ),
                                    onPressed: _isLoading ? null : () async {
                                      if (_formKey.currentState!.validate()) {
                                        // Validasi Rating Manual
                                        if (_cleanliness == 0 || _fieldCondition == 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Please give stars for both categories"),
                                              backgroundColor: Colors.red,
                                            )
                                          );
                                          return;
                                        }

                                        setState(() => _isLoading = true);

                                        try {
                                          final response = await ReviewService().createFacilityReview(
                                            request, 
                                            widget.facilityId, 
                                            {
                                              'cleanliness': _cleanliness,     // Integer 1-5
                                              'field_condition': _fieldCondition, // Integer 1-5
                                              'comment': _commentController.text,
                                            }
                                          );

                                          if (context.mounted) {
                                            setState(() => _isLoading = false);
                                            if (response['success'] == true) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Review submitted successfully!"),
                                                  backgroundColor: Colors.green,
                                                )
                                              );
                                              Navigator.pop(context, true); // Balik dan refresh
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(response['message'] ?? "Failed"),
                                                  backgroundColor: Colors.red,
                                                )
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Error: $e"))
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: _isLoading 
                                      ? const SizedBox(
                                          width: 24, 
                                          height: 24, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        )
                                      : const Text(
                                          "Send Review",
                                          style: TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}