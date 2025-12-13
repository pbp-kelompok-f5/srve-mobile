import 'dart:convert';

List<HostReview> hostReviewFromJson(String str) => 
    List<HostReview>.from(json.decode(str).map((x) => HostReview.fromJson(x)));

class HostReview {
  final int pk;
  final String username;
  final double rating;
  final String comment;
  final String createdAt;
  // Field Khusus Host
  final double communication;
  final double responsiveness;
  final double punctuality;

  HostReview({
    required this.pk,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.communication,
    required this.responsiveness,
    required this.punctuality,
  });

  factory HostReview.fromJson(Map<String, dynamic> json) {
    return HostReview(
      pk: json['pk'],
      username: json['username'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      createdAt: json['created_at'],
      communication: (json['communication'] as num).toDouble(),
      responsiveness: (json['responsiveness'] as num).toDouble(),
      punctuality: (json['punctuality'] as num).toDouble(),
    );
  }
}