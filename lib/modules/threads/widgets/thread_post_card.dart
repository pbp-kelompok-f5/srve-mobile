import 'dart:ui';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // 🔹 Glass effect: terang + sedikit transparan
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTapCard,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------- Header: avatar + username --------
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: post.author.avatarUrl != null
                              ? NetworkImage(post.author.avatarUrl!)
                              : null,
                          backgroundColor: const Color(0xFFDAF0B5),
                          child: post.author.avatarUrl == null
                              ? Text(
                                  post.author.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          post.author.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // -------- Content --------
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),

                    // -------- Image --------
                    if (post.imageUrl != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    // -------- Actions: like & reply --------
                    if (showActions) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: onTapLike,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: post.isLiked
                                      ? Colors.redAccent
                                      : Colors.grey[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.likesCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: onTapReply,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: Colors.grey[200],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.repliesCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
