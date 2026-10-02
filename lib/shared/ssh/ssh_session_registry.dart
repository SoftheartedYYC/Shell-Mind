import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import '../../features/ssh_terminal/data/ssh_client_manager.dart';
import '../../features/ssh_terminal/domain/entities/connection_state.dart';

/// A single live SSH session tracked by the [SshSessionRegistry].
///
/// Bundles the connection's identity ([serverId] / [config]), the transport
/// owner ([manager]) used to run commands, and the moment it went live
/// ([connectedAt]) so consumers can report uptime or pick the freshest
/// session as a default target.
@immutable
class RegisteredSession {
  const RegisteredSession({
    required this.serverId,
    required this.config,
    required this.manager,
    required this.connectedAt,
  });

  /// Stable UUID of the server this session belongs to.
  final String serverId;

  /// Non-secret metadata (name/host/port/user) for the connected server.
  final ServerConfig config;

  /// The manager owning the underlying `dartssh2` connection. Owned by the
  /// [SshSessionRegistry] — disposed when the session is disconnected.
  final SshClientManager manager;

  /// When the session was registered (i.e. went live).
  final DateTime connectedAt;

  /// Convenience label used in command results and logs.
  String get serverName => config.name;

  /// True while the underlying manager still reports a live shell.
  bool get isConnected => manager.isConnected;

