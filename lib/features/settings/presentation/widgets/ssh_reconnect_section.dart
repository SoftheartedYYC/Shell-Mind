import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_reconnect_policy.dart';
import '../../../../core/constants/app_constants.dart';

/// Settings tile for the "SSH 断线自动重连" toggle and its max-attempts
/// selector.
///
/// Lives in its own file (instead of inline in settings_page.dart) to keep
/// the insertion into the page a one-line change. Mirrors the visual shape of
/// the `_HideIpTile` switch row: icon + two-line text + trailing control.
class SshReconnectSection extends ConsumerWidget {
  const SshReconnectSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool enabled = ref.watch(sshAutoReconnectProvider);
    final int maxAttempts = ref.watch(sshReconnectMaxAttemptsProvider);
    final SshReconnectMaxAttemptsNotifier attemptsNotifier =
        ref.read(sshReconnectMaxAttemptsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(Icons.restart_alt_rounded,
                    size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.sshReconnectToggle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        l10n.sshReconnectToggleDesc,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (bool value) => ref
                      .read(sshAutoReconnectProvider.notifier)
                      .setAutoReconnect(value),
                ),
              ],
            ),
          ),
        ),
        // Max-attempts row is only meaningful while the toggle is on.
        if (enabled)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAttemptsPicker(
                context,
                attemptsNotifier,
                maxAttempts,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.format_list_numbered_rounded,
                        size: 20, color: colors.onSurfaceVariant),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.sshReconnectMaxAttempts,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            l10n.sshReconnectMaxAttemptsDesc,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      maxAttempts == 0
                          ? l10n.sshReconnectMaxAttemptsUnlimited
                          : l10n.sshReconnectMaxAttemptsValue(maxAttempts),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: colors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Bottom-sheet chooser for the maximum reconnect attempts
  /// (1–[AppConstants.kMaxSshReconnectMaxAttempts], plus "unlimited" = 0).
  void _showAttemptsPicker(
    BuildContext context,
    SshReconnectMaxAttemptsNotifier notifier,
    int current,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<int> options = <int>[
      0,
      for (int i = AppConstants.kMinSshReconnectMaxAttempts;
          i <= AppConstants.kMaxSshReconnectMaxAttempts;
          i++)
        i,
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.sshReconnectMaxAttempts,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            RadioGroup<int>(
              groupValue: current,
              onChanged: (int? value) {
                if (value != null) notifier.setMaxAttempts(value);
                Navigator.of(ctx).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final int option in options)
                    RadioListTile<int>(
                      value: option,
                      title: Text(
                        option == 0
                            ? l10n.sshReconnectMaxAttemptsUnlimited
                            : l10n.sshReconnectMaxAttemptsValue(option),
                        style: TextStyle(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
