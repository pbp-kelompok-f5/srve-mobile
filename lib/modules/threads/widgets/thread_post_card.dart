import 'package:flutter/material.dart';
import 'package:srve_mobile/modules/threads/models/thread_post.dart';

class ThreadPostCard extends StatelessWidget {
  final ThreadPost post;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapLike;
  final VoidCallback? onTapReply;
  final bool showActions;

  const ThreadPostCard({
    super.key,
    required this.post,
    this.onTapCard,
    this.onTapLike,
    this.onTapReply,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: InkWell(
        // tap di mana saja di card → ke detail
        onTap: onTapCard,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: avatar + username
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: post.author.avatarUrl != null
                        ? NetworkImage(post.author.avatarUrl!)
                        : null,
                    child: post.author.avatarUrl == null
                        ? Text(
                            post.author.username[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.author.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // CONTENT
              Text(post.content),

              // IMAGE (kalau ada)
              if (post.imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(post.imageUrl!),
                ),
              ],

              if (showActions) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // ❤️ LIKE
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onTapLike,
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color:
                                post.isLiked ? Colors.redAccent : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}'),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 💬 REPLY
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onTapReply,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.repliesCount}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
