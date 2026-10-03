import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/command_audit_log.dart';
import '../../../core/services/crash_report_service.dart';

/// Pure text assembler for the diagnostic report file.
///
/// Combines device metadata, the crash ring buffer and a capped summary of
/// the AI command audit trail into a single standalone `.txt` document. No
/// I/O and no Flutter dependencies — trivially unit-testable; file writing
/// lives in the diagnostics page (same split as `ChatExporter`).
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
  }) {
    final DateTime at = exportedAt ?? DateTime.now();
    final StringBuffer buffer = StringBuffer()
      ..writeln('# Shell-Mind 诊断报告')
      ..writeln()
      ..writeln('- 导出时间：${_formatTimestamp(at)}')
      ..writeln('- App 版本：${appVersion ?? AppConstants.appVersion}')
      ..writeln('- 平台：${platform ?? 'unknown'}')
      ..writeln('- 语言：${localeTag ?? 'unknown'}')
      ..writeln('- 本地数据占用：${storageBytes.isEmpty ? '—' : storageBytes}')
      ..writeln('- 捕获错误：${crashes.length} 条')
      ..writeln()
      ..writeln(_separator)
      ..writeln();

    _writeCrashes(buffer, crashes);
    _writeAudit(buffer, auditEntries);
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
  ) {
    buffer
      ..writeln('## 捕获的错误')
      ..writeln();
    if (crashes.isEmpty) {
      buffer
        ..writeln('（无）')
        ..writeln();
      return;
    }
    for (final CrashReportEntry e in crashes) {
      buffer
        ..writeln('### ${_formatTimestamp(e.occurredAt.toLocal())} · ${e.source}')
        ..writeln()
        ..writeln('- 错误摘要：${e.message}')
        ..writeln('- App 版本：${e.appVersion}')
        ..writeln('- 平台：${e.platform}')
        ..writeln('- 语言：${e.locale.isEmpty ? '—' : e.locale}')
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
  ) {
    buffer
      ..writeln('## AI 命令审计（最近 $auditSummaryLimit 条摘要）')
      ..writeln();
    if (auditEntries.isEmpty) {
      buffer
        ..writeln('（无）')
        ..writeln();
      return;
    }
    for (final CommandAuditEntry e in auditEntries.take(auditSummaryLimit)) {
      final String server =
          e.serverName.trim().isEmpty ? '?' : e.serverName;
      buffer.writeln(
        '- ${_formatTimestamp(e.executedAt.toLocal())} · '
        '$server · '
        '${e.success ? '成功' : '失败'} · '
        '退出码 ${e.exitCode} · `${e.command}`',
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
