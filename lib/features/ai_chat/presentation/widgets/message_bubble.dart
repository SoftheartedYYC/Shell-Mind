import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/chat_message.dart';
import 'streaming_text.dart';
import 'tool_result_bubble.dart';

/// A single chat turn rendered in a clean Material style.
///
/// User turns are right-aligned with a primary-tinted background; assistant
/// turns are left-aligned on a surface card with a subtle avatar and
/// Markdown-rendered body (live cursor while streaming).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.onExecuteCode,
    this.onAnalyzeTool,
  });

  final ChatMessage message;
  final bool showTimestamp;
  final void Function(String code, String language)? onExecuteCode;
  final VoidCallback? onAnalyzeTool;

  @override
  Widget build(BuildContext context) {
    // Special handling for tool results
    if (message.role == MessageRole.tool && message.toolPayload != null) {
      return ToolResultBubble(
        payload: message.toolPayload!,
        onAnalyze: onAnalyzeTool,
      );
    }
    return message.isUser
        ? _UserBubble(message: message, showTimestamp: showTimestamp)
        : _AssistantBubble(
            message: message,
            showTimestamp: showTimestamp,
            onExecuteCode: onExecuteCode,
          );
  }
}

// ─── User bubble ────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.showTimestamp});

  final ChatMessage message;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.content,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  height: 1.5,
                ),
              ),
            ),
            if (showTimestamp)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: _Timestamp(time: message.timestamp, alignRight: true),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Assistant bubble ───────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message, required this.showTimestamp, this.onExecuteCode});

  final ChatMessage message;
  final bool showTimestamp;
  final void Function(String code, String language)? onExecuteCode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isError = message.error;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Avatar.
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isError
                        ? colors.error.withValues(alpha: 0.1)
                        : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      isError ? Icons.error_outline_rounded : Icons.smart_toy_outlined,
                      size: 16,
                      color: isError ? colors.error : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Role tag.
                      Text(
                        isError
                            ? AppLocalizations.of(context).aiChatError
                            : AppLocalizations.of(context).aiChatAssistantName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: isError
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: isError
                              ? colors.error.withValues(alpha: 0.05)
                              : colors.surfaceContainerLow,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: isError
                                ? colors.error.withValues(alpha: 0.2)
                                : colors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: _AssistantBody(
                          message: message,
                          onExecuteCode: onExecuteCode,
                        ),
                      ),
                      if (showTimestamp || !message.isStreaming)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 2),
                          child: _AssistantFooter(message: message),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody({required this.message, this.onExecuteCode});

  final ChatMessage message;
  final void Function(String code, String language)? onExecuteCode;

  @override
  Widget build(BuildContext context) {
    // Waiting for the first token — show a soft thinking pulse.
    if (message.isStreaming && message.content.isEmpty) {
      return const _ThinkingDots();
    }

    return StreamingText(
      text: message.content,
      isStreaming: message.isStreaming,
      selectable: true,
      onExecuteCode: onExecuteCode,
    );
  }
}

class _AssistantFooter extends StatelessWidget {
  const _AssistantFooter({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Timestamp(time: message.timestamp),
        if (!message.isStreaming && message.content.isNotEmpty) ...<Widget>[
          const SizedBox(width: 8),
          _MiniCopyButton(text: message.content),
        ],
      ],
    );
  }
}

class _MiniCopyButton extends StatefulWidget {
  const _MiniCopyButton({required this.text});
  final String text;

  @override
  State<_MiniCopyButton> createState() => _MiniCopyButtonState();
}

class _MiniCopyButtonState extends State<_MiniCopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _copy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            size: 12,
            color: _copied ? context.sem.success : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            _copied
                ? AppLocalizations.of(context).aiChatCopied
                : AppLocalizations.of(context).aiChatCopy,
            style: TextStyle(
              fontSize: 10,
              color: _copied ? context.sem.success : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared bits ────────────────────────────────────────────────────────

class _Timestamp extends StatelessWidget {
  const _Timestamp({required this.time, this.alignRight = false});

  final DateTime time;
  final bool alignRight;

  String _format(DateTime t) {
    final String h = t.hour.toString().padLeft(2, '0');
    final String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(time),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Three dots that pulse in sequence while awaiting the first token.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++) _dot(i, colors),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).aiChatThinking,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dot(int index, ColorScheme colors) {
    // Stagger each dot by a third of the cycle.
    final double phase = (_c.value + index / 3) % 1.0;
    final double t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.3 + 0.7 * t),
        shape: BoxShape.circle,
      ),
    );
  }
}
