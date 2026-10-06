import 'package:flutter/foundation.dart';

/// Direction of an SSH port forward.
enum SshTunnelType { local, remote }

/// A live SSH port-forward ("tunnel") description.
///
/// For a **local** forward (`ssh -L`): [bindHost]/[bindPort] is the listener on
/// this device and [targetHost]/[targetPort] is the remote destination reached
/// through the SSH server. For a **remote** forward (`ssh -R`): [bindHost]/
/// [bindPort] is the listener on the SSH server side.
@immutable
class SshTunnel {
  const SshTunnel({
    required this.id,
    required this.serverId,
    required this.type,
    required this.bindHost,
    required this.bindPort,
    required this.targetHost,
    required this.targetPort,
  });

  final String id;
  final String serverId;
  final SshTunnelType type;

  /// Local listener host (local forward) or remote bind host (remote forward).
  final String bindHost;

  /// Actual bound port.
  final int bindPort;

  /// Remote destination host (local forward only).
  final String targetHost;

  /// Remote destination port (local forward only).
  final int targetPort;

  /// Human-readable description, e.g. `127.0.0.1:8080 → db:5432`.
  String get label => type == SshTunnelType.local
      ? '$bindHost:$bindPort → $targetHost:$targetPort'
      : '$bindHost:$bindPort (remote)';

  /// Validates a port range; returns an error message or `null` when valid.
  static String? validatePort(int? port) {
    if (port == null || port < 1 || port > 65535) {
      return 'Port must be between 1 and 65535.';
    }
    return null;
  }
}
