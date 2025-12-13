// lib/screens/communities/my_communities_page.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../screens/community_form_page.dart';
import '../screens/community_details_page.dart';
import '../services/community_service.dart';
import '../widgets/left_drawer.dart';

class MyCommunitiesPage extends StatefulWidget {
  const MyCommunitiesPage({super.key});

  @override
  State<MyCommunitiesPage> createState() => _MyCommunitiesPageState();
}

class _MyCommunitiesPageState extends State<MyCommunitiesPage> {
  late CommunityService _communityService;
  late Future<List<Community>> _futureMyCommunities;

  @override
  void initState() {
    super.initState();
    _communityService = CommunityService(context.read<CookieRequest>());
    _futureMyCommunities = _communityService.fetchMyCommunities();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMyCommunities = _communityService.fetchMyCommunities();
    });
    await _futureMyCommunities;
  }

  Future<void> _deleteCommunity(String slug) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Komunitas'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus komunitas ini?\n'
            'Aksi ini tidak bisa dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await _communityService.deleteCommunity(slug);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komunitas berhasil dihapus.')),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus komunitas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Communities')),
      drawer: const LeftDrawer(),
      body: request.loggedIn
          ? RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Community>>(
                future: _futureMyCommunities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Terjadi kesalahan saat memuat komunitas.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Kamu belum menjadi anggota komunitas apapun.\n'
                          'Coba join komunitas dari halaman All Communities.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final myCommunities = snapshot.data!;

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: myCommunities.length,
                    itemBuilder: (context, index) {
                      final c = myCommunities[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  c.description.isEmpty
                                      ? 'Tidak ada deskripsi.'
                                      : c.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sports,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.sport,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.speed, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.skillLevel,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${c.membersCount} anggota',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (c.isAdmin)
                                      const Chip(
                                        label: Text('Kamu Admin'),
                                        avatar: Icon(Icons.shield, size: 16),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      )
                                    else
                                      const Chip(
                                        label: Text('Kamu Anggota'),
                                        avatar: Icon(Icons.check, size: 16),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () async {
                                final shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityDetailPage(community: c),
                                  ),
                                );

                                if (shouldRefresh == true && mounted) {
                                  // untuk list all:
                                  setState(() {
                                    _futureMyCommunities = _communityService.fetchAllCommunities();
                                  });

                                  // untuk my communities:
                                  // _refresh();
                                }
                              },

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.isAdmin)
                                  IconButton(
                                        tooltip: 'Edit komunitas',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final shouldRefresh = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CommunityFormPage(community: c),
                                            ),
                                          );

                                          if (shouldRefresh == true && mounted) {
                                            _refresh();
                                          }
                                        },
                                      
                                  ),
                                if (c.isAdmin)
                                  IconButton(
                                    tooltip: 'Hapus komunitas',
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteCommunity(c.slug),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Silakan login terlebih dahulu untuk melihat komunitas milikmu.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      floatingActionButton: request.loggedIn
          ? FloatingActionButton(
              onPressed: () {
                // TODO: ganti dengan route ke CommunityFormPage (create)
                // Misal:
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => const CommunityFormPage(),
                //   ),
                // );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
