import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

/// First-connect host-key confirmation (D2 policy).
///
/// Rendered as a modal dialog over the **root** navigator: the host-key
/// callback can fire while the terminal page (itself a root-level route) is
/// coming up, so a dialog must be anchored to the navigator that owns every
/// route — never to an inner shell or the `MaterialApp.builder` context.
///
/// Shows the endpoint, the OpenSSH-style SHA-256 fingerprint in a selectable
/// monospace block, and the security consequence. Resolves `true` when the
/// user chose "trust and connect".
///
/// The dialog auto-rejects after [countdown]: an unattended trust prompt can
/// never linger indefinitely while the SSH handshake budget is ticking, and
/// an expiry always resolves to `false` so trust is never recorded without
/// an explicit confirmation. The countdown must stay strictly shorter than
/// the handshake timeout granted for approval-enabled connections — see
/// `AppConstants.sshHandshakeTimeoutWithApproval`.
class HostKeyApprovalDialog extends StatefulWidget {
  const HostKeyApprovalDialog({
    super.key,
    required this.host,
    required this.port,
    required this.fingerprint,
    this.countdown = AppConstants.hostKeyApprovalTimeout,
  });

  /// Endpoint the client is dialing.
  final String host;

  /// Port the client is dialing.
  final int port;

  /// OpenSSH-style SHA-256 fingerprint (`SHA256:<base64>`).
  final String fingerprint;

  /// Time granted for reviewing the fingerprint. When it elapses the dialog
  /// resolves `false` (reject) and closes itself.
  final Duration countdown;

  /// Pushes the dialog onto [navigator] and resolves the user's answer.
  ///
  /// Any dismissal path that is not an explicit "trust and connect" tap is a
  /// rejection — back button, system back gesture and countdown expiry all
  /// count as "no" so a security decision can never be skipped by accident.
  /// The barrier is not dismissible for the same reason.
  static Future<bool> show(
    GlobalKey<NavigatorState> navigator, {
    required String host,
    required int port,
    required String fingerprint,
    Duration countdown = AppConstants.hostKeyApprovalTimeout,
  }) {
    final BuildContext? ctx = navigator.currentContext;
    if (ctx == null) return Future<bool>.value(false);

    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => HostKeyApprovalDialog(
        host: host,
        port: port,
        fingerprint: fingerprint,
        countdown: countdown,
      ),
    ).then((bool? trusted) => trusted ?? false);
  }

  @override
  State<HostKeyApprovalDialog> createState() =>
      _HostKeyApprovalDialogState();
}

class _HostKeyApprovalDialogState extends State<HostKeyApprovalDialog> {
  /// Seconds left before the auto-reject fires; seeded from [widget.countdown].
  late int _secondsRemaining;

  Timer? _ticker;

  /// Single-shot guard: whichever dismissal path runs first (trust tap,
  /// reject tap, back button or countdown expiry) pops the dialog exactly
  /// once and disables every other path.
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdown.inSeconds;
    if (_secondsRemaining > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    } else {
      // Zero (or negative) countdown: reject immediately, post-frame so the
      // first pop does not happen mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _settle(false);
      });
    }
  }

  void _onTick(Timer timer) {
    if (_settled || !mounted) {
      timer.cancel();
      return;
    }
    final int next = _secondsRemaining - 1;
    if (next <= 0) {
      // Countdown expired — treat as a rejection.
      _settle(false);
      return;
    }
    setState(() => _secondsRemaining = next);
  }

  /// Resolves the dialog with [trusted] exactly once.
  void _settle(bool trusted) {
    if (_settled || !mounted) return;
    _settled = true;
    _ticker?.cancel();
    _ticker = null;
    Navigator.of(context).pop(trusted);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final bool urgent = _secondsRemaining <= 10;

    return AlertDialog(
      icon: Icon(Icons.verified_user_outlined, color: colors.primary),
      title: Text(l10n.hostKeyConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.hostKeyConfirmMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.hostKeyEndpointLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.host}:${widget.port}',
              style: AppTheme.monoStyle(context, size: 14),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.hostKeyFingerprintLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: SelectionArea(
                child: Text(
                  widget.fingerprint,
                  style: AppTheme.monoStyle(context,
                      size: 12, weight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.shield_outlined,
                    size: 15, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.hostKeySecurityNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
            if (_secondsRemaining > 0) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: urgent ? colors.error : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.hostKeyAutoRejectCountdown(_secondsRemaining),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                urgent ? colors.error : colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => _settle(false),
          child: Text(l10n.hostKeyReject),
        ),
        FilledButton(
          onPressed: () => _settle(true),
          child: Text(l10n.hostKeyTrustAndConnect),
        ),
      ],
    );
  }
}
