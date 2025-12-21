import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class Env {
  // Backend base URL
  static const String baseUrl = 'https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/';

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
