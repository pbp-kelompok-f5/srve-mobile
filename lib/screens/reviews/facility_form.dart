import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
// Import widget slider yang tadi dibuat
import '../../widgets/rating_slider.dart'; 

class FacilityReviewForm extends StatefulWidget {
  final int facilityId; // Kita butuh ID fasilitas yang mau direview

  const FacilityReviewForm({Key? key, required this.facilityId}) : super(key: key);

  @override
  State<FacilityReviewForm> createState() => _FacilityReviewFormState();
}

class _FacilityReviewFormState extends State<FacilityReviewForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Variable untuk menyimpan input user
  double _cleanliness = 5.0;
  double _fieldCondition = 5.0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Facility'),
      ),
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
                
                // 1. Slider Kebersihan
                RatingSlider(
                  label: "Cleanliness",
                  value: _cleanliness,
                  onChanged: (val) => setState(() => _cleanliness = val),
                ),

                // 2. Slider Kondisi Lapangan
                RatingSlider(
                  label: "Field Condition",
                  value: _fieldCondition,
                  onChanged: (val) => setState(() => _fieldCondition = val),
                ),

                // 3. Input Komentar
                const Text("Comment", style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Write your comment here",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Comment cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // 4. Tombol Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final response = await request.postJson(
                          "http://127.0.0.1:8000/reviews/facility/${widget.facilityId}/create/", 
                          jsonEncode(<String, dynamic>{
                            'cleanliness': _cleanliness,
                            'field_condition': _fieldCondition,
                            'comment': _commentController.text,
                          }),
                        );

                        if (context.mounted) {
                          if (response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review berhasil disimpan!")));
                            Navigator.pop(context); // Kembali ke halaman sebelumnya
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed")));
                          }
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