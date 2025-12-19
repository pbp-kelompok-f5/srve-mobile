import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/rating_slider.dart';
import '../services/review_services.dart'; // Import Service

class EditHostReviewForm extends StatefulWidget {
  final int reviewId;
  final double initialCommunication;
  final double initialResponsiveness;
  final double initialPunctuality;
  final String initialComment;
  final String hostName;

  const EditHostReviewForm({
    super.key,
    required this.reviewId,
    required this.initialCommunication,
    required this.initialResponsiveness,
    required this.initialPunctuality,
    required this.initialComment,
    required this.hostName,
  });

  @override
  State<EditHostReviewForm> createState() => _EditHostReviewFormState();
}

class _EditHostReviewFormState extends State<EditHostReviewForm> {
  final _formKey = GlobalKey<FormState>();

  late double _communication;
  late double _responsiveness;
  late double _punctuality;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _communication = widget.initialCommunication;
    _responsiveness = widget.initialResponsiveness;
    _punctuality = widget.initialPunctuality;
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
              label: const Text("Back to Host Profile", style: TextStyle(color: Colors.white)),
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
                        Text(widget.hostName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(height: 20),

                        RatingSlider(label: "Communication", value: _communication, onChanged: (val) => setState(() => _communication = val)),
                        RatingSlider(label: "Responsiveness", value: _responsiveness, onChanged: (val) => setState(() => _responsiveness = val)),
                        RatingSlider(label: "Punctuality", value: _punctuality, onChanged: (val) => setState(() => _punctuality = val)),

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
                          maxLines: 4,
                          validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // --- UPDATE: PAKAI SERVICE ---
                                try {
                                  final response = await ReviewService().editHostReview(
                                    request, 
                                    widget.reviewId, 
                                    {
                                      'communication': _communication,
                                      'responsiveness': _responsiveness,
                                      'punctuality': _punctuality,
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