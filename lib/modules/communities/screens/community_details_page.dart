import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// --- MODELS & SERVICES ---
// Pastikan path import ini sesuai dengan struktur project kamu
import '../models/community.dart';
import '../services/community_service.dart';

// --- WIDGETS ---
import '../widgets/left_drawer.dart';

// --- SCREENS ---
import '../screens/community_form_page.dart';
import '../../reviews/screens/create_community_review.dart';
import '../../reviews/screens/edit_community_review.dart';

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

  // ================== HELPER: SAFE PARSING ==================
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ========================== LOGIKA REVIEW ==========================

  Future<void> _navigateToEditReview(dynamic review) async {
    // 1. Ambil nilai dari JSON Backend (biasanya typo 'sportmanship')
    final double backendSportsValue = _safeParseDouble(review['sportmanship']); 

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityReviewForm(
          reviewId: review['id'],
          initialCommunication: _safeParseDouble(review['communication']),
          initialSportmanship: backendSportsValue, 
          initialPlaytime: _safeParseDouble(review['playtime']),
          initialComment: review['comment'] ?? "",
          communityName: _community.name,
        ),
      ),
    );

    // Refresh halaman jika update berhasil
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final request = context.read<CookieRequest>();
    try {
      // Pastikan URL ini sesuai dengan urls.py kamu
      final response = await request.post(
        'http://10.0.2.2:8000/reviews/delete-community-flutter/$reviewId/', 
        {}
      );
      
      if (response['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review deleted successfully")));
        setState(() {
           _hasUserReviewed = false; 
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed to delete")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
    // Pastikan URL ini benar
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
              // --- HEADER INFO ---
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
              
              // --- DESKRIPSI ---
              Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _community.description.isEmpty ? 'No description available.' : _community.description,
                style: const TextStyle(height: 1.4),
              ),
              
              const SizedBox(height: 24),

              // --- TOMBOL JOIN / LEAVE ---
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

              // --- REVIEWS SECTION ---
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D7C4).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER REVIEW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Reviews",
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: Color(0xFF5A4633)
                          ),
                        ),
                        
                        // LOGIC TOMBOL WRITE REVIEW
                        if (request.loggedIn && !_community.isAdmin)
                          if (_hasUserReviewed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    "Reviewed",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () async {
                                 final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommunityReviewForm(
                                        communitySlug: _community.slug,
                                        communityName: _community.name,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF556047),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Write a Review",
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 16),

                    // LIST REVIEW
                    FutureBuilder(
                      future: request.get(reviewUrl),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          var reviews = snapshot.data;
                          if (reviews == null || (reviews as List).isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_hasUserReviewed && mounted) setState(() => _hasUserReviewed = false);
                            });
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text("No reviews yet. Be the first!", style: TextStyle(color: Colors.grey))),
                            );
                          }

                          // --- LOGIKA LIST TILE ---
                          
                          bool foundUserReview = false;
                          List<Widget> reviewWidgets = [];

                          for (var r in reviews) {
                            // Ambil data
                            final String reviewAuthor = r['user']?.toString() ?? 'Anonymous';
                            final String comment = r['comment'] ?? '';
                            
                            final double rating = _safeParseDouble(r['rating']);
                            final double commScore = _safeParseDouble(r['communication']);
                            final double sportsScore = _safeParseDouble(r['sportmanship']); 
                            final double playScore = _safeParseDouble(r['playtime']);
                            
                            // CEK APAKAH INI REVIEW SAYA
                            final bool isMyReview = r['is_my_review'] == true;
                            
                            if (isMyReview) foundUserReview = true;

                            // UI ITEM
                            reviewWidgets.add(
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5D7C4), // Solid Beige
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF5A4633).withOpacity(0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(reviewAuthor, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A4633))),
                                        Row(
                                          children: [
                                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const Icon(Icons.star, color: Colors.amber, size: 18),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('"$comment"', style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF4B3B2B))),
                                    ],
                                    const SizedBox(height: 8),
                                    
                                    // Detail Scores
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Text("Comm: ${commScore.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
                                        const Text("•", style: TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
                                        Text("Sports: ${sportsScore.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
                                        const Text("•", style: TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
                                        Text("Play: ${playScore.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A4633))),
                                      ],
                                    ),

                                    // TOMBOL EDIT & DELETE (Muncul jika review milik user)
                                    if (isMyReview) 
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _navigateToEditReview(r),
                                              child: const Text("Edit", style: TextStyle(color: Color(0xFF556047), fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 20),
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text("Delete Review?"),
                                                    content: const Text("Are you sure you want to delete this review?"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx), 
                                                        child: const Text("Cancel")
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(ctx);
                                                          _deleteReview(r['id']);
                                                        }, 
                                                        child: const Text("Delete", style: TextStyle(color: Colors.red))
                                                      ),
                                                    ],
                                                  )
                                                );
                                              },
                                              child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                ),
                              )
                            );
                          }

                          // Update state "Reviewed" agar tombol Write Review hilang jika sudah review
                          if (_hasUserReviewed != foundUserReview) {
                             WidgetsBinding.instance.addPostFrameCallback((_) {
                               if (mounted) setState(() => _hasUserReviewed = foundUserReview);
                             });
                          }

                          return Column(children: reviewWidgets);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}