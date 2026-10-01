import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lightweight discriminated union for operations that can fail.
///
/// Prefer this over `try/catch` in repository/data layers so callers can
/// branch on success vs failure without exceptions escaping across
/// boundaries. UI layers typically pattern-match via [when] or the
/// `is Success`/`is Failure` type checks.
///
/// ```dart
/// final result = await repo.fetchServer(id);
/// return result.when(
///   success: (server) => ServerTile(server),
///   failure: (err) => ErrorBanner(err.message),
/// );
/// ```
@immutable
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success<T>(:final T value) => value,
        Failure<T>() => null,
      };

  /// Error when failed, otherwise `null`.
  Failure<T>? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>() => this as Failure<T>,
      };

  /// Value when successful, otherwise [fallback].
  T getOrElse(T fallback) => switch (this) {
        Success<T>(:final T value) => value,
        Failure<T>() => fallback,
      };

  /// Value when successful, otherwise invoke [orElse].
  T getOrElseWith(T Function(Failure<T> failure) orElse) => switch (this) {
        Success<T>(:final T value) => value,
        Failure<T>() => orElse(this as Failure<T>),
      };

  /// Throws the underlying error when failed, returns the value otherwise.
  T getOrThrow() => switch (this) {
        Success<T>(:final T value) => value,
        Failure<T>(:final AppFailure failure) => throw failure.toException(),
      };

  /// Structural match.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success<T>(value: final T v) => success(v),
      Failure<T>(failure: final AppFailure f) => failure(f),
    };
  }

  /// Structural match with a default for the failure branch.
  R maybeWhen<R>({
    required R Function(T value) success,
    R Function(AppFailure failure)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success<T>(value: final T v) => success(v),
      Failure<T>(failure: final AppFailure f) =>
        failure != null ? failure(f) : orElse(),
    };
  }

  /// Maps the success value.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final T value) =>
          Result<R>.success(transform(value)),
        Failure<T>(:final AppFailure failure) =>
          Result<R>.failure(failure),
      };

  /// Chains another [Result]-returning operation on success.
  Result<R> flatMap<R>(Result<R> Function(T value) next) => switch (this) {
        Success<T>(:final T value) => next(value),
        Failure<T>(:final AppFailure failure) =>
          Result<R>.failure(failure),
      };

  /// Wraps a synchronous/async call, converting thrown exceptions into a
  /// [Failure]. The optional [onError] hook lets callers map specific
  /// exception types to richer [AppFailure] values.
  static Future<Result<R>> guard<R>(
    FutureOr<R> Function() body, {
    AppFailure Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      return Result<R>.success(await body());
    } catch (e, st) {
      return Result<R>.failure(
        onError?.call(e, st) ?? AppFailure.unexpected(e, stackTrace: st),
      );
    }
  }

  /// Sync variant of [guard].
  static Result<R> guardSync<R>(
    R Function() body, {
    AppFailure Function(Object error, StackTrace stack)? onError,
  }) {
    try {
      return Result<R>.success(body());
    } catch (e, st) {
      return Result<R>.failure(
        onError?.call(e, st) ?? AppFailure.unexpected(e, stackTrace: st),
      );
    }
  }

  // Convenience named constructors.
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppFailure failure) = Failure<T>;
}

@immutable
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success<T>, value);

  @override
  String toString() => 'Success($value)';
}

@immutable
final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failure<T>, failure);

  @override
  String toString() => 'Failure($failure)';
}

// ─── Failure model ────────────────────────────────────────────────────────

/// Categorical taxonomy of failures the app can surface.
enum FailureKind {
  network,
  timeout,
  auth,
  notFound,
  validation,
  permission,
  ssh,
  aiProvider,
  storage,
  cancelled,
  unexpected,
}

/// Structured error info carried inside [Failure].
@immutable
class AppFailure {
  const AppFailure({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
    this.details = const <String, dynamic>{},
    this.recoverable = false,
  });

  final FailureKind kind;

  /// Human-readable, localisation-ready message. Should never leak stack
  /// traces or secrets.
  final String message;

