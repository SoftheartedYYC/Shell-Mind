import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/shared/ssh/command_block_parser.dart';

void main() {
  group('CommandBlockParser', () {
    test('parse single bash block', () {
      const String input = '''
Here is a command:
```bash
echo "hello"
```
Done.
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(1));
      expect(blocks.single.command, 'echo "hello"');
      expect(blocks.single.language, 'bash');
      expect(blocks.single.targetServer, isNull);
      expect(blocks.single.blockIndex, 0);
    });

    test('parse multiple blocks with different languages', () {
      const String input = '''
```bash
ls -la
```
Some text
```shell
pwd
```
```sh
whoami
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(3));
      expect(blocks[0].command, 'ls -la');
      expect(blocks[0].language, 'bash');
      expect(blocks[0].blockIndex, 0);
      expect(blocks[1].command, 'pwd');
      expect(blocks[1].language, 'shell');
      expect(blocks[1].blockIndex, 1);
      expect(blocks[2].command, 'whoami');
      expect(blocks[2].language, 'sh');
      expect(blocks[2].blockIndex, 2);
    });

    test('parse server tag', () {
      const String input = '''
```bash
# server: prod-web-01
uptime
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(1));
      expect(blocks.single.targetServer, 'prod-web-01');
      // The tag line is stripped from the command body.
      expect(blocks.single.command, 'uptime');
      expect(blocks.single.command.contains('server:'), isFalse);
    });

    test('ignore non-executable languages', () {
      const String input = '''
```python
print("hi")
```
```json
{"a": 1}
```
```
no language
```
```dart
void main() {}
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, isEmpty);
      expect(CommandBlockParser.hasExecutableBlocks(input), isFalse);
    });

    test('parse unclosed fence (streaming)', () {
      const String input = '''
```bash
echo "streaming"
df -h
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(1));
      expect(blocks.single.command, 'echo "streaming"\ndf -h');
      expect(blocks.single.language, 'bash');
    });

    test('skip empty command blocks', () {
      const String input = '''
```bash
```
```shell
   
```
```bash
real-command
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      // Only the block with actual content survives; indices are compacted.
      expect(blocks, hasLength(1));
      expect(blocks.single.command, 'real-command');
      expect(blocks.single.blockIndex, 0);
    });

    test('skip block that only contains a server tag', () {
      const String input = '''
```bash
# server: lone-tag
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, isEmpty);
    });

    test('case insensitive language tags', () {
      const String input = '''
```BASH
echo upper
```
```Shell
echo mixed
```
```SH
echo lower
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(3));
      expect(blocks[0].command, 'echo upper');
      expect(blocks[1].command, 'echo mixed');
      expect(blocks[2].command, 'echo lower');
      // Language is normalised to lower case.
      expect(blocks[0].language, 'bash');
      expect(blocks[1].language, 'shell');
      expect(blocks[2].language, 'sh');
    });

    test('case insensitive server keyword', () {
      const String input = '''
```bash
# SERVER: Upper-Keyword
command-a
```
```bash
# Server:  spaced-name
command-b
```
''';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(2));
      expect(blocks[0].targetServer, 'Upper-Keyword');
      expect(blocks[0].command, 'command-a');
      expect(blocks[1].targetServer, 'spaced-name');
      expect(blocks[1].command, 'command-b');
    });

    test('handles CRLF line endings', () {
      const String input = '```bash\r\necho hi\r\n```';

      final List<CommandBlock> blocks = CommandBlockParser.parse(input);

      expect(blocks, hasLength(1));
      expect(blocks.single.command, 'echo hi');
    });

    test('hasExecutableBlocks true for executable content', () {
      const String input = '''
```bash
ls
```
''';
      expect(CommandBlockParser.hasExecutableBlocks(input), isTrue);
    });
  });
}
