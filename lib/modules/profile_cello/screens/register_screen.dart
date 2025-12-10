import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'home_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String _username = "";
  String _password1 = "";
  String _password2 = "";
  bool _isLoading = false;

  // GANTI BASE URL jika perlu (emulator vs real device)
  // Android emulator => 10.0.2.2
  // iOS simulator / web => 127.0.0.1
  static const String baseUrl = "http://10.0.2.2:8000";

  Future<void> _register(BuildContext context) async {
    final request = Provider.of<CookieRequest>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // simple client-side check
    if (_password1 != _password2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // pbp_django_auth provides request.post / login wrappers
      final response = await request.post(
        "$baseUrl/accounts/ajax/register/",
        {
          "username": _username,
          "password1": _password1,
          "password2": _password2,
        },
      );

      // response expected: JSON with { success: bool, message: ... }
      if (response != null && response["success"] == true) {
        // server auto-logs-in user (your Django code does login(request, user))
        // Confirm cookies and redirect to Home
        if (!mounted) return;
        // debug print
        debugPrint("Registered — cookies: ${request.cookies}");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final message = (response != null && response["message"] != null)
            ? response["message"]
            : "Registration failed";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      // network / parsing errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      debugPrint("Register error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color(0xFFD4D3C9),
        foregroundColor: const Color(0xFF6B7E5A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.sports_tennis, color: Color(0xFF6B7E5A), size: 72),
                const SizedBox(height: 12),
                const Text(
                  "Create account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join SRVE — quick registration",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Username",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Username required" : null,
                        onSaved: (v) => _username = v!.trim(),
                      ),
                      const SizedBox(height: 16),

                      // Password 1
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? "Minimum 8 characters" : null,
                        onSaved: (v) => _password1 = v ?? "",
                      ),
                      const SizedBox(height: 16),

                      // Password 2
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirm password",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? "Minimum 8 characters" : null,
                        onSaved: (v) => _password2 = v ?? "",
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _register(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B7E5A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Link to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text("Log In", style: TextStyle(color: Color(0xFF6B7E5A))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
