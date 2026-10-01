import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

/// A dependency-free Markdown renderer tuned for the Material theme.
///
/// Supports the subset an LLM actually emits in a shell-assistant context:
/// fenced code blocks (with language tag + copy button), inline code, bold,
/// italic, headings, and ordered/unordered lists. Parsing is intentionally
/// forgiving — an unterminated code fence (common mid-stream) is rendered as
/// a live code block rather than breaking the layout.
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.text,
    this.selectable = true,
    this.textScale = 1.0,
  });

  final String text;

  /// When true, body paragraphs use [SelectableText] for easy copying.
  final bool selectable;

  /// Multiplier applied to base font sizes.
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final List<_Block> blocks = _parse(text);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < blocks.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _renderBlock(context, blocks[i]),
        ],
      ],
    );
  }

  Widget _renderBlock(BuildContext context, _Block block) {
    return switch (block) {
      _CodeBlock(:final String lang, :final String content) =>
        _CodeBlockView(language: lang, code: content, textScale: textScale),
      _Heading(:final int level, :final String content) =>
        _HeadingView(level: level, content: content, textScale: textScale),
      _ListBlock(:final List<String> items, :final bool ordered) =>
        _ListView(
          items: items,
          ordered: ordered,
          selectable: selectable,
          textScale: textScale,
        ),
      _Paragraph(:final String content) => _ParagraphView(
          content: content,
          selectable: selectable,
          textScale: textScale,
        ),
    };
  }
}

// ─── Block model ────────────────────────────────────────────────────────

sealed class _Block {
  const _Block();
}

class _CodeBlock extends _Block {
  const _CodeBlock(this.lang, this.content);
  final String lang;
  final String content;
}

class _Heading extends _Block {
  const _Heading(this.level, this.content);
  final int level;
  final String content;
}

class _ListBlock extends _Block {
  const _ListBlock(this.items, this.ordered);
  final List<String> items;
  final bool ordered;
}

class _Paragraph extends _Block {
  const _Paragraph(this.content);
  final String content;
}

// ─── Parser ─────────────────────────────────────────────────────────────

final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final RegExp _bulletRe = RegExp(r'^\s*[-*+]\s+(.*)$');
final RegExp _orderedRe = RegExp(r'^\s*\d+[.)]\s+(.*)$');

List<_Block> _parse(String source) {
  final String normalised = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final List<String> lines = normalised.split('\n');
  final List<_Block> blocks = <_Block>[];

  final List<String> paragraph = <String>[];
  void flushParagraph() {
    if (paragraph.isEmpty) return;
    // Trim leading/trailing blank lines within the paragraph buffer.
    final String joined = paragraph.join('\n').trim();
    paragraph.clear();
    if (joined.isNotEmpty) blocks.add(_Paragraph(joined));
  }

  int i = 0;
  while (i < lines.length) {
    final String line = lines[i];

    // Fenced code block.
    final String trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      flushParagraph();
      final String lang = trimmed.substring(3).trim();
      final List<String> code = <String>[];
      i++;
      while (i < lines.length) {
        if (lines[i].trimLeft().startsWith('```')) {
          i++;
          break;
        }
        code.add(lines[i]);
        i++;
      }
      // An unterminated fence (common mid-stream) still renders as code.
      blocks.add(_CodeBlock(lang, code.join('\n')));
      continue;
    }

    // Heading.
    final RegExpMatch? heading = _headingRe.firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(_Heading(
        heading.group(1)!.length,
        heading.group(2)!.trim(),
      ));
      i++;
      continue;
    }

    // List (bullet or ordered) — gather consecutive items.
    final bool isBullet = _bulletRe.hasMatch(line);
    final bool isOrdered = _orderedRe.hasMatch(line);
    if (isBullet || isOrdered) {
      flushParagraph();
      final bool ordered = isOrdered;
      final List<String> items = <String>[];
      while (i < lines.length) {
        final RegExpMatch? m =
            (ordered ? _orderedRe : _bulletRe).firstMatch(lines[i]);
        if (m == null) break;
        items.add(m.group(1)!.trim());
        i++;
      }
      blocks.add(_ListBlock(items, ordered));
      continue;
    }

    // Blank line ends the current paragraph.
    if (line.trim().isEmpty) {
      flushParagraph();
      i++;
      continue;
    }

    paragraph.add(line);
    i++;
  }
  flushParagraph();

  return blocks;
}

// ─── Inline formatting ──────────────────────────────────────────────────

final RegExp _inlineRe = RegExp(
  r'(`[^`]+`)|(\*\*[^*]+\*\*)|(__[^_]+__)|(\*[^*\n]+\*)|(_[^_\n]+_)|(~~[^~]+~~)',
);

