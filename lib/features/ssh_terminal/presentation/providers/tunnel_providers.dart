import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../data/ssh_tunnel_manager.dart';
import '../../domain/entities/ssh_tunnel.dart';

/// App-wide registry of active SSH port-forwards, keyed by server id.
///
/// Each server's tunnels live under a [SshTunnelManager] that owns the local
/// listeners and remote-forward requests; the manager is created lazily on the
/// first forward and disposed when its last tunnel closes or the server
/// disconnects.
final NotifierProvider<SshTunnelsController, Map<String, List<SshTunnel>>>
    sshTunnelsProvider =
    NotifierProvider<SshTunnelsController, Map<String, List<SshTunnel>>>(
  SshTunnelsController.new,
);

class SshTunnelsController extends Notifier<Map<String, List<SshTunnel>>> {
  final Map<String, SshTunnelManager> _managers =
      <String, SshTunnelManager>{};

  @override
  Map<String, List<SshTunnel>> build() {
    ref.onDispose(() {
      for (final SshTunnelManager m in _managers.values) {
        unawaited(m.closeAll());
      }
      _managers.clear();
    });
    return const <String, List<SshTunnel>>{};
  }

  List<SshTunnel> forServer(String serverId) =>
      state[serverId] ?? const <SshTunnel>[];

  SshTunnelManager _managerFor(String serverId) {
    final SshTunnelManager? existing = _managers[serverId];
    if (existing != null) return existing;

    final RegisteredSession? session =
        ref.read(sshSessionRegistryProvider)[serverId];
    if (session == null || session.manager.client == null) {
      throw AppFailureException(
          AppFailure.ssh('Not connected — cannot open a tunnel.'));
    }
    final SshTunnelManager manager =
        SshTunnelManager(session.manager.client!, serverId);
    _managers[serverId] = manager;
    return manager;
  }

  Future<SshTunnel> startLocalForward(
    String serverId, {
    required String remoteHost,
    required int remotePort,
    String localHost = '127.0.0.1',
    int localPort = 0,
  }) async {
    final SshTunnelManager manager = _managerFor(serverId);
    final SshTunnel tunnel = await manager.startLocalForward(
      remoteHost: remoteHost,
      remotePort: remotePort,
      localHost: localHost,
      localPort: localPort,
    );
    _publish(serverId, manager);
    return tunnel;
  }

  Future<SshTunnel> startRemoteForward(
    String serverId, {
    String host = '',
    int port = 0,
  }) async {
    final SshTunnelManager manager = _managerFor(serverId);
    final SshTunnel tunnel =
        await manager.startRemoteForward(host: host, port: port);
    _publish(serverId, manager);
    return tunnel;
  }

  Future<void> close(String serverId, String tunnelId) async {
    final SshTunnelManager? manager = _managers[serverId];
    if (manager == null) return;
    await manager.close(tunnelId);
    if (manager.tunnels.isEmpty) {
      _managers.remove(serverId);
      final Map<String, List<SshTunnel>> next =
          Map<String, List<SshTunnel>>.from(state)..remove(serverId);
      state = next;
    } else {
      _publish(serverId, manager);
    }
  }

  void _publish(String serverId, SshTunnelManager manager) {
    state = <String, List<SshTunnel>>{
      ...state,
      serverId: List<SshTunnel>.unmodifiable(manager.tunnels),
    };
  }
}
