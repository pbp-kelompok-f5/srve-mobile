import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/rating_slider.dart'; 
import '../services/review_services.dart'; // Import Service

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
  
  double _cleanliness = 5.0;
  double _fieldCondition = 5.0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/SRVEreviews.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // LAYER 2: Overlay
          Container(color: Colors.black.withOpacity(0.6)),

          // LAYER 3: Back Button
          Positioned(
            top: 50,
            left: 16,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text("Back to Courts", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),

          // LAYER 4: Form Card
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0E4), 
                    borderRadius: BorderRadius.circular(20),
                    // ignore: deprecated_member_use
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Leave a Review for", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(widget.facilityName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                        const SizedBox(height: 20),
                        
                        RatingSlider(
                          label: "Cleanliness",
                          value: _cleanliness,
                          onChanged: (val) => setState(() => _cleanliness = val),
                        ),

                        RatingSlider(
                          label: "Field Condition",
                          value: _fieldCondition,
                          onChanged: (val) => setState(() => _fieldCondition = val),
                        ),

                        const SizedBox(height: 10),
                        const Text("Comment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Write your comment here",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                        ),
                        const SizedBox(height: 30),

                        // Tombol Send
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF556B2F), 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // --- UPDATE: MENGGUNAKAN SERVICE ---
                                try {
                                  final response = await ReviewService().createFacilityReview(
                                    request, 
                                    widget.facilityId, 
                                    {
                                      'cleanliness': _cleanliness,
                                      'field_condition': _fieldCondition,
                                      'comment': _commentController.text,
                                    }
                                  );

                                  if (context.mounted) {
                                    if (response['success'] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review berhasil disimpan!")));
                                      Navigator.pop(context); 
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed")));
                                    }
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              }
                            },
                            child: const Text("Send Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}