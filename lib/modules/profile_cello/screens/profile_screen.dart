import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../providers/profile_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<ProfileProvider>(context, listen: false)
          .loadProfile(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = Provider.of<CookieRequest>(context);
    final provider = Provider.of<ProfileProvider>(context);

    // 🚨 USER BELUM LOGIN
    if (!request.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Please login first"),
          ),
        ),
      );
    }

    // ⏳ LOADING
    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ ERROR
    if (provider.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: Text("Failed to load profile")),
      );
    }

    // 🎉 SUCCESS
    final p = provider.profile!;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              p.username,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _infoTile("Bio", p.bio),
            _infoTile("Skill Level", p.skillLevel),
            _infoTile("Location", p.preferredLocation),
            _infoTile("Instagram", p.instagram),
            _infoTile("Date of Birth", p.dateOfBirth ?? "Not set"),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "Not set" : value,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
