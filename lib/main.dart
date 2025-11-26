import 'package:flutter/material.dart';
import 'features/threads/pages/threads_home_page.dart';

void main() {
  runApp(const SrveApp());
}

class SrveApp extends StatelessWidget {
  const SrveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRVE',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const ThreadsHomePage(),
    );
  }
}
