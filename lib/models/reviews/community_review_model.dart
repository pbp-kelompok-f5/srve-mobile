import 'dart:convert';

List<CommunityReview> communityReviewFromJson(String str) => 
    List<CommunityReview>.from(json.decode(str).map((x) => CommunityReview.fromJson(x)));

class CommunityReview {
  final int pk;
  final String username;
  final double rating;
  final String comment;
  final String createdAt;
  // Field Khusus Komunitas
  final double communication;
  final double sportmanship;
  final double playtime;

  CommunityReview({
    required this.pk,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.communication,
    required this.sportmanship,
    required this.playtime,
  });

  factory CommunityReview.fromJson(Map<String, dynamic> json) {
    return CommunityReview(
      pk: json['pk'],
      username: json['username'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      createdAt: json['created_at'],
      communication: (json['communication'] as num).toDouble(),
      sportmanship: (json['sportmanship'] as num).toDouble(),
      playtime: (json['playtime'] as num).toDouble(),
    );
  }
}