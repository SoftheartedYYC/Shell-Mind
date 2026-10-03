import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/biometric_auth_service.dart';
import '../core/storage/preferences_service.dart';
import '../core/utils/result.dart';
import '../l10n/app_localizations.dart';

/// Outcome of the settings-toggle round-trip (`AuthLockController.setEnabled`).
enum AuthLockToggleResult {
  /// The new state was persisted and applied.
  applied,

  /// The device cannot verify right now (no hardware / nothing enrolled).
  unavailable,

  /// The verification round-trip did not pass (user cancel / reject).
  failed,
}

/// Drives the biometric app-lock: whether the lock is active, whether the
/// unlock attempt just failed, and the auto-verification round-trip.
///
/// Lifecycle wiring lives in [ShellMindApp] (see `app.dart`): `hidden`/
/// `inactive` mark the session as needing verification, `resumed` triggers
/// the actual biometric prompt.
class AuthLockController extends Notifier<AuthLockState> {
  /// Guards against double biometric prompts: while a verification
  /// round-trip is in flight, the system auth UI itself sends the app
  /// through inactive/hidden/resumed transitions, which must not re-trigger
  /// another prompt.
  bool _verifying = false;

  @override
  AuthLockState build() {
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    // An enabled lock covers cold start too: the overlay is shown until the
    // user passes verification (or the round-trip auto-fires on `resumed`).
    return AuthLockState(
      enabled: prefs.authLockEnabled,
      needsVerification: prefs.authLockEnabled,
    );
  }

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);
  BiometricAuthService get _bio => ref.read(biometricAuthServiceProvider);

  /// Whether the app is currently showing the lock screen.
  bool get isLocked => state.needsVerification;

  /// Marks the session as needing verification (app hidden/inactive) and
  /// immediately starts one verification attempt when the app is resumed.
  Future<void> onAppLifecycleChanged(AppLifecycleState lifecycle) async {
    if (_verifying) return;
    switch (lifecycle) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Behind the biometric prompt itself the app also passes through
        // inactive — only flag when the lock is actually enabled.
        if (state.enabled) {
          state = state.copyWith(
            needsVerification: true,
            lastAttemptFailed: false,
          );
        }
      case AppLifecycleState.resumed:
        if (!state.enabled || !state.needsVerification) return;
        await _verify();
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
        break;
    }
  }

  /// Enables/disables the lock from the settings toggle.
  ///
  /// Enabling runs a verification round-trip first — the lock must never be
  /// turned on by someone who cannot pass it.
  Future<AuthLockToggleResult> setEnabled(bool value) async {
    if (value == state.enabled) return AuthLockToggleResult.applied;

    if (!value) {
      state = state.copyWith(enabled: false, needsVerification: false);
      await _prefs.setAuthLockEnabled(false);
      return AuthLockToggleResult.applied;
    }

    final Result<bool> capability = await _bio.canCheckBiometrics();
    final bool canCheck = capability.getOrElse(false);
    if (!canCheck) return AuthLockToggleResult.unavailable;

    final Result<bool> verification = await _bio.authenticate();
    final bool verified = verification.getOrElse(false);
    if (!verified) return AuthLockToggleResult.failed;

    state = state.copyWith(
      enabled: true,
      needsVerification: false,
      lastAttemptFailed: false,
    );
    await _prefs.setAuthLockEnabled(true);
    return AuthLockToggleResult.applied;
  }

  /// Manual re-verification from the lock screen button. Returns the result
  /// so the UI can show the failure hint.
  Future<bool> unlock() async {
    await _verify();
    return !state.lastAttemptFailed;
  }

  Future<void> _verify() async {
    if (_verifying) return;
    _verifying = true;
    try {
      final Result<bool> verification = await _bio.authenticate();
      final bool verified = verification.getOrElse(false);
      if (verified) {
        state = state.copyWith(
          needsVerification: false,
          lastAttemptFailed: false,
        );
      } else {
        state = state.copyWith(lastAttemptFailed: true);
      }
    } finally {
      _verifying = false;
    }
  }
}

/// Immutable UI state for the app-lock feature.
class AuthLockState {
  const AuthLockState({
    required this.enabled,
    this.needsVerification = false,
    this.lastAttemptFailed = false,
  });

  /// The lock is turned on in settings (persisted).
  final bool enabled;

  /// The lock screen must be shown right now.
  final bool needsVerification;

  /// The last verification attempt failed (drives the failure hint).
  final bool lastAttemptFailed;

  AuthLockState copyWith({
    bool? enabled,
    bool? needsVerification,
    bool? lastAttemptFailed,
  }) =>
      AuthLockState(
        enabled: enabled ?? this.enabled,
        needsVerification: needsVerification ?? this.needsVerification,
        lastAttemptFailed: lastAttemptFailed ?? this.lastAttemptFailed,
      );
}

final authLockProvider =
    NotifierProvider<AuthLockController, AuthLockState>(
        AuthLockController.new);

/// One-shot probe of device biometric capability, cached per app run so the
/// settings tile can explain *why* the lock cannot be enabled.
final biometricCapabilityProvider = FutureProvider<bool>((ref) async {
  final BiometricAuthService bio = ref.read(biometricAuthServiceProvider);
  final Result<bool> capability = await bio.canCheckBiometrics();
  return capability.getOrElse(false);
});

/// Full-screen overlay shown whenever [AuthLockState.needsVerification] is
/// true. All app content stays mounted underneath (privacy-safe: the router
/// shell is opaque and covered), the overlay just blocks interaction.
class AuthLockOverlay extends ConsumerWidget {
  const AuthLockOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthLockState state = ref.watch(authLockProvider);
    if (!state.needsVerification) return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Material(
        color: isDark ? const Color(0xFF101418) : colors.surface,
        elevation: 0,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 42,
                    color: colors.primary,
                    semanticLabel: 'ShellMind',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.authLockScreenTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.authLockScreenSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                // Failure hint — only after a rejected attempt.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: state.lastAttemptFailed
                      ? Padding(
                          key: ValueKey<bool>(state.lastAttemptFailed),
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.error_outline_rounded,
                                  size: 16, color: colors.error),
                              const SizedBox(width: 6),
                              Text(
                                l10n.authLockUnlockFailed,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.error),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.read(authLockProvider.notifier).unlock(),
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: Text(l10n.authLockUnlockAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
