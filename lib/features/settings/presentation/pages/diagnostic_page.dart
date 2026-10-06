import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/command_audit_log.dart';
import '../../../../core/services/crash_report_service.dart';
import '../../../../core/services/storage_inspector.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/diagnostic_exporter.dart';

/// Full-screen diagnostics page: captured errors (expandable stack traces),
/// app info and a "Export diagnostic report" action writing a redacted
/// `.txt` bundle to `<docs>/exports/`.
///
/// Reads the live [crashReportNotifierProvider] snapshot; mirrors the visual
/// language of [AuditLogPage] so both diagnostic surfaces feel like siblings.
class DiagnosticPage extends ConsumerStatefulWidget {
  const DiagnosticPage({super.key});

  @override
  ConsumerState<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends ConsumerState<DiagnosticPage> {
  final Set<String> _expanded = <String>{};
  bool _exporting = false;

  Future<void> _export() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final CrashReportService crash = ref.read(crashReportServiceProvider);
      final CacheBreakdown storage =
          await ref.read(storageInspectorProvider).inspect();

      // Format the storage figure with the shared helper before handing it
      // to the (pure) exporter so the whole file assembly stays testable.
      final String report = DiagnosticExporter.export(
        crashes: crash.all,
        auditEntries: ref.read(commandAuditLogProvider).all,
        appVersion: crash.currentAppVersion,
        platform: crash.currentPlatform,
        localeTag: crash.currentLocale,
        storageBytes: formatBytes(storage.hiveBytes),
        l10n: l10n,
      );

      final DateTime now = DateTime.now();
      final String fileName =
          'shell-mind-diagnostic-${DiagnosticExporter.fileStamp(now)}.txt';

      final Directory dir = await getApplicationDocumentsDirectory();
      final Directory exportDir = Directory(
        '${dir.path}${Platform.pathSeparator}exports',
      );
      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }
      final File file = File(
        '${exportDir.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsString(report, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.diagExportSuccess(file.path)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.diagExportFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmClear() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int count = ref.read(crashReportNotifierProvider).length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.diagClearConfirmTitle),
        content: Text(l10n.diagClearConfirmMessage(count)),
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
            child: Text(l10n.diagClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(crashReportNotifierProvider.notifier).clearAll();
    if (!mounted) return;
    setState(_expanded.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.diagCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CrashReportEntry> crashes =
        ref.watch(crashReportNotifierProvider);
    final CrashReportService service = ref.watch(crashReportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagTitle),
        actions: <Widget>[
          IconButton(
            onPressed: crashes.isEmpty ? null : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.diagClearTooltip,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ─── Export bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.diagExportAction),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.diagPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // ─── App info card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _AppInfoCard(
              version: service.currentAppVersion,
              platform: service.currentPlatform,
              locale: service.currentLocale,
            ),
          ),
          // ─── Error list ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              l10n.diagEntriesCount(crashes.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: crashes.isEmpty
                ? EmptyState(
                    icon: Icons.bug_report_outlined,
                    title: l10n.diagEmptyTitle,
                    message: l10n.diagEmptyMessage,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                    itemCount: crashes.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _CrashCard(
                      entry: crashes[index],
                      expanded: _expanded.contains(crashes[index].id),
                      onToggle: () => setState(() {
                        final String id = crashes[index].id;
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

// ─── App info card ─────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({
    required this.version,
    required this.platform,
    required this.locale,
  });

  final String version;
  final String platform;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.diagAppInfoTitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 8),
          _row(context, l10n.diagAppInfoVersion, version, colors),
          _row(context, l10n.diagAppInfoPlatform,
              platform.isEmpty ? '—' : platform, colors),
          _row(context, l10n.diagAppInfoLocale,
              locale.isEmpty ? '—' : locale, colors),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, ColorScheme colors) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallback,
                      color: colors.onSurface,
                    ),
              ),
            ),
          ],
        ),
      );
}

// ─── Crash card ────────────────────────────────────────────────────────────

class _CrashCard extends StatelessWidget {
  const _CrashCard({
    required this.entry,
    required this.expanded,
    required this.onToggle,
  });

  final CrashReportEntry entry;
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
                      _formatTimestamp(entry.occurredAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    const Spacer(),
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
                  entry.message,
                  maxLines: expanded ? null : 3,
                  overflow:
                      expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _SourceBadge(source: entry.source),
                    Text(
                      'v${entry.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: AppTheme.monoFallback,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
                if (expanded) ...<Widget>[
                  const SizedBox(height: 10),
                  if (entry.stackTrace.isNotEmpty) ...<Widget>[
                    Text(
                      l10n.diagStackTrace,
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
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.stackTrace,
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
                      l10n.diagNoStackTrace,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Source badge ──────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color tint = switch (source) {
      'platform' => colors.tertiary,
      'zone' => colors.secondary,
      _ => colors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        switch (source) {
          'platform' => l10n.diagSourcePlatform,
          'zone' => l10n.diagSourceZone,
          _ => l10n.diagSourceFlutter,
        },
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
