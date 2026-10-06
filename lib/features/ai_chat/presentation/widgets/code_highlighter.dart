import 'package:flutter/material.dart';

/// Lightweight, dependency-free syntax highlighter for the AI chat code blocks.
///
/// The markdown renderer previously painted every fenced block in a single
/// foreground colour. This tokenizer splits source into classified spans
/// ([HighlightToken]) so the renderer can colour keywords, strings, comments,
/// numbers and functions differently. It is intentionally small and fast —
/// only the languages an LLM actually emits in a shell-assistant context get
/// dedicated keyword tables; everything else degrades to strings/numbers.
///
/// Pure Dart (no Flutter widgets, no I/O), so it is trivially unit-testable.
/// The single Flutter-facing surface is [palette] / [toSpans], used by
/// `MarkdownView`.
abstract final class CodeHighlighter {
  /// Classifies [code] for the given (possibly empty / aliased) [language].
  ///
  /// Unknown languages fall back to the generic pass (strings, numbers,
  /// comments, `/* */` blocks) so a future model output is never shown in a
  /// single flat colour.
  static List<HighlightToken> highlight(String code, String language) {
    final _Language lang = _languageFor(language);
    final List<HighlightToken> tokens = <HighlightToken>[];

    final String normalised =
        code.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final List<String> lines = normalised.split('\n');

    // A previous unterminated `/*` must not leak into this call.
    _blockCommentState = false;

    for (int li = 0; li < lines.length; li++) {
      _scanLine(lines[li], lang, tokens);
      if (li < lines.length - 1) {
        tokens.add(const HighlightToken('\n', HighlightKind.plain));
      }
    }
    _blockCommentState = false;
    return tokens;
  }

  /// Flutter colour for a [HighlightKind]. Palette is fixed because code
  /// blocks always render on a dark background regardless of app theme.
  static Color colorFor(HighlightKind kind) => switch (kind) {
        HighlightKind.keyword => const Color(0xFFC678DD),
        HighlightKind.string => const Color(0xFF98C379),
        HighlightKind.comment => const Color(0xFF7F848E),
        HighlightKind.number => const Color(0xFFD19A66),
        HighlightKind.function => const Color(0xFF61AFEF),
        HighlightKind.constant => const Color(0xFFE06C75),
        HighlightKind.operator => const Color(0xFF56B6C2),
        HighlightKind.plain => const Color(0xFFD4D4D4),
      };

  /// Converts tokens into styled spans. [base] supplies the shared text style
  /// (family/size/height); each token overrides only its colour.
  static List<TextSpan> toSpans(
    List<HighlightToken> tokens, {
    required TextStyle base,
  }) {
    return <TextSpan>[
      for (final HighlightToken token in tokens)
        TextSpan(
          text: token.text,
          style: base.copyWith(color: colorFor(token.kind)),
        ),
    ];
  }

  // ─── Internal state for multi-line block comments ───────────────────────
  static bool _blockCommentState = false;

