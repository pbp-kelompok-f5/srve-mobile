// lib/communities/screens/community_detail_page.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/left_drawer.dart';
import '../screens/community_form_page.dart';

class CommunityDetailPage extends StatefulWidget {
  final Community community;

  const CommunityDetailPage({super.key, required this.community});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Community? _community; // kalau nanti mau refresh dari backend
  late CommunityService _communityService;
  bool _isDeleting = false;

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
          title: const Text('Hapus Komunitas'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus komunitas ini?\n'
            'Aksi ini tidak dapat dibatalkan.',
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final c = _community!;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
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
                    c.openToPublic ? 'Terbuka untuk umum' : 'Private',
                  ),
                  avatar: Icon(
                    c.openToPublic ? Icons.lock_open : Icons.lock,
                    size: 18,
                  ),
                ),
                if (c.isAdmin)
                  const Chip(
                    label: Text('Kamu Admin'),
                    avatar: Icon(Icons.shield, size: 18),
                  )
                else if (c.isMember)
                  const Chip(
                    label: Text('Kamu Anggota'),
                    avatar: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Deskripsi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              c.description.isEmpty
                  ? 'Belum ada deskripsi untuk komunitas ini.'
                  : c.description,
            ),
          ],
        ),
      ),
    );
  }
}
