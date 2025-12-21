import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  String _oldPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final request = Provider.of<CookieRequest>(context, listen: false);

    try {
      final response = await request.post(
        "https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/profile/change-password/",
        {
          "old_password": _oldPassword,
          "new_password": _newPassword,
          "new_password_confirm": _confirmPassword,
        },
      );

      if (response["success"] == true) {
        if (!mounted) return;

        // ❗❗ JANGAN LOGOUT LAGI !!!
        request.cookies.clear();  // bersihkan session di Flutter

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed! Please log in again.")),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Failed.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: const Color(0xFFD4D3C9),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // OLD PASSWORD
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
                onSaved: (value) => _oldPassword = value!,
              ),
              const SizedBox(height: 16),

              // NEW PASSWORD
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.length < 8 ? "Minimum 8 characters" : null,
                onSaved: (value) => _newPassword = value!,
              ),
              const SizedBox(height: 16),

              // CONFIRM PASSWORD
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value != _newPassController.text
                        ? "Passwords do not match"
                        : null,
                onSaved: (value) => _confirmPassword = value!,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E5A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
