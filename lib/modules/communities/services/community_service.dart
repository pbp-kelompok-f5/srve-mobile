// lib/services/community_service.dart

import 'dart:convert';

import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/community.dart';


const String baseUrl = "https://khayru-rafamanda-srve.pbp.cs.ui.ac.id";

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

  /// View: create_community / CreateCommunityView
  /// Di Django sekarang form HTML, tapi kamu bisa pakai endpoint ini
  /// untuk Flutter kalau: menerima POST + balikin JsonResponse untuk AJAX.
  static String createCommunity() => "$baseUrl/communities/create/";

  /// View: edit_community
  static String editCommunity(String slug) =>
      "$baseUrl/communities/$slug/edit/";

  /// View: delete_community
  static String deleteCommunity(String slug) =>
      "$baseUrl/communities/$slug/delete/";
}

/// Service wrapper biar pemanggilan ke backend rapi.
class CommunityService {
  final CookieRequest request;

  CommunityService(this.request);

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
  ///
  /// Mengacu ke view: create_community / CreateCommunityView
  /// yang menerima field form:
  /// - name
  /// - description
  /// - sport
  /// - skill_level
  /// - open_to_public
  ///
  /// Catatan:
  /// - Di Django, kemungkinan besar endpoint ini sekarang utamanya form HTML.
  ///   Kalau di dalam view kamu sudah handle request AJAX dan balikin JsonResponse,
  ///   Flutter bisa langsung pakai endpoint yang sama.
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

    final dynamic response =
        await request.post(CommunityEndpoints.createCommunity(), data);

    return _isSuccessResponse(response);
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  /// Update komunitas yang sudah ada.
  ///
  /// Mengacu ke view: edit_community
  /// biasanya path-nya /communities/<slug>/edit/
  ///
  /// Catatan:
  /// - Sama seperti create, sebaiknya view edit di Django juga handle
  ///   request AJAX / JSON dan balikin JsonResponse supaya Flutter enak makainya.
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

    final dynamic response =
        await request.post(CommunityEndpoints.editCommunity(slug), data);

    return _isSuccessResponse(response);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Hapus komunitas.
  ///
  /// Mengacu ke view: delete_community
  /// - biasanya hanya boleh dilakukan oleh creator / owner.
  /// - di Django sekarang, view-nya mungkin redirect kalau form HTML,
  ///   tapi kalau sudah kamu lengkapi dengan JsonResponse untuk AJAX,
  ///   Flutter bisa pakai endpoint yang sama.
  Future<bool> deleteCommunity(String slug) async {
    // Biasanya delete di Django butuh POST (bukan GET).
    final dynamic response =
        await request.post(CommunityEndpoints.deleteCommunity(slug), {});

    return _isSuccessResponse(response);
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
}
