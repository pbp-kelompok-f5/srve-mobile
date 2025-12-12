import 'thread_user.dart';

class ThreadPost {
  final int id;
  final ThreadUser author;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;

  ThreadPost({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.repliesCount,
    required this.isLiked,
  });

  factory ThreadPost.fromJson(Map<String, dynamic> json) {
    return ThreadPost(
      id: json['id'] as int,
      author: ThreadUser.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likesCount: json['likes_count'] as int,
      repliesCount: json['replies_count'] as int,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  ThreadPost copyWith({
    int? likesCount,
    int? repliesCount,
    bool? isLiked,
  }) {
    return ThreadPost(
      id: id,
      author: author,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
