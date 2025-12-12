import 'package:flutter/material.dart';
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

  List<ThreadPost> _threads = [];
  bool _loading = true;
  String? _error;

  String _tab = 'latest'; // 'latest' | 'top' | 'media'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = Provider.of<CookieRequest>(context);
    _api = ThreadsApiService(request);
    _fetchThreads();
  }

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
      setState(() {
        _loading = false;
      });
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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like post')),
      );
    }
  }

  void _openDetail(ThreadPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreadDetailPage(post: post),
      ),
    );
  }

  void _changeTab(String tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
    });
    _fetchThreads();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load threads: $_error',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_threads.isEmpty) {
      return Column(
        children: [
          _TabBarRow(tab: _tab, onChanged: _changeTab),
          const Expanded(
            child: Center(child: Text('No threads yet')),
          ),
        ],
      );
    }

    return Column(
      children: [
        _TabBarRow(tab: _tab, onChanged: _changeTab),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchThreads,
            child: ListView.builder(
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
            ),
          ),
        ),
      ],
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
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
      ),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFF6B7E5A),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
