import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/ssh_tunnel.dart';

/// Owns the active port-forwards for a single SSH connection.
///
/// A **local** forward binds a [ServerSocket] on this device and bridges each
/// incoming connection to a fresh `direct-tcpip` channel over SSH (equivalent
/// to `ssh -L`). A **remote** forward requests a listener on the server
/// (`ssh -R`); incoming remote connections are accepted and their channels are
/// simply drained unless a consumer subscribes (the app currently surfaces the
/// listener for port discovery, not for remote-to-local bridging).
class SshTunnelManager {
  SshTunnelManager(this._client, this.serverId);

  final SSHClient _client;
  final String serverId;

  final Map<String, _ActiveLocalTunnel> _locals = <String, _ActiveLocalTunnel>{};
  final Map<String, _ActiveRemoteTunnel> _remotes =
      <String, _ActiveRemoteTunnel>{};
  int _counter = 0;

  /// Currently active local + remote tunnels, in creation order.
  ///
  /// Pure read — the tunnel ids are minted once at creation time and stored, so
  /// repeated reads return stable ids (the UI closes tunnels by id).
  List<SshTunnel> get tunnels => <SshTunnel>[
        ..._locals.values.map((_ActiveLocalTunnel t) => t.tunnel),
        ..._remotes.values.map((_ActiveRemoteTunnel r) => r.tunnel),
      ];

  /// Starts a local forward: `localHost:localPort` → `remoteHost:remotePort`
  /// via the SSH server. Returns the tunnel with the actual bound port.
  Future<SshTunnel> startLocalForward({
    required String remoteHost,
    required int remotePort,
    String localHost = '127.0.0.1',
    int localPort = 0,
  }) async {
    final ServerSocket server =
        await ServerSocket.bind(localHost, localPort);
    final SshTunnel tunnel = SshTunnel(
      id: 'local-${++_counter}',
      serverId: serverId,
      type: SshTunnelType.local,
      bindHost: localHost,
      bindPort: server.port,
      targetHost: remoteHost,
      targetPort: remotePort,
    );
    final StreamSubscription<Socket> sub = server.listen((Socket socket) {
      unawaited(_bridge(socket, remoteHost, remotePort));
    });
    _locals[tunnel.id] =
        _ActiveLocalTunnel(tunnel, server, sub);
    return tunnel;
  }

  /// Starts a remote forward on the server side; [host] empty = all interfaces,
  /// [port] 0 = a random port chosen by the server.
  Future<SshTunnel> startRemoteForward({String host = '', int port = 0}) async {
    final SSHRemoteForward? remote =
        await _client.forwardRemote(host: host, port: port);
    if (remote == null) {
      throw AppFailureException(
        AppFailure.ssh('Server refused the remote forward.'),
      );
    }
    final String id = 'remote-${++_counter}';
    final SshTunnel tunnel = SshTunnel(
      id: id,
      serverId: serverId,
      type: SshTunnelType.remote,
      bindHost: remote.host.isEmpty ? '*' : remote.host,
      bindPort: remote.port,
      targetHost: '',
      targetPort: 0,
    );
    // Accept and drain incoming channels so the listener stays alive; a real
    // consumer could subscribe to `remote.connections` instead.
    final StreamSubscription<SSHForwardChannel> sub =
        remote.connections.listen((SSHForwardChannel channel) {
      channel.stream.drain<void>().ignore();
    });
    _remotes[id] = _ActiveRemoteTunnel(tunnel, remote, sub);
    return tunnel;
  }

  /// Closes the tunnel with [id] (no-op when unknown).
  Future<void> close(String id) async {
    final _ActiveLocalTunnel? local = _locals.remove(id);
    if (local != null) {
      await local.subscription.cancel();
      await local.server.close();
      return;
    }
    final _ActiveRemoteTunnel? remote = _remotes.remove(id);
    if (remote != null) {
      await remote.subscription.cancel();
      remote.forward.close();
    }
  }

  /// Closes every active tunnel.
  Future<void> closeAll() async {
    for (final String id in _locals.keys.toList()) {
      await close(id);
    }
    for (final String id in _remotes.keys.toList()) {
      await close(id);
    }
  }

  Future<void> _bridge(Socket socket, String remoteHost, int remotePort) async {
    SSHForwardChannel? channel;
    try {
      channel = await _client.forwardLocal(remoteHost, remotePort);
    } catch (_) {
      socket.destroy();
      return;
    }
    // Remote → local.
    final StreamSubscription<Uint8List> toSocket =
        channel.stream.listen(socket.add, onError: (_) => socket.destroy());
    // Local → remote.
    final StreamSubscription<Uint8List> toChannel = socket.listen(
      (Uint8List data) => channel?.sink.add(data),
      onError: (_) => channel?.close(),
      onDone: () => channel?.close(),
    );
    channel.done.whenComplete(() {
      toSocket.cancel();
      toChannel.cancel();
      socket.destroy();
    });
  }
}

class _ActiveLocalTunnel {
  const _ActiveLocalTunnel(this.tunnel, this.server, this.subscription);

  final SshTunnel tunnel;
  final ServerSocket server;
  final StreamSubscription<Socket> subscription;
}

class _ActiveRemoteTunnel {
  const _ActiveRemoteTunnel(this.tunnel, this.forward, this.subscription);

  final SshTunnel tunnel;
  final SSHRemoteForward forward;
  final StreamSubscription<SSHForwardChannel> subscription;
}
