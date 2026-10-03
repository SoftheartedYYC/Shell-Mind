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

/// Server selection bottom sheet for the AI chat surface.
///
/// Two modes:
///
/// * **Manage** (`manage: true`) — the in-chat connection manager. Lists
///   **all** configured servers (from [serverConfigListProvider]) with live
///   online/offline badges. Tapping an offline row connects it through
///   [SshServerConnectController] (credentials resolved from the secure
///   keystore, session registered in the global [SshSessionRegistry]); online
///   rows expose an explicit disconnect action. This is how servers are
///   brought online for the AI assistant without visiting the terminal page.
/// * **Pick** (`manage: false`, default) — the command-target chooser over the
///   currently online sessions only, with single or multi-select.
class ServerSelectorSheet extends ConsumerStatefulWidget {
  const ServerSelectorSheet({
    super.key,
    this.multiSelect = false,
    this.manage = false,
  });

  final bool multiSelect;

  /// When true the sheet becomes a connection manager over the whole fleet
  /// instead of a target picker over live sessions.
  final bool manage;

  /// Shows the sheet. Returns the selected server IDs in pick mode (`null`
  /// when cancelled); always `null` in manage mode.
  static Future<List<String>?> show(
    BuildContext context, {
    bool multiSelect = false,
    bool manage = false,
  }) async {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => ServerSelectorSheet(
        multiSelect: multiSelect,
        manage: manage,
      ),
    );
  }

  @override
  ConsumerState<ServerSelectorSheet> createState() =>
      _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends ConsumerState<ServerSelectorSheet> {
  final Map<String, bool> _selected = <String, bool>{};

  // ─── Manage mode ────────────────────────────────────────────────────────

  Future<void> _connect(ServerConfig config) async {
    // The registry tears down any prior session for this server first, so a
    // reconnect attempt is always safe.
    await ref.read(sshServerConnectProvider.notifier).connect(config);
    // On failure the attempt state stays published so the row keeps showing
    // the error; on success the row flips to online via the registry watch.
  }

  void _disconnect(String serverId) {
    unawaited(
        ref.read(sshSessionRegistryProvider.notifier).disconnect(serverId));
  }

  Widget _buildManageSheet(ColorScheme colors) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<ServerConfig>> fleet =
        ref.watch(serverConfigListProvider);
    final Map<String, RegisteredSession> sessions =
        ref.watch(sshSessionRegistryProvider);
    final Map<String, SshServerConnectAttempt> attempts =
        ref.watch(sshServerConnectProvider);

    final List<ServerConfig> servers = fleet.valueOrNull ??
        const <ServerConfig>[];

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
                    l10n.aiServerManageTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aiServerManageSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Row(
                children: <Widget>[
                  Icon(Icons.circle,
                      size: 8, color: context.sem.success),
                  const SizedBox(width: 6),
                  Text(
                    l10n.aiServerOnlineCount(sessions.length),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: servers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.commonNothingToShow,
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
                          _ManageTile(
                        config: servers[index],
                        session: sessions[servers[index].id],
                        attempt: attempts[servers[index].id],
                        maskAddress:
                            ref.watch(hideIpAddressesProvider),
                        onConnect: () => unawaited(_connect(servers[index])),
                        onDisconnect: () =>
                            _disconnect(servers[index].id),
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

  // ─── Pick mode ──────────────────────────────────────────────────────────

  List<RegisteredSession> get _sessions =>
      ref.read(sshSessionRegistryProvider.notifier).activeSessions;

  void _toggleSelection(String serverId) {
    if (!mounted) return;
    setState(() => _selected[serverId] = !(_selected[serverId] ?? false));
  }

  int get _selectedCount =>
      _selected.values.where((bool s) => s).length;

  Widget _buildPickSheet(ColorScheme colors) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<RegisteredSession> sessions = _sessions;

    return DraggableScrollableSheet(
      initialChildSize: sessions.isEmpty ? 0.3 : 0.6,
      minChildSize: 0.3,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.aiExecuteSelectServer,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (sessions.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _selectedCount > 0
                            ? Icons.close_rounded
                            : Icons.check_rounded,
                        size: 22,
                      ),
                      onPressed: () => setState(() {
                        if (_selectedCount > 0) {
                          _selected.clear();
                        } else {
                          for (final RegisteredSession s in sessions) {
                            _selected[s.serverId] = true;
                          }
                        }
                      }),
                      tooltip: _selectedCount > 0
                          ? l10n.aiExecuteClearSelection
                          : l10n.aiExecuteSelectAll,
                    ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? _PickEmptyState(colors: colors)
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final RegisteredSession session = sessions[index];
                        final bool isSelected =
                            _selected[session.serverId] ?? false;
                        final Duration uptime =
                            DateTime.now().difference(session.connectedAt);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _toggleSelection(session.serverId),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: <Widget>[
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelection(
                                        session.serverId),
                                    side: BorderSide(
                                      color: colors.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          session.serverName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${maskHostAddress(session.config.host, enabled: ref.watch(hideIpAddressesProvider))}:${session.config.port}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontFamily:
                                                    AppTheme.monoFont,
                                                fontFamilyFallback:
                                                    AppTheme.monoFallback,
                                                color:
                                                    colors.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.aiExecuteUptime(
                                            uptime.inHours,
                                            uptime.inMinutes % 60,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: context.sem.success
                                                    .withValues(alpha: 0.8),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: context.sem.success,
                                      shape: BoxShape.circle,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: context.sem.success
                                              .withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (sessions.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_selectedCount == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.multiSelect
                                  ? l10n.aiExecuteAtLeastOne
                                  : l10n.aiExecuteSelectHint,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop<List<String>>(
                        _selected.entries
                            .where((MapEntry<String, bool> e) => e.value)
                            .map((MapEntry<String, bool> e) => e.key)
                            .toList(),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(l10n.aiExecuteRunCount(_selectedCount)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return widget.manage ? _buildManageSheet(colors) : _buildPickSheet(colors);
  }
}

// ─── Manage-mode row ────────────────────────────────────────────────────────

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.config,
    required this.session,
    required this.attempt,
    required this.maskAddress,
    required this.onConnect,
    required this.onDisconnect,
  });

  final ServerConfig config;

  /// When true, the host/IP renders masked (privacy toggle).
  final bool maskAddress;

  /// Non-null when the server currently has a live session.
  final RegisteredSession? session;

  /// Latest connection attempt progress/failure, if any.
  final SshServerConnectAttempt? attempt;

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  bool get _online => session != null;
  bool get _connecting => attempt?.connecting ?? false;

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
        onTap: !_online && !_connecting ? onConnect : null,
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
              // Trailing action.
              if (_online)
                IconButton(
                  onPressed: onDisconnect,
                  tooltip: l10n.terminalTooltipDisconnect,
                  icon: Icon(Icons.link_off_rounded,
                      size: 20, color: colors.error),
                )
              else if (!_connecting)
                IconButton(
                  onPressed: onConnect,
                  tooltip: l10n.serverActionConnect,
                  icon: Icon(Icons.link_rounded,
                      size: 20, color: colors.primary),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pick-mode empty state ─────────────────────────────────────────────────

class _PickEmptyState extends StatelessWidget {
  const _PickEmptyState({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.lan_outlined,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.aiExecuteNoServer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
