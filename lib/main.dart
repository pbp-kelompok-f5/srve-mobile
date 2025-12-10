import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'modules/profile_cello/screens/landing_page.dart';
import 'modules/profile_cello/providers/profile_provider.dart';
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CookieRequest()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SRVE",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B7E5A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD4D3C9),
          elevation: 0,
        ),
      ),
      home: const LandingPage(), // halaman awal
    );
  }
}
