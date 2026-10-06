import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_storage_service.dart';
import '../../data/command_snippet_repository_impl.dart';
import '../../domain/entities/command_snippet.dart';
import '../../domain/repositories/command_snippet_repository.dart';

/// Concrete [CommandSnippetRepository] backed by the shared Hive facade.
///
/// Overridable in tests (`ProviderContainer.overrides`).
final Provider<CommandSnippetRepository> commandSnippetRepositoryProvider =
    Provider<CommandSnippetRepository>((Ref ref) {
  return CommandSnippetRepositoryImpl(ref.watch(hiveStorageServiceProvider));
});

/// Notifier driving the snippet list surface (chat composer sheet + terminal
/// toolbar sheet). Loads from the repository once per subscription and keeps
/// the in-memory list in sync with every mutation.
class CommandSnippetsController extends AsyncNotifier<List<CommandSnippet>> {
  @override
  Future<List<CommandSnippet>> build() async {
    return ref.watch(commandSnippetRepositoryProvider).getAll();
  }

  /// Creates and persists a snippet from raw form text. Blank commands are
  /// rejected silently (the UI validates first); names are trimmed and blank
  /// names collapse to `null`. The new snippet lands at the top of the list.
  Future<void> addSnippet({
    required String command,
    String? name,
  }) async {
    final CommandSnippet? snippet =
        CommandSnippet.tryCreate(command: command, name: name);
    if (snippet == null) return;
    await ref.read(commandSnippetRepositoryProvider).add(snippet);
    await _refresh();
  }

  /// Removes the snippet with [id]. No-op when unknown.
  Future<void> removeSnippet(String id) async {
    await ref.read(commandSnippetRepositoryProvider).remove(id);
    await _refresh();
  }

  /// Bulk-imports [snippets] (already re-issued fresh ids by the transfer
  /// layer). Returns how many were actually added; a duplicate/conflicting id
  /// is skipped without failing the whole import.
  Future<int> importSnippets(List<CommandSnippet> snippets) async {
    final CommandSnippetRepository repo =
        ref.read(commandSnippetRepositoryProvider);
    int added = 0;
    for (final CommandSnippet snippet in snippets) {
      try {
        await repo.add(snippet);
        added++;
      } catch (_) {
        // Duplicate id / malformed entry — skip and continue.
      }
    }
    await _refresh();
    return added;
  }

  Future<void> _refresh() async {
    state = const AsyncValue<List<CommandSnippet>>.loading();
    state = await AsyncValue.guard(
      () => ref.read(commandSnippetRepositoryProvider).getAll(),
    );
  }
}

/// The saved-snippet list, newest first.
final AsyncNotifierProvider<CommandSnippetsController, List<CommandSnippet>>
    commandSnippetsProvider = AsyncNotifierProvider<
        CommandSnippetsController, List<CommandSnippet>>(
  CommandSnippetsController.new,
);
