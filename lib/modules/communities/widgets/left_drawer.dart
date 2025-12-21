// lib/communities/widgets/left_drawer.dart

import 'package:flutter/material.dart';

import '../screens/my_communities_page.dart';
import 'navigation_helpers.dart';

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
              color: Color(0xFF6B7E5A),
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
            onTap: () => closeDrawerAndNavigateToCommunitiesHome(context),
          ),

          // My Communities
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Communities'),
            onTap: () {
              Navigator.pop(context); // close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(
                    name: MyCommunitiesPage.routeName,
                  ),
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
