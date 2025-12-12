import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:srve_mobile/modules/threads/models/thread_post.dart';
import 'package:srve_mobile/modules/threads/models/thread_reply.dart';
import 'package:srve_mobile/modules/threads/services/threads_api_service.dart';
import 'package:srve_mobile/modules/threads/widgets/reply_item.dart';
import 'package:srve_mobile/modules/threads/widgets/thread_post_card.dart';

class ThreadDetailPage extends StatefulWidget {
  final ThreadPost post;

  const ThreadDetailPage({super.key, required this.post});

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  late ThreadsApiService _api;

  List<ThreadReply> _replies = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = Provider.of<CookieRequest>(context);
    _api = ThreadsApiService(request);
    _fetchReplies();
  }

  Future<void> _fetchReplies() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchReplies(widget.post.id);
      setState(() {
        _replies = data;
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

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final reply = await _api.createReply(widget.post.id, text);
      _controller.clear();
      setState(() {
        _replies = [..._replies, reply];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread'),
        backgroundColor: const Color(0xFFD4D3C9),
      ),
      body: Column(
        children: [
          ThreadPostCard(
            post: post,
            showActions: false, // di detail, kita fokus ke replies
          ),
          const Divider(height: 0),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Failed to load replies: $_error',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _replies.isEmpty
                        ? const Center(child: Text('No replies yet'))
                        : ListView.builder(
                            itemCount: _replies.length,
                            itemBuilder: (context, index) {
                              final reply = _replies[index];
                              return ReplyItem(reply: reply);
                            },
                          ),
          ),
          const Divider(height: 0),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF5F4EC),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              const BorderSide(color: Colors.black26),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendReply,
                    icon: const Icon(Icons.send),
                    color: const Color(0xFF6B7E5A),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