  /// Tokenises a single [line] into [out], honouring an in-flight `/* */`
  /// block from a previous line.
  static void _scanLine(String line, _Language lang, List<HighlightToken> out) {
    int i = 0;
    final int n = line.length;

    void emitPlain(int end) {
      if (end > i) {
        out.add(HighlightToken(line.substring(i, end), HighlightKind.plain));
      }
    }

    while (i < n) {
      // In a block comment until `*/` closes it.
      if (_blockCommentState) {
        final int end = line.indexOf('*/', i);
        if (end == -1) {
          out.add(HighlightToken(line.substring(i), HighlightKind.comment));
          i = n;
          break;
        }
        out.add(
            HighlightToken(line.substring(i, end + 2), HighlightKind.comment));
        i = end + 2;
        _blockCommentState = false;
        continue;
      }

      // Line comments: `#`, `//`, `--`.
      if (lang.hashComment && line[i] == '#') {
        emitPlain(i);
        out.add(HighlightToken(line.substring(i), HighlightKind.comment));
        return;
      }
      if (lang.doubleSlashComment &&
          line[i] == '/' &&
          i + 1 < n &&
          line[i + 1] == '/') {
        emitPlain(i);
        out.add(HighlightToken(line.substring(i), HighlightKind.comment));
        return;
      }
      if (lang.dashComment &&
          line[i] == '-' &&
          i + 1 < n &&
          line[i + 1] == '-') {
        emitPlain(i);
        out.add(HighlightToken(line.substring(i), HighlightKind.comment));
        return;
      }
      if (lang.blockComment &&
          line[i] == '/' &&
          i + 1 < n &&
          line[i + 1] == '*') {
        final int end = line.indexOf('*/', i + 2);
        if (end == -1) {
          emitPlain(i);
          out.add(HighlightToken(line.substring(i), HighlightKind.comment));
          _blockCommentState = true;
          return;
        }
        emitPlain(i);
        out.add(
            HighlightToken(line.substring(i, end + 2), HighlightKind.comment));
        i = end + 2;
        continue;
      }

      // Shell-style variable: `$VAR` or `${VAR}`.
      if (lang.dollarVariable && line[i] == '\$') {
        int j = i + 1;
        if (j < n && line[j] == '{') {
          final int close = line.indexOf('}', j);
          if (close != -1) {
            emitPlain(i);
            out.add(HighlightToken(
                line.substring(i, close + 1), HighlightKind.constant));
            i = close + 1;
            continue;
          }
        }
        if (j < n && _isWordStart(line[j])) {
          while (j < n && _isWordChar(line[j])) {
            j++;
          }
          emitPlain(i);
          out.add(HighlightToken(
              line.substring(i, j), HighlightKind.constant));
          i = j;
          continue;
        }
      }

      // String literals (single, double, backtick) with escape handling.
      final String? quote = _stringStart(line, i, lang);
      if (quote != null) {
        emitPlain(i);
        final int end = _stringEnd(line, i + quote.length, quote);
        final int close = end == -1 ? n : end;
        out.add(HighlightToken(
            line.substring(i, close), HighlightKind.string));
        i = close;
        continue;
      }

      // Numbers.
      final int? numberEnd = _numberEnd(line, i);
      if (numberEnd != null) {
        emitPlain(i);
        out.add(HighlightToken(
            line.substring(i, numberEnd), HighlightKind.number));
        i = numberEnd;
        continue;
      }

      // Words: keywords, booleans, constants, functions.
      if (_isWordStart(line[i])) {
        int j = i;
        while (j < n && _isWordChar(line[j])) {
          j++;
        }
        final String word = line.substring(i, j);
        emitPlain(i);
        final HighlightKind kind = _classifyWord(word, lang, line, j, n);
        out.add(HighlightToken(word, kind));
        i = j;
        continue;
      }

      // Operators / punctuation.
      if (_isOperatorChar(line[i])) {
        emitPlain(i);
        int j = i;
        while (j < n && _isOperatorChar(line[j])) {
          j++;
        }
        out.add(HighlightToken(line.substring(i, j), HighlightKind.operator));
        i = j;
        continue;
      }

      // Unrecognized character (whitespace, decorators, non-ASCII…) — batch
      // the run as one plain token so the source text is preserved verbatim.
      int j = i + 1;
      while (j < n &&
          !_isWordStart(line[j]) &&
          !_isOperatorChar(line[j]) &&
          _stringStart(line, j, lang) == null &&
          !(lang.dollarVariable && line[j] == '\$') &&
          _numberEnd(line, j) == null) {
        j++;
      }
      out.add(HighlightToken(line.substring(i, j), HighlightKind.plain));
      i = j;
    }
    emitPlain(n);
  }

  static HighlightKind _classifyWord(
    String word,
    _Language lang,
    String line,
    int end,
    int n,
  ) {
    final String lower = word.toLowerCase();
    if (lang.keywords.contains(lower) || lang.booleans.contains(lower)) {
      return HighlightKind.keyword;
    }
    // Function call: identifier immediately followed by `(`.
    if (end < n && line[end] == '(') return HighlightKind.function;
    // SCREAMING_SNAKE / ALL-CAPS constants.
    if (_isConstant(word)) return HighlightKind.constant;
    return HighlightKind.plain;
  }

  static bool _isConstant(String word) {
    if (word.length < 2) return false;
    for (final int c in word.codeUnits) {
      final bool ok = (c >= 0x30 && c <= 0x39) ||
          (c >= 0x41 && c <= 0x5A) ||
          c == 0x5F;
      if (!ok) return false;
    }
    return true;
  }

  static String? _stringStart(String line, int i, _Language lang) {
    final String c = line[i];
    if (c == '"' || c == "'") return c;
    if (c == '`' && lang.backtickString) return c;
    return null;
  }

  /// Returns the index just past the closing quote, or -1 when unterminated.
  static int _stringEnd(String line, int i, String quote) {
    final int n = line.length;
    while (i < n) {
      final String c = line[i];
      if (c == '\\') {
        i += 2;
        continue;
      }
      if (c == quote) return i + 1;
      i++;
    }
    return -1;
  }

