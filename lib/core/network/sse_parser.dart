import 'dart:async';
import 'dart:convert';

/// Streaming parser for Server-Sent Events (SSE).
///
/// SSE frames look like:
///
/// ```
/// event: message
/// data: {"content":"hi"}
///
/// data: [DONE]
/// ```
///
/// Each frame is separated by a blank line; each field is a `name: value`
/// line. OpenAI-compatible providers emit `data:` frames only, and terminate
/// the stream with the sentinel `[DONE]`.
///
/// This parser accepts a raw byte stream (as returned by Dio's
/// `ResponseType.stream`) and produces the payload of each `data:` line as
/// a [String]. Multi-line `data:` payloads within one frame are joined with
/// `\n` per the SSE spec. The `[DONE]` sentinel closes the stream instead of
/// being emitted downstream.
class SseParser {
  const SseParser._();

  /// Sentinel used by OpenAI and most compatible providers.
  static const String doneMarker = '[DONE]';

  /// Decodes [bytes] (typically a `ResponseBody.stream`) into a
  /// `Stream<String>` of `data:` payloads, ending on `[DONE]` or upstream
  /// close.
  ///
  /// Any non-UTF-8 bytes are replaced rather than throwing — LLM providers
  /// occasionally emit malformed trailing bytes on cancel.
  static Stream<String> parse(
    Stream<List<int>> bytes, {
    String doneMarkerValue = doneMarker,
  }) async* {
    const Utf8Decoder decoder = Utf8Decoder(allowMalformed: true);
    // `bytes` is statically a `Stream<List<int>>` but Dio's
    // `ResponseBody.stream` is a `Stream<Uint8List>` at runtime. Calling
    // `.transform(decoder)` directly reifies the transformer's input type as
    // `Uint8List`, and since `Utf8Decoder` is only a
    // `StreamTransformer<List<int>, String>` (generics are invariant here) it
    // throws `type 'Utf8Decoder' is not a subtype of type
    // 'StreamTransformer<Uint8List, String>'` — surfacing to the user as an
    // "Unexpected error". `cast<List<int>>()` normalises the runtime element
    // type while keeping the single stateful decoder, so multi-byte UTF-8
    // sequences split across chunks still decode correctly.
    final Stream<String> lines = bytes
        .cast<List<int>>()
        .transform(decoder)
        .transform(const LineSplitter());

    // Buffers multi-line `data:` fields belonging to the current frame.
    final List<String> dataLines = <String>[];

    await for (final String raw in lines) {
      // A blank line marks the end of a frame — flush it.
      if (raw.isEmpty) {
        if (dataLines.isEmpty) continue;
        final String payload = dataLines.join('\n');
        dataLines.clear();

        if (payload == doneMarkerValue ||
            payload.trim() == doneMarkerValue) {
          return;
        }
        yield payload;
        continue;
      }

      // Lines beginning with ':' are SSE comments — drop them.
      if (raw.startsWith(':')) continue;

      final int colon = raw.indexOf(':');
      if (colon < 0) {
        // Malformed line: treat whole line as field with empty value.
        // The spec says to ignore, but keeping it makes debugging easier.
        continue;
      }

      final String field = raw.substring(0, colon);
      // Trim a single leading space from the value (per spec).
      String value = raw.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case 'data':
          dataLines.add(value);
        case 'event':
        case 'id':
        case 'retry':
          // Ignored — this parser only surfaces `data:` payloads.
          break;
        default:
          // Unknown field — ignore per SSE spec.
          break;
      }
    }

    // Stream ended without an explicit [DONE]: flush any trailing frame.
    if (dataLines.isNotEmpty) {
      final String payload = dataLines.join('\n');
      if (payload != doneMarkerValue && payload.trim() != doneMarkerValue) {
        yield payload;
      }
    }
  }

  /// Parses each SSE `data:` payload as JSON and yields the resulting
  /// `Map<String, dynamic>`. Non-JSON payloads are silently dropped.
  static Stream<Map<String, dynamic>> parseJson(
    Stream<List<int>> bytes, {
    String doneMarkerValue = doneMarker,
  }) async* {
    await for (final String payload
        in parse(bytes, doneMarkerValue: doneMarkerValue)) {
      final Object? decoded = tryJsonDecode(payload);
      if (decoded is Map<String, dynamic>) yield decoded;
    }
  }

  /// Non-throwing JSON decode — returns `null` on parse error.
  static Object? tryJsonDecode(String source) {
    if (source.isEmpty) return null;
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }
}

/// Extension sugar: `stream.sseEvents` reads nicer than
/// `SseParser.parse(stream)` inside feature code.
extension SseStreamX on Stream<List<int>> {
  Stream<String> get sseEvents => SseParser.parse(this);
  Stream<Map<String, dynamic>> get sseJsonEvents => SseParser.parseJson(this);
}
