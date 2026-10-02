import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';

void main() {
  group('MessageRole', () {
    test('has expected values', () {
      expect(MessageRole.values.length, 4);
      expect(MessageRole.system.index, 0);
      expect(MessageRole.user.index, 1);
      expect(MessageRole.assistant.index, 2);
      expect(MessageRole.tool.index, 3);
    });

    test('wire returns name', () {
      expect(MessageRole.system.wire, 'system');
      expect(MessageRole.user.wire, 'user');
      expect(MessageRole.assistant.wire, 'assistant');
      expect(MessageRole.tool.wire, 'tool');
    });

    test('fromWire parses correctly', () {
      expect(MessageRole.fromWire('system'), MessageRole.system);
      expect(MessageRole.fromWire('user'), MessageRole.user);
      expect(MessageRole.fromWire('assistant'), MessageRole.assistant);
      expect(MessageRole.fromWire('tool'), MessageRole.tool);
    });

    test('fromWire falls back to user for unknown', () {
      expect(MessageRole.fromWire('unknown'), MessageRole.user);
      expect(MessageRole.fromWire(''), MessageRole.user);
    });
  });

  group('ChatMessage construction', () {
    test('basic constructor sets all fields', () {
      final ts = DateTime(2024, 6, 1);
      final msg = ChatMessage(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: ts,
      );
      expect(msg.id, 'msg-1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
      expect(msg.timestamp, ts);
      expect(msg.isStreaming, isFalse);
      expect(msg.error, isFalse);
    });

    test('user factory creates user message', () {
      final msg = ChatMessage.user(id: 'u1', content: 'Hi there');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hi there');
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
      expect(msg.isSystem, isFalse);
      expect(msg.isStreaming, isFalse);
    });

    test('user factory accepts explicit timestamp', () {
      final ts = DateTime(2024, 1, 15);
      final msg = ChatMessage.user(id: 'u2', content: 'test', timestamp: ts);
      expect(msg.timestamp, ts);
    });

    test('assistantStreaming factory creates streaming message', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1');
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, '');
      expect(msg.isStreaming, isTrue);
      expect(msg.isAssistant, isTrue);
    });

    test('assistantStreaming factory accepts initial content', () {
      final msg = ChatMessage.assistantStreaming(id: 'a2', content: 'partial');
      expect(msg.content, 'partial');
      expect(msg.isStreaming, isTrue);
    });
  });

  group('ChatMessage.append', () {
    test('appends content', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1', content: 'Hello');
      final appended = msg.append(' World');
      expect(appended.content, 'Hello World');
      expect(appended.isStreaming, isTrue); // streaming flag preserved
      expect(appended.id, 'a1');
    });

    test('append to empty content', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1');
      final appended = msg.append('token');
      expect(appended.content, 'token');
    });

    test('append does not mutate original', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1', content: 'original');
      final appended = msg.append(' extra');
      expect(msg.content, 'original');
      expect(appended.content, 'original extra');
    });

    test('multiple appends accumulate', () {
      var msg = ChatMessage.assistantStreaming(id: 'a1');
      msg = msg.append('one');
      msg = msg.append(' two');
      msg = msg.append(' three');
      expect(msg.content, 'one two three');
    });
  });

  group('ChatMessage.finish', () {
    test('sets isStreaming to false', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1', content: 'done');
      final finished = msg.finish();
      expect(finished.isStreaming, isFalse);
      expect(finished.content, 'done');
      expect(finished.id, 'a1');
    });

    test('finish on non-streaming message is no-op', () {
      final msg = ChatMessage.user(id: 'u1', content: 'hi');
      final finished = msg.finish();
      expect(finished.isStreaming, isFalse);
      expect(finished, equals(msg));
    });
  });

  group('ChatMessage.copyWith', () {
    test('copies without changes', () {
      final msg = ChatMessage.user(id: 'u1', content: 'hello');
      expect(msg.copyWith(), equals(msg));
    });

    test('overrides content', () {
      final msg = ChatMessage.user(id: 'u1', content: 'old');
      final copy = msg.copyWith(content: 'new');
      expect(copy.content, 'new');
      expect(copy.id, 'u1');
    });

    test('overrides role', () {
      final msg = ChatMessage.user(id: 'u1', content: 'hi');
      final copy = msg.copyWith(role: MessageRole.assistant);
      expect(copy.role, MessageRole.assistant);
    });

    test('overrides error flag', () {
      final msg = ChatMessage.user(id: 'u1', content: 'hi');
      final copy = msg.copyWith(error: true);
      expect(copy.error, isTrue);
    });

    test('overrides isStreaming', () {
      final msg = ChatMessage.assistantStreaming(id: 'a1');
      final copy = msg.copyWith(isStreaming: false);
      expect(copy.isStreaming, isFalse);
    });
  });

  group('ChatMessage JSON serialization', () {
    test('toJson produces correct map', () {
      final ts = DateTime(2024, 3, 15, 10, 30);
      final msg = ChatMessage(
        id: 'msg-json',
        role: MessageRole.assistant,
        content: 'Response text',
        timestamp: ts,
        isStreaming: false,
        error: false,
      );

      final json = msg.toJson();
      expect(json['id'], 'msg-json');
      expect(json['role'], 'assistant');
      expect(json['content'], 'Response text');
      expect(json['timestamp'], ts.toIso8601String());
      expect(json['isStreaming'], isFalse);
      expect(json['error'], isFalse);
    });

    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 'parsed-1',
        'role': 'user',
        'content': 'Parsed content',
        'timestamp': '2024-06-01T12:00:00.000',
        'isStreaming': false,
        'error': false,
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 'parsed-1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Parsed content');
      expect(msg.timestamp, DateTime(2024, 6, 1, 12));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final msg = ChatMessage.fromJson(json);
      expect(msg.id, '');
      expect(msg.role, MessageRole.user);
      expect(msg.content, '');
      expect(msg.isStreaming, isFalse);
      expect(msg.error, isFalse);
    });

    test('roundtrip serialization preserves data', () {
      final original = ChatMessage(
        id: 'round-trip',
        role: MessageRole.assistant,
        content: 'Hello world',
        timestamp: DateTime(2024, 1, 1),
        isStreaming: true,
        error: true,
      );

      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.timestamp, original.timestamp);
      expect(restored.isStreaming, original.isStreaming);
      expect(restored.error, original.error);
    });
  });

  group('ChatMessage equality', () {
    test('identical messages are equal', () {
      final ts = DateTime(2024, 1, 1);
      final a = ChatMessage(id: '1', role: MessageRole.user, content: 'hi', timestamp: ts);
      final b = ChatMessage(id: '1', role: MessageRole.user, content: 'hi', timestamp: ts);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different content makes messages unequal', () {
      final ts = DateTime(2024, 1, 1);
      final a = ChatMessage(id: '1', role: MessageRole.user, content: 'hi', timestamp: ts);
      final b = ChatMessage(id: '1', role: MessageRole.user, content: 'bye', timestamp: ts);
      expect(a, isNot(equals(b)));
    });

    test('different streaming flag makes messages unequal', () {
      final ts = DateTime(2024, 1, 1);
      final a = ChatMessage(id: '1', role: MessageRole.user, content: 'hi', timestamp: ts, isStreaming: false);
      final b = ChatMessage(id: '1', role: MessageRole.user, content: 'hi', timestamp: ts, isStreaming: true);
      expect(a, isNot(equals(b)));
    });
  });

  group('ChatMessage.toString', () {
    test('includes role and content length', () {
      final msg = ChatMessage.user(id: 'u1', content: 'hello world');
      final str = msg.toString();
      expect(str, contains('user'));
      expect(str, contains('11 chars'));
    });
  });
}
