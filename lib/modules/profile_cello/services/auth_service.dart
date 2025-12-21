import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';

class AuthService {
  // 🌐 Base URL Configuration
  // Karena kamu pakai Flutter langsung (bukan emulator), pakai localhost
  static const String baseUrl = 'https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/';
  
  // Alternatif: Kalau 127.0.0.1 ga jalan, coba 'http://localhost:8000'
  
  // 🔐 Login
  static Future<Map<String, dynamic>> login(
    CookieRequest request,
    String username,
    String password,
  ) async {
    try {
      await request.get("${Env.baseUrl}/csrf/");

      final response = await request.post(
        "${Env.baseUrl}/accounts/ajax/login/",
        {"username": username, "password": password},
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Login failed',
        'redirect_url': response['redirect_url'] ?? '/',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // 📝 Register
  static Future<Map<String, dynamic>> register(
    CookieRequest request,
    String username,
    String password1,
    String password2,
  ) async {
    try {
      final response = await request.post(
        "${Env.baseUrl}/accounts/ajax/register/",
        {
          'username': username,
          'password1': password1,
          'password2': password2,
        },
      );

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Registration failed',
        'redirect_url': response['redirect_url'] ?? '/',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // 🚪 Logout
  static Future<Map<String, dynamic>> logout(CookieRequest request) async {
    try {
      final response = await request.post(
        "${Env.baseUrl}/accounts/ajax/logout/",
        {},
      );

      return {
        'success': response['success'] ?? false,
        'redirect_url': response['redirect_url'] ?? '/',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Logout error: ${e.toString()}',
      };
    }
  }

  // ✅ Check if user is logged in
  static bool isLoggedIn(CookieRequest request) {
    return request.loggedIn;
  }

  // 👤 Get current user info
  static Future<Map<String, dynamic>?> getUserProfile(
    CookieRequest request,
  ) async {
    try {
      return await request.get(
        "${Env.baseUrl}/accounts/ajax/profile/",
      );
    } catch (e) {
      return null;
    }
  }
}
