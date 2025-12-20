import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/left_drawer.dart';
import '../screens/community_form_page.dart';
import '../widgets/navigation_helpers.dart';
import '../screens/my_communities_page.dart';

// --- IMPORT SCREEN REVIEW ---
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
  Community? _community;
  late CommunityService _communityService;
  bool _isDeleting = false;
  bool _isJoining = false;
  bool _isLeaving = false;
  
  // State untuk Review
  bool _hasUserReviewed = false; 

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _communityService = CommunityService(context.read<CookieRequest>());
  }

  // --- LOGIKA REVIEW ---
  
  Future<void> _handleReviewButton() async {
    // 1. CEK: Apakah user adalah Admin/Pemilik Komunitas?
    // Jika iya, tidak boleh review komunitas sendiri.
    if (_community!.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot review your own community"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. CEK: Apakah user sudah pernah review sebelumnya?
    if (_hasUserReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already reviewed this community"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Jika lolos kedua cek di atas, baru buka form review
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityReviewForm(
          communitySlug: _community!.slug,
          communityName: _community!.name,
        ),
      ),
    );

    // Refresh halaman jika user berhasil buat review
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
          // Gunakan tryParse agar aman
          initialCommunication: double.tryParse(review['communication'].toString()) ?? 0.0,
          initialSportsmanship: double.tryParse(review['sportsmanship'].toString()) ?? 0.0,
          initialPlaytime: double.tryParse(review['playtime'].toString()) ?? 0.0,
          initialComment: review['comment'],
          communityName: _community!.name,
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
          communityName: _community!.name,
          commentPreview: review['comment'],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // --- LOGIKA DELETE COMMUNITY ---

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

    final success = await _communityService.deleteCommunity(_community!.slug);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komunitas berhasil dihapus.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus komunitas.')),
      );
    }
  }

  Future<void> _goToEdit() async {
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
      setState(() {});
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
    
    final String reviewUrl = 'http://10.0.2.2:8000/reviews/community/${c.slug}/reviews-list/';

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
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // --- BAGIAN REVIEW ---
              const SizedBox(height: 32),
              const Divider(thickness: 2),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleReviewButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF556B2F), 
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Write a Review"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FutureBuilder untuk Fetch Reviews
              FutureBuilder(
                future: request.get(reviewUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    var reviews = snapshot.data;
                    
                    if (reviews == null || (reviews as List).isEmpty) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         if(_hasUserReviewed && mounted) setState(() => _hasUserReviewed = false);
                       });
                      return const Text("No reviews yet.", style: TextStyle(color: Colors.grey));
                    }

                    // Cek apakah user sudah review
                    bool foundUserReview = false;
                    final currentUser = request.jsonData.isNotEmpty ? request.jsonData['username'] : null;
                    
                    for (var r in reviews) {
                      if (r['user'] == currentUser) {
                        foundUserReview = true;
                        break;
                      }
                    }

                    if (_hasUserReviewed != foundUserReview) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (mounted) setState(() => _hasUserReviewed = foundUserReview);
                       });
                    }

                    return ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final String user = review['user'] ?? 'Anonymous';
                        final String comment = review['comment'] ?? '';
                        
                        // Parse Double (Safe Mode)
                        final double rating = double.tryParse(review['rating'].toString()) ?? 0.0;
                        final double commScore = double.tryParse(review['communication'].toString()) ?? 0.0;
                        final double sportsScore = double.tryParse(review['sportsmanship'].toString()) ?? 0.0;
                        final double playScore = double.tryParse(review['playtime'].toString()) ?? 0.0;
                        
                        final bool isOwner = (currentUser != null && user == currentUser);

                        return Card(
                          color: const Color(0xFFF2F0E4), 
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(review['created_at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('"$comment"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                const SizedBox(height: 12),
                                
                                // Detail Scores
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text("Communication: $commScore", style: const TextStyle(fontSize: 11)),
                                    Text("Sportsmanship: $sportsScore", style: const TextStyle(fontSize: 11)),
                                    Text("Playtime: $playScore", style: const TextStyle(fontSize: 11)),
                                  ],
                                ),

                             
                                if (isOwner) ...[
                                  const SizedBox(height: 8),
                                  const Divider(color: Colors.black12), // Garis pemisah tipis
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end, // Taruh di kanan
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _navigateToEditReview(review),
                                        icon: const Icon(Icons.edit, size: 16, color: Color.fromARGB(255, 0, 33, 4)),
                                        label: const Text("Edit", style: TextStyle(color: Color.fromARGB(255, 0, 33, 4), fontSize: 13)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _navigateToDeleteReview(review),
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        label: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
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
}