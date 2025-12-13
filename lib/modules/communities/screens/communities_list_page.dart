

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../screens/community_details_page.dart';
import '../widgets/left_drawer.dart';
import '../screens/community_form_page.dart';

class CommunitiesListPage extends StatefulWidget {
  const CommunitiesListPage({super.key});

  @override
  State<CommunitiesListPage> createState() => _CommunitiesListPageState();
}

class _CommunitiesListPageState extends State<CommunitiesListPage> {
  late CommunityService _communityService;
  late Future<List<Community>> _futureCommunities;

  @override
  void initState() {
    super.initState();
    // ambil CookieRequest dari Provider untuk inisialisasi service
    // context.read boleh dipakai di initState selama tidak listen perubahan
    _communityService = CommunityService(context.read<CookieRequest>());
    _futureCommunities = _communityService.fetchAllCommunities();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureCommunities = _communityService.fetchAllCommunities();
    });
    await _futureCommunities;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Communities'),
      ),
      drawer: const LeftDrawer(),
      body: request.loggedIn
          ? RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Community>>(
                future: _futureCommunities,
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
                      child: Text('Belum ada komunitas yang terdaftar.'),
                    );
                  }

                  final communities = snapshot.data!;

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: communities.length,
                    itemBuilder: (context, index) {
                      final c = communities[index];

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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.sport,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.speed,
                                      size: 16,
                                    ),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
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
                                    Chip(
                                      label: Text(
                                        c.openToPublic
                                            ? 'Terbuka untuk umum'
                                            : 'Private',
                                      ),
                                      avatar: Icon(
                                        c.openToPublic
                                            ? Icons.lock_open
                                            : Icons.lock,
                                        size: 16,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (c.isAdmin)
                                      const Chip(
                                        label: Text('Admin'),
                                        avatar: Icon(
                                          Icons.shield,
                                          size: 16,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                    if (!c.isAdmin && c.isMember)
                                      const Chip(
                                        label: Text('Anggota'),
                                        avatar: Icon(
                                          Icons.check,
                                          size: 16,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity:
                                            VisualDensity.compact,
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
                                  _futureCommunities = _communityService.fetchAllCommunities();
                                });

                                // untuk my communities:
                                // _refresh();
                              }
                            },

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
                  'Silakan login terlebih dahulu untuk melihat daftar communities.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      // TODO: setelah community_form_page dibuat, aktifkan FAB di bawah ini
      floatingActionButton: request.loggedIn
          ? FloatingActionButton(
              onPressed: () async {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunityFormPage(),
                  ),
                );

                if (shouldRefresh == true && mounted) {
                  setState(() {
                    _futureCommunities = _communityService.fetchAllCommunities();
                  });
                }
              },
              child: const Icon(Icons.add),
            )

          : null,
    );
  }
}
