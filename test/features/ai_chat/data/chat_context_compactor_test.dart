import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ai_chat/data/chat_context_compactor.dart';
import 'package:shell_mind/features/ai_chat/data/chat_repository_impl.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';

/// Unit tests for the chat context compaction policy.
///
/// Covers the five contract areas required by the feature spec:
///   1. short conversations are forwarded verbatim (no summary),
///   2. crossing the message threshold triggers a summary turn,
///   3. tool results collapse to the `执行了 <cmd>@<server> → 退出码 N` digest,
///   4. the token budget sheds weight oldest-first (summary lines → tool
///      envelopes → recent turns, never below one recent turn),
///   5. the summary lands in the wire format as a user turn right after the
///      system prompt, with tool roles downgraded to user.
void main() {
  // ─── Helpers ────────────────────────────────────────────────────────────

  ChatMessage user(String id, String content) =>
      ChatMessage.user(id: id, content: content);

  ChatMessage assistant(String id, String content) => ChatMessage(
        id: id,
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime(2024),
      );

  ChatMessage toolMsg(
    String id, {
    String command = 'cmd',
    String serverName = 'srv-1',
    String stdout = '',
    String stderr = '',
    int exitCode = 0,
  }) =>
      ChatMessage.toolResult(
        id: id,
        payload: ToolPayload(
          toolType: 'ssh_exec',
          command: command,
          serverId: 'srv',
          serverName: serverName,
          stdout: stdout,
          stderr: stderr,
          exitCode: exitCode,
          elapsed: const Duration(milliseconds: 10),
        ),
      );

  /// Builds `count` alternating user/assistant turns.
  List<ChatMessage> alternatingTurns(int count) => <ChatMessage>[
        for (int i = 0; i < count; i++)
          if (i.isEven)
            user('u$i', 'turn $i')
          else
            assistant('a$i', 'turn $i'),
      ];

  group('estimateTokens', () {
    test('empty text costs nothing', () {
      expect(estimateTokens(''), 0);
    });

    test('ASCII text averages 4 characters per token (rounded up)', () {
      expect(estimateTokens('hello world'), 3); // 11 chars * 0.25 = 2.75
      expect(estimateTokens('abc'), 1); // 0.75 -> ceil
    });

    test('CJK text costs one token per character', () {
      expect(estimateTokens('你好世界，世界'), 7); // fullwidth comma counts too
    });

    test('mixed text is priced per character class', () {
      expect(estimateTokens('hi 你好'), 3); // 2 CJK + 3 other * 0.25 = 2.75
    });
  });

  group('compactToolResult', () {
    test('renders the key-field one-liner', () {
      expect(
        compactToolResult(
          ToolPayload(
            toolType: 'ssh_exec',
            command: 'systemctl status nginx',
            serverId: 'srv',
            serverName: 'web-1',
            stdout: 'a lot of output that must not appear',
            stderr: '',
            exitCode: 0,
            elapsed: Duration.zero,
          ),
        ),
        '执行了 systemctl status nginx@web-1 → 退出码 0',
      );
    });

    test('falls back to serverId when serverName is blank', () {
      final String line = compactToolResult(
        ToolPayload(
          toolType: 'ssh_exec',
          command: 'ls',
          serverId: 'srv-9',
          serverName: '  ',
          stdout: '',
          stderr: '',
          exitCode: 2,
          elapsed: Duration.zero,
        ),
      );
      expect(line, '执行了 ls@srv-9 → 退出码 2');
    });

    test('uses a placeholder server when both name and id are blank', () {
      final String line = compactToolResult(
        ToolPayload(
          toolType: 'ssh_exec',
          command: 'ls',
          serverId: '',
          serverName: '',
          stdout: '',
          stderr: '',
          exitCode: 0,
          elapsed: Duration.zero,
        ),
      );
      expect(line, '执行了 ls@- → 退出码 0');
    });
  });

  group('compactMessageForSummary', () {
    test('user turns become 用户-prefixed lines', () {
      expect(compactMessageForSummary(user('u', 'hi there')), '用户: hi there');
    });

    test('assistant turns become 助手-prefixed lines', () {
      expect(
        compactMessageForSummary(assistant('a', 'hello back')),
        '助手: hello back',
      );
    });

    test('tool turns with a payload collapse to the key-field digest', () {
      final ChatMessage m = toolMsg('t', command: 'df -h', serverName: 'db-1');
      expect(
        compactMessageForSummary(m),
        '执行了 df -h@db-1 → 退出码 0',
      );
    });

    test('system turns carry nothing into the summary', () {
      final ChatMessage m = ChatMessage(
        id: 's',
        role: MessageRole.system,
        content: 'system noise',
        timestamp: DateTime(2024),
      );
      expect(compactMessageForSummary(m), '');
    });

    test('newlines flatten to spaces and long lines clip with an ellipsis',
        () {
      final String line =
          compactMessageForSummary(user('u', '${'a' * 300}\n${'b' * 50}'));
      // '用户: ' prefix (4 chars) + 200 clipped chars + '…'.
      expect(line.length, 205);
      expect(line, startsWith('用户: '));
      expect(line, endsWith('…'));
      expect(line, isNot(contains('\n')));
    });
  });

  group('compactChatHistory — short conversations', () {
    test('no summary when history fits the recent window', () {
      final List<ChatMessage> history = alternatingTurns(5);
      final CompactedContext c = compactChatHistory(history);

      expect(c.hasSummary, isFalse, reason: 'nothing to compact');
      expect(c.summary, '');
      expect(c.compactedCount, 0);
      expect(c.droppedSummaryLines, 0);
      expect(c.droppedToolOutputs, 0);
      expect(c.recent.length, 5);
      expect(c.recent.map((ChatMessage m) => m.content),
          history.map((ChatMessage m) => m.content));
      expect(c.estimatedTokens, lessThanOrEqualTo(kDefaultTokenBudget));
    });

    test('system and blank messages never enter the context', () {
      final List<ChatMessage> history = <ChatMessage>[
        ChatMessage(
          id: 's',
          role: MessageRole.system,
          content: 'system noise',
          timestamp: DateTime(2024),
        ),
        user('u0', '   '),
        user('u1', 'real question'),
        assistant('a1', 'real answer'),
      ];
      final CompactedContext c = compactChatHistory(history);

      expect(c.hasSummary, isFalse);
      expect(c.recent.length, 2);
      expect(c.recent[0].content, 'real question');
      expect(c.recent[1].content, 'real answer');
    });
  });

  group('compactChatHistory — over the message threshold', () {
    test('older turns fold into a summary, recent window is preserved', () {
      final List<ChatMessage> history = alternatingTurns(25);
      final CompactedContext c = compactChatHistory(history);

      // 25 turns -> 5 oldest compacted, 20 kept verbatim.
      expect(c.compactedCount, 5);
      expect(c.hasSummary, isTrue);
      expect(c.recent.length, kMaxHistoryMessages,
          reason: 'kMaxHistoryMessages keeps its keep-recent semantics');
      expect(c.recent.first.content, 'turn 5');
      expect(c.recent.last.content, 'turn 24');

      // Summary carries the oldest five turns as digest lines.
      expect(c.summary, startsWith(kContextSummaryHeader));
      expect(c.summary, contains('用户: turn 0'));
      expect(c.summary, contains('助手: turn 1'));
      expect(c.summary, contains('用户: turn 4'));
      expect(c.summary, isNot(contains('turn 5')));

      // Nothing was shed by the budget for this size.
      expect(c.droppedSummaryLines, 0);
      expect(c.droppedToolOutputs, 0);
    });

    test('tool results inside the summarized range become digests', () {
      final List<ChatMessage> history = <ChatMessage>[
        toolMsg('t0',
            command: 'systemctl status nginx',
            serverName: 'web-1',
            stdout: 'active (running) since boot'),
        user('u1', 'and now?'),
        assistant('a1', 'done'),
      ];
      // Force the three turns into the summarized bucket.
      final CompactedContext c = compactChatHistory(
        history,
        config: const CompactionConfig(keepRecentMessages: 0),
      );

      expect(c.compactedCount, 3);
      expect(c.summary, contains('执行了 systemctl status nginx@web-1 → 退出码 0'));
      expect(c.summary, contains('用户: and now?'));
      expect(c.summary, contains('助手: done'));
      // The heavy stdout must not leak into the summary.
      expect(c.summary, isNot(contains('active (running)')));
      expect(c.recent, isEmpty);
    });
  });

  group('compactChatHistory — token budget', () {
    test('summary lines are shed oldest-first before touching recent turns',
        () {
      // 25 tiny turns, an absurdly small budget: all 5 summary digest lines
      // are dropped, the 20 recent turns survive untouched.
      final List<ChatMessage> history = alternatingTurns(25);
      final CompactedContext c = compactChatHistory(
        history,
        config: const CompactionConfig(tokenBudget: 50),
      );

      expect(c.droppedSummaryLines, 5, reason: 'oldest lines go first');
      expect(c.hasSummary, isFalse, reason: 'every digest line was shed');
      expect(c.droppedToolOutputs, 0);
      expect(c.recent.length, 20);
      expect(c.estimatedTokens, lessThanOrEqualTo(50));
    });

    test('recent tool envelopes degrade to key-field digests', () {
      final List<ChatMessage> history = <ChatMessage>[
        for (int i = 0; i < 3; i++)
          toolMsg('t$i', command: 'cmd', serverName: 'srv-1', stdout: 'o' * 400),
      ];
      final CompactedContext c = compactChatHistory(
        history,
        config: const CompactionConfig(
          keepRecentMessages: 3,
          tokenBudget: 200,
        ),
      );

      // ~120 tokens per full envelope: 360 > 200 -> the two oldest degrade,
      // the newest survives (140 estimated tokens total).
      expect(c.droppedToolOutputs, 2);
      expect(c.recent[0].content, '执行了 cmd@srv-1 → 退出码 0');
      expect(c.recent[0].toolPayload, isNull,
          reason: 'degraded turns drop the payload so the wire uses the digest');
      expect(c.recent[2].content, contains('[tool-output]'),
          reason: 'the newest tool result keeps its full envelope');
      expect(c.recent[2].content, contains('o' * 400));
      expect(c.estimatedTokens, lessThanOrEqualTo(200));
    });

    test('budget floor always keeps at least one recent turn', () {
      final List<ChatMessage> history = <ChatMessage>[
        user('u0', '好' * 1000),
        user('u1', '好' * 1000),
        user('u2', '好' * 1000),
      ];
      final CompactedContext c = compactChatHistory(
        history,
        config: const CompactionConfig(
          keepRecentMessages: 3,
          tokenBudget: 500,
        ),
      );

      // Even the best effort (one 1000-token turn) exceeds the budget, but
      // the last turn must never be dropped.
      expect(c.recent.length, 1);
      expect(c.recent.single.content, '好' * 1000);
      expect(c.hasSummary, isFalse);
    });
  });

  group('buildWireMessages — wire format', () {
    test('summary lands as a user turn right after the system prompt', () {
      final CompactedContext c = compactChatHistory(
        alternatingTurns(25),
        config: const CompactionConfig(keepRecentMessages: 4),
      );
      final List<Map<String, String>> wire = buildWireMessages(
        systemPrompt: 'SYS',
        context: c,
        userMessage: 'live question',
      );

      expect(wire, hasLength(1 + 1 + 4 + 1));
      expect(wire[0]['role'], 'system');
      expect(wire[0]['content'], 'SYS');
      expect(wire[1]['role'], 'user', reason: 'summary travels as a user turn');
      expect(wire[1]['content'], c.summary);
      expect(wire[1]['content'], startsWith(kContextSummaryHeader));
      expect(wire[2]['role'], 'assistant');
      expect(wire[2]['content'], 'turn 21');
      expect(wire.last['role'], 'user');
      expect(wire.last['content'], 'live question');
    });

    test('no summary and no live message when the conversation is short', () {
      final CompactedContext c =
          compactChatHistory(alternatingTurns(2));
      final List<Map<String, String>> wire =
          buildWireMessages(systemPrompt: 'SYS', context: c);

      expect(wire, hasLength(3));
      expect(wire[0]['role'], 'system');
      expect(
        wire.map((Map<String, String> m) => m['role']),
        <String>['system', 'user', 'assistant'],
      );
    });

    test('tool results travel as user turns with the full envelope', () {
      final ToolPayload payload = ToolPayload(
        toolType: 'ssh_exec',
        command: 'uptime',
        serverId: 'srv',
        serverName: 'web-1',
        stdout: 'up 5 days',
        stderr: '',
        exitCode: 0,
        elapsed: Duration.zero,
      );
      final CompactedContext c = compactChatHistory(
        <ChatMessage>[
          toolMsg('t0',
              command: 'uptime', serverName: 'web-1', stdout: 'up 5 days'),
        ],
      );
      final List<Map<String, String>> wire =
          buildWireMessages(systemPrompt: 'SYS', context: c);

      expect(wire, hasLength(2));
      expect(wire[1]['role'], 'user',
          reason: 'standalone tool role never reaches the wire');
      expect(wire[1]['content'], payload.toWireContent());
      expect(wire[1]['content'], contains('up 5 days'));
    });

    test('degraded tool results carry their digest text, not the envelope',
        () {
      final CompactedContext c = compactChatHistory(
        <ChatMessage>[
          for (int i = 0; i < 2; i++)
            toolMsg('t$i', command: 'cmd', serverName: 'srv-1', stdout: 'o' * 400),
        ],
        config: const CompactionConfig(
          keepRecentMessages: 2,
          tokenBudget: 150,
        ),
      );
      final List<Map<String, String>> wire =
          buildWireMessages(systemPrompt: 'SYS', context: c);

      expect(wire, hasLength(3));
      expect(wire[1]['role'], 'user');
      expect(wire[1]['content'], '执行了 cmd@srv-1 → 退出码 0',
          reason: 'budget-degraded turn forwards the digest line');
      expect(wire[2]['content'], contains('[tool-output]'));
    });

    test('blank live user messages are skipped (tool-result continuations)',
        () {
      final CompactedContext c =
          compactChatHistory(<ChatMessage>[user('u0', 'hi')]);
      final List<Map<String, String>> wire = buildWireMessages(
        systemPrompt: 'SYS',
        context: c,
        userMessage: '   ',
      );

      expect(wire, hasLength(2));
      expect(wire.last['content'], 'hi');
    });
  });
}
