import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/sse_parser.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/ai_provider.dart';

/// Exception carrying a structured [AppFailure] so callers (repository,
/// providers) can branch on failure kind without string parsing.
class AiServiceException implements Exception {
  const AiServiceException(this.failure);
  final AppFailure failure;

  @override
  String toString() => 'AiServiceException(${failure.message})';
}

/// Transport layer for any OpenAI-compatible Chat Completions provider.
///
/// All built-in providers ([AiProviders]) — OpenAI, DeepSeek, Qwen, GLM, MiMo
/// — speak the same protocol, so a single service drives them. The concrete
/// provider, credential, model and temperature are injected at construction
/// time (resolved by the Riverpod layer from storage/preferences), keeping
/// this class a pure, easily testable transport.
///
/// Responsibilities are deliberately narrow: build the request payload, POST
/// it to `{baseUrl}/chat/completions`, and turn the SSE byte stream into
/// content deltas. Prompt assembly and history policy live in the repository.
class AiService {
  AiService({
    required this.client,
    required this.provider,
    required this.apiKey,
    required this.model,
    required this.temperature,
  });

  final DioClient client;
  final AiProvider provider;
  final String apiKey;
  final String model;
  final double temperature;

  /// True when a usable credential is present.
  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// Full endpoint: provider base URL (trailing slash stripped) + chat path.
  String get _endpoint {
    String base = provider.baseUrl.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base${AppConstants.aiChatCompletionsPath}';
  }

  /// Builds the shared request body. [stream] toggles the SSE mode.
  Map<String, dynamic> _payload(
    List<Map<String, String>> messages, {
    required bool stream,
  }) =>
      <String, dynamic>{
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'stream': stream,
      };

  Options _authOptions({Duration? receiveTimeout}) => Options(
        headers: <String, dynamic>{'Authorization': 'Bearer ${apiKey.trim()}'},
        receiveTimeout: receiveTimeout,
      );

  AiServiceException _missingKey() => AiServiceException(
        AppFailure.auth(message: '${provider.name} API key is not configured.'),
      );

  // ─── Streaming ────────────────────────────────────────────────────────

  /// Streams assistant content deltas for [messages].
  ///
  /// Emits only the `choices[0].delta.content` fragments; the caller
  /// concatenates them. Errors are surfaced as [AiServiceException] on the
  /// stream (or thrown synchronously before it opens, e.g. missing key).
  Stream<String> chatStream(
    List<Map<String, String>> messages, {
    CancelToken? cancelToken,
  }) async* {
    if (!hasApiKey) throw _missingKey();

    Response<ResponseBody> response;
    try {
      response = await client.postStream(
        _endpoint,
        data: _payload(messages, stream: true),
        cancelToken: cancelToken,
        options: _authOptions(),
      );
    } on DioException catch (e) {
      throw AiServiceException(_mapDioError(e));
    }

    final ResponseBody? body = response.data;
    if (body == null) {
      throw AiServiceException(
        AppFailure.aiProvider('Empty response body from provider.'),
      );
    }

    // SSE frames arrive as `data: {json}` lines; parse them into deltas.
    await for (final Map<String, dynamic> event in body.stream.sseJsonEvents) {
      // Some gateways emit an error object mid-stream.
      final Object? error = event['error'];
      if (error is Map<String, dynamic>) {
        throw AiServiceException(
          AppFailure.aiProvider(
            (error['message'] as String?) ?? 'Provider returned an error.',
          ),
        );
      }

      final String? delta = _extractDelta(event);
      if (delta != null && delta.isNotEmpty) {
        yield delta;
      }
    }
  }

  /// Pulls the incremental text out of one Chat Completions chunk.
  String? _extractDelta(Map<String, dynamic> event) {
    final Object? choices = event['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final Object? first = choices.first;
    if (first is! Map) return null;

    final Object? delta = first['delta'];
    if (delta is Map) {
      final Object? content = delta['content'];
      if (content is String) return content;
    }
    // Non-streaming fallback shape (`message.content`) — harmless to support.
    final Object? message = first['message'];
    if (message is Map && message['content'] is String) {
      return message['content'] as String;
    }
    return null;
  }

  // ─── Non-streaming (backup) ─────────────────────────────────────────────

  /// Requests a single, complete completion. Throws [AiServiceException] on
  /// failure so the repository can wrap it in a [Result].
  Future<String> chat(
    List<Map<String, String>> messages, {
    CancelToken? cancelToken,
  }) async {
    if (!hasApiKey) throw _missingKey();

    try {
      final Response<dynamic> response = await client.post<dynamic>(
        _endpoint,
        data: _payload(messages, stream: false),
        cancelToken: cancelToken,
        options: _authOptions(receiveTimeout: AppConstants.chatRequestTimeout),
      );

      final Object? data = response.data;
      if (data is! Map) {
        throw AiServiceException(
          AppFailure.aiProvider('Malformed completion response.'),
        );
      }
      final String? text = _extractDelta(data.cast<String, dynamic>());
      return text ?? '';
    } on DioException catch (e) {
      throw AiServiceException(_mapDioError(e));
    }
  }

  // ─── Error mapping ────────────────────────────────────────────────────

  /// Converts a [DioException] into a user-facing [AppFailure] with a
  /// provider-aware message (rate limit, auth, server, network, timeout).
  AppFailure _mapDioError(DioException e) {
    // Cancellation is expected when the user hits "stop".
    if (e.type == DioExceptionType.cancel) {
      return AppFailure.cancelled(cause: e);
    }

    final Response<dynamic>? resp = e.response;
    if (resp != null) {
      final int status = resp.statusCode ?? 0;
      final String serverMessage = _extractApiErrorMessage(resp.data);

      switch (status) {
        case 401:
        case 403:
          return AppFailure.auth(
            message: serverMessage.isNotEmpty
                ? serverMessage
                : 'Invalid API key (HTTP $status).',
            cause: e,
          );
        case 429:
          return AppFailure.aiProvider(
            serverMessage.isNotEmpty
                ? serverMessage
                : 'Rate limit reached — slow down or check your quota.',
            statusCode: status,
            cause: e,
          );
        case 404:
          return AppFailure.notFound(
            message: serverMessage.isNotEmpty
                ? serverMessage
                : 'Model or endpoint not found (HTTP 404).',
            cause: e,
          );
        default:
          if (status >= 500) {
            return AppFailure.aiProvider(
              serverMessage.isNotEmpty
                  ? serverMessage
                  : 'Provider server error (HTTP $status).',
              statusCode: status,
              cause: e,
            );
          }
          return AppFailure.aiProvider(
            serverMessage.isNotEmpty
                ? serverMessage
                : 'Request failed (HTTP $status).',
            statusCode: status,
            cause: e,
          );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppFailure.timeout(
          AppConstants.chatRequestTimeout,
          cause: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return AppFailure.network(e, stackTrace: e.stackTrace);
    }
  }

  /// Best-effort extraction of `error.message` from an OpenAI-style error body.
  String _extractApiErrorMessage(Object? data) {
    if (data is Map) {
      final Object? err = data['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    if (data is String && data.trim().isNotEmpty) {
      final Object? decoded = SseParser.tryJsonDecode(data);
      if (decoded is Map) return _extractApiErrorMessage(decoded);
    }
    return '';
  }
}
