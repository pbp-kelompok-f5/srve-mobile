import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
// Pastikan path import ini benar sesuai struktur foldermu
import '../services/review_services.dart'; 

class EditCommunityReviewForm extends StatefulWidget {
  final int reviewId;
  final double initialCommunication;
  final double initialSportmanship; // Perhatikan ejaan variabel ini
  final double initialPlaytime;
  final String initialComment;
  final String communityName;

  const EditCommunityReviewForm({
    super.key,
    required this.reviewId,
    required this.initialCommunication,
    required this.initialSportmanship,
    required this.initialPlaytime,
    required this.initialComment,
    required this.communityName,
  });

  @override
  State<EditCommunityReviewForm> createState() => _EditCommunityReviewFormState();
}

class _EditCommunityReviewFormState extends State<EditCommunityReviewForm> {
  final _formKey = GlobalKey<FormState>();

  late double _communication;
  late double _sportmanship;
  late double _playtime;
  late TextEditingController _commentController;
  
  bool _isLoading = false; // Tambahan: Loading state agar tombol tidak dipencet 2x

  @override
  void initState() {
    super.initState();
    _communication = widget.initialCommunication;
    _sportmanship = widget.initialSportmanship;
    _playtime = widget.initialPlaytime;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
            color: Colors.white.withOpacity(0.9),
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
                  size: 36, 
                  color: starIndex <= value 
                      ? const Color(0xFFFBBF24) // Amber
                      : const Color(0xFF4B5563), // Grey
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
      extendBodyBehindAppBar: true, 
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/SRVEreviews.jpg', // Pastikan gambar ini ada di folder assets
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF556047)), // Fallback warna jika gambar gagal load
            ),
          ),
          
          // 2. OVERLAY WARNA
          Positioned.fill(
            child: Container(
              color: const Color.fromRGBO(229, 215, 196, 0.65),
            ),
          ),

          // 3. TOMBOL BACK
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Color(0xFF556047), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Back",
                      style: TextStyle(
                        color: Color(0xFF556047),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. CONTENT CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24), // Top padding lebih besar agar tidak ketutup tombol back
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500), 
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Gelapkan sedikit agar teks putih terbaca
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                        "Update Your Review",
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "for ${widget.communityName}",
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF86EFAC), 
                        ),
                      ),
                      
                      const SizedBox(height: 30),

                      // Input Ratings
                      _buildStarRating("Communication", _communication, (val) => setState(() => _communication = val)),
                      const SizedBox(height: 20),
                      _buildStarRating("Sportmanship", _sportmanship, (val) => setState(() => _sportmanship = val)),
                      const SizedBox(height: 20),
                      _buildStarRating("Playtime", _playtime, (val) => setState(() => _playtime = val)),

                      const SizedBox(height: 24),

                      // Input Comment
                      const Text(
                        "Comment",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          hintText: "Write your review here...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 4, 
                        validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                      ),
                      
                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF556047),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true); // Mulai loading
                              
                              try {
                                final response = await ReviewService().editCommunityReview(
                                  request, 
                                  widget.reviewId, 
                                  {
                                    'communication': _communication,
                                    'sportmanship': _sportmanship,
                                    'playtime': _playtime,
                                    'comment': _commentController.text,
                                  }
                                );

                                if (!context.mounted) return;

                                if (response['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Review updated successfully!"),
                                      backgroundColor: Color(0xFF556047),
                                    )
                                  );
                                  // Navigasi Balik + Kirim sinyal refresh
                                  Navigator.pop(context, true); 
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message'] ?? "Update failed"),
                                      backgroundColor: Colors.red,
                                    )
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e"))
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false); // Stop loading
                              }
                            }
                          },
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Update Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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