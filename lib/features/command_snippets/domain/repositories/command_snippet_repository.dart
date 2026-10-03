import '../entities/command_snippet.dart';

/// Persistence contract for reusable shell command snippets.
///
/// Implementations back onto Hive (`command_snippets` box). The presentation
/// layer talks only to this interface so storage details stay swappable and
/// testable.
abstract interface class CommandSnippetRepository {
  /// One-shot snapshot of every snippet, newest first.
  Future<List<CommandSnippet>> getAll();

  /// Inserts [snippet] (fails softly via [AppFailure]-free contract:
  /// duplicates by id are rejected with a [StateError]).
  Future<void> add(CommandSnippet snippet);

  /// Removes the snippet with [id] (no-op when unknown).
  Future<void> remove(String id);

  /// Removes every snippet.
  Future<void> clear();
}
