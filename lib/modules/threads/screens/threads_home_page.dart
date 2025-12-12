import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:srve_mobile/modules/threads/models/thread_post.dart';
import 'package:srve_mobile/modules/threads/screens/thread_detail_page.dart';
import 'package:srve_mobile/modules/threads/services/threads_api_service.dart';
import 'package:srve_mobile/modules/threads/widgets/thread_post_card.dart';

class ThreadsHomePage extends StatefulWidget {
  const ThreadsHomePage({super.key});

  @override
  State<ThreadsHomePage> createState() => _ThreadsHomePageState();
}

class _ThreadsHomePageState extends State<ThreadsHomePage> {
  late ThreadsApiService _api;

  bool _initialized = false;
  bool _loading = true;
  bool _posting = false;
  String? _error;

  List<ThreadPost> _threads = [];
  String _tab = 'latest';

  final TextEditingController _postController = TextEditingController();

  // gambar yang dipilih dari device
  XFile? _pickedImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final request = Provider.of<CookieRequest>(context);
      _api = ThreadsApiService(request);
      _fetchThreads();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  // ========== API ACTIONS ==========

  Future<void> _fetchThreads() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchThreads(tab: _tab);
      setState(() {
        _threads = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onToggleLike(ThreadPost post) async {
    try {
      final result = await _api.toggleLike(post.id);
      setState(() {
        _threads = _threads
            .map(
              (p) => p.id == post.id
                  ? p.copyWith(
                      isLiked: result.liked,
                      likesCount: result.likesCount,
                    )
                  : p,
            )
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like post: $e')),
      );
    }
  }

  void _openDetail(ThreadPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ThreadDetailPage(post: post)),
    );
  }

  void _changeTab(String tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _fetchThreads();
  }

  Future<void> _onAddImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _pickedImage = result;
      });
    }
  }

  Future<void> _onPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dulu konten atau pilih gambar.')),
      );
      return;
    }

    setState(() => _posting = true);

    try {
      // 🔹 Sekarang baru kirim TEXT ke Django.
      // Gambar masih belum di-upload, tapi minimal UI-nya sudah benar.
      final newPost = await _api.createPost(text);

      _postController.clear();
      setState(() {
        _pickedImage = null; // reset preview
        _threads = [newPost, ..._threads];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/SRVEthreads.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TabBarRow(tab: _tab, onChanged: _changeTab),
                const SizedBox(height: 12),
                Expanded(child: _buildGlassPanel()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildComposer(),
            const Divider(height: 1, color: Colors.white24),
            Expanded(child: _buildFeedBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's new?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _postController,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Share your day with others!",
                hintStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // preview gambar kalau ada
          if (_pickedImage != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_pickedImage!.path),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onAddImage,
                child: Row(
                  children: const [
                    Icon(
                      Icons.image_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Add image",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _posting ? null : _onPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4D3C9),
                  foregroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load threads:\n$_error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_threads.isEmpty) {
      return const Center(
        child: Text(
          'No threads yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final post = _threads[index];
        return ThreadPostCard(
          post: post,
          onTapLike: () => _onToggleLike(post),
          onTapReply: () => _openDetail(post),
          onTapCard: () => _openDetail(post),
        );
      },
    );
  }
}

// ========== Glass Tabs ==========

class _TabBarRow extends StatelessWidget {
  final String tab;
  final void Function(String) onChanged;

  const _TabBarRow({
    super.key,
    required this.tab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabChip(
          label: 'Latest',
          value: 'latest',
          selected: tab == 'latest',
          onSelected: onChanged,
        ),
        const SizedBox(width: 8),
        _TabChip(
          label: 'Top',
          value: 'top',
          selected: tab == 'top',
          onSelected: onChanged,
        ),
        const SizedBox(width: 8),
        _TabChip(
          label: 'Media',
          value: 'media',
          selected: tab == 'media',
          onSelected: onChanged,
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final void Function(String) onSelected;

  const _TabChip({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? Colors.white.withOpacity(0.95)
        : Colors.white.withOpacity(0.12);
    final borderColor = selected ? Colors.white : Colors.white70;
    final textColor = selected ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
