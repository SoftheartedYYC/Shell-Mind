import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import 'ssh_reconnect_policy.dart';

/// Lifecycle of the auto-reconnect machinery for one server.
enum SshReconnectStatus {
  /// No reconnect activity.
  idle,

  /// Backoff delays and dial attempts are being driven automatically.
  reconnecting,

  /// All attempts were exhausted (or a fatal credential error was hit).
  gaveUp,
}

/// Per-server reconnect progress published by [SshReconnectCoordinator].
///
/// [SshReconnectStatus.gaveUp] is a sticky terminal state: it survives until
/// the user retries manually or the registry entry disappears entirely.
/// Equality is value-based so Riverpod/UI only rebuild on transitions.
@immutable
class SshReconnectState {
  const SshReconnectState({
    required this.status,
    this.attempt = 0,
    this.maxAttempts,
    this.lastError,
    this.failureKind,
  });

  /// Initial state: no reconnect activity for this server.
  const SshReconnectState.idle() : this(status: SshReconnectStatus.idle);

  /// Waiting for the backoff delay before dialing [attempt] (1-based).
  const SshReconnectState.waiting({
    required this.attempt,
    this.maxAttempts,
    this.lastError,
    this.failureKind,
  }) : status = SshReconnectStatus.reconnecting;

  /// A dial attempt is currently in flight.
  const SshReconnectState.dialing({
    required this.attempt,
    this.maxAttempts,
    this.lastError,
    this.failureKind,
  }) : status = SshReconnectStatus.reconnecting;

  /// All attempts exhausted (or a non-retryable failure was reported).
  const SshReconnectState.gaveUp({
    required this.lastError,
    this.maxAttempts,
    this.failureKind,
  })  : status = SshReconnectStatus.gaveUp,
        attempt = 0;

  final SshReconnectStatus status;

  /// Upcoming / just-failed 1-based attempt number while reconnecting.
  final int attempt;

  /// Cap the current loop was started with (`null` = unlimited).
  final int? maxAttempts;

  /// Message of the last failed dial, for tooltips and debug surfaces.
  final String? lastError;

  /// [FailureKind] name of the last failure, for colour-coding.
  final String? failureKind;

  bool get isReconnecting => status == SshReconnectStatus.reconnecting;
  bool get hasGivenUp => status == SshReconnectStatus.gaveUp;

