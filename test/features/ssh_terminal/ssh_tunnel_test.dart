import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/ssh_tunnel.dart';

void main() {
  group('SshTunnel', () {
    test('validatePort accepts the valid range and rejects the rest', () {
      expect(SshTunnel.validatePort(22), isNull);
      expect(SshTunnel.validatePort(1), isNull);
      expect(SshTunnel.validatePort(65535), isNull);
      expect(SshTunnel.validatePort(0), isNotNull);
      expect(SshTunnel.validatePort(65536), isNotNull);
      expect(SshTunnel.validatePort(-1), isNotNull);
      expect(SshTunnel.validatePort(null), isNotNull);
    });

    test('local forward label shows bind → target', () {
      const SshTunnel tunnel = SshTunnel(
        id: 'local-1',
        serverId: 's1',
        type: SshTunnelType.local,
        bindHost: '127.0.0.1',
        bindPort: 8080,
        targetHost: 'db',
        targetPort: 5432,
      );
      expect(tunnel.label, '127.0.0.1:8080 → db:5432');
    });

    test('remote forward label marks the direction', () {
      const SshTunnel tunnel = SshTunnel(
        id: 'remote-1',
        serverId: 's1',
        type: SshTunnelType.remote,
        bindHost: '*',
        bindPort: 9090,
        targetHost: '',
        targetPort: 0,
      );
      expect(tunnel.label, '*:9090 (remote)');
    });
  });
}