  /// Provider/protocol-specific code (e.g. HTTP status, SSH disconnect code).
  final int? code;

  /// Underlying error, kept for logging only.
  final Object? cause;
  final StackTrace? stackTrace;

  /// Free-form metadata useful for UI branching (e.g. `retryAfter`).
  final Map<String, dynamic> details;

  /// Whether a simple retry might succeed without user intervention.
  final bool recoverable;

  // ─── Named constructors for common cases ────────────────────────────────

  factory AppFailure.network(Object? cause, {StackTrace? stackTrace}) =>
      AppFailure(
        kind: FailureKind.network,
        message: 'Network unreachable.',
        cause: cause,
        stackTrace: stackTrace,
        recoverable: true,
      );

  factory AppFailure.timeout(
    Duration duration, {
    Object? cause,
    StackTrace? stackTrace,
  }) =>
      AppFailure(
        kind: FailureKind.timeout,
        message: 'Timed out after ${duration.inSeconds}s.',
        cause: cause,
        stackTrace: stackTrace,
        recoverable: true,
      );

  factory AppFailure.auth({String? message, Object? cause}) => AppFailure(
        kind: FailureKind.auth,
        message: message ?? 'Authentication failed.',
        cause: cause,
      );

  factory AppFailure.notFound({String? message, Object? cause}) => AppFailure(
        kind: FailureKind.notFound,
        message: message ?? 'Resource not found.',
        cause: cause,
      );

  factory AppFailure.validation(String message,
          {Map<String, dynamic> details = const <String, dynamic>{}}) =>
      AppFailure(
        kind: FailureKind.validation,
        message: message,
        details: details,
      );

  factory AppFailure.permission({String? message}) => AppFailure(
        kind: FailureKind.permission,
        message: message ?? 'Permission denied.',
      );

  factory AppFailure.ssh(String message,
          {int? code, Object? cause, StackTrace? stackTrace}) =>
      AppFailure(
        kind: FailureKind.ssh,
        message: message,
        code: code,
        cause: cause,
        stackTrace: stackTrace,
        recoverable: true,
      );

  factory AppFailure.aiProvider(String message,
          {int? statusCode, Object? cause}) =>
      AppFailure(
        kind: FailureKind.aiProvider,
        message: message,
        code: statusCode,
        cause: cause,
        recoverable: statusCode != null && statusCode >= 500,
      );

  factory AppFailure.storage(String message, {Object? cause}) => AppFailure(
        kind: FailureKind.storage,
        message: message,
        cause: cause,
      );

  factory AppFailure.cancelled({Object? cause}) => AppFailure(
        kind: FailureKind.cancelled,
        message: 'Operation cancelled.',
        cause: cause,
      );

  factory AppFailure.unexpected(Object? cause, {StackTrace? stackTrace}) =>
      AppFailure(
        kind: FailureKind.unexpected,
        message: 'Unexpected error.',
        cause: cause,
        stackTrace: stackTrace,
      );

  /// Converts this failure into a throwable exception. Used by
  /// [Result.getOrThrow] so callers can opt back into exception flow.
  Object toException() =>
      cause ?? AppFailureException(this);

  AppFailure copyWith({
    FailureKind? kind,
    String? message,
    int? code,
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
    bool? recoverable,
  }) =>
      AppFailure(
        kind: kind ?? this.kind,
        message: message ?? this.message,
        code: code ?? this.code,
        cause: cause ?? this.cause,
        stackTrace: stackTrace ?? this.stackTrace,
        details: details ?? this.details,
        recoverable: recoverable ?? this.recoverable,
      );

  @override
  bool operator ==(Object other) =>
      other is AppFailure &&
      other.kind == kind &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(kind, message, code);

  @override
  String toString() =>
      'AppFailure(${kind.name}, message: "$message", code: $code)';
}

/// Exception thrown by [Result.getOrThrow] when no original [Object] cause
/// is available.
class AppFailureException implements Exception {
  const AppFailureException(this.failure);
  final AppFailure failure;

  @override
  String toString() => 'AppFailureException: ${failure.message}';
}
