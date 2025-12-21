import 'package:flutter/material.dart';
// Import modul Matches (sesuai struktur folder baru kamu)
import 'package:srve_mobile/modules/matches/screens/match_list.dart';
import 'package:srve_mobile/modules/matches/screens/match_form.dart';
import 'package:srve_mobile/main.dart'; 

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              // Ganti warna sesuai tema SRVE (Olive Green)
              color: Color(0xFF6B7E5A), 
            ),
            child: Column(
              children: [
                Text(
                  'SRVE Mobile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Text("Cari lawan tandingmu di sini!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Halaman Utama'),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_tennis),
            title: const Text('Daftar Match'),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchListPage(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tambah Match'),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchFormPage(),
                  ));
            },
          ),
        ],
      ),
    );
  }
}