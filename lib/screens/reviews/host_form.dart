import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/rating_slider.dart';

class HostReviewForm extends StatefulWidget {
  final int hostId; // ID User si Host

  const HostReviewForm({Key? key, required this.hostId}) : super(key: key);

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
      appBar: AppBar(title: const Text('Review Host')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Leave a Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                RatingSlider(label: "Communication", value: _communication, onChanged: (val) => setState(() => _communication = val)),
                RatingSlider(label: "Responsiveness", value: _responsiveness, onChanged: (val) => setState(() => _responsiveness = val)),
                RatingSlider(label: "Punctuality", value: _punctuality, onChanged: (val) => setState(() => _punctuality = val)),

                const Text("Comment", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(hintText: "Write your comment here", border: OutlineInputBorder()),
                  maxLines: 4,
                  validator: (value) => (value == null || value.isEmpty) ? 'Comment cannot be empty' : null,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // TODO: GANTI URL
                        final url = "http://127.0.0.1:8000/reviews/host/${widget.hostId}/create//";
                        
                        try {
                          final response = await request.postJson(
                            url,
                            jsonEncode(<String, dynamic>{
                              'communication': _communication,
                              'responsiveness': _responsiveness,
                              'punctuality': _punctuality,
                              'comment': _commentController.text,
                            }),
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
                    child: const Text("Send Review"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}