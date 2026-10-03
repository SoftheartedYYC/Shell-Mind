import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_storage_service.dart';
import '../domain/entities/command_snippet.dart';
import '../domain/repositories/command_snippet_repository.dart';
import 'models/command_snippet_model.dart';

/// Hive-backed [CommandSnippetRepository].
///
/// Each snippet is stored under its own key in the `command_snippets` box
/// (key = snippet id, value = JSON string) so deletes are O(1) single-key
/// operations and no [TypeAdapter] registration is needed. Reads are served
/// from an in-memory snapshot refreshed on every mutation, mirroring
/// `CustomAiProviderStore`.
class CommandSnippetRepositoryImpl implements CommandSnippetRepository {
  CommandSnippetRepositoryImpl(this._hive);

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxSnippets;

  List<CommandSnippet> _cache = const <CommandSnippet>[];

  /// Current in-memory snapshot, newest first. Empty until [getAll] (or a
  /// mutation) has run.
  List<CommandSnippet> get cached => _cache;

  @override
  Future<List<CommandSnippet>> getAll() async {
    _cache = _readAllFromBox();
    return List<CommandSnippet>.unmodifiable(_cache);
  }

  @override
  Future<void> add(CommandSnippet snippet) async {
    if (_cache.any((CommandSnippet s) => s.id == snippet.id)) {
      throw StateError('Duplicate snippet id: ${snippet.id}');
    }
    final List<CommandSnippet> next = <CommandSnippet>[snippet, ..._cache];
    await _hive.put(_box, snippet.id, CommandSnippetModel.fromEntity(snippet).toJsonMap());
    _cache = next;
  }

  @override
  Future<void> remove(String id) async {
    if (!_cache.any((CommandSnippet s) => s.id == id)) return;
    final List<CommandSnippet> next =
        _cache.where((CommandSnippet s) => s.id != id).toList(growable: false);
    await _hive.delete(_box, id);
    _cache = next;
  }

  @override
  Future<void> clear() async {
    await _hive.clearBox(_box);
    _cache = const <CommandSnippet>[];
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  List<CommandSnippet> _readAllFromBox() {
    final Map<String, dynamic> raw = _hive.toMap(_box);
    final List<CommandSnippet> parsed = <CommandSnippet>[
      for (final dynamic entry in raw.values)
        if (CommandSnippetModel.fromJsonMap(entry) case final CommandSnippetModel m)
          m.toEntity(),
    ];
    parsed.sort(
        (CommandSnippet a, CommandSnippet b) => b.createdAt.compareTo(a.createdAt));
    return List<CommandSnippet>.unmodifiable(parsed);
  }
}
