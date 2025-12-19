import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../models/booking_result.dart';

import '../models/booking_item.dart';
import 'dart:convert';


class BookingApiService {
  const BookingApiService();

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
    required String dateIso,   // YYYY-MM-DD
    required String startHHmm, // "HH:MM"
  }) async {
    // Pastikan CSRF cookie ada
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

    if (res is Map<String, dynamic>) {
      return BookingResult.fromJson(res);
    }
    if (res is Map) {
      return BookingResult.fromJson(Map<String, dynamic>.from(res));
    }

    // kalau backend balas bukan JSON (harusnya nggak), kita bungkus jadi error
    return BookingResult(ok: false, error: "Unexpected response: $res");
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

  Future<bool> cancelBooking(CookieRequest request, int bookingId) async {
    await seedCsrf(request);

    final payload = {"id": bookingId};

    final res = await request.postJson(
      Env.bookingCancelApi,
      jsonEncode(payload),
    );

    // biasanya: {ok: true}
    if (res is Map && res["ok"] == true) return true;

    // kalau error JSON: {ok:false, error:"..."}
    if (res is Map && res["ok"] == false) {
      final msg = res["error"]?.toString() ?? "Cancel gagal";
      throw Exception(msg);
    }

    // fallback kalau response aneh
    throw Exception("Unexpected response cancel: $res");
  }


}








