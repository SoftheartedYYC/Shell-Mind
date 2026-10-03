import 'package:flutter/foundation.dart';

import '../../domain/entities/command_snippet.dart';

/// Hive persistence mapping for [CommandSnippet].
///
/// The entry lives as a JSON string inside the `command_snippets` box (one key
/// per snippet, key = snippet id) — no [TypeAdapter] registration required,
/// mirroring `CustomAiProvider` / `ChatHistoryStore`. [fromJsonMap] is
/// tolerant: any malformed frame decodes to `null` so a corrupt entry can
/// never crash a list rebuild.
@immutable
class CommandSnippetModel {
  const CommandSnippetModel._(this._entity);

  /// Wraps a domain entity for persistence.
  factory CommandSnippetModel.fromEntity(CommandSnippet entity) =>
      CommandSnippetModel._(entity);

  /// Decodes a persisted JSON map produced by [toJsonMap]. Returns `null`
  /// for malformed frames (wrong types, blank command, unparsable date).
  static CommandSnippetModel? fromJsonMap(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    final Object? command = raw['command'];
    if (id is! String || id.isEmpty) return null;
    if (command is! String || command.trim().isEmpty) return null;

    DateTime createdAt;
    final Object? ts = raw['createdAt'];
    if (ts is String) {
      final DateTime? parsed = DateTime.tryParse(ts);
      if (parsed == null) return null;
      createdAt = parsed;
    } else {
      // Missing or non-string timestamp — reject rather than invent one.
      return null;
    }

    final Object? name = raw['name'];
    final String? validName =
        (name is String && name.trim().isNotEmpty) ? name.trim() : null;

    return CommandSnippetModel._(
      CommandSnippet(
        id: id,
        command: command,
        name: validName,
        createdAt: createdAt,
      ),
    );
  }

  final CommandSnippet _entity;

  String get id => _entity.id;
  String get command => _entity.command;
  String? get name => _entity.name;
  DateTime get createdAt => _entity.createdAt;

  /// Unwraps back to the domain entity.
  CommandSnippet toEntity() => _entity;

  Map<String, Object?> toJsonMap() => <String, Object?>{
        'id': _entity.id,
        'command': _entity.command,
        if (_entity.name != null) 'name': _entity.name,
        'createdAt': _entity.createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is CommandSnippetModel && other._entity == _entity;

  @override
  int get hashCode => _entity.hashCode;

  @override
  String toString() => 'CommandSnippetModel(${_entity.id})';
}
