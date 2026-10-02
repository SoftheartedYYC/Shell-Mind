import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../data/ssh_client_manager.dart';
import '../../data/ssh_session_repository.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/repositories/ssh_repository.dart';

/// Owns the single live [SshClientManager].
///
/// Auto-disposed: when the terminal page unmounts and nothing else watches it,
/// the manager (and thus the socket) is released. The app shows one terminal
/// at a time, so a single instance is sufficient.
final AutoDisposeProvider<SshClientManager> sshClientManagerProvider =
    Provider.autoDispose<SshClientManager>((ref) {
  final SshClientManager manager = SshClientManager();
  ref.onDispose(manager.dispose);
  return manager;
});

/// Binds the [SshRepository] contract to the `dartssh2`-backed manager.
final AutoDisposeProvider<SshRepository> sshRepositoryProvider =
    Provider.autoDispose<SshRepository>((ref) {
  return SshSessionRepository(ref.watch(sshClientManagerProvider));
});

/// Reactive SSH connection state for the terminal screen.
///
/// Mirrors the manager's [SshRepository.stateStream] into Riverpod state and
/// exposes [SshConnectionController.connect] / [disconnect] for the page.
final AutoDisposeNotifierProvider<SshConnectionController, SshConnectionState>
    sshConnectionStateProvider = NotifierProvider.autoDispose<
        SshConnectionController, SshConnectionState>(
  SshConnectionController.new,
);

class SshConnectionController extends AutoDisposeNotifier<SshConnectionState> {
  /// Server id of the session this controller currently owns, used to
  /// unregister from the global [SshSessionRegistry] on disconnect/dispose.
  String? _activeServerId;

  @override
  SshConnectionState build() {
    final SshRepository repo = ref.watch(sshRepositoryProvider);
    final StreamSubscription<SshConnectionState> sub =
        repo.stateStream.listen((SshConnectionState next) => state = next);
    ref.onDispose(sub.cancel);
    // Safety net: if the terminal page is torn down without an explicit
    // disconnect, drop our registry entry so no stale session lingers. The
    // registry's own state-stream watcher usually beats this, but the two are
    // idempotent.
    ref.onDispose(() {
      final String? id = _activeServerId;
      if (id != null) {
        ref.read(sshSessionRegistryProvider.notifier).unregister(id);
      }
    });
    return repo.currentState;
  }

  /// Resolves [config]'s stored credential and opens an interactive shell.
  ///
  /// State transitions are driven by the repository's stream; this method only
  /// gathers secrets and kicks the attempt off, surfacing credential problems
  /// (missing password/key) directly as an error state.
  Future<void> connect(
    ServerConfig config, {
    int width = 80,
    int height = 24,
  }) async {
    final SshRepository repo = ref.read(sshRepositoryProvider);
    final SecureStorageService secure = ref.read(secureStorageServiceProvider);

    // Optimistic paint so the spinner shows before the first stream event.
    state = SshConnectionState.connecting(serverName: config.name);

    String? password;
    String? privateKey;
    String? passphrase;

    if (config.authType == AuthType.password) {
      password = await secure.getPassword(config.id);
      if (password == null || password.isEmpty) {
        state = SshConnectionState.error(
          message: 'No password stored for "${config.name}". '
              'Edit the server to add one.',
          serverName: config.name,
          failureKind: FailureKind.auth.name,
        );
        return;
      }
    } else {
      privateKey = await secure.getPrivateKey(config.id);
      passphrase = await secure.getPassphrase(config.id);
      if (privateKey == null || privateKey.trim().isEmpty) {
        state = SshConnectionState.error(
          message: 'No private key stored for "${config.name}". '
              'Edit the server to add one.',
          serverName: config.name,
          failureKind: FailureKind.auth.name,
        );
        return;
      }
    }

    final Result<void> result = await repo.connect(
      host: config.host,
      port: config.port,
      username: config.username,
      serverName: config.name,
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
      width: width,
      height: height,
    );

    await result.when(
      success: (_) async {
        // Publish the live session to the global registry so other modules
        // (e.g. the AI assistant) can discover and run commands on it.
        _activeServerId = config.id;
        ref.read(sshSessionRegistryProvider.notifier).register(
              config.id,
              ref.read(sshClientManagerProvider),
              config,
            );
        // Stamp lastConnectedAt so the fleet list reflects the fresh session.
        await ref
            .read(serverConfigListProvider.notifier)
            .markConnected(config.id);
      },
      failure: (AppFailure failure) async {
        // The manager already emitted an error state; this is a safety net for
        // failures raised before any emission (e.g. credential guard above).
        if (!state.isConnected) {
          state = SshConnectionState.error(
            message: failure.message,
            serverName: config.name,
            failureKind: failure.kind.name,
          );
        }
      },
    );
  }

  /// Tears the shell down and returns to the idle state.
  Future<void> disconnect() {
    // Drop the registry entry eagerly; the manager's state stream will also
    // emit `disconnected`, but unregistering here keeps the two in lockstep
    // and makes the intent explicit.
    final String? id = _activeServerId;
    if (id != null) {
      ref.read(sshSessionRegistryProvider.notifier).unregister(id);
      _activeServerId = null;
    }
    return ref.read(sshRepositoryProvider).disconnect();
  }
}
