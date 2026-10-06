import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../data/ssh_client_manager.dart';
import '../../domain/entities/connection_state.dart';

// ─── Per-server family providers (read from registry) ─────────────────────

/// The [SshClientManager] for a given server, sourced from the global registry.
///
/// Returns `null` when the server is not currently connected. The terminal page
/// and any other consumer should watch this to react to sessions appearing or
/// disappearing.
final ProviderFamily<SshClientManager?, String>
    sshClientManagerForServerProvider =
    Provider.family<SshClientManager?, String>((Ref ref, String serverId) {
  final Map<String, RegisteredSession> sessions =
      ref.watch(sshSessionRegistryProvider);
  return sessions[serverId]?.manager;
});

// ─── Connection controller ────────────────────────────────────────────────

/// Reactive SSH connection state for the terminal screen.
///
/// Delegates all connection lifecycle to the global [SshSessionRegistry].
/// The controller is "attached" to a specific serverId by the terminal page;
/// it mirrors that server's manager state stream into Riverpod state so the
/// UI can react to transitions (connecting → connected → error/disconnected).
///
/// Non-autoDispose: survives navigation so the state remains consistent when
/// the user returns to a still-live terminal session.
final NotifierProvider<SshConnectionController, SshConnectionState>
    sshConnectionStateProvider =
    NotifierProvider<SshConnectionController, SshConnectionState>(
  SshConnectionController.new,
);

class SshConnectionController extends Notifier<SshConnectionState> {
  /// Server id this controller is currently monitoring.
  String? _activeServerId;

  /// Subscription to the active server's manager state stream.
  StreamSubscription<SshConnectionState>? _stateSub;

  @override
  SshConnectionState build() {
    ref.onDispose(() {
      unawaited(_stateSub?.cancel());
      _stateSub = null;
    });
    return const SshConnectionState.disconnected();
  }

  /// Attaches this controller to the session for [serverId] (if any) and
  /// starts mirroring its state. Called by the terminal page on init so
  /// an already-live session is immediately reflected in the UI.
  ///
  /// If no session exists for [serverId], state resets to disconnected.
  void attach(String serverId) {
    _activeServerId = serverId;
    unawaited(_stateSub?.cancel());
    _stateSub = null;

    final RegisteredSession? session =
        ref.read(sshSessionRegistryProvider)[serverId];
    if (session != null) {
      state = session.manager.currentState;
      _stateSub = session.manager.stateStream.listen(
        (SshConnectionState next) => state = next,
        onError: (Object _) {},
        cancelOnError: false,
      );
    } else {
      state = const SshConnectionState.disconnected();
    }
  }

  /// Resolves [config]'s stored credentials and opens an interactive shell
  /// via the global registry.
  ///
  /// State transitions are driven by the manager's stream once connected;
  /// this method only gathers secrets and kicks the attempt off, surfacing
  /// credential problems (missing password/key) directly as an error state.
  Future<void> connect(
    ServerConfig config, {
    int width = 80,
    int height = 24,
  }) async {
    final SecureStorageService secure = ref.read(secureStorageServiceProvider);

    // Optimistic paint so the spinner shows before the first stream event.
    state = SshConnectionState.connecting(serverName: config.name);
    _activeServerId = config.id;

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

    final Result<void> result =
        await ref.read(sshSessionRegistryProvider.notifier).connect(
              config,
              password: password,
              privateKey: privateKey,
              passphrase: passphrase,
              width: width,
              height: height,
            );

    await result.when(
      success: (_) async {
        // Attach to the newly created session's state stream.
        attach(config.id);
        // Stamp lastConnectedAt so the fleet list reflects the fresh session.
        await ref
            .read(serverConfigListProvider.notifier)
            .markConnected(config.id);
      },
      failure: (AppFailure failure) async {
        state = SshConnectionState.error(
          message: failure.message,
          serverName: config.name,
          failureKind: failure.kind.name,
        );
      },
    );
  }

  /// Explicitly disconnects the active server via the registry.
  Future<void> disconnect() async {
    final String? id = _activeServerId;
    if (id != null) {
      await ref.read(sshSessionRegistryProvider.notifier).disconnect(id);
    }
    unawaited(_stateSub?.cancel());
    _stateSub = null;
    _activeServerId = null;
    state = const SshConnectionState.disconnected();
  }

  /// Disconnects a specific server (used when the terminal page's explicit
  /// disconnect button is pressed).
  Future<void> disconnectServer(String serverId) async {
    await ref.read(sshSessionRegistryProvider.notifier).disconnect(serverId);
    if (_activeServerId == serverId) {
      unawaited(_stateSub?.cancel());
      _stateSub = null;
      _activeServerId = null;
      state = const SshConnectionState.disconnected();
    }
  }
}
