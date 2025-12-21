class Env {
  // 🌐 Base URL untuk HP fisik (laptop kamu)
  static const String baseUrl = 'http://192.168.1.110:8000';

  // Threads list (GET)
  static String get threadsListApi => '$baseUrl/threads/api/';

  // Threads create (POST)
  static String get threadsCreateApi => '$baseUrl/threads/api/create/';
}
