import 'dart:ui'; // Diperlukan untuk ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/review_services.dart';

class CommunityReviewForm extends StatefulWidget {
  final String communitySlug;
  final String communityName;

  const CommunityReviewForm({
    super.key,
    required this.communitySlug,
    required this.communityName,
  });

  @override
  State<CommunityReviewForm> createState() => _CommunityReviewFormState();
}

class _CommunityReviewFormState extends State<CommunityReviewForm> {
  final _formKey = GlobalKey<FormState>();

  // Rating State
  double _communication = 0.0;
  double _sportmanship = 0.0;
  double _playtime = 0.0;

  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false; // Untuk handle loading state pada tombol

  // Widget Helper untuk Bintang
  Widget _buildStarRating(String label, double currentValue, Function(double) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white70, // text-white/90
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            int starIndex = index + 1;
            return GestureDetector(
              onTap: () {
                onUpdate(starIndex.toDouble());
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  starIndex <= currentValue ? Icons.star : Icons.star_border,
                  // Warna Amber/Kuning (#fbbf24) untuk aktif, Abu-abu untuk tidak aktif
                  color: starIndex <= currentValue ? const Color(0xFFFBBF24) : Colors.grey,
                  size: 32, // Ukuran font-size 2.5rem kira-kira 40, tapi 32 cukup proporsional di HP
                ),
              ),
            );
          }),
        ),
        // Error message placeholder (optional, bisa ditambah validasi visual di sini)
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      // Extend body agar background memenuhi layar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- LAYER 1: Background Image ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Pastikan gambar ini ada di pubspec.yaml
                // Menggunakan gambar sesuai template HTML
                image: AssetImage('assets/images/SRVEreviews.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),

          // --- LAYER 2: Overlay Hitam Transparan ---
          Container(
            color: const Color.fromRGBO(229, 215, 196, 0.65),
          ),

          // --- LAYER 3: Content ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Back
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 85, 96, 71), size: 20),
                    label: Text(
                      "Back to Community",
                      style: TextStyle(color: Color.fromARGB(255, 85, 96, 71), fontWeight: FontWeight.w800),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // --- GLASSMORPHISM CARD ---
                  // Efek: bg-black/20 backdrop-blur-lg border-white/20
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // backdrop-blur-lg
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2), // bg-black/20
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2), // border-white/20
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Judul
                              const Text(
                                "Leave a Review for",
                                style: TextStyle(
                                  fontSize: 24, // text-3xl
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))]
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.communityName,
                                style: const TextStyle(
                                  fontSize: 20, // text-2xl
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF86EFAC), // text-green-300 (Tailwind color)
                                ),
                              ),

                              const SizedBox(height: 32),

                              // --- RATING INPUTS ---
                              _buildStarRating("Communication", _communication, (val) => setState(() => _communication = val)),
                              _buildStarRating("Sportmanship", _sportmanship, (val) => setState(() => _sportmanship = val)),
                              _buildStarRating("Playtime", _playtime, (val) => setState(() => _playtime = val)),

                              // --- COMMENT INPUT ---
                              const Text(
                                "Comment",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _commentController,
                                style: const TextStyle(color: Color(0xFF1F2937)), // Text dark gray inside input
                                decoration: InputDecoration(
                                  hintText: "Write your comment here...",
                                  hintStyle: const TextStyle(color: Colors.black45),
                                  filled: true,
                                  // Background putih transparan (rgba(255, 255, 255, 0.9))
                                  fillColor: Colors.white.withOpacity(0.9),
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
                                maxLines: 5,
                                validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                              ),
                              
                              const SizedBox(height: 32),

                              // --- SUBMIT BUTTON ---
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(85, 96, 71, 1).withOpacity(0.9), // Warna #556047
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: _isLoading ? null : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // Validasi Rating manual (karena bukan TextFormField)
                                      if (_communication == 0 || _sportmanship == 0 || _playtime == 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please fill all star ratings")),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        final response = await ReviewService().createCommunityReview(
                                          request,
                                          widget.communitySlug,
                                          {
                                            'communication': _communication,
                                            'sportsmanship': _sportmanship, 
                                            'playtime': _playtime,
                                            'comment': _commentController.text,
                                          }
                                        );

                                        if (context.mounted) {
                                          if (response['status'] == 'success' || response['success'] == true) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Your review has been saved"),
                                                backgroundColor: Color(0xFF556047),
                                              )
                                            );
                                            Navigator.pop(context, true);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(response['message'] ?? "Failed to save review."),
                                                backgroundColor: Colors.red[400],
                                              )
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error: $e"))
                                          );
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                                  child: _isLoading
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20, 
                                              height: 20, 
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                            ),
                                            SizedBox(width: 10),
                                            Text("Processing...")
                                          ],
                                        )
                                      : const Text(
                                          "Send Review",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}