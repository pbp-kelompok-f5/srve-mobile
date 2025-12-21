import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

// --- IMPORT MODUL AUTH & PROVIDERS (PENTING DARI MASTER) ---
import 'package:srve_mobile/modules/base/screens/landing_page.dart';
import 'package:srve_mobile/modules/profile_cello/providers/profile_provider.dart';
import 'package:srve_mobile/modules/booking_erich/providers/booking_provider.dart';

// --- IMPORT SCREENS UNTUK NAVIGASI (DARI KODEMU) ---
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';
import 'package:srve_mobile/modules/communities/screens/communities_list_page.dart';
import 'package:srve_mobile/modules/threads/screens/threads_home_page.dart';
import 'package:srve_mobile/modules/matches/screens/match_list.dart'; // Fitur Matches Kamu

// --- IMPORT WIDGETS ---
import 'package:srve_mobile/modules/communities/widgets/left_drawer.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CookieRequest()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()), // Provider Cello
        ChangeNotifierProvider(create: (_) => BookingProvider()), // Provider Erich
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
    return MaterialApp(
      title: 'SRVE Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ).copyWith(secondary: Colors.deepPurple[400]),
      ),
      debugShowCheckedModeBanner: false,
      // Gunakan LandingPage sebagai default (standar Master), 
      // atau LoginScreen jika kamu sedang debugging fitur spesifik.
      home: home ?? const LandingPage(), 
    );
  }
}