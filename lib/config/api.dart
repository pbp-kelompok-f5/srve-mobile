class Env {
  // Backend base URL
  static const String baseUrl = 'https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/';

  // Threads list (GET) + like + replies
  static String get threadsListApi => '$baseUrl/threads/api/';

  // Threads create (POST)
  static String get threadsCreateApi => '$baseUrl/threads/api/create/';
}
