import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Application-wide [Dio] configuration.
///
/// A single Dio instance is exposed through [dioProvider]; feature layers
/// build on top of it (adding auth headers, SSE handling, etc.) rather than
/// instantiating their own clients.
class DioClient {
  DioClient._(this._dio);

  factory DioClient.createDefault() => DioClient._(_buildDefaultDio());

  final Dio _dio;
  Dio get dio => _dio;

  // ─── Convenience passthroughs ───────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

  /// Streaming POST for Server-Sent Events. Callers consume
  /// `response.data` as a `Stream<List<int>>`.
  Future<Response<ResponseBody>> postStream(
    String path, {
    required Object data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _dio.post<ResponseBody>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          responseType: ResponseType.stream,
          // SSE endpoints can stay open indefinitely — don't let Dio's
          // receive timeout kill the stream.
          receiveTimeout: const Duration(seconds: 0),
          headers: <String, dynamic>{
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            ...?options?.headers,
          },
        ),
      );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  static Dio _buildDefaultDio() {
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.httpConnectTimeout,
        receiveTimeout: AppConstants.httpReceiveTimeout,
        sendTimeout: AppConstants.httpSendTimeout,
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': AppConstants.userAgent,
        },
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      _TimingInterceptor(),
      if (AppConstants.debugNetwork) _LoggingInterceptor(),
    ]);

    return dio;
  }
}

// ─── Interceptors ─────────────────────────────────────────────────────────

/// Adds an `X-Request-Id` and reports latency to console when debug is on.
class _TimingInterceptor extends Interceptor {
  static const String _kStart = '__shellmind_start__';
  int _counter = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_kStart] = DateTime.now().microsecondsSinceEpoch;
    options.headers['X-Request-Id'] =
        'sm-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _logDuration(response.requestOptions, ok: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logDuration(err.requestOptions, ok: false);
    handler.next(err);
  }

  void _logDuration(RequestOptions options, {required bool ok}) {
    if (!AppConstants.debugNetwork) return;
    final dynamic start = options.extra[_kStart];
    if (start is! int) return;
    final int ms =
        (DateTime.now().microsecondsSinceEpoch - start) ~/ Duration.microsecondsPerMillisecond;
    // ignore: avoid_print
    print('[dio] ${ok ? 'ok' : 'err'} ${options.method} ${options.uri} '
        '· ${ms}ms');
  }
}

/// Full request/response logging — only wired up when debugNetwork is true.
class _LoggingInterceptor extends LogInterceptor {
  _LoggingInterceptor()
      : super(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (Object? o) {
            // ignore: avoid_print
            print('[dio] $o');
          },
        );
}

/// Exposes the app-wide [Dio] instance.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final DioClient client = DioClient.createDefault();
  ref.onDispose(client.dio.close);
  return client.dio;
});

/// Exposes the wrapper for callers that need the streaming helpers.
final Provider<DioClient> dioClientProvider = Provider<DioClient>((ref) {
  final Dio dio = ref.watch(dioProvider);
  return DioClient._(dio);
});
