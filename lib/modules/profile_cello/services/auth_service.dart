import 'package:pbp_django_auth/pbp_django_auth.dart';

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
      await request.get("$baseUrl/csrf/"); 

      final response = await request.post(
        "$baseUrl/accounts/ajax/login/",
        {"username": username, "password": password},
      );

      print('Login Response: $response');

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Login failed',
        'redirect_url': response['redirect_url'] ?? '/',
      };

    } catch (e) {
      print('Login Error: $e');
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
        '$baseUrl/accounts/ajax/register/',
        {
          'username': username,
          'password1': password1,
          'password2': password2,
        },
      );

      // Debug print
      print('Register Response: $response');

      if (response is Map) {
        return {
          'success': response['success'] ?? false,
          'message': response['message'] ?? 'Registration failed',
          'redirect_url': response['redirect_url'] ?? '/',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Register Error: $e');
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
        '$baseUrl/accounts/ajax/logout/',
        {},
      );

      print('Logout Response: $response');

      if (response is Map) {
        return {
          'success': response['success'] ?? false,
          'redirect_url': response['redirect_url'] ?? '/',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Logout Error: $e');
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

  // 👤 Get current user info (if needed)
  static Future<Map<String, dynamic>?> getUserProfile(CookieRequest request) async {
    try {
      final response = await request.get('$baseUrl/accounts/users/me/');
      return response;
    } catch (e) {
      print('Get Profile Error: $e');
      return null;
    }
  }
}