import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/rating_slider.dart'; 
import '../services/review_services.dart';

class HostReviewForm extends StatefulWidget {
  final int hostId; 
  final String hostName;

  const HostReviewForm({
    super.key, 
    required this.hostId,
    required this.hostName,
  });

  @override
  State<HostReviewForm> createState() => _HostReviewFormState();
}

class _HostReviewFormState extends State<HostReviewForm> {
  final _formKey = GlobalKey<FormState>();
  
  // 3 Kriteria untuk Host
  double _communication = 5.0;
  double _responsiveness = 5.0;
  double _punctuality = 5.0;
  
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
              label: const Text("Back to Community", style: TextStyle(color: Colors.white)),
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
                            hintText: "Write your comment here",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 4,
                          validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                        ),
                        const SizedBox(height: 30),

                        // Tombol Send
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
                                  final response = await ReviewService().createHostReview(
                                    request, 
                                    widget.hostId, 
                                    {
                                      'communication': _communication,
                                      'responsiveness': _responsiveness,
                                      'punctuality': _punctuality,
                                      'comment': _commentController.text,
                                    }
                                  );

                                  if (context.mounted) {
                                    if (response['success'] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your review has been saved")));
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed.")));
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