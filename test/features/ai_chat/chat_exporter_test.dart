import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ai_chat/domain/chat_exporter.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';

void main() {
  final DateTime t1 = DateTime(2026, 10, 3, 9, 30, 5);
  final DateTime t2 = DateTime(2026, 10, 3, 9, 30, 6);

  ToolPayload payload({
    String serverName = 'web-01',
    String command = 'systemctl status nginx',
    int exitCode = 0,
    String stdout = 'nginx is running',
    String stderr = '',
  }) =>
      ToolPayload(
        toolType: 'ssh_exec',
        command: command,
        serverId: 'srv-1',
        serverName: serverName,
        stdout: stdout,
        stderr: stderr,
        exitCode: exitCode,
        elapsed: const Duration(milliseconds: 120),
      );

  group('ChatExporter.export — header', () {
    test('writes title, timestamp and message count', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.user(id: 'u1', content: 'hi', timestamp: t1),
        ],
        exportedAt: t2,
      );
      expect(md, startsWith('# Shell-Mind 对话导出'));
      expect(md, contains('导出时间：2026-10-03 09:30:06'));
      expect(md, contains('消息数：1'));
    });

    test('empty conversation yields a valid header and no turns', () {
      final String md = ChatExporter.export(
        const <ChatMessage>[],
        exportedAt: t1,
      );
      expect(md, contains('消息数：0'));
      expect(md, isNot(contains('## 用户')));
      expect(md, isNot(contains('## 助手')));
      expect(md, isNot(contains('## 工具执行')));
    });
  });

  group('ChatExporter.export — user messages', () {
    test('renders as quoted section with timestamp', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.user(id: 'u1', content: '查看磁盘占用', timestamp: t1),
        ],
        exportedAt: t2,
      );
      expect(md, contains('## 用户 · 2026-10-03 09:30:05'));
      expect(md, contains('> 查看磁盘占用'));
    });

    test('multi-line user message quotes every line', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.user(id: 'u1', content: '第一行\n\n第三行', timestamp: t1),
        ],
        exportedAt: t2,
      );
      expect(md, contains('> 第一行\n>\n> 第三行'));
    });

    test('CRLF user message is quoted without stray \\r', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.user(id: 'u1', content: 'a\r\nb', timestamp: t1),
        ],
        exportedAt: t2,
      );
      expect(md, contains('> a\n> b'));
      expect(md, isNot(contains('\r')));
    });
  });

  group('ChatExporter.export — assistant messages', () {
    test('renders body verbatim (markdown preserved)', () {
      const String body = '使用 `df -h`：\n\n```bash\ndf -h\n```\n\n- 项目 **一**';
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage(
            id: 'a1',
            role: MessageRole.assistant,
            content: body,
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      expect(md, contains('## 助手 · 2026-10-03 09:30:05'));
      expect(md, contains(body));
    });

    test('empty assistant placeholder renders a placeholder note', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage(
            id: 'a1',
            role: MessageRole.assistant,
            content: '  ',
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      expect(md, contains('_(无内容)_'));
    });
  });

  group('ChatExporter.export — tool messages', () {
    test('renders server name, exit code, command and stdout', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.toolResult(id: 't1', payload: payload(), timestamp: t1),
        ],
        exportedAt: t2,
      );
      expect(
        md,
        contains('## 工具执行 · web-01 · 退出码 0 · 2026-10-03 09:30:05'),
      );
      expect(md, contains('**命令**'));
      expect(md, contains('```bash\nsystemctl status nginx\n```'));
      expect(md, contains('**输出**'));
      expect(md, contains('```text\nnginx is running\n```'));
      expect(md, isNot(contains('**错误输出**')));
    });

    test('renders stderr section only when non-empty', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.toolResult(
            id: 't1',
            payload: payload(
              exitCode: 2,
              stdout: '',
              stderr: 'permission denied',
            ),
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      expect(md, contains('退出码 2'));
      expect(md, isNot(contains('**输出**')));
      expect(md, contains('**错误输出**'));
      expect(md, contains('```text\npermission denied\n```'));
    });

    test('blank server name falls back to 未知服务器', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.toolResult(
            id: 't1',
            payload: payload(serverName: '  '),
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      expect(md, contains('## 工具执行 · 未知服务器'));
    });

    test('message without payload degrades to a text block', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage(
            id: 't1',
            role: MessageRole.tool,
            content: '[tool-output] legacy',
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      expect(md, contains('## 工具执行 · 2026-10-03 09:30:05'));
      expect(md, contains('```text\n[tool-output] legacy\n```'));
    });
  });

  group('ChatExporter.export — misc', () {
    test('system messages are skipped', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage(
            id: 's1',
            role: MessageRole.system,
            content: 'SECRET SYSTEM PROMPT',
            timestamp: t1,
          ),
          ChatMessage.user(id: 'u1', content: 'hi', timestamp: t2),
        ],
        exportedAt: t2,
      );
      expect(md, isNot(contains('SECRET SYSTEM PROMPT')));
      expect(md, contains('消息数：2')); // Header counts the raw list.
      expect(md, contains('## 用户'));
    });

    test('content containing triple backticks cannot break the fence', () {
      const String tricky = '```toml\n[agent]\n```';
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.toolResult(
            id: 't1',
            payload: payload(stdout: tricky),
            timestamp: t1,
          ),
        ],
        exportedAt: t2,
      );
      // The inner run is 3 backticks → the fence grows to 4. A trailing
      // blank line follows the fence, so trim before checking the closer.
      expect(md, contains('````text'));
      expect(md.trimRight(), endsWith('````'));
    });

    test('full conversation keeps chronological order', () {
      final String md = ChatExporter.export(
        <ChatMessage>[
          ChatMessage.user(id: 'u1', content: 'q1', timestamp: t1),
          ChatMessage(
            id: 'a1',
            role: MessageRole.assistant,
            content: 'ans1',
            timestamp: t2,
          ),
          ChatMessage.user(id: 'u2', content: 'q2', timestamp: t2),
        ],
        exportedAt: t2,
      );
      final int iQ1 = md.indexOf('> q1');
      final int iA1 = md.indexOf('ans1');
      final int iQ2 = md.indexOf('> q2');
      expect(iQ1, greaterThanOrEqualTo(0));
      expect(iQ1, lessThan(iA1));
      expect(iA1, lessThan(iQ2));
    });
  });

  group('ChatExporter.fileStamp', () {
    test('formats yyyyMMdd-HHmmss', () {
      expect(ChatExporter.fileStamp(DateTime(2026, 1, 3, 7, 8, 9)),
          '20260103-070809');
    });
  });
}
