import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'modules/base/screens/landing_page.dart';
import 'modules/profile_cello/providers/profile_provider.dart';
import 'modules/booking_erich/providers/booking_provider.dart';
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';

// --- IMPORT MODUL FITUR LAIN ---
import 'package:srve_mobile/modules/communities/screens/communities_list_page.dart';
import 'package:srve_mobile/modules/threads/screens/threads_home_page.dart';

// --- IMPORT MODUL MATCHES (CORRECTED PATH) ---
import 'package:srve_mobile/modules/matches/screens/match_list.dart';

// --- IMPORT WIDGETS UMUM ---
import 'package:srve_mobile/modules/communities/widgets/left_drawer.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CookieRequest()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  final Widget? home;

  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'SRVE Mobile',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.deepPurple,
          ).copyWith(secondary: Colors.deepPurple[400]),
        ),
        debugShowCheckedModeBanner: false,
        home: home ?? const LoginScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Daftar Halaman untuk Bottom Navigation Bar (CORRECTED)
  final List<Widget> _screens = [
    const HomeTabScreen(),           // Index 0: Home
    const CommunitiesListPage(),     // Index 1: Communities
    const ThreadsHomePage(),         // Index 2: Threads
    const MatchListPage(),           // Index 3: Matches (CORRECTED - was showing Courts placeholder)
    const CourtPlaceholder(),        // Index 4: Courts
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Communities'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Threads'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Courts'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6B7E5A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SRVE Home"),
        backgroundColor: const Color(0xFF6B7E5A),
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis, size: 100, color: Color(0xFF6B7E5A)),
            SizedBox(height: 20),
            Text(
              "Welcome to SRVE!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("Cari teman sparring kamu sekarang."),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Courts feature
class CourtPlaceholder extends StatelessWidget {
  const CourtPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Courts"),
        backgroundColor: const Color(0xFF6B7E5A),
      ),
      body: const Center(
        child: Text(
          "Courts Feature Coming Soon",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}