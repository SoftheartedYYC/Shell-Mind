import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_server_connect_controller.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../settings/presentation/providers/hide_ip_provider.dart';
import '../../domain/entities/server_config.dart';
import '../providers/server_config_providers.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/server_card.dart';

/// How the fleet list orders items inside each group.
enum _SortMode {
  name,
  recent;

  _SortMode get next =>
      this == _SortMode.name ? _SortMode.recent : _SortMode.name;

  String label(AppLocalizations l10n) => switch (this) {
        _SortMode.name => l10n.serversSortName,
        _SortMode.recent => l10n.serversSortRecent,
      };

  IconData get icon => switch (this) {
        _SortMode.name => Icons.sort_by_alpha_rounded,
        _SortMode.recent => Icons.schedule_rounded,
      };
}

/// A named section of the fleet list. [label] is `null` for the ungrouped
/// bucket, which always sorts last.
class _Group {
  const _Group({required this.label, required this.items});

  final String? label;
  final List<ServerConfig> items;
}

/// Live fleet list — the primary landing tab.
///
/// Backed by [serverConfigListProvider], which seeds from Hive and then tracks
/// the box stream, so inserts/edits/deletes elsewhere in the app surface here
/// instantly. Tap a card to open a terminal, long-press (or use ⋮) for the
/// action sheet, swipe left to delete, and pull down to re-read from disk.
class ServersPage extends ConsumerStatefulWidget {
  const ServersPage({super.key});

  @override
  ConsumerState<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends ConsumerState<ServersPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  _SortMode _sort = _SortMode.name;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final String q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  void _toggleSort() => setState(() => _sort = _sort.next);

  // ─── Navigation ─────────────────────────────────────────────────────────

  void _openAdd() => context.push('/servers/edit');

  void _openEdit(ServerConfig config) =>
      context.push('/servers/edit?id=${config.id}');

  void _connect(ServerConfig config) {
    // Fire-and-forget: stamping lastConnected shouldn't block navigation.
    ref.read(serverConfigListProvider.notifier).markConnected(config.id);
    context.push('/terminal/${config.id}');
  }

  /// Manually tears down the live session for [config].
  ///
  /// Goes through [SshSessionRegistry.disconnect] — the authoritative manual
  /// path — which cancels any running auto-reconnect coordinator before
  /// dropping the transport. The registry's state change instantly repaints
  /// the card back to offline (providers are reactive).
  Future<void> _disconnect(ServerConfig config) async {
    await ref.read(sshSessionRegistryProvider.notifier).disconnect(config.id);
  }

