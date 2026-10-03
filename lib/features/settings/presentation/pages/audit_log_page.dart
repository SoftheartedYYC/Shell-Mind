import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/command_audit_log.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen audit trail of every command the AI agent executed.
///
/// Reads the live [commandAuditNotifierProvider] snapshot, offers filter
/// chips (server / mode / outcome), expandable output summaries and a
/// destructive clear-all action guarded by a confirmation dialog.
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _serverId;
  CommandAuditMode? _mode;
  bool? _success;
  final Set<String> _expanded = <String>{};

  List<CommandAuditEntry> _applyFilters(List<CommandAuditEntry> entries) {
    return entries
        .where((CommandAuditEntry e) =>
            (_serverId == null || e.serverId == _serverId) &&
            (_mode == null || e.mode == _mode) &&
            (_success == null || e.success == _success))
        .toList(growable: false);
  }

  /// Unique `(serverId, serverName)` pairs in first-seen order.
  List<(String, String)> _serverOptions(List<CommandAuditEntry> entries) {
    final List<(String, String)> options = <(String, String)>[];
    for (final CommandAuditEntry e in entries) {
      if (e.serverId.isEmpty) continue;
      if (!options.any(((String, String) o) => o.$1 == e.serverId)) {
        options.add((e.serverId, e.serverName));
      }
    }
    return options;
  }

  Future<void> _confirmClear() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int count = ref.read(commandAuditNotifierProvider).length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.auditClearConfirmTitle),
        content: Text(l10n.auditClearConfirmMessage(count)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.auditClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(commandAuditNotifierProvider.notifier).clearAll();
    if (!mounted) return;
    setState(_expanded.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.auditCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CommandAuditEntry> entries =
        ref.watch(commandAuditNotifierProvider);
    final List<CommandAuditEntry> filtered = _applyFilters(entries);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditTitle),
        actions: <Widget>[
          IconButton(
            onPressed: entries.isEmpty ? null : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.auditClearTooltip,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FilterBar(
            serverOptions: _serverOptions(entries),
            serverId: _serverId,
            mode: _mode,
            success: _success,
            onSelectServer: (String? id) => setState(() => _serverId = id),
            onSelectMode: (CommandAuditMode? m) => setState(() => _mode = m),
            onSelectSuccess: (bool? s) => setState(() => _success = s),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              l10n.auditEntriesCount(filtered.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.auditEmptyTitle,
                    message: l10n.auditEmptyMessage,
                  )
                : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: l10n.auditFilteredEmpty,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                        itemCount: filtered.length,
                        itemBuilder: (BuildContext context, int index) =>
                            _AuditCard(
                          entry: filtered[index],
                          expanded: _expanded.contains(filtered[index].id),
                          onToggle: () => setState(() {
                            final String id = filtered[index].id;
                            if (!_expanded.remove(id)) _expanded.add(id);
                          }),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────

/// Single horizontally-scrolling row of grouped filter chips.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.serverOptions,
    required this.serverId,
    required this.mode,
    required this.success,
    required this.onSelectServer,
    required this.onSelectMode,
    required this.onSelectSuccess,
  });

  final List<(String, String)> serverOptions;
  final String? serverId;
  final CommandAuditMode? mode;
  final bool? success;
  final ValueChanged<String?> onSelectServer;
  final ValueChanged<CommandAuditMode?> onSelectMode;
  final ValueChanged<bool?> onSelectSuccess;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<Widget> chips = <Widget>[
      FilterChip(
        label: Text(l10n.auditFilterAllServers),
        selected: serverId == null,
        onSelected: (bool _) => onSelectServer(null),
      ),
      for (final (String, String) option in serverOptions)
        FilterChip(
          label: Text(option.$2),
          selected: serverId == option.$1,
          onSelected: (bool _) =>
              onSelectServer(serverId == option.$1 ? null : option.$1),
        ),
      _groupDivider(colors),
      FilterChip(
        label: Text(l10n.auditFilterAllModes),
        selected: mode == null,
        onSelected: (bool _) => onSelectMode(null),
      ),
      FilterChip(
        label: Text(l10n.auditFilterConfirmed),
        selected: mode == CommandAuditMode.confirmed,
        onSelected: (bool _) => onSelectMode(
          mode == CommandAuditMode.confirmed ? null : CommandAuditMode.confirmed,
        ),
      ),
      FilterChip(
        label: Text(l10n.auditFilterAuto),
        selected: mode == CommandAuditMode.auto,
        onSelected: (bool _) => onSelectMode(
          mode == CommandAuditMode.auto ? null : CommandAuditMode.auto,
        ),
      ),
      _groupDivider(colors),
      FilterChip(
        label: Text(l10n.auditFilterAllResults),
        selected: success == null,
        onSelected: (bool _) => onSelectSuccess(null),
      ),
      FilterChip(
        label: Text(l10n.auditFilterSuccess),
        selected: success == true,
        onSelected: (bool _) => onSelectSuccess(success == true ? null : true),
      ),
      FilterChip(
        label: Text(l10n.auditFilterFailed),
        selected: success == false,
        onSelected: (bool _) =>
            onSelectSuccess(success == false ? null : false),
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          for (int i = 0; i < chips.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }

  Widget _groupDivider(ColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 24,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.outlineVariant,
          ),
        ),
      );
}

// ─── Entry card ───────────────────────────────────────────────────────────

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry, required this.expanded, required this.onToggle});

  final CommandAuditEntry entry;
  final bool expanded;
  final VoidCallback onToggle;

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTimestamp(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} '
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ShellMindSemanticColors sem = context.sem;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      _formatTimestamp(entry.executedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    const Spacer(),
                    Text(
                      entry.serverName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.command,
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: AppTheme.monoFallback,
                        fontSize: 13,
                        height: 1.4,
                        color: colors.onSurface,
                      ),
                ),
                if (expanded) ...<Widget>[
                  const SizedBox(height: 10),
                  if (entry.hasOutput && entry.outputSummary.isNotEmpty) ...<Widget>[
                    Text(
                      l10n.auditOutputSummary,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.outputSummary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: AppTheme.monoFont,
                              fontFamilyFallback: AppTheme.monoFallback,
                              fontSize: 12,
                              height: 1.45,
                              color: colors.onSurface,
                            ),
                      ),
                    ),
                  ] else
                    Text(
                      l10n.auditNoOutput,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _ModeBadge(mode: entry.mode),
                    StatusPill(
                      label: entry.success
                          ? l10n.auditStatusSuccess
                          : l10n.auditStatusFailed,
                      color: entry.success ? sem.success : sem.danger,
                      size: StatusPillSize.small,
                    ),
                    Text(
                      '${l10n.auditExitCode(entry.exitCode)} · ${formatElapsed(entry.elapsed)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: AppTheme.monoFallback,
                            fontSize: 11,
                          ),
                    ),
                    if (entry.hasDangerous)
                      StatusPill(
                        label: l10n.auditDangerousBadge,
                        color: sem.danger,
                        size: StatusPillSize.small,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mode badge ───────────────────────────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final CommandAuditMode mode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool confirmed = mode == CommandAuditMode.confirmed;
    final Color tint = confirmed ? colors.primary : colors.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        confirmed ? l10n.auditModeConfirmed : l10n.auditModeAuto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tint,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
