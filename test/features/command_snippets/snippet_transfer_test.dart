import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/command_snippets/domain/entities/command_snippet.dart';
import 'package:shell_mind/features/command_snippets/domain/snippet_transfer.dart';

void main() {
  group('SnippetTransfer', () {
    test('round-trips snippets with names and timestamps', () {
      final CommandSnippet a = CommandSnippet(
        id: 'a',
        command: 'df -h',
        name: 'Disk usage',
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      );
      final CommandSnippet b = CommandSnippet(
        id: 'b',
        command: 'uptime',
        name: null,
        createdAt: DateTime(2026, 1, 2, 3, 4, 6),
      );

      final String json = SnippetTransfer.encode(<CommandSnippet>[a, b]);
      final List<CommandSnippet> decoded = SnippetTransfer.decode(json);

      expect(decoded, hasLength(2));
      expect(decoded[0].command, 'df -h');
      expect(decoded[0].name, 'Disk usage');
      expect(decoded[1].command, 'uptime');
      expect(decoded[1].name, isNull);
    });

    test('re-issues fresh ids on import to avoid collisions', () {
      final CommandSnippet a = CommandSnippet(
        id: 'a',
        command: 'ls',
        createdAt: DateTime(2026),
      );
      final List<CommandSnippet> decoded =
          SnippetTransfer.decode(SnippetTransfer.encode(<CommandSnippet>[a]));
      expect(decoded.single.id, isNot('a'));
      expect(decoded.single.id, isNotEmpty);
    });

    test('skips malformed items without failing the import', () {
      const String json = '''
      {"format": "shellmind-command-snippets", "version": 1,
       "items": [ {"command": "ok"}, {"command": ""}, "garbage", 7 ]}
      ''';
      final List<CommandSnippet> decoded = SnippetTransfer.decode(json);
      expect(decoded, hasLength(1));
      expect(decoded.single.command, 'ok');
    });

    test('rejects foreign documents', () {
      expect(
        () => SnippetTransfer.decode('{"format": "other"}'),
        throwsFormatException,
      );
      expect(
        () => SnippetTransfer.decode('not json'),
        throwsFormatException,
      );
    });
  });
}
