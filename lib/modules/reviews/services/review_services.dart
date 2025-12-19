import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReviewService {
  // Base URL server Django kamu
  final String baseUrl = "http://10.0.2.2:8000";

  // ==================== COMMUNITY ====================

  // Create Community Review
  Future<Map<String, dynamic>> createCommunityReview(CookieRequest request, int communityId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/community/$communityId/create/",
      jsonEncode(data),
    );
    return response;
  }

  // Edit Community Review
  Future<Map<String, dynamic>> editCommunityReview(CookieRequest request, int reviewId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/community/edit/$reviewId/",
      jsonEncode(data),
    );
    return response;
  }

  // Delete Community Review
  Future<dynamic> deleteCommunityReview(CookieRequest request, int reviewId) async {
    // Delete biasanya tidak butuh body JSON, dan return-nya bisa jadi bukan JSON
    return await request.post("$baseUrl/reviews/delete/community/$reviewId/", {});
  }

  // ==================== FACILITY ====================

  // Create Facility Review
  Future<Map<String, dynamic>> createFacilityReview(CookieRequest request, int facilityId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/facility/$facilityId/create/",
      jsonEncode(data),
    );
    return response;
  }

  // Edit Facility Review
  Future<Map<String, dynamic>> editFacilityReview(CookieRequest request, int reviewId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/facility/edit/$reviewId/",
      jsonEncode(data),
    );
    return response;
  }

  // Delete Facility Review
  Future<dynamic> deleteFacilityReview(CookieRequest request, int reviewId) async {
    return await request.post("$baseUrl/reviews/delete/facility/$reviewId/", {});
  }

  // ==================== HOST ====================

  // Create Host Review
  Future<Map<String, dynamic>> createHostReview(CookieRequest request, int hostId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/host/$hostId/create/", 
      jsonEncode(data),
    );
    return response;
  }

  // Edit Host Review
  Future<Map<String, dynamic>> editHostReview(CookieRequest request, int reviewId, Map<String, dynamic> data) async {
    final response = await request.postJson(
      "$baseUrl/reviews/host/edit/$reviewId/",
      jsonEncode(data),
    );
    return response;
  }

  // Delete Host Review
  Future<dynamic> deleteHostReview(CookieRequest request, int reviewId) async {
    return await request.post("$baseUrl/reviews/delete/host/$reviewId/", {});
  }
}