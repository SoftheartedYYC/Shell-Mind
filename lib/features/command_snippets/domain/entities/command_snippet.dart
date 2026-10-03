import 'package:flutter/foundation.dart';

import '../../../../core/utils/id_generator.dart';

/// A reusable shell command the user saved for quick re-use.
///
/// Pure domain object: no persistence details. [command] is the raw text
/// sent to the shell (or pre-filled into the chat composer); [name] is an
/// optional human label shown in lists, falling back to the command itself
/// when absent.
@immutable
class CommandSnippet {
  const CommandSnippet({
    required this.id,
    required this.command,
    this.name,
    required this.createdAt,
  });

  /// Creates a brand-new snippet with a freshly minted UUID and a
  /// `createdAt` stamp. Used by the add-snippet form.
  factory CommandSnippet.create({
    required String command,
    String? name,
  }) {
    return CommandSnippet(
      id: generateId(),
      command: command,
      name: name,
      createdAt: DateTime.now(),
    );
  }

  /// Stable unique key (UUID) — survives restarts and re-ordering.
  final String id;

  /// The raw command text. Never empty on a valid snippet.
  final String command;

  /// Optional display label; `null` means "show the command itself".
  final String? name;

  /// Wall-clock creation time — drives "newest first" list ordering.
  final DateTime createdAt;

  /// The label to render in a list row: the name when set, else the command.
  String get displayLabel =>
      (name != null && name!.trim().isNotEmpty) ? name! : command;

  /// Defensive constructor helper: `null` for blank/invalid input so callers
  /// can build directly from form text without pre-validation.
  static CommandSnippet? tryCreate({
    required String command,
    String? name,
  }) {
    final String trimmed = command.trim();
    if (trimmed.isEmpty) return null;
    final String? trimmedName = (name == null || name.trim().isEmpty)
        ? null
        : name.trim();
    return CommandSnippet.create(command: trimmed, name: trimmedName);
  }

  CommandSnippet copyWith({
    String? id,
    String? command,
    String? name,
    bool clearName = false,
    DateTime? createdAt,
  }) =>
      CommandSnippet(
        id: id ?? this.id,
        command: command ?? this.command,
        name: clearName ? null : (name ?? this.name),
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      other is CommandSnippet &&
      other.id == id &&
      other.command == command &&
      other.name == name &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, command, name, createdAt);

  @override
  String toString() => 'CommandSnippet($id, ${displayLabel.length} chars)';
}
