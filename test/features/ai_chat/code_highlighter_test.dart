import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ai_chat/presentation/widgets/code_highlighter.dart';

/// Reconstructs the original source from tokens — a structural invariant that
/// guards against dropped/reordered characters in the scanner.
String _join(List<HighlightToken> tokens) =>
    tokens.map((HighlightToken t) => t.text).join();

HighlightToken? _tokenAt(List<HighlightToken> tokens, String needle) {
  for (final HighlightToken t in tokens) {
    if (t.text == needle) return t;
  }
  return null;
}

void main() {
  group('CodeHighlighter.highlight', () {
    test('preserves the full source text', () {
      final String code = 'echo "hello world"\nfor i in 1 2 3; do\n  echo \$i\ndone';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'bash');
      expect(_join(tokens), code);
    });

    test('classifies shell keywords, strings, variables and comments', () {
      final String code = '# a comment\necho "hi"\necho \$X\nif [ -n "\$Y" ]; then\n  export Z=42\nfi';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'bash');

      expect(_tokenAt(tokens, '# a comment')?.kind, HighlightKind.comment);
      expect(_tokenAt(tokens, 'echo')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'if')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'then')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'fi')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'export')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, '"hi"')?.kind, HighlightKind.string);
      // Unquoted shell variable → constant; quoted "$Y" stays a string token.
      expect(_tokenAt(tokens, r'$X')?.kind, HighlightKind.constant);
      expect(_tokenAt(tokens, '42')?.kind, HighlightKind.number);
    });

    test('classifies python keywords and function calls', () {
      const String code = 'def run(cmd):\n    return subprocess.call(cmd)';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'python');
      expect(_tokenAt(tokens, 'def')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'return')?.kind, HighlightKind.keyword);
      // `run`/`call` are immediately followed by `(` → function; `subprocess`
      // is followed by `.` so it stays plain.
      expect(_tokenAt(tokens, 'subprocess')?.kind, HighlightKind.plain);
      expect(_tokenAt(tokens, 'call')?.kind, HighlightKind.function);
    });

    test('classifies JSON booleans and null', () {
      const String code = '{"ok": true, "count": 3, "ref": null}';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'json');
      expect(_tokenAt(tokens, 'true')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, 'null')?.kind, HighlightKind.keyword);
      expect(_tokenAt(tokens, '3')?.kind, HighlightKind.number);
    });

    test('handles SQL line and block comments', () {
      final String code = 'SELECT * FROM t; -- trailing\n/* multi\nline */ SELECT 1;';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'sql');
      expect(_tokenAt(tokens, '-- trailing')?.kind, HighlightKind.comment);
      expect(_tokenAt(tokens, 'SELECT')?.kind, HighlightKind.keyword);
      // Every token that is part of the block comment is classified as comment.
      final HighlightToken blockStart = tokens.firstWhere(
        (HighlightToken t) => t.text.startsWith('/*'),
        orElse: () => const HighlightToken('', HighlightKind.plain),
      );
      expect(blockStart.kind, HighlightKind.comment);
    });

    test('unknown languages fall back to the generic pass', () {
      final String code = 'let x = 5; // note';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'foobar');
      expect(_join(tokens), code);
      expect(_tokenAt(tokens, '// note')?.kind, HighlightKind.comment);
      expect(_tokenAt(tokens, '5')?.kind, HighlightKind.number);
    });

    test('handles an unterminated string without throwing', () {
      final String code = 'echo "unterminated';
      final List<HighlightToken> tokens = CodeHighlighter.highlight(code, 'bash');
      expect(_join(tokens), code);
    });
  });

  group('CodeHighlighter.toSpans', () {
    test('emits one styled span per token', () {
      final List<TextSpan> spans = CodeHighlighter.toSpans(
        const <HighlightToken>[
          HighlightToken('echo', HighlightKind.keyword),
          HighlightToken(' "hi"', HighlightKind.string),
        ],
        base: const TextStyle(fontSize: 12),
      );
      expect(spans, hasLength(2));
      expect(spans[0].text, 'echo');
      expect(spans[1].text, ' "hi"');
    });
  });
}
