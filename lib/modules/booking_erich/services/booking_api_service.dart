import 'dart:convert';

import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../models/booking_result.dart';
import '../models/booking_item.dart';

class BookingApiService {
  const BookingApiService();

  Map<String, dynamic> _ensureMap(dynamic res) {
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);

    // Jika server balas HTML / text (mis. CSRF/session expire) bisa jadi String
    if (res is String) {
      final s = res.toLowerCase();
      if (s.contains("<html") || s.contains("<!doctype")) {
        throw Exception(
          "Server mengirim HTML (kemungkinan session habis / CSRF). Coba login ulang.",
        );
      }
      throw Exception("Unexpected string response: $res");
    }

    throw Exception("Unexpected response type: ${res.runtimeType}");
  }

  Future<void> seedCsrf(CookieRequest request) async {
    await request.get(Env.bookingAliveApi);
  }

  Future<List<Facility>> fetchFacilities(CookieRequest request) async {
    final res = await request.get(Env.bookingFacilitiesApi);

    if (res is! List) {
      throw Exception('Facilities response bukan List: $res');
    }

    return res
        .whereType<Map>()
        .map((m) => Facility.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<Slot>> fetchAvailability(
    CookieRequest request, {
    required int facilityId,
    required String dateIso, // YYYY-MM-DD
  }) async {
    final url = Env.bookingAvailabilityApi(facilityId, dateIso);
    final res = await request.get(url);

    if (res is! Map) {
      throw Exception("Availability response bukan Map: $res");
    }

    final slotsRaw = res["slots"];
    if (slotsRaw is! List) return [];

    return slotsRaw
        .whereType<Map>()
        .map((m) => Slot.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<BookingResult> bookSlot(
    CookieRequest request, {
    required int facilityId,
    required String dateIso, // YYYY-MM-DD
    required String startHHmm, // "HH:MM"
  }) async {
    await seedCsrf(request);

    final payload = {
      "facility": facilityId,
      "date": dateIso,
      "start": startHHmm,
    };

    final res = await request.postJson(
      Env.bookingBookApi,
      jsonEncode(payload),
    );

    final m = _ensureMap(res);
    return BookingResult.fromJson(m);
  }


  Future<List<BookingItem>> fetchBookings(CookieRequest request) async {
    final res = await request.get(Env.bookingBookingsApi);

    if (res is! List) {
      throw Exception("Bookings response bukan List: $res");
    }

    return res
        .whereType<Map>()
        .map((m) => BookingItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> cancelBooking(CookieRequest request, int bookingId) async {
    await seedCsrf(request);

    final res = await request.postJson(
      Env.bookingCancelApi,
      jsonEncode({"id": bookingId}),
    );

    final m = _ensureMap(res);

    if (m["ok"] == true) return;

    throw Exception(m["error"]?.toString() ?? "Cancel gagal");
  }
}
