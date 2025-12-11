import 'thread_user.dart';

class ThreadReply {
  final int id;
  final int postId;
  final ThreadUser author;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  ThreadReply({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThreadReply.fromJson(Map<String, dynamic> json) {
    return ThreadReply(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      author: ThreadUser.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
