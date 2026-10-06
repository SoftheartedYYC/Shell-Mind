import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/command_audit_log.dart';
import '../../../core/services/crash_report_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_en.dart';

/// Pure text assembler for the diagnostic report file.
///
/// Combines device metadata, the crash ring buffer and a capped summary of
/// the AI command audit trail into a single standalone `.txt` document.
/// All natural-language labels come from [AppLocalizations] so the report
/// follows the app language; [l10n] is optional — callers without a context
/// (pure data / tests) may omit it and the report falls back to the English
/// wordings. No I/O and no Flutter dependency lookups — trivially
/// unit-testable; file writing lives in the diagnostics page.
class DiagnosticExporter {
  const DiagnosticExporter._();

  /// Number of audit-log entries summarised in the report.
  static const int auditSummaryLimit = 20;

  /// Renders the diagnostic report.
  ///
  /// [exportedAt] overrides the header timestamp (defaults to now) — inject
  /// a fixed value in tests for deterministic output. [storageBytes] is the
  /// app's on-disk Hive footprint (already formatted by the caller); pass an
  /// empty string when the platform plugin is unavailable.
  static String export({
    required List<CrashReportEntry> crashes,
    required List<CommandAuditEntry> auditEntries,
    String? appVersion,
    String? platform,
    String? localeTag,
    String storageBytes = '',
    DateTime? exportedAt,
    AppLocalizations? l10n,
  }) {
    final AppLocalizations doc = l10n ?? AppLocalizationsEn();
    final DateTime at = exportedAt ?? DateTime.now();
    final StringBuffer buffer = StringBuffer()
      ..writeln('# ${doc.exportDocDiagTitle}')
      ..writeln()
      ..writeln('- ${doc.exportDocExportedAt(_formatTimestamp(at))}')
      ..writeln('- ${doc.exportDocDiagAppVersion(appVersion ?? AppConstants.appVersion)}')
      ..writeln('- ${doc.exportDocDiagPlatform(platform ?? 'unknown')}')
      ..writeln('- ${doc.exportDocDiagLocale(localeTag ?? 'unknown')}')
      ..writeln('- ${doc.exportDocDiagStorage(storageBytes.isEmpty ? '—' : storageBytes)}')
      ..writeln('- ${doc.exportDocDiagCrashCount(crashes.length)}')
      ..writeln()
      ..writeln(_separator)
      ..writeln();

    _writeCrashes(buffer, crashes, doc);
    _writeAudit(buffer, auditEntries, doc);
    return buffer.toString();
  }

  /// Filesystem-safe compact stamp: `yyyyMMdd-HHmmss` (used in export file
  /// names, e.g. `shell-mind-diagnostic-20261004-153005.txt`).
  static String fileStamp(DateTime time) {
    String p(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${p(time.year, 4)}${p(time.month)}${p(time.day)}'
        '-${p(time.hour)}${p(time.minute)}${p(time.second)}';
  }

  /// Locale-independent `yyyy-MM-dd HH:mm:ss`.
  static String _formatTimestamp(DateTime time) {
    String p(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${p(time.year, 4)}-${p(time.month)}-${p(time.day)} '
        '${p(time.hour)}:${p(time.minute)}:${p(time.second)}';
  }

  static void _writeCrashes(
    StringBuffer buffer,
    List<CrashReportEntry> crashes,
    AppLocalizations doc,
  ) {
    buffer
      ..writeln('## ${doc.exportDocDiagCrashesSection}')
      ..writeln();
    if (crashes.isEmpty) {
      buffer
        ..writeln(doc.exportDocDiagNone)
        ..writeln();
      return;
    }
    for (final CrashReportEntry e in crashes) {
      buffer
        ..writeln('### ${_formatTimestamp(e.occurredAt.toLocal())} · ${e.source}')
        ..writeln()
        ..writeln('- ${doc.exportDocDiagErrorMessage(e.message)}')
        ..writeln('- ${doc.exportDocDiagAppVersion(e.appVersion)}')
        ..writeln('- ${doc.exportDocDiagPlatform(e.platform)}')
        ..writeln('- ${doc.exportDocDiagLocale(e.locale.isEmpty ? '—' : e.locale)}')
        ..writeln();
      if (e.stackTrace.isNotEmpty) {
        buffer
          ..writeln('```')
          ..writeln(e.stackTrace)
          ..writeln('```')
          ..writeln();
      }
    }
  }

  static void _writeAudit(
    StringBuffer buffer,
    List<CommandAuditEntry> auditEntries,
    AppLocalizations doc,
  ) {
    buffer
      ..writeln('## ${doc.exportDocDiagAuditSection(auditSummaryLimit)}')
      ..writeln();
    if (auditEntries.isEmpty) {
      buffer
        ..writeln(doc.exportDocDiagNone)
        ..writeln();
      return;
    }
    for (final CommandAuditEntry e in auditEntries.take(auditSummaryLimit)) {
      final String server =
          e.serverName.trim().isEmpty ? '?' : e.serverName;
      buffer.writeln(
        '- ${_formatTimestamp(e.executedAt.toLocal())} · '
        '$server · '
        '${e.success ? doc.exportDocDiagSuccess : doc.exportDocDiagFailed} · '
        '${doc.exportDocDiagExitCodeOf(e.exitCode)} · `${e.command}`',
      );
    }
    buffer.writeln();
  }

  static const String _separator =
      '——————————————————————————————————————';
}

/// Riverpod provider that assembles the diagnostic report from the live
/// crash ring buffer and audit trail snapshots.
final Provider<String> diagnosticReportProvider = Provider<String>((Ref ref) {
  final List<CrashReportEntry> crashes = ref.watch(crashReportNotifierProvider);
  final List<CommandAuditEntry> audit =
      ref.watch(commandAuditNotifierProvider);
  return DiagnosticExporter.export(
    crashes: crashes,
    auditEntries: audit,
    appVersion: ref.watch(crashReportServiceProvider).currentAppVersion,
    platform: ref.watch(crashReportServiceProvider).currentPlatform,
    localeTag: ref.watch(crashReportServiceProvider).currentLocale,
  );
});
