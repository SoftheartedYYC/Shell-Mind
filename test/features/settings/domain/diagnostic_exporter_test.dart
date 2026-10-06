import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/services/command_audit_log.dart';
import 'package:shell_mind/core/services/crash_report_service.dart';
import 'package:shell_mind/features/settings/domain/diagnostic_exporter.dart';
import 'package:shell_mind/l10n/app_localizations.dart';
import 'package:shell_mind/l10n/app_localizations_en.dart';
import 'package:shell_mind/l10n/app_localizations_zh.dart';

CrashReportEntry _crash({
  String id = 'c1',
  String message = 'StateError: bad state',
  String stack = ' #0 main (package:shell_mind/main.dart:1)',
  String source = 'flutter',
  DateTime? when,
}) =>
    CrashReportEntry(
      id: id,
      source: source,
      message: message,
      stackTrace: stack,
      appVersion: '1.4.1',
      platform: 'android',
      locale: 'zh_CN',
      occurredAt: when ?? DateTime(2026, 10, 4, 12, 30, 5),
    );

CommandAuditEntry _audit({
  String id = 'a1',
  String command = 'df -h /',
  int exitCode = 0,
  DateTime? when,
}) =>
    CommandAuditEntry(
      id: id,
      command: command,
      serverId: 'srv-1',
      serverName: 'web-1',
      exitCode: exitCode,
      success: exitCode == 0,
      mode: CommandAuditMode.auto,
      executedAt: when ?? DateTime(2026, 10, 4, 12, 0, 0),
      elapsed: const Duration(milliseconds: 120),
      hasDangerous: false,
      hasOutput: false,
    );

void main() {
  // Export through the Chinese report wordings so assertions keep matching
  // the (byte-identical) pre-l10n hardcoded strings.
  final AppLocalizations zh = AppLocalizationsZh();

  String exportReport({
    List<CrashReportEntry> crashes = const <CrashReportEntry>[],
    List<CommandAuditEntry> auditEntries = const <CommandAuditEntry>[],
    String? appVersion,
    String? platform,
    String? localeTag,
    String storageBytes = '',
    DateTime? exportedAt,
  }) =>
      DiagnosticExporter.export(
        crashes: crashes,
        auditEntries: auditEntries,
        appVersion: appVersion,
        platform: platform,
        localeTag: localeTag,
        storageBytes: storageBytes,
        exportedAt: exportedAt,
        l10n: zh,
      );

  group('DiagnosticExporter.fileStamp', () {
    test('formats yyyyMMdd-HHmmss with zero padding', () {
      final String stamp = DiagnosticExporter.fileStamp(
          DateTime(2026, 1, 2, 3, 4, 5));
      expect(stamp, '20260102-030405');
    });
  });

  group('DiagnosticExporter.export', () {
    test('empty inputs still produce a valid header', () {
      final String report = exportReport(
        crashes: const <CrashReportEntry>[],
        auditEntries: const <CommandAuditEntry>[],
        appVersion: '1.4.1',
        platform: 'android',
        localeTag: 'zh_CN',
        storageBytes: '12.0 KB',
        exportedAt: DateTime(2026, 10, 4, 12, 30, 5),
      );

      expect(report, contains('# Shell-Mind'));
      expect(report, contains('1.4.1'));
      expect(report, contains('android'));
      expect(report, contains('zh_CN'));
      expect(report, contains('12.0 KB'));
      expect(report, contains('2026-10-04 12:30:05'));
    });

    test('renders crash entries with timestamps and stack fences', () {
      final String report = exportReport(
        crashes: <CrashReportEntry>[
          _crash(id: 'c1', source: 'platform'),
          _crash(id: 'c2', stack: ''),
        ],
        auditEntries: const <CommandAuditEntry>[],
        exportedAt: DateTime(2026, 10, 4),
      );

      expect(report, contains('StateError: bad state'));
      expect(report, contains('2026-10-04 12:30:05'));
      expect(report, contains('platform'));
      // Non-empty stack is fenced, empty stack renders no fence for c2.
      expect(report, contains(' #0 main (package:shell_mind/main.dart:1)'));
    });

    test('summaries at most 20 audit entries', () {
      final List<CommandAuditEntry> entries = <CommandAuditEntry>[
        for (int i = 0; i < 30; i++)
          _audit(id: 'a$i', command: 'cmd-$i', when: DateTime(2026, 10, i + 1)),
      ];
      final String report = exportReport(
        crashes: const <CrashReportEntry>[],
        auditEntries: entries,
      );

      expect(report, contains('cmd-0'));
      // 30 entries capped to the first 20 (cmd-0 .. cmd-19).
      expect(report, contains('cmd-19'));
      expect(report, isNot(contains('cmd-29')));
      expect(report, isNot(contains('cmd-25')));
    });

    test('crash entries already carry redacted text end-to-end', () {
      // The service redacts at record time; the exporter must not need to
      // re-scrub. This test documents the contract with a pre-redacted entry.
      final CrashReportEntry entry = _crash(
        message: CrashReportEntry.redact('Failed with key sk-abcdef123456'),
        stack: CrashReportEntry.redact(
            '-----BEGIN PRIVATE KEY-----\nMIIEvQ\n-----END PRIVATE KEY-----'),
      );
      final String report = exportReport(
        crashes: <CrashReportEntry>[entry],
        auditEntries: const <CommandAuditEntry>[],
      );

      expect(report, contains('[REDACTED]'));
      expect(report, isNot(contains('sk-abcdef123456')));
      expect(report, isNot(contains('MIIEvQ')));
    });

    test('audit lines include server name, outcome and exit code', () {
      final String report = exportReport(
        crashes: const <CrashReportEntry>[],
        auditEntries: <CommandAuditEntry>[_audit(exitCode: 2)],
      );

      expect(report, contains('df -h /'));
      expect(report, contains('web-1'));
      expect(report, contains('2'));
    });

    test('English l10n renders English report labels', () {
      final String report = DiagnosticExporter.export(
        crashes: const <CrashReportEntry>[],
        auditEntries: <CommandAuditEntry>[_audit(exitCode: 2)],
        appVersion: '1.4.1',
        platform: 'android',
        localeTag: 'zh_CN',
        exportedAt: DateTime(2026, 10, 4, 12, 30, 5),
        l10n: AppLocalizationsEn(),
      );
      expect(report, startsWith('# Shell-Mind Diagnostic Report'));
      expect(report, contains('- Exported at: 2026-10-04 12:30:05'));
      expect(report, contains('- App version: 1.4.1'));
      expect(report, contains('- Captured errors: 0'));
      expect(report, contains('## AI command audit'));
      expect(report, contains('exit code 2'));
      expect(report, isNot(contains('诊断报告')));
      expect(report, isNot(contains('导出时间')));
      expect(report, isNot(contains('命令审计')));
    });

    test('omitting l10n falls back to the English wordings', () {
      final String report = DiagnosticExporter.export(
        crashes: const <CrashReportEntry>[],
        auditEntries: const <CommandAuditEntry>[],
      );
      expect(report, startsWith('# Shell-Mind Diagnostic Report'));
      expect(report, isNot(contains('本地数据占用')));
      expect(report, contains('- Local data usage: —'));
    });
  });
}
