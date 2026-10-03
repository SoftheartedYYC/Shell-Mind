import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/utils/result.dart';

/// Outcome of a single reconnect policy evaluation.
///
/// The coordinator polls [SshReconnectPolicy.nextAttempt] after every failed
/// dial: [wait] schedules the next try, [giveUp] ends the loop.
enum ReconnectDecisionKind { wait, giveUp }

@immutable
class ReconnectDecision {
  const ReconnectDecision.wait(this.delay, this.attemptNumber)
      : kind = ReconnectDecisionKind.wait;

  const ReconnectDecision.giveUp()
      : kind = ReconnectDecisionKind.giveUp,
        delay = null,
        attemptNumber = null;

  final ReconnectDecisionKind kind;

  /// Backoff delay before the next dial (populated for [wait]).
  final Duration? delay;

  /// 1-based attempt number the delay applies to.
  final int? attemptNumber;

  bool get shouldRetry => kind == ReconnectDecisionKind.wait;
}

/// Pure scheduling policy for SSH reconnect attempts.
///
/// Holds the knob values captured when a reconnect loop starts so a settings
/// change mid-loop does not silently alter an in-flight schedule — the next
/// drop picks up the new values. The schedule is exponential:
/// 2s → 4s → 8s → 16s → 30s (capped), with attempt `1` being the first
/// automatic retry after the drop.
@immutable
class SshReconnectPolicy {
  const SshReconnectPolicy({
    this.maxAttempts = AppConstants.kDefaultSshReconnectMaxAttempts,
    this.baseDelay = AppConstants.sshReconnectBaseDelay,
    this.maxDelay = AppConstants.sshReconnectMaxDelay,
  })  : assert(maxAttempts >= 0),
        assert(baseDelay > Duration.zero),
        assert(maxDelay >= baseDelay);

  /// Builds the policy from the persisted user preferences. Exposed for the
  /// registry so tests can override [preferencesServiceProvider] instead of
  /// touching real [SharedPreferences].
  factory SshReconnectPolicy.fromPreferences(PreferencesService prefs) {
    return SshReconnectPolicy(
      maxAttempts: prefs.sshReconnectMaxAttempts,
    );
  }

  /// Maximum automatic attempts per dropped session; `0` retries forever.
  final int maxAttempts;

  final Duration baseDelay;

  final Duration maxDelay;

  /// Exponential backoff for [attempt] (1-based): base × 2^(n−1), capped.
  Duration delayFor(int attempt) {
    if (attempt <= 1) return baseDelay;
    final int exponent = attempt - 1;
    // Guard against overflow for absurd attempt numbers.
    final Duration raw = exponent > 16
        ? maxDelay
        : baseDelay * (1 << exponent);
    return raw > maxDelay ? maxDelay : raw;
  }

  /// Evaluates the schedule for [attempt] (1-based, the upcoming one).
  ///
  /// [giveUp] only when the cap is set (non-zero) and [attempt] exceeds it.
  ReconnectDecision nextAttempt(int attempt) {
    if (maxAttempts > 0 && attempt > maxAttempts) {
      return const ReconnectDecision.giveUp();
    }
    return ReconnectDecision.wait(delayFor(attempt), attempt);
  }

  /// The attempt number scheduled after the failed [attempt].
  int nextAttemptNumber(int attempt) => attempt + 1;

  @override
  String toString() => 'SshReconnectPolicy(maxAttempts: $maxAttempts)';
}

/// Mirrors `AppConstants.kDefaultSshReconnectMaxAttempts` bounds in the
/// settings UI. Kept here so the settings widget does not import the
/// constants file for scalars it already gets via [PreferencesService].
const int kSshReconnectAttemptsStep = 1;

/// Riverpod Notifier holding the live "SSH 断线自动重连" toggle.
///
/// Reads the persisted value on first build and writes back on change.
/// The registry reads this synchronously when a drop occurs; toggling it
/// affects drops that happen afterwards.
class SshAutoReconnectNotifier extends Notifier<bool> {
  @override
  bool build() {
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    return prefs.sshAutoReconnect;
  }

  Future<void> setAutoReconnect(bool value) async {
    state = value;
    await ref.read(preferencesServiceProvider).setSshAutoReconnect(value);
  }
}

final NotifierProvider<SshAutoReconnectNotifier, bool>
    sshAutoReconnectProvider =
    NotifierProvider<SshAutoReconnectNotifier, bool>(
  SshAutoReconnectNotifier.new,
);

/// Riverpod Notifier for the configurable maximum reconnect attempts
/// (`0` = unlimited, UI-labelled).
class SshReconnectMaxAttemptsNotifier extends Notifier<int> {
  @override
  int build() {
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    return prefs.sshReconnectMaxAttempts;
  }

  Future<void> setMaxAttempts(int value) async {
    final int clamped = value.clamp(
      0,
      AppConstants.kMaxSshReconnectMaxAttempts,
    );
    state = clamped;
    await ref
        .read(preferencesServiceProvider)
        .setSshReconnectMaxAttempts(clamped);
  }
}

final NotifierProvider<SshReconnectMaxAttemptsNotifier, int>
    sshReconnectMaxAttemptsProvider =
    NotifierProvider<SshReconnectMaxAttemptsNotifier, int>(
  SshReconnectMaxAttemptsNotifier.new,
);

/// Convenience helper: current policy for a fresh reconnect loop, assembled
/// from the user's persisted preferences.
SshReconnectPolicy currentReconnectPolicy(PreferencesService prefs) =>
    SshReconnectPolicy.fromPreferences(prefs);

/// Small guard used by the coordinator loop: converts a thrown dial failure
/// into a [Failure] result (the dialer already returns [Result], this covers
/// programming errors escaping into the schedule).
Future<Result<void>> guardDial(Future<Result<void>> Function() dial) async {
  try {
    return await dial();
  } catch (error, stack) {
    return Result<void>.failure(
      AppFailure.unexpected(error, stackTrace: stack),
    );
  }
}
