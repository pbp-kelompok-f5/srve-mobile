import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:srve_mobile/core/config/env.dart';
import 'package:srve_mobile/features/threads/models/thread_post.dart';
import 'package:srve_mobile/features/threads/models/thread_reply.dart';

class ThreadsApiService {
  final http.Client _client;

  ThreadsApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ThreadPost>> fetchThreads({
    int page = 1,
    String tab = 'latest',
    String query = '',
  }) async {
    final uri = Uri.parse(Env.threadsApi).replace(queryParameters: {
      'page': page.toString(),
      'tab': tab,
      if (query.isNotEmpty) 'q': query,
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load threads (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = data['results'] as List<dynamic>;

    return results
        .map((item) => ThreadPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ThreadReply>> fetchReplies(int postId) async {
    final uri = Uri.parse('${Env.threadsApi}$postId/replies/');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load replies');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = data['results'] as List<dynamic>;

    return results
        .map((item) => ThreadReply.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleLike(int postId) async {
    final uri = Uri.parse('${Env.threadsApi}$postId/like-toggle/');
    final response = await _client.post(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle like');
    }
  }
}
