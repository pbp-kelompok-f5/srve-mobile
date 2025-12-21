import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// Pastikan path import ini sesuai dengan lokasi file service kamu
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

  // State
  int _cleanliness = 0;
  int _fieldCondition = 0;
  bool _isLoading = false;

  final TextEditingController _commentController = TextEditingController();

  // WIDGET HELPER BINTANG
  Widget _buildStarRating(String label, int value, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w500, 
            color: Colors.white70 
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
                  size: 40,
                  color: starIndex <= value 
                      ? const Color(0xFFFBBF24) // Kuning Emas
                      : Colors.white24,         // Abu transparan
                ),
              ),
            );
          }),
        ),
        if (value == 0 && _isLoading)
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
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 85, 96, 71)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Back to Courts", style: TextStyle(color: Color.fromARGB(255, 85, 96, 71), fontSize: 16, fontWeight: FontWeight.bold)),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          // LAYER 1: Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/SRVEreviews.jpg', 
              fit: BoxFit.cover,
            ),
          ),

          // LAYER 2: Overlay Hitam Transparan
          Positioned.fill(
            child: Container(
              color:  const Color.fromRGBO(229, 215, 196, 0.65),
            ),
          ),

          // LAYER 3: Form Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
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
                          // Header
                          const Text(
                            "Leave a Review for",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.facilityName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF86EFAC),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Rating Inputs
                          _buildStarRating("Cleanliness", _cleanliness, (val) => setState(() => _cleanliness = val)),
                          const SizedBox(height: 24),
                          _buildStarRating("Field Condition", _fieldCondition, (val) => setState(() => _fieldCondition = val)),

                          const SizedBox(height: 24),

                          // Comment Input
                          const Text("Comment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.black87),
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Share your experience...",
                              hintStyle: const TextStyle(color: Colors.black38),
                              filled: true,
                              fillColor: const Color(0xFFE5D7C4).withOpacity(0.9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) 
                                ? 'Please write a comment' 
                                : null,
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF556047),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  // Validasi Manual Bintang
                                  if (_cleanliness == 0 || _fieldCondition == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please provide a rating for both categories."),
                                        backgroundColor: Colors.red,
                                      )
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  try {
                                    // Panggil Service
                                    final response = await ReviewService().createFacilityReview(
                                      request, 
                                      widget.facilityId, 
                                      {
                                        'cleanliness': _cleanliness, // Kirim int, Django akan convert ke float
                                        'field_condition': _fieldCondition,
                                        'comment': _commentController.text,
                                      }
                                    );

                                    if (context.mounted) {
                                      setState(() => _isLoading = false);
                                      
                                      // PERBAIKAN PENTING: Gunakan .toString() untuk cek status
                                      // Ini mencegah error "int is not subtype of String"
                                      String status = response['status'].toString();
                                      
                                      if (status == 'success') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Review submitted successfully!"),
                                            backgroundColor: Colors.green,
                                          )
                                        );
                                        // Return true agar halaman sebelumnya bisa refresh
                                        Navigator.pop(context, true); 
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            // Gunakan toString() pada message juga
                                            content: Text(response['message']?.toString() ?? "Failed to submit review"),
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
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Submit Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}