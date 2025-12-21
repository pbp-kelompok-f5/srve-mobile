import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class Env {
  // Base URL yang otomatis menyesuaikan platform
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000'; // ✅ Chrome Web di Mac
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000'; // ✅ Android emulator
      default:
        return 'http://127.0.0.1:8000'; // ✅ macOS app / iOS simulator
    }
  }

  // Threads
  static String get threadsListApi => '$baseUrl/threads/api/';
  static String get threadsCreateApi => '$baseUrl/threads/api/create/';

  // Booking
  static String get bookingAliveApi => '$baseUrl/booking/alive/';
  static String get bookingFacilitiesApi => '$baseUrl/booking/json_facilities/';
  static String bookingAvailabilityApi(int facilityId, String dateIso) =>
      '$baseUrl/booking/api/availability/?facility=$facilityId&date=$dateIso';
  static String get bookingBookApi => '$baseUrl/booking/api/book/';
  static String get bookingCancelApi => '$baseUrl/booking/api/cancel/';
  static String get bookingBookingsApi => '$baseUrl/booking/json_booking';
}
