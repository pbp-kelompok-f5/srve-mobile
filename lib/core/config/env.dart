class Env {
  // Emulator Android -> akses localhost Django pakai 10.0.2.2
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Endpoint API
  static const String threadsApi = '$baseUrl/threads/api/';
}
