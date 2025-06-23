import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Menampilkan indikator loading jika pesan adalah 'typing'
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 15, right: 15),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    // Menentukan warna dan alignment berdasarkan pengirim atau status error
    Color bubbleColor;
    if (message.isError) {
      bubbleColor = colors.errorContainer;
    } else if (message.isFromUser) {
      bubbleColor = colors.primaryContainer;
    } else {
      bubbleColor = colors.surfaceContainerHighest;
    }


    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 15, right: 15),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: MarkdownBody(
          data: message.text,
          selectable: true,
        ),
      ),
    );
  }
}