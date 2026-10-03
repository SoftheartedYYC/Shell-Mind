import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_server_connect_controller.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../../settings/presentation/providers/hide_ip_provider.dart';
import '../providers/terminal_tab_providers.dart';

/// Server picker behind the terminal page's "+" tab button.
///
/// Lists the whole configured fleet (from [serverConfigListProvider]) with
/// live status:
///
/// * **online** rows (session in the global [SshSessionRegistry]) open an
///   already-buffered tab instantly;
/// * **offline** rows dial first through [SshServerConnectController]
///   (credentials resolved from the secure keystore); on success the sheet
///   closes and the fresh session becomes the focused tab;
/// * rows already open as tabs show a check mark, but stay tappable —
///   tapping simply re-focuses that tab.
///
/// Failures stay published on the row (mirroring the AI chat manage sheet)
/// so the user can retry without reopening the picker.
class TerminalServerPickerSheet extends ConsumerStatefulWidget {
  const TerminalServerPickerSheet({super.key, required this.onSelect});

  /// Called with the chosen server id right before the sheet closes.
  final void Function(String serverId) onSelect;

  /// Shows the sheet.
  static Future<void> show(
    BuildContext context, {
    required void Function(String serverId) onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) =>
          TerminalServerPickerSheet(onSelect: onSelect),
    );
  }

  @override
  ConsumerState<TerminalServerPickerSheet> createState() =>
      _TerminalServerPickerSheetState();
}

class _TerminalServerPickerSheetState
    extends ConsumerState<TerminalServerPickerSheet> {
  /// Focuses an online server immediately, or dials it first and focuses on
  /// success. Failures keep the sheet open with the error on the row.
  Future<void> _open(ServerConfig config) async {
    final bool online =
        ref.read(sshSessionRegistryProvider).containsKey(config.id);
    if (online) {
      Navigator.of(context).pop();
      widget.onSelect(config.id);
      return;
    }
    final bool ok =
        await ref.read(sshServerConnectProvider.notifier).connect(config);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onSelect(config.id);
    }
    // On failure the attempt state stays published; the row keeps showing it.
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<ServerConfig> servers =
        ref.watch(serverConfigListProvider).valueOrNull ?? const <ServerConfig>[];
    final Map<String, RegisteredSession> sessions =
        ref.watch(sshSessionRegistryProvider);
    final Map<String, SshServerConnectAttempt> attempts =
        ref.watch(sshServerConnectProvider);
    final Set<String> openTabs =
        ref.watch(terminalTabsProvider).openIds.toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scroll) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.terminalTabPickerTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.terminalTabPickerSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: servers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.terminalTabPickerEmpty,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: servers.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _PickerTile(
                        config: servers[index],
                        session: sessions[servers[index].id],
                        attempt: attempts[servers[index].id],
                        alreadyOpen:
                            openTabs.contains(servers[index].id),
                        maskAddress:
                            ref.watch(hideIpAddressesProvider),
                        onOpen: () => unawaited(_open(servers[index])),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(l10n.aiServerDone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Picker row ─────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.config,
    required this.session,
    required this.attempt,
    required this.alreadyOpen,
    required this.maskAddress,
    required this.onOpen,
  });

  final ServerConfig config;

  /// Non-null when the server currently has a live session.
  final RegisteredSession? session;

  /// Latest out-of-page connection attempt progress/failure, if any.
  final SshServerConnectAttempt? attempt;

  /// Whether this server is already open as a terminal tab.
  final bool alreadyOpen;

  /// When true, the host/IP renders masked (privacy toggle).
  final bool maskAddress;

  final VoidCallback onOpen;

  bool get _online => session != null;
  bool get _connecting => attempt?.connecting ?? false;
  bool get _busy => _connecting;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final String statusLabel = _online
        ? l10n.serverOnline
        : _connecting
            ? l10n.aiServerConnecting
            : l10n.aiServerOffline;
    final Color statusColor = _online
        ? context.sem.success
        : _connecting
            ? context.sem.warning
            : colors.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: !_busy ? onOpen : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: <Widget>[
              // Status indicator: spinner while dialing, dot otherwise.
              SizedBox(
                width: 22,
                height: 22,
                child: _connecting
                    ? Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.sem.warning,
                        ),
                      )
                    : Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: _online
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: context.sem.success
                                          .withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${maskHostAddress(config.host, enabled: maskAddress)}:${config.port}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: AppTheme.monoFallback,
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      statusLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: statusColor),
                    ),
                    if (attempt?.error != null && !_online) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        attempt!.failureKind == 'auth'
                            ? l10n.aiServerNoCredential
                            : '${l10n.aiServerConnectFailed}: ${attempt!.error}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.error),
                      ),
                    ],
                  ],
                ),
              ),
              if (alreadyOpen)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_rounded,
                      size: 20, color: colors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