  static int? _numberEnd(String line, int i) {
    if (line[i] == '.') {
      if (i + 1 >= line.length) return null;
      if (!_isDigit(line[i + 1])) return null;
    } else if (!_isDigit(line[i])) {
      return null;
    }
    int j = i;
    final int n = line.length;
    bool seenDot = false;
    while (j < n) {
      final String c = line[j];
      if (_isDigit(c)) {
        j++;
        continue;
      }
      if (c == '.' && !seenDot && j + 1 < n && _isDigit(line[j + 1])) {
        seenDot = true;
        j++;
        continue;
      }
      break;
    }
    return j;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
  static bool _isWordStart(String c) {
    final int u = c.codeUnitAt(0);
    return (u >= 0x41 && u <= 0x5A) ||
        (u >= 0x61 && u <= 0x7A) ||
        c == '_';
  }

  static bool _isWordChar(String c) {
    final int u = c.codeUnitAt(0);
    return (u >= 0x41 && u <= 0x5A) ||
        (u >= 0x61 && u <= 0x7A) ||
        (u >= 0x30 && u <= 0x39) ||
        c == '_' ||
        c == '-';
  }

  static bool _isOperatorChar(String c) {
    const String ops = '+-*/%=<>!&|^~?:;,()[]{}';
    return ops.contains(c);
  }

  static _Language _languageFor(String language) {
    final String lower = language.trim().toLowerCase();
    if (lower == 'bash' || lower == 'sh' || lower == 'shell' || lower == 'zsh') {
      return _Language.shell;
    }
    if (lower == 'python' || lower == 'py' || lower == 'python3') {
      return _Language.python;
    }
    if (lower == 'json' || lower == 'json5') return _Language.json;
    if (lower == 'yaml' || lower == 'yml') return _Language.yaml;
    if (lower == 'dockerfile' || lower == 'docker') return _Language.dockerfile;
    if (lower == 'sql' || lower == 'mysql' || lower == 'postgresql' ||
        lower == 'postgres' || lower == 'plsql') {
      return _Language.sql;
    }
    return _Language.generic;
  }
}

/// Kind of a highlighted token. Drives the palette colour only.
enum HighlightKind { plain, keyword, string, comment, number, function, constant, operator }

/// A contiguous run of source text with a single [HighlightKind].
@immutable
class HighlightToken {
  const HighlightToken(this.text, this.kind);

  final String text;
  final HighlightKind kind;

  @override
  String toString() => 'HighlightToken(${kind.name}, ${text.length} chars)';
}

/// Per-language lexical configuration used by the scanner.
class _Language {
  const _Language({
    required this.keywords,
    this.booleans = const <String>{},
    this.hashComment = false,
    this.doubleSlashComment = false,
    this.dashComment = false,
    this.blockComment = false,
    this.dollarVariable = false,
    this.backtickString = false,
  });

  final Set<String> keywords;
  final Set<String> booleans;
  final bool hashComment;
  final bool doubleSlashComment;
  final bool dashComment;
  final bool blockComment;
  final bool dollarVariable;
  final bool backtickString;

  static const _Language shell = _Language(
    keywords: <String>{
      'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'until', 'do',
      'done', 'case', 'esac', 'in', 'select', 'function', 'time', 'coproc',
      'echo', 'cd', 'export', 'source', 'alias', 'unalias', 'read', 'local',
      'return', 'exit', 'set', 'unset', 'shift', 'trap', 'test', 'printf',
      'exec', 'eval', 'declare', 'typeset', 'sudo', 'command', 'builtin',
      'true', 'false', 'yes', 'no',
    },
    booleans: <String>{'true', 'false'},
    hashComment: true,
    dollarVariable: true,
    backtickString: true,
  );

  static const _Language python = _Language(
    keywords: <String>{
      'def', 'class', 'return', 'if', 'elif', 'else', 'for', 'while',
      'import', 'from', 'as', 'try', 'except', 'finally', 'with', 'lambda',
      'pass', 'break', 'continue', 'yield', 'global', 'nonlocal', 'del',
      'assert', 'raise', 'in', 'is', 'not', 'and', 'or', 'None', 'True',
      'False', 'async', 'await', 'print', 'self',
    },
    booleans: <String>{'None', 'True', 'False'},
    hashComment: true,
  );

  static const _Language json = _Language(
    keywords: <String>{'true', 'false', 'null'},
    booleans: <String>{'true', 'false', 'null'},
  );

  static const _Language yaml = _Language(
    keywords: <String>{'true', 'false', 'null', 'yes', 'no', 'on', 'off'},
    booleans: <String>{'true', 'false', 'null'},
    hashComment: true,
  );

  static const _Language dockerfile = _Language(
    keywords: <String>{
      'from', 'run', 'cmd', 'copy', 'add', 'env', 'workdir', 'expose',
      'entrypoint', 'volume', 'user', 'arg', 'label', 'onbuild',
      'stopsignal', 'healthcheck', 'shell', 'maintainer',
    },
    hashComment: true,
  );

  static const _Language sql = _Language(
    keywords: <String>{
      'select', 'from', 'where', 'insert', 'into', 'values', 'update', 'set',
      'delete', 'create', 'table', 'drop', 'alter', 'join', 'left', 'right',
      'inner', 'outer', 'full', 'on', 'as', 'and', 'or', 'not', 'null',
      'group', 'by', 'order', 'having', 'limit', 'offset', 'distinct',
      'union', 'all', 'case', 'when', 'then', 'else', 'end', 'exists',
      'between', 'like', 'in', 'is', 'primary', 'key', 'foreign', 'references',
      'index', 'view', 'default', 'unique', 'count', 'sum', 'avg', 'min', 'max',
    },
    booleans: <String>{'true', 'false', 'null'},
    dashComment: true,
    blockComment: true,
  );

  static const _Language generic = _Language(
    keywords: <String>{},
    hashComment: true,
    doubleSlashComment: true,
    dashComment: true,
    blockComment: true,
    dollarVariable: true,
    backtickString: true,
  );
}
