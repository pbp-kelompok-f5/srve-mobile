import 'dart:convert';

List<FacilityReview> facilityReviewFromJson(String str) => 
    List<FacilityReview>.from(json.decode(str).map((x) => FacilityReview.fromJson(x)));

class FacilityReview {
  final int pk;
  final String username;
  final double rating;
  final String comment;
  final String createdAt;
  // Field Khusus Fasilitas
  final double cleanliness;
  final double fieldCondition;

  FacilityReview({
    required this.pk,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.cleanliness,
    required this.fieldCondition,
  });

  factory FacilityReview.fromJson(Map<String, dynamic> json) {
    return FacilityReview(
      pk: json['pk'],
      username: json['username'],
      rating: (json['rating'] as num).toDouble(), // Aman jika int atau double
      comment: json['comment'],
      createdAt: json['created_at'],
      cleanliness: (json['cleanliness'] as num).toDouble(),
      fieldCondition: (json['field_condition'] as num).toDouble(),
    );
  }
}