  // ─── Delete flow ────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(ServerConfig config) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.serversDeleteConfirmTitle),
        content: Text(
          l10n.serversDeleteConfirmMessage(
            config.name,
            config.identity,
            config.port,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteNow(ServerConfig config) async {
    final Result<void> result =
        await ref.read(serverConfigListProvider.notifier).deleteServer(config.id);
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.serversDeleted(config.identity)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
        ),
      );
    } else {
      final AppFailure failure = result.failureOrNull?.failure ??
          AppFailure.storage(l10n.serversReadError);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.serversDeleteFailed(failure.message)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Used by the card's action sheet / overflow menu (non-swipe deletes).
  Future<void> _requestDelete(ServerConfig config) async {
    final bool ok = await _confirmDelete(config);
    if (!ok) return;
    await _deleteNow(config);
  }

  // ─── Filtering / grouping ───────────────────────────────────────────────

  bool _matches(ServerConfig c) {
    if (_query.isEmpty) return true;
    return c.name.toLowerCase().contains(_query) ||
        c.host.toLowerCase().contains(_query) ||
        c.username.toLowerCase().contains(_query) ||
        (c.group?.toLowerCase().contains(_query) ?? false) ||
        c.address.toLowerCase().contains(_query);
  }

  int _compare(ServerConfig a, ServerConfig b) {
    switch (_sort) {
      case _SortMode.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortMode.recent:
        final DateTime? at = a.lastConnectedAt;
        final DateTime? bt = b.lastConnectedAt;
        if (at == null && bt == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
    }
  }

  /// Applies the active filter + sort, then buckets into groups. Named groups
  /// sort alphabetically and come first; the ungrouped bucket is last.
  List<_Group> _groupAndSort(List<ServerConfig> all) {
    final List<ServerConfig> filtered =
        all.where(_matches).toList()..sort(_compare);

    final Map<String, List<ServerConfig>> named =
        <String, List<ServerConfig>>{};
    final List<ServerConfig> ungrouped = <ServerConfig>[];

    for (final ServerConfig c in filtered) {
      final String? g = c.group;
      if (g == null || g.trim().isEmpty) {
        ungrouped.add(c);
      } else {
        named.putIfAbsent(g.trim(), () => <ServerConfig>[]).add(c);
      }
    }

    final List<String> keys = named.keys.toList()..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );

    return <_Group>[
      for (final String k in keys) _Group(label: k, items: named[k]!),
      if (ungrouped.isNotEmpty) _Group(label: null, items: ungrouped),
    ];
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ServerConfig>> async =
        ref.watch(serverConfigListProvider);
    final List<ServerConfig> all = async.valueOrNull ?? const <ServerConfig>[];
    // Live status for the per-card connection badges.
    final Map<String, RegisteredSession> sessions =
        ref.watch(sshSessionRegistryProvider);
    final Map<String, SshServerConnectAttempt> attempts =
        ref.watch(sshServerConnectProvider);
    final bool hideIp = ref.watch(hideIpAddressesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ServersHeader(count: all.length),
            if (all.isNotEmpty)
              _FilterBar(
                controller: _searchCtrl,
                sort: _sort,
                query: _query,
                onSortTap: _toggleSort,
                onClear: _clearSearch,
              ),
            Expanded(
              child: async.when(
                loading: () => Center(
                    child: AppLoader(
                        label: AppLocalizations.of(context).serversLoading)),
                error: (Object error, _) => _ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(serverConfigListProvider),
                ),
                data: (List<ServerConfig> list) =>
                    _buildData(list, sessions, attempts, hideIp),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context).serversAdd),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildData(
    List<ServerConfig> list,
    Map<String, RegisteredSession> sessions,
    Map<String, SshServerConnectAttempt> attempts,
    bool maskAddress,
  ) {
    if (list.isEmpty) return _ServersEmpty(onAdd: _openAdd);

    final List<_Group> groups = _groupAndSort(list);
    if (groups.isEmpty) {
      return _NoMatches(query: _query, onClear: _clearSearch);
    }
    // Per-card status sources: online = live registry session, connecting =
    // in-flight attempt from the shared connect controller.
    final Set<String> onlineIds = sessions.keys.toSet();
    final Set<String> connectingIds = attempts.entries
        .where((MapEntry<String, SshServerConnectAttempt> e) => e.value.inProgress)
        .map((MapEntry<String, SshServerConnectAttempt> e) => e.key)
        .toSet();
    return _FleetList(
      groups: groups,
      servers: list,
      onlineIds: onlineIds,
      connectingIds: connectingIds,
      maskAddress: maskAddress,
      onRefresh: () =>
          ref.read(serverConfigListProvider.notifier).refresh(),
      onConnect: _connect,
      onDisconnect: _disconnect,
      onEdit: _openEdit,
      onDelete: _requestDelete,
      onSwipeDelete: _deleteNow,
      onConfirmSwipe: _confirmDelete,
    );
  }
}

// ─── Fleet list ───────────────────────────────────────────────────────────

class _FleetList extends StatelessWidget {
  const _FleetList({
    required this.groups,
    required this.servers,
    required this.onlineIds,
    required this.connectingIds,
    required this.maskAddress,
    required this.onRefresh,
    required this.onConnect,
    required this.onDisconnect,
    required this.onEdit,
    required this.onDelete,
    required this.onSwipeDelete,
    required this.onConfirmSwipe,
  });

  final List<_Group> groups;

  /// Full fleet for the health summary card (probe targets + ratio).
  final List<ServerConfig> servers;

  /// Server ids with a live registry session — drives the green online badge.
  final Set<String> onlineIds;

  /// Server ids with a dial currently in flight — drives the spinner badge.
  final Set<String> connectingIds;

  /// When true, hosts/IPs render masked on the card identity line.
  final bool maskAddress;

  final Future<void> Function() onRefresh;
  final void Function(ServerConfig) onConnect;
  final Future<void> Function(ServerConfig) onDisconnect;
  final void Function(ServerConfig) onEdit;
  final void Function(ServerConfig) onDelete;
  final Future<void> Function(ServerConfig) onSwipeDelete;
  final Future<bool> Function(ServerConfig) onConfirmSwipe;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      HealthSummaryCard(servers: servers),
    ];

    for (final _Group group in groups) {
      children.add(
        SectionHeader(
          label: group.label ?? AppLocalizations.of(context).serversUngrouped,
          padding: EdgeInsets.fromLTRB(
            20,
            children.isEmpty ? 16 : 20,
            20,
            8,
          ),
          trailing: _CountBadge(count: group.items.length),
        ),
      );
      for (final ServerConfig config in group.items) {
        children.add(
          Dismissible(
            key: ValueKey<String>(config.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            confirmDismiss: (_) => onConfirmSwipe(config),
            onDismissed: (_) => onSwipeDelete(config),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ServerCard(
                config: config,
                connected: onlineIds.contains(config.id),
                connecting: connectingIds.contains(config.id),
                maskAddress: maskAddress,
                onConnect: () => onConnect(config),
                onDisconnect: () => onDisconnect(config),
                onEdit: () => onEdit(config),
                onDelete: () => onDelete(config),
              ),
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        children: children,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );
  }
}

/// Swipe-to-delete backdrop.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline_rounded, size: 22, color: colors.error),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _ServersHeader extends StatelessWidget {
  const _ServersHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.serversTitle,
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.serversHostCount(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter bar (functional) ──────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.sort,
    required this.query,
    required this.onSortTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final _SortMode sort;
  final String query;
  final VoidCallback onSortTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SearchField(
              controller: controller,
              showClear: query.isNotEmpty,
              onClear: onClear,
            ),
          ),
          const SizedBox(width: 8),
          _SortButton(sort: sort, onTap: onSortTap),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.showClear,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context).serversSearch,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: showClear
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 16),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onTap});

  final _SortMode sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(sort.icon, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  sort.label(AppLocalizations.of(context)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty / no-match states ──────────────────────────────────────────────

class _ServersEmpty extends StatelessWidget {
  const _ServersEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.dns_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.serversEmpty,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.serversEmptyHint,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.serversAdd),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SectionHeader(
            label: l10n.serversQuickStart, padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        _QuickStep(
          step: 1,
          title: l10n.serversQuickStep1Title,
          description: l10n.serversQuickStep1Desc,
          icon: Icons.add_circle_outline_rounded,
          onTap: onAdd,
        ),
        const SizedBox(height: 8),
        _QuickStep(
          step: 2,
          title: l10n.serversQuickStep2Title,
          description: l10n.serversQuickStep2Desc,
          icon: Icons.lan_outlined,
        ),
        const SizedBox(height: 8),
        _QuickStep(
          step: 3,
          title: l10n.serversQuickStep3Title,
          description: l10n.serversQuickStep3Desc,
          icon: Icons.terminal_rounded,
        ),
      ],
    );
  }
}

class _QuickStep extends StatelessWidget {
  const _QuickStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final int step;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(icon, size: 14, color: colors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).serversNoMatch(query),
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(AppLocalizations.of(context).serversClearFilter),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorBanner(
          failure:
              AppFailure.storage(AppLocalizations.of(context).serversReadError),
          onRetry: onRetry,
        ),
      ),
    );
  }
}
