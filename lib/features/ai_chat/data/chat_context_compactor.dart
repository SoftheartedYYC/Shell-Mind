import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/entities/chat_message.dart';

// ─── Context-window compaction ────────────────────────────────────────────
//
// Long conversations must not overflow the model's context window, but hard
// truncation (the previous behaviour: keep only the most recent
// [kDefaultKeepRecentMessages] turns) silently drops everything the
// conversation established earlier.
//
// Strategy, in order:
//   1. The trailing [CompactionConfig.keepRecentMessages] turns are forwarded
//      verbatim — never compressed.
//   2. Older turns are merged into ONE synthesized user-role summary turn
//      ("[早期对话摘要]") inserted right after the system prompt: user and
//      assistant turns become 「用户: … / 助手: …」 digest lines, tool results
//      collapse to 「执行了 <命令>@<服务器> → 退出码 N」.
//   3. When the estimated token budget ([CompactionConfig.tokenBudget]) is
//      still exceeded, the ladder gives up fidelity from the oldest side:
//      a. drop oldest summary digest lines,
//      b. degrade recent tool envelopes to their key-field digest lines,
//      c. drop oldest recent turns entirely (at least one is always kept).
//
// Everything here is pure and side-effect free so the policy can be unit
// tested without touching the transport layer.

/// Single source of truth for "how many trailing messages are forwarded to
/// the model uncompressed". [ChatRepositoryImpl] aliases this as
/// `kMaxHistoryMessages`, whose documented meaning is exactly this.
const int kDefaultKeepRecentMessages = 20;

/// Default estimated-token ceiling for the compacted context (summary turn +
/// recent turns). Conservative enough for small-window providers while still
/// carrying a meaningful digest of long sessions.
const int kDefaultTokenBudget = 6000;

/// Stable header of the synthesized summary turn. Also serves as the marker
/// tests (and debugging tooling) use to spot compaction on the wire.
const String kContextSummaryHeader = '[早期对话摘要]';

/// Prefix for degraded tool results kept as a bare digest line.
const String kToolDigestPrefix = '[tool-output]';

/// Digest lines are clipped to this length — a summary line that reproduces
/// a whole 10k-char assistant answer would defeat the compaction.
const int kMaxDigestLineChars = 200;

// ─── Token estimation ─────────────────────────────────────────────────────

/// Estimates the model token count of [text].
///
/// Heuristic required by the compaction budget: CJK characters cost ~1 token
/// each, non-CJK text averages ~4 characters per token (roughly one word per
/// 4 ASCII characters). Mixed text is priced per character class. The result
/// is rounded up — over-estimating is the safe direction for a budget check.
int estimateTokens(String text) {
  if (text.isEmpty) return 0;
  int cjk = 0;
  int other = 0;
  for (final int code in text.runes) {
    if (_isCjkCodePoint(code)) {
      cjk++;
    } else {
      other++;
    }
  }
  return (cjk + other * 0.25).ceil();
}