  SshReconnectState copyWith({
    SshReconnectStatus? status,
    int? attempt,
    int? maxAttempts,
    String? lastError,
    String? failureKind,
  }) {
    return SshReconnectState(
      status: status ?? this.status,
      attempt: attempt ?? this.attempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastError: lastError ?? this.lastError,
      failureKind: failureKind ?? this.failureKind,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SshReconnectState &&
          other.status == status &&
          other.attempt == attempt &&
          other.maxAttempts == maxAttempts &&
          other.lastError == lastError &&
          other.failureKind == failureKind;

  @override
  int get hashCode =>
      Object.hash(status, attempt, maxAttempts, lastError, failureKind);

  @override
  String toString() =>
      'SshReconnectState(${status.name}, attempt: $attempt, '
      'lastError: $lastError)';
}

/// Callback that performs one connection attempt. Injectable so tests can
/// stub dials without touching the real registry / secure storage.
typedef SshReconnectDialer = Future<Result<void>> Function(
  ServerConfig config, {
  String? password,
  String? privateKey,
  String? passphrase,
});

/// Callback that resolves stored credentials for [serverId]. Injectable for
/// the same reason as [SshReconnectDialer].
typedef SshCredentialResolver = Future<
    ({
      String? password,
      String? privateKey,
      String? passphrase,
    })> Function(String serverId, AuthType authType);

/// Drives the exponential-backoff reconnect loop for a single server.
///
/// One coordinator instance per [serverId]; the [SshSessionRegistry] creates
/// one when a session drops unexpectedly and cancels it on manual
/// disconnect / successful reconnect / registry teardown.
///
/// The loop:
/// 1. waits for the policy's backoff delay,
/// 2. resolves fresh credentials from secure storage,
/// 3. dials through the injected [dialer],
/// 4. on success calls [onSuccess]; on failure re-evaluates the policy and
///    either schedules the next attempt or transitions to [gaveUp] and calls
///    [onGiveUp].
class SshReconnectCoordinator {
  SshReconnectCoordinator({
    required this.serverId,
    required this.config,
    required this.policy,
    required this.publish,
    required this.resolveCredentials,
    required this.dialer,
    this.onSuccess,
    this.onGiveUp,
  })  : _state = const SshReconnectState.idle();

  final String serverId;
  final ServerConfig config;
  final SshReconnectPolicy policy;

  /// Publishes progress so the UI can show "重连第 N 次".
  final void Function(SshReconnectState state) publish;

  final SshCredentialResolver resolveCredentials;
  final SshReconnectDialer dialer;

  /// Invoked after a successful dial (before the loop ends).
  final void Function()? onSuccess;

  /// Invoked once when the loop gives up.
  final void Function(SshReconnectState finalState)? onGiveUp;

  SshReconnectState _state;
  Timer? _timer;
  bool _cancelled = false;
  int _nextAttempt = 1;
  bool _gaveUp = false;

  /// Latest published snapshot.
  SshReconnectState get state => _state;

  bool get isCancelled => _cancelled;
  bool get hasGivenUp => _gaveUp;

  /// Kicks off the loop with the first scheduled attempt.
  void start() {
    if (_cancelled || _gaveUp) return;
    _scheduleNext();
  }

  /// Stops the loop and clears any pending timer. Idempotent.
  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Manually retries after [gaveUp]: resets counters and restarts the loop.
  /// Returns `false` when the coordinator is still active or was cancelled.
  bool retryManually() {
    if (_cancelled || !_gaveUp) return false;
    _gaveUp = false;
    _nextAttempt = 1;
    _publish(const SshReconnectState.idle());
    _scheduleNext();
    return true;
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  void _scheduleNext() {
    if (_cancelled || _gaveUp) return;

    final int attempt = _nextAttempt;
    final ReconnectDecision decision = policy.nextAttempt(attempt);
    if (!decision.shouldRetry) {
      _giveUp(
        lastError: _state.lastError ?? 'Connection lost.',
        failureKind: _state.failureKind,
      );
      return;
    }

    _publish(SshReconnectState.waiting(
      attempt: attempt,
      maxAttempts: policy.maxAttempts > 0 ? policy.maxAttempts : null,
      lastError: _state.lastError,
      failureKind: _state.failureKind,
    ));

    final Duration delay = decision.delay!;
    _timer = Timer(delay, () {
      _timer = null;
      unawaited(_dial(attempt));
    });
  }

  Future<void> _dial(int attempt) async {
    if (_cancelled || _gaveUp) return;

    _publish(SshReconnectState.dialing(
      attempt: attempt,
      maxAttempts: policy.maxAttempts > 0 ? policy.maxAttempts : null,
      lastError: _state.lastError,
      failureKind: _state.failureKind,
    ));

    final ({String? password, String? privateKey, String? passphrase}) creds =
        await resolveCredentials(serverId, config.authType);

    if (_cancelled || _gaveUp) return;

    final Result<void> result = await guardDial(() => dialer(
          config,
          password: creds.password,
          privateKey: creds.privateKey,
          passphrase: creds.passphrase,
        ));

    if (_cancelled || _gaveUp) return;

    final AppFailure? failure = result.failureOrNull?.failure;
    if (failure == null) {
      // Success — reset attempt bookkeeping before notifying.
      _nextAttempt = 1;
      _publish(const SshReconnectState.idle());
      onSuccess?.call();
      return;
    }

    _state = SshReconnectState(
      status: SshReconnectStatus.reconnecting,
      attempt: attempt,
      lastError: failure.message,
      failureKind: failure.kind.name,
    );

    // Non-retryable failures (auth / validation) end the loop immediately.
    if (!_isRetryable(failure)) {
      _giveUp(lastError: failure.message, failureKind: failure.kind.name);
      return;
    }

    _nextAttempt = attempt + 1;
    _scheduleNext();
  }

  void _giveUp({
    required String lastError,
    String? failureKind,
  }) {
    if (_gaveUp || _cancelled) return;
    _gaveUp = true;
    _timer?.cancel();
    _timer = null;
    final SshReconnectState finalState = SshReconnectState.gaveUp(
      lastError: lastError,
      maxAttempts: policy.maxAttempts > 0 ? policy.maxAttempts : null,
      failureKind: failureKind,
    );
    _publish(finalState);
    onGiveUp?.call(finalState);
  }

  void _publish(SshReconnectState next) {
    if (_cancelled) return;
    _state = next;
    publish(next);
  }

  /// Auth and validation failures will not fix themselves on retry — give up
  /// immediately instead of burning through the backoff schedule.
  static bool _isRetryable(AppFailure failure) =>
      failure.kind != FailureKind.auth && failure.kind != FailureKind.validation;
}
