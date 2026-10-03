import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/health_probe.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../ai_chat/domain/entities/ai_chat_extra.dart';
import '../../domain/entities/server_config.dart';

/// Fleet-level health summary shown above the server list.
///
/// Everything here is user-initiated: the card renders the last snapshot (or
/// an idle hint) until the user taps the probe button or pulls to trigger a
/// round — there is no background polling. Only server **names** are shown,
/// so the "hide IP" preference is honoured by construction.
class HealthSummaryCard extends ConsumerStatefulWidget {
  const HealthSummaryCard({super.key, required this.servers});

  /// The full fleet (saved configs), used both for probe targets and for the
  /// online/total ratio.
  final List<ServerConfig> servers;

  @override
  ConsumerState<HealthSummaryCard> createState() => _HealthSummaryCardState();
}

class _HealthSummaryCardState extends ConsumerState<HealthSummaryCard> {
  void _probe({bool force = true}) {
    if (widget.servers.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(fleetHealthProvider.notifier).probe(
          widget.servers,
          force: force,
        );
  }

  void _openAiDiagnostics(FleetHealthSnapshot snapshot) {
    HapticFeedback.selectionClick();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StringBuffer buffer = StringBuffer(l10n.healthDiagIntro);
    buffer.writeln();
    final int online = snapshot.onlineCount;
    final int total = snapshot.totalCount;
    buffer.writeln(l10n.healthDiagStats(online, total));
    for (final ServerHealth offline in snapshot.offlineServers) {
      buffer.writeln(l10n.healthDiagOfflineItem(offline.serverName));
    }
    for (final ServerHealth online in snapshot.onlineServers) {
      final String uptime =
          online.uptimeBrief == null ? '' : ' (${online.uptimeBrief})';
      final String load =
          online.loadAverage == null ? '' : ', load ${online.loadAverage}';
      buffer.writeln(
        l10n.healthDiagOnlineItem(online.serverName, '$uptime$load'),
      );
    }
    buffer.writeln(l10n.healthDiagOutro);
    context.goNamed(
      RouteNames.aiChat,
      extra: AiChatExtra(
        initialQuery: buffer.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FleetHealthState health = ref.watch(fleetHealthProvider);
    final Map<String, RegisteredSession> sessions =
        ref.watch(sshSessionRegistryProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Connectivity truth comes from the registry; the probe only enriches
    // online servers with uptime/load details.
    final Set<String> onlineIds = sessions.keys.toSet();
    final int onlineCount =
        widget.servers.where((ServerConfig c) => onlineIds.contains(c.id)).length;
    final int totalCount = widget.servers.length;

    if (totalCount == 0) return const SizedBox.shrink();

    final bool hasSnapshot = health.snapshot != null;
    final bool probing = health.isProbing;

    final FleetMood mood =
        hasSnapshot ? health.snapshot!.mood : FleetMood.empty;
    final Color accent = switch (mood) {
      FleetMood.allOnline => context.sem.success,
      FleetMood.degraded => context.sem.warning,
      FleetMood.allOffline => context.sem.danger,
      FleetMood.empty => colors.primary,
    };
    final String moodLabel = switch (mood) {
      FleetMood.allOnline => l10n.healthMoodAllOnline,
      FleetMood.degraded => l10n.healthMoodDegraded,
      FleetMood.allOffline => l10n.healthMoodAllOffline,
      FleetMood.empty => l10n.healthNoData,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Top strip: status colour + fleet ratio ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                _StatusBadge(color: accent, probing: probing),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.healthTitle,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        probing
                            ? l10n.healthProbing
                            : mood == FleetMood.empty
                                ? l10n.healthOnlineRatio(onlineCount, totalCount)
                                : moodLabel,
                        style: context.text.bodySmall?.copyWith(
                          color: mood == FleetMood.empty || probing
                              ? colors.onSurfaceVariant
                              : accent,
                          fontWeight: mood == FleetMood.empty || probing
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.healthOnlineRatio(onlineCount, totalCount),
                  style: context.text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: l10n.healthProbeTooltip,
                  onPressed: probing ? null : () => _probe(),
                  icon: probing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.monitor_heart_outlined, size: 22),
                  color: colors.primary,
                ),
              ],
            ),
          ),
          // ── Indeterminate progress while probing ────────────────────────
          if (probing)
            const LinearProgressIndicator(minHeight: 2),
          // ── Detail body ─────────────────────────────────────────────────
          if (hasSnapshot) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _HealthBody(
                snapshot: health.snapshot!,
                onlineIds: onlineIds,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.healthProbedAt(_formatClock(health.snapshot!.probedAt)),
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  SnackBarActionButton(
                    label: l10n.healthDiagnose,
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => _openAiDiagnostics(health.snapshot!),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                l10n.healthNoData,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatClock(DateTime at) {
    final String hh = at.hour.toString().padLeft(2, '0');
    final String mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ─── Status badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.probing});

  final Color color;
  final bool probing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: probing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
            )
          : Icon(Icons.dns_rounded, size: 22, color: color),
    );
  }
}

// ─── Detail body ────────────────────────────────────────────────────────────

class _HealthBody extends StatelessWidget {
  const _HealthBody({required this.snapshot, required this.onlineIds});

  final FleetHealthSnapshot snapshot;
  final Set<String> onlineIds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // A session may have dropped since the probe — reconcile so stale
    // "online" entries don't promise a shell that's gone.
    final List<ServerHealth> visibleOnline = snapshot.onlineServers
        .where((ServerHealth s) => onlineIds.contains(s.serverId))
        .toList(growable: false);
    final List<String> offlineNames = <String>[
      for (final ServerHealth s in snapshot.offlineServers) s.serverName,
    ];

    final List<Widget> rows = <Widget>[];

    for (final ServerHealth s in visibleOnline) {
      final String detail = <String>[
        if (s.uptimeBrief != null) s.uptimeBrief!,
        if (s.loadAverage != null) l10n.healthLoad(s.loadAverage!),
      ].join(' · ');
      rows.add(
        _HealthRow(
          icon: Icons.check_circle_outline_rounded,
          color: context.sem.success,
          name: s.serverName,
          detail: detail.isEmpty ? null : detail,
        ),
      );
    }

    if (offlineNames.isNotEmpty) {
      rows.add(
        _HealthRow(
          icon: Icons.cancel_outlined,
          color: context.sem.danger,
          name: l10n.healthOfflineServers(offlineNames.join(', ')),
          detail: null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
        if (visibleOnline.isNotEmpty &&
            snapshot.onlineCount > visibleOnline.length)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.healthStaleNote,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: name,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty)
                  TextSpan(
                    text: '  $detail',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallback,
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Small button with icon+label (M3 tonal) ───────────────────────────────

class SnackBarActionButton extends StatelessWidget {
  const SnackBarActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // Tinted surface + primary foreground. The app-level FilledButtonTheme
    // forces backgroundColor to scheme.primary, which would otherwise render
    // this tonal button as blue-on-blue (label invisible) — an explicit
    // background restores the intended tonal look (M3 secondaryContainer-ish).
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: colors.primary,
        backgroundColor: colors.primary.withValues(alpha: 0.10),
      ),
    );
  }
}


