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

    final data = await request.get(uri.toString());
    final results = data['results'] as List<dynamic>;
    return results
        .map((item) => ThreadPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LikeResult> toggleLike(int postId) async {
    final uri = Uri.parse('${Env.threadsApi}$postId/like-toggle/');
    final data = await request.post(uri.toString(), {});
    return LikeResult(
      liked: data['liked'] as bool,
      likesCount: data['likes_count'] as int,
    );
  }

  Future<List<ThreadReply>> fetchReplies(int postId) async {
    final uri = Uri.parse('${Env.threadsApi}$postId/replies/');
    final data = await request.get(uri.toString());
    final results = data['results'] as List<dynamic>;
    return results
        .map((item) => ThreadReply.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ThreadReply> createReply(int postId, String content) async {
    final uri = Uri.parse('${Env.threadsApi}$postId/replies/');
    final data = await request.post(uri.toString(), {'content': content});
    final replyJson = data['reply'] as Map<String, dynamic>;
    return ThreadReply.fromJson(replyJson);
  }
}
