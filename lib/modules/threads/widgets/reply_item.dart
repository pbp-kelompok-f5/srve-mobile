import 'package:flutter/material.dart';
import 'package:srve_mobile/modules/threads/models/thread_reply.dart';

class ReplyItem extends StatelessWidget {
  final ThreadReply reply;

  const ReplyItem({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        child: Text(reply.author.username[0].toUpperCase()),
      ),
      title: Text(
        reply.author.username,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(reply.content),
    );
  }
}
