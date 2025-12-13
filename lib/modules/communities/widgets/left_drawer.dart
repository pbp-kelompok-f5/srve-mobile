// lib/communities/widgets/left_drawer.dart

import 'package:flutter/material.dart';

import '../screens/communities_list_page.dart';
import '../screens/my_communities_page.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Communities Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          // All Communities
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('All Communities'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunitiesListPage(),
                ),
              );
            },
          ),

          // My Communities
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Communities'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyCommunitiesPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
