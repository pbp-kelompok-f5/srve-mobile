class Env {
  // Backend base URL
  static const String baseUrl = 'http://10.0.2.2:8000';
  // Kalau kamu pakai iOS simulator / macOS, ganti jadi:
  // static const String baseUrl = 'http://127.0.0.1:8000';

  // Threads
  static String get threadsListApi => '$baseUrl/threads/api/';
  static String get threadsCreateApi => '$baseUrl/threads/api/create/';


  static String get bookingAliveApi => '$baseUrl/booking/alive/';
  static String get bookingFacilitiesApi => '$baseUrl/booking/json_facilities/';
  static String bookingAvailabilityApi(int facilityId, String dateIso) =>
      '$baseUrl/booking/api/availability/?facility=$facilityId&date=$dateIso';

  static String get bookingBookApi => '$baseUrl/booking/api/book/';
  static String get bookingCancelApi => '$baseUrl/booking/api/cancel/';
}