/// Builds rich spans for inline `code`, **bold**, *italic*, ~~strike~~.
List<InlineSpan> _inlineSpans(
  String text, {
  required TextStyle base,
  required TextStyle code,
  required Color codeBg,
}) {
  final List<InlineSpan> spans = <InlineSpan>[];
  int cursor = 0;

  for (final RegExpMatch m in _inlineRe.allMatches(text)) {
    final int start = m.start;
    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start)));
    }
    final String token = m.group(0)!;
    if (token.startsWith('`')) {
      final String inner = token.substring(1, token.length - 1);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _InlineCode(text: inner, style: code, background: codeBg),
      ));
    } else if (token.startsWith('~~')) {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: base.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: base.color,
        ),
      ));
    } else if (token.startsWith('**') || token.startsWith('__')) {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: base.copyWith(fontWeight: FontWeight.w700),
      ));
    } else {
      // *italic* or _italic_
      spans.add(TextSpan(
        text: token.substring(1, token.length - 1),
        style: base.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    cursor = m.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

// ─── Block widgets ──────────────────────────────────────────────────────

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.content,
    required this.selectable,
    required this.textScale,
  });

  final String content;
  final bool selectable;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle base = (context.text.bodyMedium ?? const TextStyle()).copyWith(
      color: colors.onSurface,
      height: 1.6,
      fontSize: 13.5 * textScale,
    );
    final TextStyle codeStyle = _mono(context, 12.5 * textScale)
        .copyWith(color: colors.primary, fontWeight: FontWeight.w500);
    final Color codeBg = colors.primary.withValues(alpha: 0.08);

    // Preserve hard line breaks inside a paragraph as separate rich lines.
    final List<String> lines = content.split('\n');
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      spans.addAll(_inlineSpans(
        lines[i],
        base: base,
        code: codeStyle,
        codeBg: codeBg,
      ));
    }

    final TextSpan rich = TextSpan(style: base, children: spans);
    if (selectable) {
      return SelectableText.rich(rich);
    }
    return Text.rich(rich);
  }
}

class _HeadingView extends StatelessWidget {
  const _HeadingView({
    required this.level,
    required this.content,
    required this.textScale,
  });

  final int level;
  final String content;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double size = switch (level) {
      1 => 19,
      2 => 17,
      3 => 15.5,
      _ => 14,
    } * textScale;

    return Padding(
      padding: EdgeInsets.only(top: level <= 2 ? 2 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 3,
            margin: const EdgeInsets.only(top: 4, right: 9),
            constraints: const BoxConstraints(minHeight: 14),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: context.text.titleLarge?.copyWith(
                fontSize: size,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: colors.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({
    required this.items,
    required this.ordered,
    required this.selectable,
    required this.textScale,
  });

  final List<String> items;
  final bool ordered;
  final bool selectable;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle base = (context.text.bodyMedium ?? const TextStyle()).copyWith(
      color: colors.onSurface,
      height: 1.55,
      fontSize: 13.5 * textScale,
    );
    final TextStyle codeStyle = _mono(context, 12.5 * textScale)
        .copyWith(color: colors.primary, fontWeight: FontWeight.w500);
    final Color codeBg = colors.primary.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: Text(
                    ordered ? '${i + 1}.' : '•',
                    style: TextStyle(
                      fontSize: 13 * textScale,
                      height: 1.55,
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: base,
                      children: _inlineSpans(
                        items[i],
                        base: base,
                        code: codeStyle,
                        codeBg: codeBg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InlineCode extends StatelessWidget {
  const _InlineCode({
    required this.text,
    required this.style,
    required this.background,
  });

  final String text;
  final TextStyle style;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: style),
    );
  }
}

class _CodeBlockView extends StatefulWidget {
  const _CodeBlockView({
    required this.language,
    required this.code,
    required this.textScale,
  });

  final String language;
  final String code;
  final double textScale;

  @override
  State<_CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<_CodeBlockView> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String label = widget.language.isEmpty ? 'code' : widget.language;

    // Code blocks always use a dark background for readability.
    final Color codeBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFF282C34);
    final Color codeFg = const Color(0xFFD4D4D4);
    final Color headerBg = isDark ? const Color(0xFF16162A) : const Color(0xFF21252B);

    final TextStyle codeStyle = _mono(context, 12.5 * widget.textScale).copyWith(
      color: codeFg,
      height: 1.55,
    );

    return Container(
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Title bar.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: AppTheme.monoFallback,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                _CopyButton(copied: _copied, onTap: _copy),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: SelectableText(
              widget.code.isEmpty ? ' ' : widget.code,
              style: codeStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.copied, required this.onTap});

  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = copied ? const Color(0xFF4CAF50) : Colors.white54;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 13,
                color: tint,
              ),
              const SizedBox(width: 4),
              Text(
                copied ? 'Copied' : 'Copy',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.3,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ─────────────────────────────────────────────────────

TextStyle _mono(BuildContext context, double size) => TextStyle(
      fontFamily: AppTheme.monoFont,
      fontFamilyFallback: AppTheme.monoFallback,
      fontSize: size,
      letterSpacing: 0.2,
    );
