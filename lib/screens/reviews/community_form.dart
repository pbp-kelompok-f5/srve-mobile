import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/rating_slider.dart';

class CommunityReviewForm extends StatefulWidget {
  final int communityId; // ID Komunitas

  const CommunityReviewForm({Key? key, required this.communityId}) : super(key: key);

  @override
  State<CommunityReviewForm> createState() => _CommunityReviewFormState();
}

class _CommunityReviewFormState extends State<CommunityReviewForm> {
  final _formKey = GlobalKey<FormState>();
  
  // 3 Kriteria untuk Komunitas
  double _communication = 5.0;
  double _sportmanship = 5.0;
  double _playtime = 5.0;
  
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Community')),
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
                RatingSlider(label: "Sportmanship", value: _sportmanship, onChanged: (val) => setState(() => _sportmanship = val)),
                RatingSlider(label: "Playtime", value: _playtime, onChanged: (val) => setState(() => _playtime = val)),

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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final url = "http://127.0.0.1:8000/reviews/community/${widget.communityId}/create/";
                        
                        try {
                          final response = await request.postJson(
                            url,
                            jsonEncode(<String, dynamic>{
                              'communication': _communication,
                              'sportmanship': _sportmanship,
                              'playtime': _playtime,
                              'comment': _commentController.text,
                            }),
                          );

                          if (context.mounted) {
                            if (response['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your review has been saved")));
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Gagal.")));
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