import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/entities/server_config.dart';
import '../domain/repositories/server_config_repository.dart';
import 'models/server_config_model.dart';

/// Hive-backed implementation of [ServerConfigRepository].
///
/// Server *metadata* lives in the `servers` box as [ServerConfigModel]s keyed
/// by their UUID; *secrets* never touch this box and are purged through
/// [SecureStorageService] on delete. Because the box is opened as
/// `Box<dynamic>`, [watchAll] simply re-reads and re-maps on every frame
/// event, giving the UI a live, ordered list.
class ServerConfigRepositoryImpl implements ServerConfigRepository {
  ServerConfigRepositoryImpl(this._hive, this._secure);

  final HiveStorageService _hive;
  final SecureStorageService _secure;

  static const String _box = AppConstants.hiveBoxServers;

  @override
  Future<List<ServerConfig>> getAll() async => _readAll();

  @override
  Stream<List<ServerConfig>> watchAll() async* {
    // Seed immediately so watchers never wait for the first mutation.
    yield _readAll();
    // Then re-emit on every box change (put/delete/clear).
    yield* _hive.watch(_box).map((_) => _readAll());
  }

  @override
  Future<ServerConfig?> getById(String id) async {
    final ServerConfigModel? model = _hive.get<ServerConfigModel>(_box, id);
    return model?.toEntity();
  }

  @override
  Future<void> save(ServerConfig config) {
    return _hive.put(
      _box,
      config.id,
      ServerConfigModel.fromEntity(config),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _hive.delete(_box, id);
    // Best-effort credential cleanup — metadata removal is the source of
    // truth for the list, so a keystore hiccup must not block the delete.
    await _secure.purgeServer(id);
  }

  @override
  Future<void> updateLastConnected(String id) async {
    final ServerConfigModel? model = _hive.get<ServerConfigModel>(_box, id);
    if (model == null) return;
    final ServerConfig updated = model
        .toEntity()
        .copyWith(lastConnectedAt: DateTime.now());
    await _hive.put(_box, id, ServerConfigModel.fromEntity(updated));
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  List<ServerConfig> _readAll() {
    final List<ServerConfig> configs = _hive
        .getAll<ServerConfigModel>(_box)
        .map((ServerConfigModel m) => m.toEntity())
        .toList();
    configs.sort(_compareForDisplay);
    return configs;
  }

  /// Display ordering: grouped servers first (alphabetical by group), then
  /// ungrouped; within a bucket, alphabetical by name (case-insensitive).
  static int _compareForDisplay(ServerConfig a, ServerConfig b) {
    final String? ga = a.group;
    final String? gb = b.group;

    if (ga == null && gb != null) return 1;
    if (ga != null && gb == null) return -1;
    if (ga != null && gb != null) {
      final int byGroup = ga.toLowerCase().compareTo(gb.toLowerCase());
      if (byGroup != 0) return byGroup;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
