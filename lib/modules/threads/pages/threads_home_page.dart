import 'package:flutter/material.dart';

import 'package:srve_mobile/features/threads/models/thread_post.dart';
import 'package:srve_mobile/features/threads/services/threads_api_service.dart';
import 'package:srve_mobile/features/threads/widgets/thread_post_card.dart';

class ThreadsHomePage extends StatefulWidget {
  const ThreadsHomePage({super.key});

  @override
  State<ThreadsHomePage> createState() => _ThreadsHomePageState();
}

class _ThreadsHomePageState extends State<ThreadsHomePage> {
  final ThreadsApiService _api = ThreadsApiService();
  late Future<List<ThreadPost>> _futureThreads;

  @override
  void initState() {
    super.initState();
    _futureThreads = _api.fetchThreads();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureThreads = _api.fetchThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threads'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ThreadPost>>(
          future: _futureThreads,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            final threads = snapshot.data ?? [];

            if (threads.isEmpty) {
              return const Center(child: Text('Belum ada post.'));
            }

            return ListView.builder(
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final post = threads[index];
                return ThreadPostCard(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}
