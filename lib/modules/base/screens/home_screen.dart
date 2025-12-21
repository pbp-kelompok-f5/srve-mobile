import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';
import '../../profile_cello/screens/profile_screen.dart';
import 'landing_page.dart';
import '../../profile_cello/screens/profile_menu_screen.dart';
import 'package:srve_mobile/modules/threads/screens/threads_home_page.dart';
import '../../communities/screens/communities_list_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class UserMenuButton extends StatefulWidget {
  const UserMenuButton({super.key});

  @override
  State<UserMenuButton> createState() => _UserMenuButtonState();
}

class _UserMenuButtonState extends State<UserMenuButton> {
  String username = "User";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final request = Provider.of<CookieRequest>(context, listen: false);

    try {
      final response =
          await request.get("http://127.0.0.1:8000/accounts/ajax/profile/");

      if (response['success'] == true) {
        setState(() {
          username = response["data"]["username"] ?? "User";
        });
      }
    } catch (e) {
      // ignore if fails
    }
  }

  String getInitial() {
     if (username.isEmpty) return "U";
        return username[0].toUpperCase();
  }

 @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) async {
        final value = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx - 150,
            details.globalPosition.dy + 8,
            0,
            0,
          ),
          items: const [
            PopupMenuItem(
              value: "profile",
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 8),
                  Text("Profile"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "logout",
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text("Logout"),
                ],
              ),
            ),
          ],
        );

        if (!mounted) return;

        if (value == "profile") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileMenuScreen()),
          );
        }

        if (value == "logout") {
          final request = Provider.of<CookieRequest>(context, listen: false);
          await request.post("${Env.baseUrl}/accounts/ajax/logout/", {});

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
          );
        }
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF6B7E5A),
        child: Text(
          getInitial(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTabScreen(),
    CommunitiesListPage(),
    ThreadsHomePage(),     
    PlaceholderWidget(text: "Matches"),
    PlaceholderWidget(text: "Courts"),
  ];

  @override
  Widget build(BuildContext context) {
    final request = Provider.of<CookieRequest>(context);

    return Scaffold(
      appBar: AppBar(
      title: const Text(
        "SRVE",
        style: TextStyle(
          color: Color(0xFF6B7E5A),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFD4D3C9),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: UserMenuButton(),
        ),
      ],
    ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        indicatorColor: const Color(0xFF6B7E5A),
        backgroundColor: const Color(0xFFD4D3C9),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: "Communities",
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: "Threads",
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_tennis),
            selectedIcon: Icon(Icons.sports),
            label: "Matches",
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: "Courts",
          ),
        ],
      ),
    );
  }
}


class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌿 HERO SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B7E5A),
                  Color(0xFF8D9F78),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome to SRVE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Your Sports Community Platform",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 24),

                // 🔍 Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search courts or communities...",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ⚡ QUICK ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.45,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickActionCard(
                      icon: Icons.calendar_month,
                      label: "Book Court",
                      color: const Color(0xFF6B7E5A),
                      onTap: () {},
                    ),
                    _QuickActionCard(
                      icon: Icons.sports,
                      label: "Find Match",
                      color: const Color(0xFF7C8F69),
                      onTap: () {},
                    ),
                    _QuickActionCard(
                      icon: Icons.people,
                      label: "Communities",
                      color: const Color(0xFF8EA07A),
                      onTap: () {},
                    ),
                    _QuickActionCard(
                      icon: Icons.reviews,
                      label: "Reviews",
                      color: const Color(0xFF9BAE88),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ⭐ RECOMMENDED SECTION (placeholder dulu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Recommended Courts",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                _HorizontalPlaceholder(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Communities For You",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                _HorizontalPlaceholder(),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.85),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPlaceholder extends StatelessWidget {
  const _HorizontalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E4DA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Coming Soon",
                style: TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


/// Placeholder untuk tab lain
class PlaceholderWidget extends StatelessWidget {
  final String text;

  const PlaceholderWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$text - Coming Soon",
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
