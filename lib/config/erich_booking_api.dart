import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ErichBookingEnv {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://localhost:8000/'; // Android emulator
    return 'http://localhost:8000/'; // iOS simulator / macOS
  }

  static String get alive => '$baseUrl/booking/alive/';
  static String get facilities => '$baseUrl/booking/json_facilities/';
  static String availability(int facilityId, String dateIso) =>
      '$baseUrl/booking/api/availability/?facility=$facilityId&date=$dateIso';

  static String get book => '$baseUrl/booking/api/book/';
  static String get cancel => '$baseUrl/booking/api/cancel/';
}