bool _isCjkCodePoint(int code) =>
    (code >= 0x3000 && code <= 0x303F) || // CJK punctuation
    (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
    (code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
    (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
    (code >= 0xFF00 && code <= 0xFFEF); // Fullwidth forms

// ─── Digests ──────────────────────────────────────────────────────────────

/// Formats a tool execution outcome as the one-line key-field digest:
/// `执行了 <命令>@<服务器> → 退出码 N`.
String compactToolResult(ToolPayload payload) {
  final String server = payload.serverName.trim().isNotEmpty
      ? payload.serverName.trim()
      : payload.serverId.trim();
  return '执行了 ${payload.command.trim()}@${server.isEmpty ? '-' : server}'
      ' → 退出码 ${payload.exitCode}';
}

/// Collapses a single message into the one-line digest used inside the
/// summary turn. Returns '' for messages that carry nothing worth keeping
/// (system noise, blank content).
String compactMessageForSummary(ChatMessage message) {
  final String content = _oneLine(message.content);
  switch (message.role) {
    case MessageRole.system:
      return '';
    case MessageRole.tool:
      final ToolPayload? payload = message.toolPayload;
      return payload == null
          ? (content.isEmpty ? '' : '$kToolDigestPrefix $content')
          : _oneLine(compactToolResult(payload));
    case MessageRole.user:
      return content.isEmpty ? '' : '用户: $content';
    case MessageRole.assistant:
      return content.isEmpty ? '' : '助手: $content';
  }
}

/// Flattens newlines/whitespace to single spaces and clips the result to
/// [kMaxDigestLineChars].
String _oneLine(String text) {
  final String flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.length <= kMaxDigestLineChars) return flat;
  return '${flat.substring(0, kMaxDigestLineChars)}…';
}

// ─── Compaction policy ────────────────────────────────────────────────────

/// Knobs of the compaction strategy.
@immutable
class CompactionConfig {
  const CompactionConfig({
    this.keepRecentMessages = kDefaultKeepRecentMessages,
    this.tokenBudget = kDefaultTokenBudget,
  });

  /// Number of trailing messages forwarded verbatim — never summarized.
  final int keepRecentMessages;

  /// Estimated-token ceiling for the compacted context (summary + recent).
  final int tokenBudget;
}

/// Outcome of [compactChatHistory].
@immutable
class CompactedContext {
  const CompactedContext({
    required this.summary,
    required this.recent,
    required this.compactedCount,
    required this.droppedSummaryLines,
    required this.droppedToolOutputs,
    required this.estimatedTokens,
  });

  /// Rendered summary turn content; '' when nothing was compacted.
  final String summary;

  bool get hasSummary => summary.isNotEmpty;

  /// Trailing messages forwarded verbatim (recent tool payloads may have
  /// been degraded to digest lines under budget pressure).
  final List<ChatMessage> recent;

  /// How many older messages were folded into the summary (before any
  /// budget-driven line dropping).
  final int compactedCount;

  /// Summary digest lines dropped under budget pressure (oldest first).
  final int droppedSummaryLines;

  /// Recent tool envelopes degraded to one-line key-field digests.
  final int droppedToolOutputs;

  /// Estimated tokens of summary + recent wire content. The system prompt
  /// and the live user message are not included.
  final int estimatedTokens;
}

/// Compacts [history] into a summary of the older turns plus a verbatim
/// recent window, keeping the estimated token cost within
/// [CompactionConfig.tokenBudget].
///
/// System messages and blank-content messages never enter the context (they
/// are filtered before any accounting). Order preservation is the contract:
/// [CompactedContext.recent] replays the original chronology of the trailing
/// window.
///
/// Budget ladder (see the module doc): drop oldest summary lines first, then
/// degrade recent tool envelopes, then drop oldest recent turns — always
/// keeping at least one recent message. If the budget is so small that even
/// that remainder does not fit, the best effort is returned as-is.
CompactedContext compactChatHistory(
  List<ChatMessage> history, {
  CompactionConfig config = const CompactionConfig(),
}) {
  final List<ChatMessage> turns = <ChatMessage>[
    for (final ChatMessage m in history)
      if (!m.isSystem && m.content.trim().isNotEmpty) m,
  ];

  final int keep =
      math.max(0, math.min(config.keepRecentMessages, turns.length));
  final int split = turns.length - keep;
  final List<ChatMessage> older = turns.sublist(0, split);
  final List<ChatMessage> recent = turns.sublist(split);

  // 1) Digest lines for the summary, chronological (oldest first).
  final List<String> lines = <String>[
    for (final ChatMessage m in older)
      if (compactMessageForSummary(m) case final String line
          when line.isNotEmpty)
        line,
  ];

  // 2) Budget ladder.
  int droppedSummaryLines = 0;
  int droppedToolOutputs = 0;
  while (_estimateContextTokens(lines, recent) > config.tokenBudget) {
    // a. Oldest summary line goes first — it carries the least context.
    if (lines.isNotEmpty) {
      lines.removeAt(0);
      droppedSummaryLines++;
      continue;
    }
    // b. Recent tool envelopes degrade to their key fields (oldest first).
    final int toolIndex = recent.indexWhere(
      (ChatMessage m) => m.role == MessageRole.tool && m.toolPayload != null,
    );
    if (toolIndex >= 0) {
      final ChatMessage m = recent[toolIndex];
      recent[toolIndex] = ChatMessage(
        id: m.id,
        role: MessageRole.tool,
        content: compactToolResult(m.toolPayload!),
        timestamp: m.timestamp,
      );
      droppedToolOutputs++;
      continue;
    }
    // c. Last resort: drop the oldest recent turn. Turns dropped here are
    //    not summarized (the summary was built first); on subsequent calls
    //    they naturally slide into the older bucket and get digested then.
    if (recent.length > 1) {
      recent.removeAt(0);
      continue;
    }
    break; // nothing left to give up — return best effort
  }

  return CompactedContext(
    summary: _renderSummary(lines),
    recent: List<ChatMessage>.unmodifiable(recent),
    compactedCount: older.length,
    droppedSummaryLines: droppedSummaryLines,
    droppedToolOutputs: droppedToolOutputs,
    estimatedTokens: _estimateContextTokens(lines, recent),
  );
}

// ─── Wire assembly ────────────────────────────────────────────────────────

/// Assembles the OpenAI-compatible `messages` payload from the system
/// prompt, the compacted context and the live user message.
///
/// Contract:
/// - system prompt first;
/// - the summary turn (user role) right after it, when present;
/// - recent turns in chronological order, with tool results downgraded to
///   user turns (the [ToolPayload.toWireContent] envelope, or the degraded
///   digest text for budget-compacted payloads) — a standalone `tool` role
///   never reaches the wire;
/// - the live [userMessage] last, skipped when blank (tool-result
///   continuations pass an empty prompt because the tool turns already
///   carry it).
List<Map<String, String>> buildWireMessages({
  required String systemPrompt,
  required CompactedContext context,
  String userMessage = '',
}) {
  final List<Map<String, String>> wire = <Map<String, String>>[
    <String, String>{
      'role': MessageRole.system.wire,
      'content': systemPrompt,
    },
  ];

  if (context.hasSummary) {
    wire.add(<String, String>{
      'role': MessageRole.user.wire,
      'content': context.summary,
    });
  }

  for (final ChatMessage m in context.recent) {
    wire.add(<String, String>{
      'role':
          m.role == MessageRole.tool ? MessageRole.user.wire : m.role.wire,
      'content': _wireContentOf(m),
    });
  }

  if (userMessage.trim().isNotEmpty) {
    wire.add(<String, String>{
      'role': MessageRole.user.wire,
      'content': userMessage,
    });
  }

  return wire;
}

String _wireContentOf(ChatMessage m) => m.role == MessageRole.tool
    ? (m.toolPayload?.toWireContent() ?? m.content)
    : m.content;

// ─── Internals ────────────────────────────────────────────────────────────

int _estimateContextTokens(List<String> lines, List<ChatMessage> recent) {
  int total = lines.isEmpty ? 0 : estimateTokens(_renderSummary(lines));
  for (final ChatMessage m in recent) {
    total += estimateTokens(_wireContentOf(m));
  }
  return total;
}

String _renderSummary(List<String> lines) {
  if (lines.isEmpty) return '';
  final StringBuffer sb = StringBuffer(kContextSummaryHeader)
    ..writeln()
    ..write('以下是本次会话较早轮次的压缩记录（按时间先后排列，细节可能省略）：');
  for (final String line in lines) {
    sb
      ..writeln()
      ..write(line);
  }
  return sb.toString();
}
