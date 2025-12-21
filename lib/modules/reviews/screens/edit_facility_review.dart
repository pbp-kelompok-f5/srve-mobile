import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/review_services.dart'; 

class EditFacilityReviewForm extends StatefulWidget {
  final int reviewId;
  final double initialCleanliness;
  final double initialFieldCondition;
  final String initialComment;
  final String facilityName;

  const EditFacilityReviewForm({
    super.key,
    required this.reviewId,
    required this.initialCleanliness,
    required this.initialFieldCondition,
    required this.initialComment,
    required this.facilityName,
  });

  @override
  State<EditFacilityReviewForm> createState() => _EditFacilityReviewFormState();
}

class _EditFacilityReviewFormState extends State<EditFacilityReviewForm> {
  final _formKey = GlobalKey<FormState>();

  late double _cleanliness;
  late double _fieldCondition;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _cleanliness = widget.initialCleanliness;
    _fieldCondition = widget.initialFieldCondition;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  // --- WIDGET HELPER UNTUK BINTANG ---
  Widget _buildStarRating(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9), // Text-white/90
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            int starIndex = index + 1;
            return GestureDetector(
              onTap: () {
                onChanged(starIndex.toDouble());
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.star,
                  size: 36, // Ukuran bintang agak besar
                  color: starIndex <= value 
                      ? const Color(0xFFFBBF24) // Warna Kuning/Emas (Tailwind amber-400)
                      : const Color(0xFF4B5563), // Warna Abu gelap (Tailwind gray-600)
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Pastikan path asset ini benar sesuai projectmu
                image: AssetImage('assets/images/SRVEreviews.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 2. OVERLAY WARNA KREM (Sesuai HTML: rgba(229, 215, 196, 0.65))
          Container(
            color: const Color.fromARGB(166, 0, 0, 0),
          ),

          // 3. BACK BUTTON (Positioned di kiri atas)
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, color: Color.fromARGB(255, 85, 96, 71), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Back to Courts",
                    style: TextStyle(
                      color: Color.fromARGB(255, 85, 96, 71),
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. KONTEN TENGAH (CARD)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                // Lebar maksimal agar tidak terlalu lebar di tablet/layar besar
                constraints: const BoxConstraints(maxWidth: 500), 
                decoration: BoxDecoration(
                  // Glassmorphism effect (bg-black/20)
                  color: Colors.black.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)), // Border putih tipis
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Text(
                        "Update Your Review for",
                        style: TextStyle(
                          fontSize: 24, // text-3xl
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.facilityName,
                        style: const TextStyle(
                          fontSize: 20, // text-2xl
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF86EFAC), // Warna Hijau Muda (mirip Tailwind green-300)
                        ),
                      ),
                      
                      const SizedBox(height: 30),

                      // Input Stars: Cleanliness
                      _buildStarRating("Cleanliness", _cleanliness, (val) {
                        setState(() => _cleanliness = val);
                      }),

                      const SizedBox(height: 20),

                      // Input Stars: Field Condition
                      _buildStarRating("Field Condition", _fieldCondition, (val) {
                        setState(() => _fieldCondition = val);
                      }),

                      const SizedBox(height: 20),

                      // Input: Comment
                      const Text(
                        "Comment",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w500, 
                          color: Colors.white70
                        )
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        style: const TextStyle(color: Color(0xFF1F2937)), // Text abu gelap
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9), // Putih agak transparan
                          hintText: "Write your review here...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF556047), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 4, // Min-height mirip textarea HTML
                        validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                      ),
                      
                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF556047), // Warna Tombol HTML
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final response = await ReviewService().editFacilityReview(
                                  request, 
                                  widget.reviewId, 
                                  {
                                    'cleanliness': _cleanliness,
                                    'field_condition': _fieldCondition,
                                    'comment': _commentController.text,
                                  }
                                );

                                if (context.mounted) {
                                  if (response['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Review updated successfully!"),
                                        backgroundColor: Color(0xFF556047),
                                      )
                                    );
                                    Navigator.pop(context, true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response['message'] ?? "Update failed"),
                                        backgroundColor: Colors.red,
                                      )
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e"))
                                );
                              }
                            }
                          },
                          child: const Text("Update Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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