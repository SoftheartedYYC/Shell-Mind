import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/result.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import '../../features/ssh_terminal/data/ssh_client_manager.dart';
import '../../features/ssh_terminal/domain/entities/connection_state.dart';
import 'ssh_reconnect_coordinator.dart';
import 'ssh_reconnect_policy.dart';

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
///
/// When a session drops unexpectedly (transport error / remote hangup) the
/// registry does **not** unregister it immediately: if the SSH auto-reconnect
/// preference is enabled a [SshReconnectCoordinator] retries the connection
/// with exponential backoff, and only a manual disconnect or a final give-up
/// removes the entry.
class SshSessionRegistry extends Notifier<Map<String, RegisteredSession>> {
  /// Per-server subscriptions to the manager state stream, used for the
  /// automatic cleanup described above. Keyed by [RegisteredSession.serverId].
  final Map<String, StreamSubscription<SshConnectionState>> _watchers = {};

  /// Active auto-reconnect loops, keyed by server id. Populated when an
  /// unexpected drop is detected and cleared on manual disconnect / success /
  /// registry teardown.
  final Map<String, SshReconnectCoordinator> _reconnectLoops = {};

  /// Injectable dialer for tests. Bound to [_dialViaConnect] in [build].
  @visibleForTesting
  late Future<Result<void>> Function(ServerConfig config,
      {String? password, String? privateKey, String? passphrase}) dialer;

  @override
  Map<String, RegisteredSession> build() {
    // Release every watcher / loop if the container itself is torn down.
    ref.onDispose(_cancelAllWatchers);
    ref.onDispose(() {
      for (final SshReconnectCoordinator loop in _reconnectLoops.values) {
        loop.cancel();
      }
      _reconnectLoops.clear();
    });
    dialer = _dialViaConnect;
    return const {};
  }

  /// Default dial implementation — delegates to this registry's own
  /// [connect], which tears down any stale session, dials a fresh manager,
  /// and registers it on success.
  Future<Result<void>> _dialViaConnect(
    ServerConfig config, {
    String? password,
    String? privateKey,
    String? passphrase,
  }) {
    return connect(config,
        password: password, privateKey: privateKey, passphrase: passphrase);
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
    // 1. Any in-flight auto-reconnect loop is superseded by this explicit
    //    connection attempt.
    _cancelReconnectLoop(config.id);

    // 2. Tear down any existing session for this server.
    if (state.containsKey(config.id)) {
      await disconnect(config.id);
    }

    // 3. Create a fresh manager owned by this registry.
    final SshClientManager manager = SshClientManager();

    // 4. Attempt connection.
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

    // 5. Register the live session.
    final RegisteredSession session = RegisteredSession(
      serverId: config.id,
      config: config,
      manager: manager,
      connectedAt: DateTime.now(),
    );
    state = {...state, config.id: session};

    // 6. Watch for unexpected drops — with auto-reconnect coordination.
    _watch(session);

    return const Result<void>.success(null);
  }

