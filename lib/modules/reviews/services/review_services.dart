import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReviewService {
  // Base URL server Django kamu
  final String baseUrl = "http://10.0.2.2:8000";
  
  // ==================== COMMUNITY ====================

  // Create Community Review
  Future<Map<String, dynamic>> createCommunityReview(CookieRequest request, String communitySlug, Map<String, dynamic> data) async {
    // URL SUDAH DIPERBAIKI: Mengarah ke /reviews/community/...
    final response = await request.postJson(
        "$baseUrl/reviews/community/$communitySlug/create-flutter/", 
        jsonEncode(data),
    );
    return response;
  }

  // Edit Community Review
  Future<Map<String, dynamic>> editCommunityReview(
      CookieRequest request, int reviewId, Map<String, dynamic> data) async {

    final Map<String, dynamic> formData = {
      'communication': data['communication'].toString(),
      'sportmanship': data['sportmanship'].toString(), // Pastikan ejaan sama dengan backend
      'playtime': data['playtime'].toString(),
      'comment': data['comment'] ?? "",
    };

    try {
      final response = await request.post(
        "$baseUrl/reviews/edit-community-flutter/$reviewId/", 
        formData,
      );


      if (response['status'] == 'success') {
        return {
          'success': true,
          'message': response['message'] ?? 'Review updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update review',
        };
      }
    } catch (e) {
      // Tangani error koneksi/parsing
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }


  // Delete Community Review
  Future<dynamic> deleteCommunityReview(CookieRequest request, int reviewId) async {
    return await request.post("$baseUrl/reviews/delete/community/$reviewId/", {});
  }

  // ==================== FACILITY ====================

  // Create Facility Review
  Future<Map<String, dynamic>> createFacilityReview(CookieRequest request, int facilityId, Map<String, dynamic> data) async {
    final url = '$baseUrl/reviews/api/facility/$facilityId/create-flutter/';
    
    final response = await request.postJson(
      url,
      jsonEncode(data), 
    );
    
    return response;
  }
  

  // Edit Facility Review
  Future<Map<String, dynamic>> editFacilityReview(
    CookieRequest request, 
    int reviewId, 
    Map<String, dynamic> data // Data: cleanliness, field_condition, comment
  ) async {
    
    final String url = 'http://10.0.2.2:8000/reviews/edit-flutter/$reviewId/'; 
  
    try {
      final response = await request.postJson(
        url,
        jsonEncode(data), 
      );

      if (response['status'] == 'success') {
        return {'success': true, 'message': response['message']};
      } else {
        return {'success': false, 'message': response['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error connecting to server: $e'};
    }
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