  RegisteredSession copyWith({
    String? serverId,
    ServerConfig? config,
    SshClientManager? manager,
    DateTime? connectedAt,
  }) {
    return RegisteredSession(
      serverId: serverId ?? this.serverId,
      config: config ?? this.config,
      manager: manager ?? this.manager,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  @override
  String toString() =>
      'RegisteredSession(server: "$serverName", id: $serverId, '
      'connectedAt: $connectedAt)';
}

/// Global registry of active SSH sessions.
///
/// **Owns** all SSH connections — each connected server gets its own
/// [SshClientManager] instance created and managed by this registry.
/// The lifecycle is app-wide (non-autoDispose): connections survive navigation
/// between pages and are only released by explicit [disconnect] / [disconnectAll]
/// or when the transport drops unexpectedly.
///
/// Other modules (AI assistant, terminal page, server list) interact with
/// connections exclusively through this registry:
/// - [connect] creates a manager, dials, and registers the session
/// - [disconnect] tears down a specific server's session
/// - [register] / [unregister] for manual session management (legacy compat)
class SshSessionRegistry extends Notifier<Map<String, RegisteredSession>> {
  /// Per-server subscriptions to the manager state stream, used for the
  /// automatic cleanup described above. Keyed by [RegisteredSession.serverId].
  final Map<String, StreamSubscription<SshConnectionState>> _watchers = {};

  @override
  Map<String, RegisteredSession> build() {
    // Release every watcher if the container itself is ever torn down.
    ref.onDispose(_cancelAllWatchers);
    return const {};
  }

  // ─── Connection ownership API ───────────────────────────────────────────

  /// Creates a new [SshClientManager], connects to the server described by
  /// [config], and registers the live session.
  ///
  /// If a session for `config.id` already exists it is torn down first
  /// (reconnect semantics). Credentials must be resolved by the caller
  /// (typically from [SecureStorageService]) and passed in.
  Future<Result<void>> connect(
    ServerConfig config, {
    String? password,
    String? privateKey,
    String? passphrase,
    int width = 80,
    int height = 24,
  }) async {
    // 1. Tear down any existing session for this server.
    if (state.containsKey(config.id)) {
      await disconnect(config.id);
    }

    // 2. Create a fresh manager owned by this registry.
    final SshClientManager manager = SshClientManager();

    // 3. Attempt connection.
    try {
      await manager.connect(
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
    } catch (e) {
      final AppFailure failure = SshClientManager.mapError(e);
      await manager.dispose();
      return Result<void>.failure(failure);
    }

    // 4. Register the live session.
    final RegisteredSession session = RegisteredSession(
      serverId: config.id,
      config: config,
      manager: manager,
      connectedAt: DateTime.now(),
    );
    state = {...state, config.id: session};

    // 5. Watch for unexpected drops and auto-cleanup.
    _watch(session);

    return const Result<void>.success(null);
  }

  /// Explicitly disconnects and disposes the session for [serverId].
  ///
  /// No-op when the server is not currently connected.
  Future<void> disconnect(String serverId) async {
    final RegisteredSession? session = state[serverId];
    if (session == null) return;
    // Cancel watcher first so the disconnect emission doesn't race cleanup.
    _cancelWatcher(serverId);
    // Remove from state before tearing down to avoid re-entrant issues.
    final Map<String, RegisteredSession> next =
        Map<String, RegisteredSession>.from(state)..remove(serverId);
    state = next;
    await session.manager.disconnect();
    await session.manager.dispose();
  }

  /// Disconnects and disposes **all** active sessions.
  ///
  /// Typically called at app shutdown.
  Future<void> disconnectAll() async {
    final List<RegisteredSession> sessions = state.values.toList();
    _cancelAllWatchers();
    state = const {};
    for (final RegisteredSession session in sessions) {
      await session.manager.disconnect();
      await session.manager.dispose();
    }
  }

  /// Adds (or replaces) the live session for [serverId].
  ///
  /// Safe to call repeatedly for the same server — a prior watcher is
  /// cancelled before a new one is attached, so re-connecting from the same
  /// terminal page won't stack subscriptions.
  void register(
    String serverId,
    SshClientManager manager,
    ServerConfig config,
  ) {
    final RegisteredSession session = RegisteredSession(
      serverId: serverId,
      config: config,
      manager: manager,
      connectedAt: DateTime.now(),
    );
    state = {...state, serverId: session};
    _watch(session);
  }

  /// Removes the session for [serverId] (no-op when absent) and cancels its
  /// cleanup watcher.
  void unregister(String serverId) {
    _cancelWatcher(serverId);
    if (!state.containsKey(serverId)) return;
    final Map<String, RegisteredSession> next = Map<String, RegisteredSession>.from(state)
      ..remove(serverId);
    state = next;
  }

  /// The session for [serverId], or `null` when that server is not online.
  RegisteredSession? getSession(String serverId) => state[serverId];

  /// All currently registered sessions, in registration order.
  List<RegisteredSession> get activeSessions => state.values.toList();

  /// Whether at least one server is online.
  bool get hasActiveSessions => state.isNotEmpty;

  /// Number of live sessions.
  int get sessionCount => state.length;

  /// The most recently connected session, used as the implicit target when a
  /// caller doesn't name a server. `null` when nothing is online.
  RegisteredSession? get defaultSession {
    if (state.isEmpty) return null;
    RegisteredSession newest = state.values.first;
    for (final RegisteredSession s in state.values) {
      if (s.connectedAt.isAfter(newest.connectedAt)) newest = s;
    }
    return newest;
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  /// Subscribes to [session]'s manager so the entry self-removes when the
  /// connection ends unexpectedly. `onDone` covers the disposal path (the
  /// manager closes its state controller in `dispose()`), which emits no
  /// terminal state.
  ///
  /// When auto-cleanup fires, the manager is also disposed since the registry
  /// owns it.
  void _watch(RegisteredSession session) {
    _cancelWatcher(session.serverId);
    _watchers[session.serverId] = session.manager.stateStream.listen(
      (SshConnectionState next) {
        if (next.isDisconnected || next.isError) {
          _cancelWatcher(session.serverId);
          unregister(session.serverId);
          unawaited(session.manager.dispose());
        }
      },
      onDone: () {
        unregister(session.serverId);
      },
      onError: (Object _) {
        unregister(session.serverId);
        unawaited(session.manager.dispose());
      },
      cancelOnError: false,
    );
  }

  void _cancelWatcher(String serverId) {
    final StreamSubscription<SshConnectionState>? sub = _watchers.remove(serverId);
    unawaited(sub?.cancel());
  }

  void _cancelAllWatchers() {
    for (final StreamSubscription<SshConnectionState> sub in _watchers.values) {
      unawaited(sub.cancel());
    }
    _watchers.clear();
  }
}

/// App-wide provider for the SSH session registry.
///
/// Deliberately **not** `autoDispose`: it must outlive any single screen so
/// background consumers can query online servers at any time.
final NotifierProvider<SshSessionRegistry, Map<String, RegisteredSession>>
    sshSessionRegistryProvider =
    NotifierProvider<SshSessionRegistry, Map<String, RegisteredSession>>(
  SshSessionRegistry.new,
);
