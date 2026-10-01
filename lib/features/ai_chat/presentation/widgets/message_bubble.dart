import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/chat_message.dart';
import 'streaming_text.dart';

/// A single chat turn rendered in the Terminal Noir language.
///
/// User turns are right-aligned on a phosphor-tinted slab; assistant turns
/// are left-aligned on a raised surface with a `>_` sigil, monospaced role
/// tag, and Markdown-rendered body (live cursor while streaming).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  final ChatMessage message;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    return message.isUser
        ? _UserBubble(message: message, showTimestamp: showTimestamp)
        : _AssistantBubble(message: message, showTimestamp: showTimestamp);
  }
}

// ─── User bubble ────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.showTimestamp});

  final ChatMessage message;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppTheme.phosphor.withValues(alpha: 0.20),
                    AppTheme.phosphor.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(3),
                ),
                border: Border.all(
                  color: AppTheme.phosphor.withValues(alpha: 0.40),
                ),
              ),
              child: SelectableText(
                message.content,
                style: context.text.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.55,
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
  const _AssistantBubble({required this.message, required this.showTimestamp});

  final ChatMessage message;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final bool isError = message.error;
    final Color accent = isError ? AppTheme.coral : AppTheme.phosphorDim;

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
                // Sigil avatar.
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.inkSurface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isError
                          ? AppTheme.coral.withValues(alpha: 0.45)
                          : AppTheme.phosphor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isError ? '!' : '>',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isError ? AppTheme.coral : AppTheme.phosphor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Role tag.
                      Text(
                        isError ? 'error' : 'shell-mind',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontFamilyFallback: const <String>[
                            'JetBrains Mono',
                            'Menlo',
                            'monospace',
                          ],
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                        decoration: BoxDecoration(
                          color: isError
                              ? AppTheme.coral.withValues(alpha: 0.06)
                              : AppTheme.inkSurface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: isError
                                ? AppTheme.coral.withValues(alpha: 0.35)
                                : AppTheme.inkBorderSoft,
                          ),
                        ),
                        child: _AssistantBody(message: message),
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
  const _AssistantBody({required this.message});

  final ChatMessage message;

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
    return GestureDetector(
      onTap: _copy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            size: 11,
            color: _copied ? AppTheme.mint : AppTheme.textTertiary,
          ),
          const SizedBox(width: 3),
          Text(
            _copied ? 'copied' : 'copy',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 9.5,
              letterSpacing: 0.5,
              color: _copied ? AppTheme.mint : AppTheme.textTertiary,
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
        fontFamily: AppTheme.monoFont,
        fontFamilyFallback: const <String>[
          'JetBrains Mono',
          'Menlo',
          'monospace',
        ],
        fontSize: 9.5,
        letterSpacing: 0.4,
        color: AppTheme.textDisabled,
      ),
    );
  }
}

/// Three phosphor dots that pulse in sequence while awaiting the first token.
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
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++) _dot(i),
            const SizedBox(width: 8),
            Text(
              'thinking',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    // Stagger each dot by a third of the cycle.
    final double phase = (_c.value + index / 3) % 1.0;
    final double t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: AppTheme.phosphor.withValues(alpha: 0.35 + 0.65 * t),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.phosphor.withValues(alpha: 0.5 * t),
            blurRadius: 6 * t,
          ),
        ],
      ),
    );
  }
}
