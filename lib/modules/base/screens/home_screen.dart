import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';
import '../../profile_cello/screens/profile_screen.dart';
import 'landing_page.dart';
import '../../profile_cello/screens/profile_menu_screen.dart';
import 'package:srve_mobile/modules/threads/screens/threads_home_page.dart';
import '../../communities/screens/communities_list_page.dart';
import 'dart:convert';
import 'package:srve_mobile/config/api.dart';
import 'package:srve_mobile/modules/booking_erich/screens/facility_list_page.dart';
import 'package:srve_mobile/modules/booking_erich/screens/booking_list_page.dart';
import 'package:srve_mobile/modules/booking_erich/screens/booking_list_page.dart';





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
        await request.get('${Env.baseUrl}/accounts/ajax/profile/');
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

void openBookingSmokeTest(BuildContext context) {
  final request = context.read<CookieRequest>();

  String log = '';
  int? facilityId;
  int? lastBookingId;

  String tomorrowIso() {
    final d = DateTime.now().add(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void append(StateSetter setModalState, String s) {
    setModalState(() => log = '$log\n$s');
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking API Smoke Test (Fase 0)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            append(setModalState, 'GET alive: ${Env.bookingAliveApi}');
                            final res = await request.get(Env.bookingAliveApi);
                            append(setModalState, 'alive => $res');
                          } catch (e) {
                            append(setModalState, 'alive ERROR => $e');
                          }
                        },
                        child: const Text('Alive'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          try {
                            append(setModalState, 'GET facilities: ${Env.bookingFacilitiesApi}');
                            final res = await request.get(Env.bookingFacilitiesApi);

                            if (res is List && res.isNotEmpty && res.first is Map) {
                              facilityId = (res.first as Map)['id'] as int?;
                              append(setModalState, 'facilities count=${res.length}');
                              append(setModalState, 'picked facilityId=$facilityId');
                              append(setModalState, 'sample => ${jsonEncode(res.first)}');
                            } else {
                              append(setModalState, 'Unexpected facilities => $res');
                            }
                          } catch (e) {
                            append(setModalState, 'facilities ERROR => $e');
                          }
                        },
                        child: const Text('Facilities'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (facilityId == null) {
                            append(setModalState, '⚠️ Tekan Facilities dulu (facilityId null)');
                            return;
                          }
                          try {
                            final dateIso = tomorrowIso();
                            final url = Env.bookingAvailabilityApi(facilityId!, dateIso);
                            append(setModalState, 'GET availability: $url');

                            final res = await request.get(url);
                            append(setModalState, 'availability => ${jsonEncode(res).substring(0, 200)}...');
                          } catch (e) {
                            append(setModalState, 'availability ERROR => $e');
                          }
                        },
                        child: const Text('Availability'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (facilityId == null) {
                            append(setModalState, '⚠️ Tekan Facilities dulu (facilityId null)');
                            return;
                          }
                          try {
                            await request.get(Env.bookingAliveApi); // seed CSRF

                            final body = {
                              "facility": facilityId,
                              "date": tomorrowIso(),
                              "start": "10:00",
                            };

                            append(setModalState, 'POST book: ${Env.bookingBookApi}');
                            append(setModalState, 'payload => $body');

                            final res = await request.postJson(
                              Env.bookingBookApi,
                              jsonEncode(body),
                            );

                            append(setModalState, 'book => $res');

                            if (res is Map && res['ok'] == true) {
                              lastBookingId = res['booking_id'];
                              append(setModalState, '✅ booking_id=$lastBookingId');
                            }
                          } catch (e) {
                            append(setModalState, 'book ERROR => $e');
                          }
                        },
                        child: const Text('Book 10:00'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (lastBookingId == null) {
                            append(setModalState, '⚠️ Book dulu (lastBookingId null)');
                            return;
                          }
                          try {
                            await request.get(Env.bookingAliveApi); // seed CSRF

                            final body = {"id": lastBookingId};
                            append(setModalState, 'POST cancel: ${Env.bookingCancelApi}');
                            append(setModalState, 'payload => $body');

                            final res = await request.postJson(
                              Env.bookingCancelApi,
                              jsonEncode(body),
                            );

                            append(setModalState, 'cancel => $res');
                          } catch (e) {
                            append(setModalState, 'cancel ERROR => $e');
                          }
                        },
                        child: const Text('Cancel last'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Text('Log:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        log.isEmpty ? '(belum ada)' : log,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTabScreen(),
    CommunitiesListPage(),
    ThreadsHomePage(),     
<<<<<<< HEAD
<<<<<<< HEAD
    MatchListPage(),
    PlaceholderWidget(text: "Courts"),
=======
    PlaceholderWidget(text: "Matches"),
    BookingListPage(),
>>>>>>> 3dcf149b0cff62eafb729a76235a26a0a43da40d
=======
    PlaceholderWidget(text: "Matches"),
    BookingListPage(),
>>>>>>> 9afea11e3ec7824d2da94426e9dbf4bb0897d5e9
  ];
  void _openBookingSmokeTest(BuildContext context) {
  final request = context.read<CookieRequest>();

  String log = '';
  int? facilityId;
  int? lastBookingId;

  String tomorrowIso() {
    final d = DateTime.now().add(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void append(StateSetter setModalState, String s) {
    setModalState(() => log = '$log\n$s');
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking API Smoke Test (Fase 0)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            append(setModalState, 'GET alive: ${Env.bookingAliveApi}');
                            final res = await request.get(Env.bookingAliveApi);
                            append(setModalState, 'alive => $res');
                          } catch (e) {
                            append(setModalState, 'alive ERROR => $e');
                          }
                        },
                        child: const Text('Alive'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          try {
                            append(setModalState, 'GET facilities: ${Env.bookingFacilitiesApi}');
                            final res = await request.get(Env.bookingFacilitiesApi);

                            if (res is List && res.isNotEmpty && res.first is Map) {
                              facilityId = (res.first as Map)['id'] as int?;
                              append(setModalState, 'facilities count=${res.length}');
                              append(setModalState, 'picked facilityId=$facilityId');
                              append(setModalState, 'sample => ${jsonEncode(res.first)}');
                            } else {
                              append(setModalState, 'Unexpected facilities => $res');
                            }
                          } catch (e) {
                            append(setModalState, 'facilities ERROR => $e');
                          }
                        },
                        child: const Text('Facilities'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (facilityId == null) {
                            append(setModalState, '⚠️ Tekan Facilities dulu (facilityId null)');
                            return;
                          }
                          try {
                            final dateIso = tomorrowIso();
                            final url = Env.bookingAvailabilityApi(facilityId!, dateIso);
                            append(setModalState, 'GET availability: $url');

                            final res = await request.get(url);
                            append(setModalState, 'availability => ${jsonEncode(res).substring(0, 200)}...');
                          } catch (e) {
                            append(setModalState, 'availability ERROR => $e');
                          }
                        },
                        child: const Text('Availability'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (facilityId == null) {
                            append(setModalState, '⚠️ Tekan Facilities dulu (facilityId null)');
                            return;
                          }
                          try {
                            // penting: seed CSRF cookie dulu
                            await request.get(Env.bookingAliveApi);

                            final body = {
                              "facility": facilityId,
                              "date": tomorrowIso(),
                              "start": "10:00",
                            };

                            append(setModalState, 'POST book: ${Env.bookingBookApi}');
                            append(setModalState, 'payload => $body');

                            final res = await request.postJson(
                              Env.bookingBookApi,
                              jsonEncode(body),
                            );

                            append(setModalState, 'book => $res');

                            if (res is Map && res['ok'] == true) {
                              lastBookingId = res['booking_id'];
                              append(setModalState, '✅ booking_id=$lastBookingId');
                            }
                          } catch (e) {
                            append(setModalState, 'book ERROR => $e');
                          }
                        },
                        child: const Text('Book 10:00'),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (lastBookingId == null) {
                            append(setModalState, '⚠️ Book dulu (lastBookingId null)');
                            return;
                          }
                          try {
                            await request.get(Env.bookingAliveApi);

                            final body = {"id": lastBookingId};
                            append(setModalState, 'POST cancel: ${Env.bookingCancelApi}');
                            append(setModalState, 'payload => $body');

                            final res = await request.postJson(
                              Env.bookingCancelApi,
                              jsonEncode(body),
                            );

                            append(setModalState, 'cancel => $res');
                          } catch (e) {
                            append(setModalState, 'cancel ERROR => $e');
                          }
                        },
                        child: const Text('Cancel last'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Text('Log:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        log.isEmpty ? '(belum ada)' : log,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


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
                      icon: Icons.list_alt,
                      label: "My Bookings",
                      color: const Color(0xFF8EA07A),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookingListPage()),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.calendar_month,
                      label: "Book Court",
                      color: const Color(0xFF6B7E5A),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FacilityListPage()),
                        );
                      },
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
