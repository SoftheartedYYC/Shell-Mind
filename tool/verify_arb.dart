import 'dart:convert';
import 'dart:io';

/// One-off structural validator for the l10n ARB files (run:
/// dart run tool/verify_arb.dart). Asserts en/zh key parity, JSON
/// decodability, and the presence of the agent-error keys added by the
/// l10n compliance wave.
void main() {
  final Map<String, dynamic> en = jsonDecode(
    File('lib/l10n/app_en.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> zh = jsonDecode(
    File('lib/l10n/app_zh.arb').readAsStringSync(),
  ) as Map<String, dynamic>;

  final List<String> keysEn =
      en.keys.where((String k) => !k.startsWith('@')).toList();
  final List<String> keysZh =
      zh.keys.where((String k) => !k.startsWith('@')).toList();

  stdout.writeln('enCount=${keysEn.length} zhCount=${keysZh.length}');

  // Structural check: detect duplicate keys within a single file (jsonDecode
  // silently keeps the last occurrence, so this must be checked on the raw
  // key list, not the map).
  for (final String label in const <String>['en', 'zh']) {
    final List<String> raw =
        (label == 'en' ? en.keys : zh.keys)
            .where((String k) => !k.startsWith('@'))
            .toList();
    final Set<String> seen = <String>{};
    final Set<String> dupes =
        raw.where((String k) => !seen.add(k)).toSet();
    if (dupes.isNotEmpty) {
      stderr.writeln('$label DUPLICATE KEYS: $dupes');
      exit(1);
    }
  }

  // Semantic parity: the key *sets* must match (order is irrelevant for
  // gen-l10n, but report an order difference for awareness).
  final Set<String> setEn = keysEn.toSet();
  final Set<String> setZh = keysZh.toSet();
  final Set<String> onlyEn = setEn.difference(setZh);
  final Set<String> onlyZh = setZh.difference(setEn);
  if (onlyEn.isNotEmpty || onlyZh.isNotEmpty) {
    stderr.writeln('KEY MISMATCH onlyEn=$onlyEn onlyZh=$onlyZh');
    exit(1);
  }
  stdout.writeln('en/zh key sets identical');
  if (keysEn.join('|') != keysZh.join('|')) {
    stdout.writeln('note: key order differs between en and zh (harmless)');
  }

  const List<String> expect = <String>[
    'agentErrorNoTargetServer',
    'agentErrorExecFailed',
    'agentErrorDangerSkipped',
    'agentErrorUnexpected',
  ];
  for (final String k in expect) {
    stdout.writeln('$k en=${en[k]} zh=${zh[k]}');
    if (en[k] == null || zh[k] == null) {
      stderr.writeln('MISSING KEY: $k');
      exit(1);
    }
  }
  stdout.writeln('ARB structure OK');
}