  /// Explicitly disconnects and disposes the session for [serverId].
  ///
  /// No-op when the server is not currently connected. A user-initiated
  /// disconnect never triggers auto-reconnect: any running coordinator is
  /// cancelled first.
  Future<void> disconnect(String serverId) async {
    // Manual disconnect is authoritative — stop any auto-reconnect loop.
    _cancelReconnectLoop(serverId);
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
    _cancelAllReconnectLoops();
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

  /// Reconnect progress for [serverId], or idle when no loop is active.
  SshReconnectState reconnectStateFor(String serverId) =>
      _reconnectLoops[serverId]?.state ?? const SshReconnectState.idle();

  /// Manually retries a server whose reconnect loop gave up. Returns `true`
  /// when a retry was started; `false` when there is nothing to retry (no
  /// loop, loop not in the gave-up state, or the server is already live).
  bool retryReconnect(String serverId) {
    final SshReconnectCoordinator? loop = _reconnectLoops[serverId];
    return loop?.retryManually() ?? false;
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  /// Subscribes to [session]'s manager state stream.
  ///
  /// On an unexpected drop ([disconnected] / [error] emission or the manager's
  /// stream closing) the entry is kept or removed depending on the
  /// auto-reconnect preference:
  ///
  /// * reconnect enabled → the manager is disposed, the entry stays so
  ///   consumers keep the config/host binding, and a
  ///   [SshReconnectCoordinator] retries with exponential backoff.
  /// * reconnect disabled → legacy behaviour: entry removed and manager
  ///   disposed.
  ///
  /// `onDone` covers the disposal path (the manager closes its state
  /// controller in `dispose()`), which emits no terminal state.
  void _watch(RegisteredSession session) {
    _cancelWatcher(session.serverId);
    _watchers[session.serverId] = session.manager.stateStream.listen(
      (SshConnectionState next) {
        if (next.isDisconnected || next.isError) {
          _cancelWatcher(session.serverId);
          _onSessionDropped(session);
        }
      },
      onDone: () {
        _onSessionDropped(session);
      },
      onError: (Object _) {
        _onSessionDropped(session);
      },
      cancelOnError: false,
    );
  }

  /// Handles an unexpected (non user-initiated) session drop.
  void _onSessionDropped(RegisteredSession session) {
    final String serverId = session.serverId;

    // A loop already running (e.g. its dial produced a transient error state)
    // owns this server's fate.
    if (_reconnectLoops.containsKey(serverId)) return;

    if (!_autoReconnectEnabled()) {
      // Legacy path: remove the entry and dispose the transport.
      unregister(serverId);
      unawaited(session.manager.dispose());
      return;
    }

    // Auto-reconnect: drop the dead transport but keep the registry entry so
    // consumers (terminal page, AI chat) keep their config binding and see
    // the "reconnecting" progress instead of an abrupt disappearance.
    unawaited(session.manager.dispose());
    _startReconnectLoop(session.config);
  }

  /// Whether the user-enabled auto-reconnect preference is currently on.
  bool _autoReconnectEnabled() {
    try {
      return ref.read(preferencesServiceProvider).sshAutoReconnect;
    } catch (_) {
      // Preferences not initialised (e.g. plain unit tests) — fall back to
      // the default (enabled), matching the shipped default.
      return AppConstants.defaultSshAutoReconnect;
    }
  }

  /// Creates and starts a reconnect loop for [config], publishing progress
  /// through the app-wide reconnect provider.
  void _startReconnectLoop(ServerConfig config) {
    _cancelReconnectLoop(config.id);

    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    final SshReconnectPolicy policy = SshReconnectPolicy.fromPreferences(prefs);

    final SshReconnectCoordinator coordinator = SshReconnectCoordinator(
      serverId: config.id,
      config: config,
      policy: policy,
      publish: (SshReconnectState state) =>
          ref.read(sshReconnectStateProvider.notifier).publish(config.id, state),
      resolveCredentials: _resolveCredentials,
      dialer: (ServerConfig cfg,
              {String? password, String? privateKey, String? passphrase}) =>
          dialer(cfg,
              password: password, privateKey: privateKey, passphrase: passphrase),
      onSuccess: () {
        _reconnectLoops.remove(config.id);
      },
      onGiveUp: (SshReconnectState finalState) {
        // Sticky gave-up state stays published for the UI; the loop itself
        // has ended. The registry entry is kept so the user can retry.
        _reconnectLoops.remove(config.id);
        ref
            .read(sshReconnectStateProvider.notifier)
            .publish(config.id, finalState);
      },
    );

    _reconnectLoops[config.id] = coordinator;
    coordinator.start();
  }

  void _cancelReconnectLoop(String serverId) {
    final SshReconnectCoordinator? loop = _reconnectLoops.remove(serverId);
    loop?.cancel();
  }

  void _cancelAllReconnectLoops() {
    for (final SshReconnectCoordinator loop in _reconnectLoops.values) {
      loop.cancel();
    }
    _reconnectLoops.clear();
  }

  /// Resolves stored credentials for a reconnect attempt.
  Future<
      ({
        String? password,
        String? privateKey,
        String? passphrase,
      })> _resolveCredentials(String serverId, AuthType authType) async {
    final SecureStorageService secure = ref.read(secureStorageServiceProvider);
    if (authType == AuthType.password) {
      final String? password = await secure.getPassword(serverId);
      return (password: password, privateKey: null, passphrase: null);
    }
    final String? privateKey = await secure.getPrivateKey(serverId);
    final String? passphrase = await secure.getPassphrase(serverId);
    return (password: null, privateKey: privateKey, passphrase: passphrase);
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

/// App-wide reconnect progress tracker, fed by the registry's coordinators.
///
/// Keyed by server id so the terminal page and AI surfaces can render
/// "重连第 N 次" / "已放弃" banners without owning the loop themselves.
class SshReconnectStatesNotifier
    extends Notifier<Map<String, SshReconnectState>> {
  @override
  Map<String, SshReconnectState> build() => const <String, SshReconnectState>{};

  /// Merges [next] for [serverId]. Idle states with no prior entry are
  /// ignored to avoid spurious rebuilds.
  void publish(String serverId, SshReconnectState next) {
    if (next.status == SshReconnectStatus.idle && !state.containsKey(serverId)) {
      return;
    }
    final Map<String, SshReconnectState> updated =
        Map<String, SshReconnectState>.from(state);
    if (next.status == SshReconnectStatus.idle) {
      // Reconnect succeeded — clear the progress entry.
      updated.remove(serverId);
    } else {
      updated[serverId] = next;
    }
    state = updated;
  }

  /// Clears the entry for [serverId] (e.g. manual disconnect).
  void clear(String serverId) {
    if (!state.containsKey(serverId)) return;
    final Map<String, SshReconnectState> updated =
        Map<String, SshReconnectState>.from(state)..remove(serverId);
    state = updated;
  }
}

final NotifierProvider<SshReconnectStatesNotifier, Map<String, SshReconnectState>>
    sshReconnectStateProvider =
    NotifierProvider<SshReconnectStatesNotifier, Map<String, SshReconnectState>>(
  SshReconnectStatesNotifier.new,
);
