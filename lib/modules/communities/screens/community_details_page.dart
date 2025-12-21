import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// --- MODELS & SERVICES ---
import '../models/community.dart';
import '../services/community_service.dart';

// --- WIDGETS ---
import '../widgets/left_drawer.dart';

// --- SCREENS ---
import '../screens/community_form_page.dart';
import '../../reviews/screens/create_community_review.dart';
import '../../reviews/screens/edit_community_review.dart';
import '../../reviews/screens/delete_community_review.dart';

class CommunityDetailPage extends StatefulWidget {
  final Community community;

  static const routeName = communityDetailRoute;

  const CommunityDetailPage({super.key, required this.community});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  // State Data
  late Community _community;
  late CommunityService _communityService;
  
  // State Loading
  bool _isDeleting = false;
  bool _isJoining = false;
  bool _isLeaving = false;
  
  // State Review
  bool _hasUserReviewed = false; 

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _communityService = CommunityService(context.read<CookieRequest>());
  }

  // ========================== LOGIKA REVIEW ==========================

  Future<void> _handleReviewButton() async {
    // 1. Cek Admin
    if (_community.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin tidak dapat mereview komunitas sendiri."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Cek apakah sudah review
    if (_hasUserReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda sudah memberikan review untuk komunitas ini."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. Buka Form
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityReviewForm(
          communitySlug: _community.slug,
          communityName: _community.name,
        ),
      ),
    );

    // 4. Refresh jika berhasil
    if (result == true && mounted) {
      setState(() {}); 
    }
  }

  Future<void> _navigateToEditReview(dynamic review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityReviewForm(
          reviewId: review['id'],
          initialCommunication: double.tryParse(review['communication'].toString()) ?? 0.0,
          initialSportsmanship: double.tryParse(review['sportsmanship'].toString()) ?? 0.0,
          initialPlaytime: double.tryParse(review['playtime'].toString()) ?? 0.0,
          initialComment: review['comment'],
          communityName: _community.name,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToDeleteReview(dynamic review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteCommunityReviewPage(
          reviewId: review['id'],
          communityName: _community.name,
          commentPreview: review['comment'],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ========================== LOGIKA KOMUNITAS ==========================

  Future<void> _deleteCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komunitas'),
        content: const Text('Yakin ingin menghapus? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final success = await _communityService.deleteCommunity(_community.slug);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komunitas dihapus.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus.')));
    }
  }

  Future<void> _joinCommunity() async {
    setState(() => _isJoining = true);
    bool success = false;
    try {
      success = await _communityService.joinCommunity(_community.slug);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isJoining = false);

    if (success) {
      setState(() {
        _community = _community.copyWith(isMember: true, membersCount: _community.membersCount + 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil bergabung!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal bergabung.')));
    }
  }

  Future<void> _leaveCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Komunitas'),
        content: const Text('Yakin ingin keluar dari komunitas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLeaving = true);
    bool success = false;
    try {
      success = await _communityService.leaveCommunity(_community.slug);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLeaving = false);

    if (success) {
      setState(() {
        final newCount = _community.membersCount > 0 ? _community.membersCount - 1 : 0;
        _community = _community.copyWith(isMember: false, membersCount: newCount);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil keluar.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal keluar.')));
    }
  }

  Future<void> _goToEdit() async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityFormPage(community: _community)),
    );
    if (shouldRefresh == true && mounted) {
      setState(() {});
    }
  }

  // ========================== BUILD UI ==========================

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    // Sesuaikan URL ini dengan endpoint Django kamu
    final String reviewUrl = 'http://10.0.2.2:8000/reviews/community/${_community.slug}/reviews-list/';

    return Scaffold(
      appBar: AppBar(
        title: Text(_community.name),
        actions: [
          if (request.loggedIn && _community.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _goToEdit,
              tooltip: 'Edit',
            ),
          if (request.loggedIn && _community.isAdmin)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteCommunity,
              tooltip: 'Hapus',
            ),
        ],
      ),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER INFO KOMUNITAS ---
              Text(
                _community.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sports, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(_community.sport),
                  const SizedBox(width: 16),
                  const Icon(Icons.speed, size: 18),
                  const SizedBox(width: 6),
                  Text(_community.skillLevel),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.group, size: 18, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('${_community.membersCount} Members'),
                ],
              ),
              const SizedBox(height: 12),
              
              // Chips Status
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_community.openToPublic ? 'Public' : 'Private'),
                    avatar: Icon(_community.openToPublic ? Icons.lock_open : Icons.lock, size: 18),
                  ),
                  if (_community.isAdmin)
                    const Chip(
                      label: Text('Admin'),
                      avatar: Icon(Icons.shield, size: 18),
                      backgroundColor: Colors.amberAccent,
                    )
                  else if (_community.isMember)
                    const Chip(
                      label: Text('Member'),
                      avatar: Icon(Icons.check, size: 18),
                      backgroundColor: Colors.lightGreenAccent,
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // --- 2. DESKRIPSI ---
              Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _community.description.isEmpty ? 'No description available.' : _community.description,
                style: const TextStyle(height: 1.4),
              ),
              
              const SizedBox(height: 24),

              // --- 3. TOMBOL JOIN / LEAVE ---
              if (request.loggedIn && !_community.isAdmin) ...[
                if (!_community.isMember)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _joinCommunity,
                      icon: _isJoining
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.group_add),
                      label: Text(_isJoining ? 'Joining...' : 'Join Community'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLeaving ? null : _leaveCommunity,
                      icon: _isLeaving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.logout),
                      label: Text(_isLeaving ? 'Leaving...' : 'Leave Community'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 32),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // --- 4. BAGIAN REVIEWS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Tombol Review hanya muncul jika belum review dan bukan admin
                  if (request.loggedIn && !_community.isAdmin && !_hasUserReviewed)
                    ElevatedButton(
                      onPressed: _handleReviewButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF556B2F),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Write Review"),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // --- 5. LIST REVIEW (FutureBuilder) ---
              FutureBuilder(
                future: request.get(reviewUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Safety check data
                    var reviews = snapshot.data;
                    if (reviews == null || (reviews as List).isEmpty) {
                      // Update state jika user ternyata belum review (reset)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_hasUserReviewed && mounted) setState(() => _hasUserReviewed = false);
                      });
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No reviews yet. Be the first!", style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    // Cek kepemilikan review (untuk update tombol 'Write Review' & tombol Edit/Delete)
                    final currentUser = request.jsonData.isNotEmpty ? request.jsonData['username'] : null;
                    bool foundUserReview = false;
                    
                    // Kita bangun list widget-nya
                    List<Widget> reviewWidgets = [];

                    for (var r in reviews) {
                      // Parsing Data Aman
                      final String user = r['user'] ?? 'Anonymous';
                      final String comment = r['comment'] ?? '';
                      final String date = r['created_at'] ?? '';
                      final double rating = double.tryParse(r['rating'].toString()) ?? 0.0;
                      
                      // Cek 'is_my_review' dari Django (jika sudah ada) ATAU cek username manual
                      final bool isMyReview = (r['is_my_review'] == true) || (currentUser != null && user == currentUser);
                      
                      if (isMyReview) foundUserReview = true;

                      reviewWidgets.add(
                        Card(
                          color: const Color(0xFFF2F0E4),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Review (Nama & Bintang)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                          const Icon(Icons.star, size: 16, color: Colors.orange),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                
                                // Isi Komentar
                                Text('"$comment"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)),
                                const SizedBox(height: 12),
                                
                                // Detail Nilai
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    _buildScoreBadge("Comm", r['communication']),
                                    _buildScoreBadge("Sports", r['sportsmanship']),
                                    _buildScoreBadge("Play", r['playtime']),
                                  ],
                                ),

                                // Tombol Edit/Delete (Khusus Pemilik Review)
                                if (isMyReview) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _navigateToEditReview(r),
                                        icon: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                                        label: const Text("Edit", style: TextStyle(color: Colors.blueGrey)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _navigateToDeleteReview(r),
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                        label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        )
                      );
                    }

                    // Update state _hasUserReviewed di luar build cycle
                    if (_hasUserReviewed != foundUserReview) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (mounted) setState(() => _hasUserReviewed = foundUserReview);
                       });
                    }

                    return Column(children: reviewWidgets);
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget kecil untuk badge nilai
  Widget _buildScoreBadge(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$label: ${value ?? '-'}", 
        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
      ),
    );
  }
}