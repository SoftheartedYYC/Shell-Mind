import 'entities/chat_message.dart';

/// Pure Markdown exporter for AI chat transcripts.
///
/// Converts an immutable [ChatMessage] list into a standalone Markdown
/// document: a timestamped header, `## 用户` block-quoted user turns, `## 助手`
/// bodies, and tool executions rendered as fenced code blocks carrying the
/// server name and exit code.
///
/// No I/O and no Flutter dependencies — trivially unit-testable. File writing
/// lives in the presentation layer (see `AiChatPage._exportChat`).
class ChatExporter {
  const ChatExporter._();

  /// Renders [messages] into a Markdown document.
  ///
  /// [exportedAt] overrides the header timestamp (defaults to now) — inject a
  /// fixed value in tests for deterministic output. Empty conversations
  /// produce a valid header with a zero message count; the UI gates the
  /// export action on a non-empty transcript.
  static String export(List<ChatMessage> messages, {DateTime? exportedAt}) {
    final DateTime at = exportedAt ?? DateTime.now();
    final StringBuffer buffer = StringBuffer();
    buffer
      ..writeln('# Shell-Mind 对话导出')
      ..writeln()
      ..writeln('- 导出时间：${formatTimestamp(at)}')
      ..writeln('- 消息数：${messages.length}')
      ..writeln();
    for (final ChatMessage message in messages) {
      if (message.isSystem) continue; // System prompts are not user-visible.
      _writeMessage(buffer, message);
    }
    return buffer.toString();
  }

  /// Filesystem-safe compact stamp: `yyyyMMdd-HHmmss` (used in export file
  /// names, e.g. `shell-mind-chat-20261003-093005.md`).
  static String fileStamp(DateTime time) {
    String p(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${p(time.year, 4)}${p(time.month)}${p(time.day)}'
        '-${p(time.hour)}${p(time.minute)}${p(time.second)}';
  }

  /// Locale-independent `yyyy-MM-dd HH:mm:ss`.
  static String formatTimestamp(DateTime time) {
    String p(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${p(time.year, 4)}-${p(time.month)}-${p(time.day)} '
        '${p(time.hour)}:${p(time.minute)}:${p(time.second)}';
  }

  static void _writeMessage(StringBuffer buffer, ChatMessage message) {
    final String stamp = formatTimestamp(message.timestamp);
    if (message.isTool) {
      _writeTool(buffer, message, stamp);
      return;
    }
    if (message.isUser) {
      buffer
        ..writeln('## 用户 · $stamp')
        ..writeln()
        ..writeln(_quote(message.content))
        ..writeln();
      return;
    }
    // Assistant (and any non-tool, non-user turn): plain body.
    final String body =
        message.content.trim().isEmpty ? '_(无内容)_' : message.content;
    buffer
      ..writeln('## 助手 · $stamp')
      ..writeln()
      ..writeln(body)
      ..writeln();
  }

  /// Renders a tool execution as a labelled section: server name and exit
  /// code in the heading, the command in a `bash` fence, and stdout/stderr in
  /// text fences.
  static void _writeTool(
    StringBuffer buffer,
    ChatMessage message,
    String stamp,
  ) {
    final ToolPayload? payload = message.toolPayload;
    if (payload == null) {
      // Degraded message (payload lost in an old snapshot): keep the wire
      // envelope as a plain text block so nothing is silently dropped.
      buffer
        ..writeln('## 工具执行 · $stamp')
        ..writeln()
        ..writeln(_fence(message.content, language: 'text'))
        ..writeln();
      return;
    }
    final String server =
        payload.serverName.trim().isEmpty ? '未知服务器' : payload.serverName;
    buffer
      ..writeln('## 工具执行 · $server · 退出码 ${payload.exitCode} · $stamp')
      ..writeln()
      ..writeln('**命令**')
      ..writeln()
      ..writeln(_fence(payload.command, language: 'bash'))
      ..writeln();
    if (payload.stdout.trim().isNotEmpty) {
      buffer
        ..writeln('**输出**')
        ..writeln()
        ..writeln(_fence(payload.stdout, language: 'text'))
        ..writeln();
    }
    if (payload.stderr.trim().isNotEmpty) {
      buffer
        ..writeln('**错误输出**')
        ..writeln()
        ..writeln(_fence(payload.stderr, language: 'text'))
        ..writeln();
    }
  }

  /// Block-quotes every line of [content], keeping blank lines as bare `>`
  /// and tolerating CRLF input.
  static String _quote(String content) => content
      .split('\n')
      .map((String line) {
        final String clean =
            line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
        return clean.isEmpty ? '>' : '> $clean';
      })
      .join('\n');

  /// Wraps [content] in a fenced code block, growing the fence beyond the
  /// longest backtick run inside the content (per CommonMark) so nested
  /// Markdown can never break out of the block.
  static String _fence(String content, {required String language}) {
    int longest = 0;
    int run = 0;
    for (final int code in content.codeUnits) {
      if (code == 0x60) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    final String fence = '`' * (longest >= 3 ? longest + 1 : 3);
    final String body = content.endsWith('\n')
        ? content.substring(0, content.length - 1)
        : content;
    return '$fence$language\n$body\n$fence';
  }
}
