import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/result.dart';

/// Abstracts device biometric authentication (fingerprint/face) so the
/// app-lock feature can be unit tested without a real platform channel.
///
/// The implementation wraps [LocalAuthentication] and never throws: every
/// failure mode (no hardware, nothing enrolled, lockout, channel error) is
/// surfaced as a `Failure(AppFailure)` inside the project [Result] union.
abstract class BiometricAuthService {
  /// Whether the device can perform a biometric check right now (hardware
  /// present and at least one biometric enrolled).
  Future<Result<bool>> canCheckBiometrics();

  /// Runs one authentication round-trip. Returns `Success(true)` only when
  /// the user is verified; the device credential (PIN/pattern/password) is
  /// accepted as a fallback because `AuthenticationOptions.biometricOnly`
  /// is disabled.
  Future<Result<bool>> authenticate({
    String localizedReason = 'Unlock ShellMind',
  });
}

/// Maps `local_auth` platform errors onto the project [AppFailure] taxonomy:
///
/// - `not_available` / `not_enrolled` / `passcode_not_set` / `no_hardware` /
///   `no_fragment_activity` → [FailureKind.validation] (the device cannot
///   verify at all right now — the lock screen fails open on these to avoid
///   a permanent lockout).
/// - `locked_out` / `permanently_locked_out` → [FailureKind.auth] (retry
///   later or fall back to the device credential).
/// - Anything else → [FailureKind.unexpected].
AppFailure mapBiometricError(Object error, StackTrace stackTrace) {
  if (error is PlatformException) {
    switch (error.code) {
      case 'not_available':
      case 'not_enrolled':
      case 'passcode_not_set':
      case 'no_hardware':
      case 'no_fragment_activity':
        return AppFailure.validation(
          'Biometrics unavailable (${error.code}).',
          details: <String, dynamic>{'platformCode': error.code},
        );
      case 'locked_out':
      case 'permanently_locked_out':
        return AppFailure.auth(
          message: 'Biometric locked out (${error.code}).',
          cause: error,
        );
    }
  }
  return AppFailure.unexpected(error, stackTrace: stackTrace);
}

/// [local_auth]-backed implementation of [BiometricAuthService].
class LocalAuthBiometricService implements BiometricAuthService {
  LocalAuthBiometricService({LocalAuthentication? localAuthentication})
      : _localAuth = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<Result<bool>> canCheckBiometrics() async {
    try {
      final bool enrolled = await _localAuth.canCheckBiometrics;
      final bool supported = await _localAuth.isDeviceSupported();
      return Result<bool>.success(enrolled && supported);
    } catch (e, st) {
      return Result<bool>.failure(mapBiometricError(e, st));
    }
  }

  @override
  Future<Result<bool>> authenticate({
    String localizedReason = 'Unlock ShellMind',
  }) async {
    try {
      final bool verified = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return Result<bool>.success(verified);
    } catch (e, st) {
      return Result<bool>.failure(mapBiometricError(e, st));
    }
  }
}

/// Riverpod provider for the singleton service.
final Provider<BiometricAuthService> biometricAuthServiceProvider =
    Provider<BiometricAuthService>((ref) => LocalAuthBiometricService());
