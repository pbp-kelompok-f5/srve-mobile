import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../base/screens/home_screen.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'match_history_screen.dart';
import 'my_communities_screen.dart';
import 'delete_profile_screen.dart';

class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final request = Provider.of<CookieRequest>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFFD4D3C9),
      ),

      // BURGER MENU (DRAWER)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF6B7E5A),
              ),
              child: FutureBuilder(
                future: Provider.of<CookieRequest>(context, listen: false)
                    .get("https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/profile/"),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final data = snapshot.data as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 48, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        data["data"]?["username"] ?? "User",
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  );
                },
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Back to Home"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await request.logout("https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/logout/");
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            _menuItem(
              context,
              icon: Icons.person,
              title: "Profile",
              page: const ProfileScreen(),
            ),

            _menuItem(
              context,
              icon: Icons.edit,
              title: "Edit Profile",
              page: const EditProfileScreen(),
            ),

            _menuItem(
              context,
              icon: Icons.lock,
              title: "Change Password",
              page: const ChangePasswordScreen(),
            ),

            // _menuItem(
            //   context,
            //   icon: Icons.history,
            //   title: "Match History",
            //   page: const MatchHistoryScreen(),
            // ),

            // _menuItem(
            //   context,
            //   icon: Icons.group,
            //   title: "My Communities",
            //   page: const MyCommunitiesScreen(),
            // ),

            _menuItem(
              context,
              icon: Icons.delete_forever,
              title: "Delete Profile",
              page: const DeleteProfileScreen(),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    Color color = Colors.black,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
