import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/sse_parser.dart';
import '../../../core/storage/preferences_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/result.dart';

/// Exception carrying a structured [AppFailure] so callers (repository,
/// providers) can branch on failure kind without string parsing.
class AiServiceException implements Exception {
  const AiServiceException(this.failure);
  final AppFailure failure;

  @override
  String toString() => 'AiServiceException(${failure.message})';
}

/// Transport layer for the OpenAI Chat Completions API.
///
/// Responsibilities are deliberately narrow: read the API key + model
/// preferences, build the request payload, and turn the SSE byte stream into
/// content deltas. Prompt assembly and history policy live in the repository.
class OpenAiService {
  OpenAiService({
    required this.client,
    required this.secureStorage,
    required this.preferences,
  });

  final DioClient client;
  final SecureStorageService secureStorage;
  final PreferencesService preferences;

  /// Resolves the base URL — a user-supplied override wins over the default,
  /// enabling OpenAI-compatible gateways (Azure proxies, local relays, etc.).
  Future<String> _resolveBaseUrl() async {
    final String? custom = await secureStorage.getApiBaseUrl();
    final String base =
        (custom != null && custom.trim().isNotEmpty) ? custom.trim() : AppConstants.openAiBaseUrl;
    // Strip a trailing slash so path concatenation is predictable.
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Future<String?> _apiKey() => secureStorage.getApiKey();

  /// Builds the shared request body. [stream] toggles the SSE mode.
  Map<String, dynamic> _payload(
    List<Map<String, String>> messages, {
    required bool stream,
  }) =>
      <String, dynamic>{
        'model': preferences.aiModel,
        'messages': messages,
        'temperature': preferences.aiTemperature,
        'stream': stream,
      };

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
    final String? key = await _apiKey();
    if (key == null || key.trim().isEmpty) {
      throw AiServiceException(
        AppFailure.auth(message: 'OpenAI API key is not configured.'),
      );
    }

    final String url = '${await _resolveBaseUrl()}${AppConstants.openAiChatPath}';

    Response<ResponseBody> response;
    try {
      response = await client.postStream(
        url,
        data: _payload(messages, stream: true),
        cancelToken: cancelToken,
        options: Options(headers: <String, dynamic>{
          'Authorization': 'Bearer $key',
        }),
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
    await for (final Map<String, dynamic> event
        in body.stream.sseJsonEvents) {
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
    final String? key = await _apiKey();
    if (key == null || key.trim().isEmpty) {
      throw AiServiceException(
        AppFailure.auth(message: 'OpenAI API key is not configured.'),
      );
    }

    final String url = '${await _resolveBaseUrl()}${AppConstants.openAiChatPath}';

    try {
      final Response<dynamic> response = await client.post<dynamic>(
        url,
        data: _payload(messages, stream: false),
        cancelToken: cancelToken,
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Bearer $key'},
          receiveTimeout: AppConstants.chatRequestTimeout,
        ),
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

  /// Best-effort extraction of `error.message` from an OpenAI error body.
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
