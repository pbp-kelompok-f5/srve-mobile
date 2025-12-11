import 'package:flutter/material.dart';
import 'package:srve_mobile/features/threads/models/thread_post.dart';

class ThreadPostCard extends StatelessWidget {
  final ThreadPost post;

  const ThreadPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + username
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
                  child: post.author.avatarUrl == null
                      ? Text(post.author.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.author.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.imageUrl!),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite,
                    size: 16,
                    color: post.isLiked ? Colors.red : Colors.grey),
                const SizedBox(width: 4),
                Text('${post.likesCount}'),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 16),
                const SizedBox(width: 4),
                Text('${post.repliesCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
