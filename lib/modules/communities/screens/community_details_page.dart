// lib/communities/screens/community_detail_page.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/left_drawer.dart';
import '../screens/community_form_page.dart';
import '../widgets/navigation_helpers.dart';
import '../screens/my_communities_page.dart';

class CommunityDetailPage extends StatefulWidget {
  final Community community;

  static const routeName = communityDetailRoute;

  const CommunityDetailPage({super.key, required this.community});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Community? _community; // kalau nanti mau refresh dari backend
  late CommunityService _communityService;
  bool _isDeleting = false;
  bool _isJoining = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _communityService = CommunityService(context.read<CookieRequest>());
  }

  Future<void> _deleteCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Community'),
          content: const Text(
            'Are you sure you want to delete this community?\n'
            'This action cannot be undone',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    final success =
        await _communityService.deleteCommunity(_community!.slug);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komunitas berhasil dihapus.')),
      );
      Navigator.pop(context, true); // balik ke list & trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus komunitas.')),
      );
    }
  }

  Future<void> _goToEdit() async {
    // kita pakai CommunityFormPage yang sudah kamu punya
    // importnya sesuaikan path-mu
    // misal: '../screens/community_form_page.dart'
    // tapi di sini aku tulis relative jelas:

    // ignore: use_build_context_synchronously
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(
          name: CommunityFormPage.routeName,
        ),
        builder: (_) => CommunityFormPage(
          community: _community!,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      // optional: kalau kamu punya endpoint detail, bisa fetch ulang
      // final updated = await _communityService.fetchCommunityDetail(_community!.slug);
      // if (updated != null) setState(() => _community = updated);

      setState(() {}); // minimal redraw dengan data lama
    }
  }

  Future<void> _leaveCommunity() async {
    if (_community == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Community'),
          content: const Text(
            'Are you sure you want to leave this community?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLeaving = true;
    });

    bool success = false;
    try {
      success = await _communityService.leaveCommunity(_community!.slug);
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    setState(() {
      _isLeaving = false;
      if (success) {
        final newCount =
            _community!.membersCount > 0 ? _community!.membersCount - 1 : 0;
        _community = _community!.copyWith(
          isMember: false,
          membersCount: newCount,
        );
      }
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to leave community. Please try again.'),
        ),
      );
    }
  }

  Future<void> _joinCommunity() async {
    if (_community == null) return;

    setState(() {
      _isJoining = true;
    });

    bool success = false;
    try {
      success = await _communityService.joinCommunity(_community!.slug);
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    setState(() {
      _isJoining = false;
    });

    if (success) {
      // update local state in case this page stays mounted
      _community = _community!.copyWith(
        isMember: true,
        membersCount: _community!.membersCount + 1,
      );

      // Redirect to My Communities after joining
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(
            name: MyCommunitiesPage.routeName,
          ),
          builder: (_) => const MyCommunitiesPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join community. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final c = _community!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateToCommunitiesHome(context),
        ),
        title: Text(c.name),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            ),
          ),
          if (request.loggedIn && c.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _goToEdit,
              tooltip: 'Edit komunitas',
            ),
          if (request.loggedIn && c.isAdmin)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteCommunity,
              tooltip: 'Hapus komunitas',
            ),
        ],
      ),
      drawer: const LeftDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              c.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sports,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(c.sport),
                const SizedBox(width: 16),
                const Icon(Icons.speed, size: 18),
                const SizedBox(width: 6),
                Text(c.skillLevel),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text('${c.membersCount} anggota'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    c.openToPublic ? 'Public' : 'Private',
                  ),
                  avatar: Icon(
                    c.openToPublic ? Icons.lock_open : Icons.lock,
                    size: 18,
                  ),
                ),
                if (c.isAdmin)
                  const Chip(
                    label: Text('You are Admin'),
                    avatar: Icon(Icons.shield, size: 18),
                  )
                else if (c.isMember)
                  const Chip(
                    label: Text('You are a Member'),
                    avatar: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              c.description.isEmpty
                  ? 'No Description'
                  : c.description,
            ),
            const SizedBox(height: 24),
            if (request.loggedIn && !c.isAdmin && !c.isMember)
              c.openToPublic
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinCommunity,
                        icon: _isJoining
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.group_add),
                        label: Text(_isJoining ? 'Joining...' : 'Join Community'),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock, color: Colors.black54),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This community is private',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
            if (request.loggedIn && !c.isAdmin && c.isMember)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLeaving ? null : _leaveCommunity,
                  icon: _isLeaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: Text(_isLeaving ? 'Leaving...' : 'Leave Community'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
