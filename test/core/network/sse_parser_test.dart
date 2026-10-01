import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/network/sse_parser.dart';

void main() {
  group('SseParser.parse', () {
    test('parses standard SSE data frame', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: {"content":"hello"}\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['{"content":"hello"}']);
    });

    test('parses multiple frames', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: first\n\ndata: second\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['first', 'second']);
    });

    test('handles [DONE] termination signal', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: content\n\ndata: [DONE]\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['content']);
    });

    test('[DONE] with extra whitespace still terminates', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: hi\n\ndata:  [DONE] \n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['hi']);
    });

    test('handles multi-line data fields', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: line1\ndata: line2\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['line1\nline2']);
    });

    test('handles data split across chunks', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      // Simulate partial data arriving in separate chunks
      controller.add(utf8.encode('data: hel'));
      controller.add(utf8.encode('lo\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['hello']);
    });

    test('ignores SSE comments (lines starting with :)', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode(': this is a comment\ndata: payload\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['payload']);
    });

    test('ignores event, id, retry fields', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(
        utf8.encode('event: message\nid: 123\nretry: 5000\ndata: value\n\n'),
      );
      await controller.close();

      final result = await events;
      expect(result, ['value']);
    });

    test('ignores malformed lines without colon', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('garbage\ndata: good\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['good']);
    });

    test('handles empty lines without preceding data (no emission)', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('\n\n\ndata: after\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['after']);
    });

    test('flushes trailing frame without final blank line', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: trailing'));
      await controller.close();

      final result = await events;
      expect(result, ['trailing']);
    });

    test('handles UTF-8 multibyte characters', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data: 你好世界🌍\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['你好世界🌍']);
    });

    test('handles malformed UTF-8 gracefully (allowMalformed)', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      // Send invalid UTF-8 bytes followed by valid frame
      controller.add([0xFF, 0xFE]); // invalid bytes
      controller.add(utf8.encode('\ndata: ok\n\n'));
      await controller.close();

      final result = await events;
      expect(result, contains('ok'));
    });

    test('data value trims single leading space per spec', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data:  two spaces\n\n'));
      await controller.close();

      final result = await events;
      // Only the first space after colon is trimmed
      expect(result, [' two spaces']);
    });

    test('data value without space after colon', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();

      controller.add(utf8.encode('data:nospace\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['nospace']);
    });

    test('empty stream produces no events', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(controller.stream).toList();
      await controller.close();

      final result = await events;
      expect(result, isEmpty);
    });

    test('custom doneMarkerValue', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parse(
        controller.stream,
        doneMarkerValue: '[END]',
      ).toList();

      controller.add(utf8.encode('data: msg\n\ndata: [END]\n\n'));
      await controller.close();

      final result = await events;
      expect(result, ['msg']);
    });
  });

  group('SseParser.parseJson', () {
    test('parses JSON payloads from SSE stream', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parseJson(controller.stream).toList();

      controller.add(utf8.encode(
        'data: {"choices":[{"delta":{"content":"hi"}}]}\n\n'
        'data: [DONE]\n\n',
      ));
      await controller.close();

      final result = await events;
      expect(result.length, 1);
      expect(result[0]['choices'], isA<List>());
    });

    test('silently drops non-JSON payloads', () async {
      final controller = StreamController<List<int>>();
      final events = SseParser.parseJson(controller.stream).toList();

      controller.add(utf8.encode(
        'data: not-json\n\ndata: {"valid":true}\n\n',
      ));
      await controller.close();

      final result = await events;
      expect(result.length, 1);
      expect(result[0]['valid'], isTrue);
    });
  });

  group('SseParser.tryJsonDecode', () {
    test('decodes valid JSON', () {
      expect(SseParser.tryJsonDecode('{"a":1}'), {'a': 1});
    });

    test('returns null for invalid JSON', () {
      expect(SseParser.tryJsonDecode('not json'), isNull);
    });

    test('returns null for empty string', () {
      expect(SseParser.tryJsonDecode(''), isNull);
    });

    test('decodes JSON arrays', () {
      expect(SseParser.tryJsonDecode('[1,2,3]'), [1, 2, 3]);
    });
  });

  group('SseStreamX extension', () {
    test('sseEvents getter works', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('data: ext\n\n'),
      ]);
      final result = await stream.sseEvents.toList();
      expect(result, ['ext']);
    });

    test('sseJsonEvents getter works', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('data: {"k":"v"}\n\n'),
      ]);
      final result = await stream.sseJsonEvents.toList();
      expect(result.length, 1);
      expect(result[0]['k'], 'v');
    });
  });
}
