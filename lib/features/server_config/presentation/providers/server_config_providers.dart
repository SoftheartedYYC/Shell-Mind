import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/server_config_repository_impl.dart';
import '../../domain/entities/server_config.dart';
import '../../domain/repositories/server_config_repository.dart';

/// Wires the [ServerConfigRepository] contract to its Hive-backed impl.
///
/// Depends only on the two storage singletons (already overridden in
/// `main()`), so swapping in fakes for tests is a matter of overriding those.
final Provider<ServerConfigRepository> serverConfigRepositoryProvider =
    Provider<ServerConfigRepository>((ref) {
  final HiveStorageService hive = ref.watch(hiveStorageServiceProvider);
  final SecureStorageService secure = ref.watch(secureStorageServiceProvider);
  return ServerConfigRepositoryImpl(hive, secure);
});

/// Raw, live feed of the fleet straight from the Hive box watcher.
///
/// Emits the current list immediately, then on every mutation. Lightweight
/// consumers that only need to *observe* (e.g. a count badge elsewhere in the
/// app) can watch this directly without pulling in the controller.
final StreamProvider<List<ServerConfig>> serverConfigListStreamProvider =
    StreamProvider<List<ServerConfig>>((ref) {
  final ServerConfigRepository repo = ref.watch(serverConfigRepositoryProvider);
  return repo.watchAll();
});

/// Primary fleet controller: seeds from disk, mirrors live box changes, and
/// exposes CRUD mutations that also manage the secure-keystore credentials.
final AsyncNotifierProvider<ServerConfigListController, List<ServerConfig>>
    serverConfigListProvider =
    AsyncNotifierProvider<ServerConfigListController, List<ServerConfig>>(
  ServerConfigListController.new,
);

class ServerConfigListController extends AsyncNotifier<List<ServerConfig>> {
  @override
  Future<List<ServerConfig>> build() async {
    final ServerConfigRepository repo =
        ref.watch(serverConfigRepositoryProvider);

    // Seed synchronously from the already-open box …
    final List<ServerConfig> seeded = await repo.getAll();

    // … then keep this notifier's state glued to the live box stream so any
    // write (from here, or another isolate/route) is reflected instantly.
    ref.listen<AsyncValue<List<ServerConfig>>>(
      serverConfigListStreamProvider,
      (previous, next) {
        if (next.hasValue) {
          state = AsyncData(next.requireValue);
        }
      },
    );

    return seeded;
  }

  // ─── Queries ────────────────────────────────────────────────────────────

  /// Synchronous lookup against the currently-loaded list.
  ServerConfig? byId(String id) {
    final List<ServerConfig>? list = state.valueOrNull;
    if (list == null) return null;
    for (final ServerConfig config in list) {
      if (config.id == id) return config;
    }
    return null;
  }

  /// Resolves a config by id — in-memory first, disk as a fallback (useful
  /// when the edit route is deep-linked before the list has loaded).
  Future<ServerConfig?> resolveById(String id) async {
    final ServerConfig? cached = byId(id);
    if (cached != null) return cached;
    return ref.read(serverConfigRepositoryProvider).getById(id);
  }

  /// Whether a secret already exists for [id] under [type]. Lets the edit
  /// form offer "leave blank to keep" instead of forcing a re-entry.
  Future<bool> hasStoredCredential(String id, AuthType type) async {
    final SecureStorageService secure = ref.read(secureStorageServiceProvider);
    final String? secret = type == AuthType.password
        ? await secure.getPassword(id)
        : await secure.getPrivateKey(id);
    return secret != null && secret.isNotEmpty;
  }

  // ─── Mutations ──────────────────────────────────────────────────────────

  /// Inserts or updates [config] and reconciles its stored credential.
  ///
  /// Credential strings are optional: pass a non-empty value to (re)set it,
  /// or omit/leave blank to keep whatever is already stored. When the auth
  /// type changes, the previous type's secret is purged so stale material
  /// never lingers in the keystore.
  Future<Result<void>> saveServer({
    required ServerConfig config,
    String? password,
    String? privateKey,
    String? passphrase,
  }) {
    return Result.guard<void>(() async {
      final ServerConfigRepository repo =
          ref.read(serverConfigRepositoryProvider);
      final SecureStorageService secure =
          ref.read(secureStorageServiceProvider);

      final ServerConfig? existing = await repo.getById(config.id);
      final bool authChanged =
          existing != null && existing.authType != config.authType;

      if (config.authType == AuthType.password) {
        if (password != null && password.isNotEmpty) {
          await secure.savePassword(config.id, password);
        }
        if (authChanged) {
          await secure.deletePrivateKey(config.id);
          await secure.deletePassphrase(config.id);
        }
      } else {
        if (privateKey != null && privateKey.isNotEmpty) {
          await secure.savePrivateKey(config.id, privateKey);
        }
        if (passphrase != null && passphrase.isNotEmpty) {
          await secure.savePassphrase(config.id, passphrase);
        } else if (authChanged) {
          await secure.deletePassphrase(config.id);
        }
        if (authChanged) {
          await secure.deletePassword(config.id);
        }
      }

      await repo.save(config);
      await _reload();
    });
  }

  /// Deletes the config and its secrets.
  ///
  /// Removal is applied optimistically (synchronously) so swipe-to-dismiss
  /// gestures stay in lock-step with the list, then reconciled from disk.
  Future<Result<void>> deleteServer(String id) {
    final List<ServerConfig>? current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(<ServerConfig>[
        for (final ServerConfig config in current)
          if (config.id != id) config,
      ]);
    }
    return Result.guard<void>(() async {
      await ref.read(serverConfigRepositoryProvider).delete(id);
      await _reload();
    });
  }

  /// Stamps `lastConnectedAt = now` (called when a session is opened).
  Future<Result<void>> markConnected(String id) {
    return Result.guard<void>(() async {
      await ref.read(serverConfigRepositoryProvider).updateLastConnected(id);
      await _reload();
    });
  }

  /// Manual pull-to-refresh — re-reads from disk.
  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    final ServerConfigRepository repo =
        ref.read(serverConfigRepositoryProvider);
    state = AsyncData(await repo.getAll());
  }
}
