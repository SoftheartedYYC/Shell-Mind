import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/server_config.dart';
import '../providers/server_config_providers.dart';
import '../widgets/server_card.dart';

/// How the fleet list orders items inside each group.
enum _SortMode {
  name,
  recent;

  _SortMode get next =>
      this == _SortMode.name ? _SortMode.recent : _SortMode.name;

  String get label => switch (this) {
        _SortMode.name => 'a–z',
        _SortMode.recent => 'recent',
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

  // ─── Delete flow ────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(ServerConfig config) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _DeleteDialog(config: config, onCancel: () {
        Navigator.of(dialogContext).pop(false);
      }, onConfirm: () {
        Navigator.of(dialogContext).pop(true);
      }),
    );
    return ok ?? false;
  }

  Future<void> _deleteNow(ServerConfig config) async {
    final Result<void> result =
        await ref.read(serverConfigListProvider.notifier).deleteServer(config.id);
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('removed · ${config.identity}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
        ),
      );
    } else {
      final AppFailure failure = result.failureOrNull?.failure ??
          AppFailure.storage('Could not delete server.');
      messenger.showSnackBar(
        SnackBar(
          content: Text('delete failed · ${failure.message}'),
          backgroundColor: AppTheme.coral,
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

    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      body: _Backdrop(
        child: SafeArea(
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
                  loading: () => const Center(
                    child: PhosphorLoader(label: 'loading fleet', compact: true),
                  ),
                  error: (Object error, _) => _ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(serverConfigListProvider),
                  ),
                  data: (List<ServerConfig> list) =>
                      _buildData(list),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AddServerFab(onPressed: _openAdd),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildData(List<ServerConfig> list) {
    if (list.isEmpty) return _ServersEmpty(onAdd: _openAdd);

    final List<_Group> groups = _groupAndSort(list);
    if (groups.isEmpty) {
      return _NoMatches(query: _query, onClear: _clearSearch);
    }
    return _FleetList(
      groups: groups,
      onRefresh: () =>
          ref.read(serverConfigListProvider.notifier).refresh(),
      onConnect: _connect,
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
    required this.onRefresh,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
    required this.onSwipeDelete,
    required this.onConfirmSwipe,
  });

  final List<_Group> groups;
  final Future<void> Function() onRefresh;
  final void Function(ServerConfig) onConnect;
  final void Function(ServerConfig) onEdit;
  final void Function(ServerConfig) onDelete;
  final Future<void> Function(ServerConfig) onSwipeDelete;
  final Future<bool> Function(ServerConfig) onConfirmSwipe;

  @override
  Widget build(BuildContext context) {
    // Flatten groups into a single scrollable with inline section headers.
    final List<Widget> children = <Widget>[];
    int revealIndex = 0;

    for (final _Group group in groups) {
      children.add(
        _Reveal(
          index: revealIndex++,
          child: SectionHeader(
            label: group.label ?? 'ungrouped',
            padding: EdgeInsets.fromLTRB(
              20,
              children.isEmpty ? 16 : 20,
              20,
              8,
            ),
            trailing: _CountBadge(count: group.items.length),
          ),
        ),
      );
      for (final ServerConfig config in group.items) {
        final int idx = revealIndex++;
        children.add(
          _Reveal(
            index: idx,
            child: Dismissible(
              key: ValueKey<String>(config.id),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              confirmDismiss: (_) => onConfirmSwipe(config),
              onDismissed: (_) => onSwipeDelete(config),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: ServerCard(
                  config: config,
                  onConnect: () => onConnect(config),
                  onEdit: () => onEdit(config),
                  onDelete: () => onDelete(config),
                ),
              ),
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.phosphor,
      backgroundColor: AppTheme.inkSurface,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.inkBorder),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontFamily: AppTheme.monoFont,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Staggered fade-and-rise entrance for list rows. Purely decorative; the
/// delay is capped so long lists don't feel sluggish.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final int delayMs = (widget.index.clamp(0, 12)) * 45;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Coral swipe-to-delete backdrop with a trash affordance.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppTheme.coral),
          const SizedBox(width: 8),
          Text(
            'rm',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.coral.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _ServersHeader extends StatelessWidget {
  const _ServersHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'fleet',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: const <String>[
                          'JetBrains Mono',
                          'Menlo',
                          'monospace',
                        ],
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.phosphor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.phosphor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '~/servers',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your hosts.',
                  style: context.text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          _CounterChip(count: count),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.inkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.phosphor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'HOSTS',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppTheme.textTertiary,
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
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1322),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inkBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded,
              size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 12.5,
                color: AppTheme.textPrimary,
                letterSpacing: 0.3,
              ),
              cursorColor: AppTheme.phosphor,
              cursorWidth: 1.4,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'grep hosts…',
                hintStyle: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (showClear)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 15, color: AppTheme.textTertiary),
            ),
        ],
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
    return Material(
      color: AppTheme.inkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.inkBorder),
      ),
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
                Icon(sort.icon, size: 15, color: AppTheme.phosphor),
                const SizedBox(width: 7),
                Text(
                  sort.label,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: <Widget>[
        const _EmptyHero(),
        const SizedBox(height: 28),
        const SectionHeader(label: 'quick start', padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        _CommandHint(
          step: '01',
          command: 'add host',
          description: 'Register an SSH endpoint with password or key auth.',
          icon: Icons.add_circle_outline_rounded,
          onTap: onAdd,
        ),
        const SizedBox(height: 8),
        const _CommandHint(
          step: '02',
          command: 'test connection',
          description: 'Probe the port before committing — catches typos fast.',
          icon: Icons.lan_outlined,
        ),
        const SizedBox(height: 8),
        const _CommandHint(
          step: '03',
          command: 'connect',
          description: 'Open a terminal session — full PTY, colours, and vim.',
          icon: Icons.terminal_rounded,
        ),
      ],
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off_rounded,
                size: 34, color: AppTheme.textTertiary),
            const SizedBox(height: 14),
            Text(
              'no match: "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('clear filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.phosphor,
                side: BorderSide(color: AppTheme.phosphor.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _TerminalDot(color: AppTheme.coral),
              const SizedBox(width: 5),
              const _TerminalDot(color: AppTheme.amber),
              const SizedBox(width: 5),
              const _TerminalDot(color: AppTheme.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'shell-mind — zsh',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _TerminalLine(
            prompt: '\$',
            text: 'ls -la ./hosts',
            color: AppTheme.textPrimary,
          ),
          const SizedBox(height: 4),
          const _TerminalLine(
            text: "ls: cannot access './hosts': No such file or directory",
            color: AppTheme.textTertiary,
            indent: 0,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.phosphor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: AppTheme.phosphor.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'IDLE',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.phosphor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'no hosts registered',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalDot extends StatelessWidget {
  const _TerminalDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TerminalLine extends StatelessWidget {
  const _TerminalLine({
    required this.text,
    this.prompt,
    this.color = AppTheme.textPrimary,
    this.indent = 0,
  });

  final String text;
  final String? prompt;
  final Color color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (prompt != null) ...<Widget>[
            Text(
              prompt!,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.phosphor,
                height: 1.5,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: const <String>[
                  'JetBrains Mono',
                  'Menlo',
                  'monospace',
                ],
                fontSize: 12,
                color: color,
                height: 1.5,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandHint extends StatelessWidget {
  const _CommandHint({
    required this.step,
    required this.command,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final String step;
  final String command;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.inkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.inkBorderSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1322),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.inkBorder),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.phosphor,
                      letterSpacing: 0.4,
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
                        Icon(icon, size: 11, color: AppTheme.textTertiary),
                        const SizedBox(width: 5),
                        Text(
                          command,
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 11.5,
                            color: AppTheme.phosphorGlow,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: context.text.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────

class _AddServerFab extends StatelessWidget {
  const _AddServerFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.phosphor.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppTheme.phosphor,
        foregroundColor: AppTheme.inkVoid,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'ADD HOST',
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
          failure: AppFailure.storage('Could not read the fleet list.'),
          onRetry: onRetry,
        ),
      ),
    );
  }
}

// ─── Delete confirmation dialog ───────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({
    required this.config,
    required this.onCancel,
    required this.onConfirm,
  });

  final ServerConfig config;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.inkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.inkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppTheme.coral),
                const SizedBox(width: 8),
                Text(
                  'rm host',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Delete "${config.name}"?',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${config.identity}:${config.port} and its stored '
              'credentials will be permanently removed.',
              style: context.text.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'cancel',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.coral,
                  ),
                  child: Text(
                    'delete',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.coral,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Atmospheric backdrop ─────────────────────────────────────────────────

/// Subtle grid + top-glow behind the tab. Adds depth without noise.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: _GridBackground()),
        const Positioned(
          top: -80,
          left: -40,
          right: -40,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.7),
                radius: 1.1,
                colors: <Color>[
                  Color(0x1F4FC3F7),
                  Color(0x004FC3F7),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double step = 28;
    final Paint paint = Paint()
      ..color = const Color(0x142B3554)
      ..strokeWidth = 0.6;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
