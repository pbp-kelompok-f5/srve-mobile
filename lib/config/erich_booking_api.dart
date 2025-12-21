import 'package:srve_mobile/config/api.dart';

class ErichBookingEnv {
  static String get baseUrl => Env.baseUrl;

  static String get alive => '$baseUrl/booking/alive/';
  static String get facilities => '$baseUrl/booking/json_facilities/';
  
  static String availability(int facilityId, String dateIso) =>
      '$baseUrl/booking/api/availability/?facility=$facilityId&date=$dateIso';

  static String get book => '$baseUrl/booking/api/book/';
  static String get cancel => '$baseUrl/booking/api/cancel/';
}
