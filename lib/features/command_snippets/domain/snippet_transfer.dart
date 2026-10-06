import 'dart:convert';

import '../../../core/utils/id_generator.dart';
import 'entities/command_snippet.dart';

/// Pure JSON (de)serialization for importing/exporting command snippets.
///
/// Export produces a versioned, human-readable JSON document; import parses it
/// back. Imported snippets are re-issued fresh ids so a re-import can never
/// collide with existing entries. No I/O and no credentials — the file writing
/// lives in the presentation layer (settings), mirroring the chat exporter.
abstract final class SnippetTransfer {
  /// Stable discriminator written into every export; also the gate on import.
  static const String formatTag = 'shellmind-command-snippets';

  static const int version = 1;

  /// Serialises [snippets] into a pretty-printed JSON document.
  static String encode(List<CommandSnippet> snippets, {DateTime? exportedAt}) {
    final DateTime at = exportedAt ?? DateTime.now();
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': formatTag,
      'version': version,
      'exportedAt': at.toIso8601String(),
      'items': <Map<String, dynamic>>[
        for (final CommandSnippet s in snippets)
          <String, dynamic>{
            'command': s.command,
            if (s.name != null && s.name!.trim().isNotEmpty) 'name': s.name,
            'createdAt': s.createdAt.toIso8601String(),
          },
      ],
    });
  }

  /// Parses an exported snippet document into fresh entities.
  ///
  /// Throws [FormatException] for a malformed or foreign document; malformed
  /// *items* are skipped (a single bad row never rejects the whole import).
  static List<CommandSnippet> decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Invalid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Not a valid export (expected an object).');
    }
    final Map<String, dynamic> doc = Map<String, dynamic>.from(decoded);
    if (doc['format'] != formatTag) {
      throw const FormatException('Not a ShellMind command-snippet export.');
    }
    final Object? items = doc['items'];
    if (items is! List) {
      throw const FormatException('Missing snippet items.');
    }

    final List<CommandSnippet> out = <CommandSnippet>[];
    for (final Object? raw in items) {
      if (raw is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
      final Object? command = map['command'];
      if (command is! String || command.trim().isEmpty) continue;
      final Object? name = map['name'];
      final String? validName =
          (name is String && name.trim().isNotEmpty) ? name.trim() : null;
      out.add(CommandSnippet(
        id: generateId(),
        command: command.trim(),
        name: validName,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ));
    }
    return out;
  }
}
