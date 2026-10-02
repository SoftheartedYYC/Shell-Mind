import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// The manager owning the underlying `dartssh2` connection. Shared with the
  /// terminal page's autoDispose provider — the registry only holds a
  /// reference and never disposes it.
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
/// Unlike the terminal page's `autoDispose` manager provider — which lives and
/// dies with a single screen — this notifier has an app-wide lifecycle. Every
/// time a connection goes live it is [register]ed here, giving other modules
/// (notably the AI assistant) a way to discover which servers are online and
/// to run commands against them via [SshClientManager.runCommand].
///
/// The registry is intentionally passive about lifetimes: it holds strong
/// references to managers it does not own. To avoid leaking entries when a
/// terminal page is torn down, [register] subscribes to the manager's
/// `stateStream` and self-[unregister]s the moment the session drops, errors,
/// or the manager is disposed (stream closed).
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
  /// connection ends. `onDone` covers the disposal path (the manager closes
  /// its state controller in `dispose()`), which emits no terminal state.
  void _watch(RegisteredSession session) {
    _cancelWatcher(session.serverId);
    _watchers[session.serverId] = session.manager.stateStream.listen(
      (SshConnectionState next) {
        if (next.isDisconnected || next.isError) {
          unregister(session.serverId);
        }
      },
      onDone: () => unregister(session.serverId),
      onError: (Object _) => unregister(session.serverId),
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
