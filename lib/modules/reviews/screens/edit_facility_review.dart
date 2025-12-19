import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/rating_slider.dart';
import '../services/review_services.dart'; // Import Service

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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/SRVEreviews.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0E4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Edit Review for", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(widget.facilityName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                        const SizedBox(height: 20),

                        RatingSlider(label: "Cleanliness", value: _cleanliness, onChanged: (val) => setState(() => _cleanliness = val)),
                        RatingSlider(label: "Field Condition", value: _fieldCondition, onChanged: (val) => setState(() => _fieldCondition = val)),

                        const SizedBox(height: 10),
                        const Text("Comment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                        ),
                        const SizedBox(height: 30),

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
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review updated successfully!")));
                                      Navigator.pop(context, true);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Update failed")));
                                    }
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              }
                            },
                            child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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