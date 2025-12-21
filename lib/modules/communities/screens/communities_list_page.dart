

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../screens/community_details_page.dart';
import '../widgets/left_drawer.dart';
import '../screens/community_form_page.dart';
import '../widgets/navigation_helpers.dart';

class CommunitiesListPage extends StatefulWidget {
  static const routeName = communitiesListRoute;

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

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No communities available'),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error. \n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
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
                                      ? 'No Description'
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
                                      '${c.membersCount} members',
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
                                            ? 'Public'
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
                                        label: Text('Member'),
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
                                  settings: const RouteSettings(
                                    name: CommunityDetailPage.routeName,
                                  ),
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
                  'login required to view communities.',
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
                    settings: const RouteSettings(
                      name: CommunityFormPage.routeName,
                    ),
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
