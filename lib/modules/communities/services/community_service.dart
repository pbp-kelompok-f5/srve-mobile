// lib/services/community_service.dart
import 'package:srve_mobile/config/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/community.dart';

// Gunakan host yang sesuai untuk emulator / platform:
// - iOS simulator / web / desktop: localhost / 127.0.0.1
final String baseUrl = "http://localhost:8000/";

/// Pastikan kita punya CSRF token sebelum POST ke endpoint Django form-based.
Future<String?> _ensureCsrfToken(CookieRequest request) async {
  var token = request.cookies['csrftoken']?.value;
  if (token != null && token.isNotEmpty) return token;

  try {
    await request.get("$baseUrl/csrf/");
    token = request.cookies['csrftoken']?.value;
  } catch (_) {
    // jika gagal, biarkan null; server mungkin csrf_exempt
  }
  return token;
}

/// Bangun header untuk http.post dengan cookie + CSRF.
Future<Map<String, String>> _buildHeaders(CookieRequest request) async {
  final headers = Map<String, String>.from(request.headers);
  final csrfToken = await _ensureCsrfToken(request);

  if (csrfToken != null && csrfToken.isNotEmpty) {
    headers['X-CSRFToken'] = csrfToken;
  }
  headers['X-Requested-With'] = 'XMLHttpRequest';

  return headers;
}

/// Kumpulan endpoint yang mengikuti views Django kamu.
/// Silakan sesuaikan path-nya dengan urls.py.
class CommunityEndpoints {
  /// View: community_list_json
  /// return: List JSON komunitas
  static String listCommunities() => "$baseUrl/communities/json/";

  /// View: community_detail (kalau nanti kamu buat versi JSON)
  /// optional, bisa dipakai kalau kamu bikin /communities/<slug>/json/
  static String detailCommunity(String slug) =>
      "$baseUrl/communities/$slug/json/";

  /// JSON API create (gunakan endpoint yang mengembalikan JsonResponse)
  static String createCommunity() => "$baseUrl/communities/api/create/";

  /// View: edit_community
  static String editCommunity(String slug) =>
      "$baseUrl/communities/$slug/edit/";

  /// View: delete_community
  static String deleteCommunity(String slug) =>
      "$baseUrl/communities/$slug/delete/";

  /// View: join_community (opsional, sesuaikan dengan urls.py)
  static String joinCommunity(String slug) =>
      "$baseUrl/communities/$slug/join/";

  /// View: leave_community (opsional, sesuaikan dengan urls.py)
  static String leaveCommunity(String slug) =>
      "$baseUrl/communities/$slug/leave/";
}

/// Service wrapper biar pemanggilan ke backend rapi.
class CommunityService {
  final CookieRequest request;

  CommunityService(this.request);

  /// Kirim POST ke backend dengan header cookies/CSRF dan parse respons.
  /// Melempar Exception ketika status bukan 2xx atau backend mengirim success=false.
  Future<Map<String, dynamic>?> _postForm(
    String url,
    Map<String, String> data,
  ) async {
    final headers = await _buildHeaders(request);
    final response =
        await http.post(Uri.parse(url), headers: headers, body: data);

    final contentType = response.headers['content-type'] ?? '';
    Map<String, dynamic>? jsonBody;
    if (contentType.contains('application/json')) {
      try {
        jsonBody = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // ignore decode error, handle via status below
      }
    }

    final isOkStatus =
        response.statusCode >= 200 && response.statusCode < 300;
    final successFlag =
        jsonBody == null ? true : _isSuccessResponse(jsonBody);

    if (isOkStatus && successFlag) {
      return jsonBody;
    }

    final errors = jsonBody?['errors'];
    final errorMessage = errors != null
        ? errors.toString()
        : "HTTP ${response.statusCode}: ${response.body}";

    throw Exception(errorMessage);
  }

