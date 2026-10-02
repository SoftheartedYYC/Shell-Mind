import 'package:flutter/foundation.dart';

/// A single executable command block extracted from an AI response.
///
/// Produced by [CommandBlockParser.parse] — one instance per fenced code
/// block whose language tag marks it as runnable (bash/shell/sh).
@immutable
class CommandBlock {
  const CommandBlock({
    required this.command,
    this.targetServer,
    required this.language,
    required this.blockIndex,
  });

  /// Pure command text with the `# server:` tag line (if any) removed and
  /// trailing blank lines trimmed.
  final String command;

  /// Target server label parsed from a leading `# server: <name>` comment,
  /// or `null` when the block does not name one (caller picks the server).
  final String? targetServer;

  /// Original fence language tag, e.g. `bash`, `shell` or `sh`.
  final String language;

  /// Zero-based index of the source code block within the AI response,
  /// counting only executable blocks in document order.
  final int blockIndex;

  @override
  bool operator ==(Object other) =>
      other is CommandBlock &&
      other.command == command &&
      other.targetServer == targetServer &&
      other.language == language &&
      other.blockIndex == blockIndex;

  @override
  int get hashCode => Object.hash(command, targetServer, language, blockIndex);

  @override
  String toString() =>
      'CommandBlock(#$blockIndex, $language, server: $targetServer, '
      '${command.length} chars)';
}

/// Extracts executable command blocks from AI response markdown.
///
/// Parsing rules:
/// 1. Recognises ```` ```bash ````/```` ```shell ````/```` ```sh ```` fenced
///    code blocks (language tag compared case-insensitively).
/// 2. If the block's first line is a `# server: <name>` comment, the name is
///    extracted as [CommandBlock.targetServer] and the line removed.
/// 3. The remaining text becomes [CommandBlock.command].
/// 4. Non-executable fences (```` ```python ````, ```` ```json ```` …) and
///    unlabeled fences are ignored.
/// 5. Blocks whose command is empty after trimming are ignored.
/// 6. An unterminated fence (typical while streaming) is tolerated: content
///    runs to the end of the response.
class CommandBlockParser {
  CommandBlockParser._();

  /// Language tags treated as runnable shell commands.
  static const Set<String> executableLanguages = <String>{'bash', 'shell', 'sh'};

  /// Matches a leading `# server: <serverName>` tag line. The `server`
  /// keyword is case-insensitive; the captured name keeps its original case.
  static final RegExp serverTagPattern = RegExp(
    r'^#\s*server:\s*(.+)$',
    caseSensitive: false,
  );

  /// Opening fence: ``` followed by an optional word-character language tag.
  static final RegExp _openFencePattern = RegExp(r'^```(\w*)\s*$');

  /// Closing fence: a bare ``` line.
  static final RegExp _closeFencePattern = RegExp(r'^```\s*$');

  /// Parses [aiResponse] and returns every executable command block found,
  /// in document order.
  static List<CommandBlock> parse(String aiResponse) {
    final List<String> lines = aiResponse.split('\n');
    final List<CommandBlock> blocks = <CommandBlock>[];

    String? openLanguage;
    List<String>? body;

    for (final String rawLine in lines) {
      // Normalize CRLF/CR leftovers from the split.
      final String line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;

      if (openLanguage == null) {
        final RegExpMatch? open = _openFencePattern.firstMatch(line);
        if (open == null) continue;
        final String language = (open.group(1) ?? '').toLowerCase();
        // Only track executable fences; others are skipped entirely so a
        // bare ``` inside e.g. a python block cannot be mistaken for a
        // shell fence opener.
        if (executableLanguages.contains(language)) {
          openLanguage = language;
          body = <String>[];
        }
        continue;
      }

      if (_closeFencePattern.hasMatch(line)) {
        final CommandBlock? block =
            _buildBlock(body!, openLanguage, blocks.length);
        if (block != null) blocks.add(block);
        openLanguage = null;
        body = null;
        continue;
      }

      body!.add(line);
    }

    // Unterminated fence (streaming in progress): accept what we have.
    if (openLanguage != null && body != null) {
      final CommandBlock? block = _buildBlock(body, openLanguage, blocks.length);
      if (block != null) blocks.add(block);
    }

    return blocks;
  }

  /// Quick check for whether [aiResponse] contains at least one executable
  /// command block.
  static bool hasExecutableBlocks(String aiResponse) =>
      parse(aiResponse).isNotEmpty;

  /// Turns a collected fence body into a [CommandBlock], or returns `null`
  /// when the command is empty after stripping the server tag line.
  static CommandBlock? _buildBlock(
    List<String> body,
    String language,
    int blockIndex,
  ) {
    String? targetServer;
    List<String> contentLines = body;

    if (body.isNotEmpty) {
      final RegExpMatch? tag = serverTagPattern.firstMatch(body.first.trim());
      if (tag != null) {
        final String name = (tag.group(1) ?? '').trim();
        if (name.isNotEmpty) {
          targetServer = name;
          contentLines = body.sublist(1);
        }
      }
    }

    final String command = contentLines.join('\n').trim();
    if (command.isEmpty) return null;

    return CommandBlock(
      command: command,
      targetServer: targetServer,
      language: language,
      blockIndex: blockIndex,
    );
  }
}
