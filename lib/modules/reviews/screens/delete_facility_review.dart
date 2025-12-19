import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/review_services.dart'; // Import Service

class DeleteFacilityReviewPage extends StatefulWidget {
  final int reviewId;
  final String facilityName;
  final String commentPreview;
  final double ratingPreview;

  const DeleteFacilityReviewPage({
    super.key,
    required this.reviewId,
    required this.facilityName,
    required this.commentPreview,
    this.ratingPreview = 0.0,
  });

  @override
  State<DeleteFacilityReviewPage> createState() => _DeleteFacilityReviewPageState();
}

class _DeleteFacilityReviewPageState extends State<DeleteFacilityReviewPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/SRVEreviews.jpg'), fit: BoxFit.cover),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Positioned(
            top: 50, left: 16,
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0E4), 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Delete Review", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          children: [
                            const TextSpan(text: "Are you sure you want to delete your review for "),
                            TextSpan(
                              text: widget.facilityName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)), 
                            ),
                            const TextSpan(text: "?"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          border: const Border(left: BorderSide(color: Colors.redAccent, width: 4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('"${widget.commentPreview}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), Text(" ${widget.ratingPreview.toStringAsFixed(1)}/5.0", style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: _isLoading ? null : () async {
                                setState(() => _isLoading = true);
                              
                                try {
                                  await ReviewService().deleteFacilityReview(request, widget.reviewId);
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review successfully deleted")));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Yes, Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                        ],
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