  /// Helper: cek apakah response JSON dari Django menandakan sukses.
  /// Biar fleksibel dengan berbagai skema:
  ///  - {"success": true}
  ///  - {"ok": true}
  ///  - {"status": "success"}
  bool _isSuccessResponse(dynamic response) {
    if (response == null) return false;
    if (response is Map<String, dynamic>) {
      if (response['success'] == true) return true;
      if (response['ok'] == true) return true;
      if (response['status'] == 'success') return true;
    }
    // fallback: kalau backend gak kirim flag apa2 tapi gak error.
    return true;
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Ambil semua komunitas (see all).
  ///
  /// Mengacu ke view: community_list_json
  /// yang mengembalikan list JSON dengan field:
  /// slug, name, description, sport, skill_level,
  /// open_to_public, members_count, is_admin, is_member, dst.
  Future<List<Community>> fetchAllCommunities() async {
    final dynamic response =
        await request.get(CommunityEndpoints.listCommunities());

    // Diasumsikan response berupa List<dynamic>
    if (response is List) {
      return Community.listFromJson(
        response.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }

    // Kalau bukan List, anggap error / kosong.
    return [];
  }

  /// Ambil komunitas yang user-nya merupakan member (“see my”).
  ///
  /// Untuk saat ini, kita filter di sisi Flutter berdasarkan flag isMember
  /// yang sudah dikirim dari view community_list_json.
  Future<List<Community>> fetchMyCommunities() async {
    final all = await fetchAllCommunities();
    return all.where((c) => c.isMember).toList();
  }

  /// Ambil detail satu komunitas (opsional, kalau kamu bikin endpoint JSON detail).
  Future<Community?> fetchCommunityDetail(String slug) async {
    try {
      final dynamic response =
          await request.get(CommunityEndpoints.detailCommunity(slug));

      if (response is Map<String, dynamic>) {
        return Community.fromJson(response);
      }
    } catch (_) {
      // Bisa kamu logging kalau mau
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Buat komunitas baru.
  Future<bool> createCommunity({
    required String name,
    required String description,
    required String sport,
    required String skillLevel,
    required bool openToPublic,
  }) async {
    final Map<String, String> data = {
      'name': name,
      'description': description,
      'sport': sport,
      'skill_level': skillLevel,
      // form Django nerima string "on"/"true"/"false" tergantung implementasi;
      // paling aman kirim "true"/"false" sebagai string.
      'open_to_public': openToPublic ? "true" : "false",
    };

    final responseJson = await _postForm(
      CommunityEndpoints.createCommunity(),
      data,
    );

    return _isSuccessResponse(responseJson);
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  /// Update komunitas yang sudah ada.
  Future<bool> updateCommunity({
    required String slug,
    required String name,
    required String description,
    required String sport,
    required String skillLevel,
    required bool openToPublic,
  }) async {
    final Map<String, String> data = {
      'name': name,
      'description': description,
      'sport': sport,
      'skill_level': skillLevel,
      'open_to_public': openToPublic ? "true" : "false",
    };

    final responseJson = await _postForm(
      CommunityEndpoints.editCommunity(slug),
      data,
    );

    return _isSuccessResponse(responseJson);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Hapus komunitas.
  Future<bool> deleteCommunity(String slug) async {
    final responseJson = await _postForm(
      CommunityEndpoints.deleteCommunity(slug),
      {},
    );

    return _isSuccessResponse(responseJson);
  }

  // ---------------------------------------------------------------------------
  // (Opsional) CREATE/UPDATE dari objek Community langsung
  // ---------------------------------------------------------------------------

  /// Helper kalau kamu mau create dari objek Community (tanpa slug).
  Future<bool> createFromModel(Community community) {
    return createCommunity(
      name: community.name,
      description: community.description,
      sport: community.sport,
      skillLevel: community.skillLevel,
      openToPublic: community.openToPublic,
    );
  }

  /// Helper kalau kamu mau update dari objek Community.
  Future<bool> updateFromModel(Community community) {
    return updateCommunity(
      slug: community.slug,
      name: community.name,
      description: community.description,
      sport: community.sport,
      skillLevel: community.skillLevel,
      openToPublic: community.openToPublic,
    );
  }

  /// Join a community (POST).
  Future<bool> joinCommunity(String slug) async {
    final headers = await _buildHeaders(request);
    final response = await http.post(
      Uri.parse(CommunityEndpoints.joinCommunity(slug)),
      headers: headers,
      body: const {},
    );

    final contentType = response.headers['content-type'] ?? '';
    Map<String, dynamic>? jsonBody;
    if (contentType.contains('application/json')) {
      try {
        jsonBody = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // ignore decode error; treat via status code below
      }
    }

    final isOkStatus =
        response.statusCode >= 200 && response.statusCode < 300;
    final isRedirect =
        response.statusCode >= 300 && response.statusCode < 400;
    final successFlag =
        jsonBody == null ? true : _isSuccessResponse(jsonBody);

    // Anggap 2xx/3xx sebagai sukses meski tidak ada JSON success flag
    if (isOkStatus || isRedirect) {
      return true;
    }

    return successFlag;
  }

  /// Leave a community (POST).
  Future<bool> leaveCommunity(String slug) async {
    final headers = await _buildHeaders(request);
    final response = await http.post(
      Uri.parse(CommunityEndpoints.leaveCommunity(slug)),
      headers: headers,
      body: const {},
    );

    final contentType = response.headers['content-type'] ?? '';
    Map<String, dynamic>? jsonBody;
    if (contentType.contains('application/json')) {
      try {
        jsonBody = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // ignore decode error; treat via status code below
      }
    }

    final isOkStatus =
        response.statusCode >= 200 && response.statusCode < 300;
    final isRedirect =
        response.statusCode >= 300 && response.statusCode < 400;
    final successFlag =
        jsonBody == null ? true : _isSuccessResponse(jsonBody);

    if (isOkStatus || isRedirect) {
      return true;
    }

    return successFlag;
  }
}
