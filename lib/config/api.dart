class Env {
  // Backend base URL
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Threads list (GET) + like + replies
  static String get threadsListApi => '$baseUrl/threads/api/';

  // Threads create (POST)
  static String get threadsCreateApi => '$baseUrl/threads/api/create/';
}
