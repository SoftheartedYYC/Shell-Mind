import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';

// ─── Transcript ─────────────────────────────────────────────────────────

/// Reversed transcript list: index 0 is the newest message, pinned to the
/// bottom of the viewport.
class ChatTranscript extends StatelessWidget {
  const ChatTranscript({
    super.key,
    required this.messages,
    required this.controller,
    this.onExecuteCode,
    this.onAnalyzeTool,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final void Function(String code, String language)? onExecuteCode;
  final VoidCallback? onAnalyzeTool;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        // reverse: index 0 is the newest (bottom-most) message.
        final ChatMessage message = messages[messages.length - 1 - index];
        // Defensive fallback: a finished assistant turn with no text and no
        // tool payload renders as a blank bubble — collapse it so a future
        // dirty-data path cannot reintroduce blank stretches when scrolling.
        // Streaming placeholders are kept (they host the typing cursor) and
        // tool turns are untouched (their content is never empty).
        if (message.role == MessageRole.assistant &&
            !message.isStreaming &&
            message.content.trim().isEmpty &&
            message.toolPayload == null) {
          return const SizedBox.shrink();
        }
        // Only offer code execution on finished assistant turns.
        final bool canExecute = message.role == MessageRole.assistant &&
            !message.isStreaming;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MessageBubble(
            key: ValueKey<String>(message.id),
            message: message,
            onExecuteCode: canExecute ? onExecuteCode : null,
            onAnalyzeTool: onAnalyzeTool,
          ),
        );
      },
    );
  }
}
