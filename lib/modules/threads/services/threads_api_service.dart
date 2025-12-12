import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';
import 'package:srve_mobile/modules/threads/models/thread_post.dart';
import 'package:srve_mobile/modules/threads/models/thread_reply.dart';

class LikeResult {
  final bool liked;
  final int likesCount;

  LikeResult({required this.liked, required this.likesCount});
}

class ThreadsApiService {
  final CookieRequest request;

  ThreadsApiService(this.request);

  // ---------- LIST ----------
  Future<List<ThreadPost>> fetchThreads({
    int page = 1,
    String tab = 'latest',
    String query = '',
  }) async {
    final uri = Uri.parse(Env.threadsListApi).replace(queryParameters: {
      'page': page.toString(),
      'tab': tab,
      if (query.isNotEmpty) 'q': query,
    });

    final data = await request.get(uri.toString());
    final results = data['results'] as List<dynamic>;
    return results
        .map((item) => ThreadPost.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  // ---------- LIKE ----------
  Future<LikeResult> toggleLike(int postId) async {
    final uri = Uri.parse('${Env.threadsListApi}$postId/like-toggle/');
    final data = await request.post(uri.toString(), {});

    return LikeResult(
      liked: data['liked'] as bool? ?? false,
      likesCount: data['likes_count'] as int? ?? 0,
    );
  }

  // ---------- REPLIES ----------
  Future<List<ThreadReply>> fetchReplies(int postId) async {
    final uri = Uri.parse('${Env.threadsListApi}$postId/replies/');
    final data = await request.get(uri.toString());
    final results = data['results'] as List<dynamic>;
    return results
        .map((item) => ThreadReply.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<ThreadReply> createReply(int postId, String content) async {
    final uri = Uri.parse('${Env.threadsListApi}$postId/replies/');
    final data = await request.post(uri.toString(), {'content': content});
    final replyJson =
        Map<String, dynamic>.from(data['reply'] as Map<dynamic, dynamic>);
    return ThreadReply.fromJson(replyJson);
  }

  // ---------- CREATE POST (TEXT ONLY DULU) ----------
  Future<ThreadPost> createPost(String content) async {
    final uri = Uri.parse(Env.threadsCreateApi);
    final data = await request.post(uri.toString(), {'content': content});

    if (data == null) throw 'Empty response from server';
    if (data is! Map) throw 'Invalid response type: $data';

    if (data['ok'] != true) {
      throw data['error'] ?? 'Unknown error: $data';
    }
    if (data['post'] == null) {
      throw 'Server did not return post data: $data';
    }

    final postJson =
        Map<String, dynamic>.from(data['post'] as Map<dynamic, dynamic>);
    return ThreadPost.fromJson(postJson);
  }
}
