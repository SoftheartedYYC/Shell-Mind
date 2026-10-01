import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';

void main() {
  group('AuthType', () {
    test('has expected values', () {
      expect(AuthType.values.length, 2);
      expect(AuthType.password.index, 0);
      expect(AuthType.privateKey.index, 1);
    });

    test('label returns human-readable string', () {
      expect(AuthType.password.label, 'Password');
      expect(AuthType.privateKey.label, 'Private key');
    });

    test('token returns short monospace string', () {
      expect(AuthType.password.token, 'pw');
      expect(AuthType.privateKey.token, 'key');
    });

    test('fromIndex returns correct type', () {
      expect(AuthType.fromIndex(0), AuthType.password);
      expect(AuthType.fromIndex(1), AuthType.privateKey);
    });

    test('fromIndex falls back to password for invalid index', () {
      expect(AuthType.fromIndex(-1), AuthType.password);
      expect(AuthType.fromIndex(99), AuthType.password);
    });

    test('fromName parses correctly', () {
      expect(AuthType.fromName('password'), AuthType.password);
      expect(AuthType.fromName('privateKey'), AuthType.privateKey);
    });

    test('fromName falls back to password for unknown', () {
      expect(AuthType.fromName('unknown'), AuthType.password);
      expect(AuthType.fromName(null), AuthType.password);
    });
  });

  group('ServerConfig.create', () {
    test('generates unique id', () {
      final a = ServerConfig.create(
        name: 'Server A',
        host: '192.168.1.1',
        username: 'root',
      );
      final b = ServerConfig.create(
        name: 'Server B',
        host: '192.168.1.2',
        username: 'root',
      );
      expect(a.id, isNot(equals(b.id)));
    });

    test('id is UUID format', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'example.com',
        username: 'user',
      );
      // UUID v4 format: 8-4-4-4-12 hex chars
      expect(config.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });

    test('sets createdAt to now', () {
      final before = DateTime.now();
      final config = ServerConfig.create(
        name: 'Test',
        host: '10.0.0.1',
        username: 'admin',
      );
      final after = DateTime.now();

      expect(config.createdAt.isAfter(before) || config.createdAt.isAtSameMomentAs(before), isTrue);
      expect(config.createdAt.isBefore(after) || config.createdAt.isAtSameMomentAs(after), isTrue);
    });

    test('uses default port 22', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'host',
        username: 'user',
      );
      expect(config.port, 22);
    });

    test('accepts custom port', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'host',
        port: 2222,
        username: 'user',
      );
      expect(config.port, 2222);
    });

    test('defaults authType to password', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'host',
        username: 'user',
      );
      expect(config.authType, AuthType.password);
    });

    test('accepts custom authType', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'host',
        username: 'user',
        authType: AuthType.privateKey,
      );
      expect(config.authType, AuthType.privateKey);
    });

    test('lastConnectedAt is null for new configs', () {
      final config = ServerConfig.create(
        name: 'Test',
        host: 'host',
        username: 'user',
      );
      expect(config.lastConnectedAt, isNull);
      expect(config.hasConnected, isFalse);
    });
  });

  group('ServerConfig computed properties', () {
    final config = ServerConfig(
      id: 'test-id',
      name: 'My Server',
      host: '192.168.1.100',
      port: 2222,
      username: 'admin',
      authType: AuthType.privateKey,
      group: 'production',
      createdAt: DateTime(2024, 1, 1),
    );

    test('address returns host:port', () {
      expect(config.address, '192.168.1.100:2222');
    });

    test('identity returns user@host', () {
      expect(config.identity, 'admin@192.168.1.100');
    });

    test('hasConnected is false without lastConnectedAt', () {
      expect(config.hasConnected, isFalse);
    });

    test('hasConnected is true with lastConnectedAt', () {
      final connected = config.copyWith(lastConnectedAt: DateTime.now());
      expect(connected.hasConnected, isTrue);
    });
  });

  group('ServerConfig.copyWith', () {
    final original = ServerConfig(
      id: 'id-1',
      name: 'Original',
      host: 'host.com',
      port: 22,
      username: 'user',
      authType: AuthType.password,
      group: 'group-a',
      createdAt: DateTime(2024, 1, 1),
      lastConnectedAt: DateTime(2024, 6, 1),
    );

    test('returns identical copy with no changes', () {
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('overrides name', () {
      final copy = original.copyWith(name: 'Updated');
      expect(copy.name, 'Updated');
      expect(copy.host, 'host.com');
      expect(copy.id, 'id-1');
    });

    test('overrides port', () {
      final copy = original.copyWith(port: 8022);
      expect(copy.port, 8022);
    });

    test('overrides authType', () {
      final copy = original.copyWith(authType: AuthType.privateKey);
      expect(copy.authType, AuthType.privateKey);
    });

    test('overrides lastConnectedAt', () {
      final newTime = DateTime(2024, 12, 25);
      final copy = original.copyWith(lastConnectedAt: newTime);
      expect(copy.lastConnectedAt, newTime);
    });
  });

  group('ServerConfig equality', () {
    final base = ServerConfig(
      id: 'same-id',
      name: 'Server',
      host: 'host',
      port: 22,
      username: 'user',
      createdAt: DateTime(2024, 1, 1),
    );

    test('identical configs are equal', () {
      final copy = ServerConfig(
        id: 'same-id',
        name: 'Server',
        host: 'host',
        port: 22,
        username: 'user',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(base, equals(copy));
      expect(base.hashCode, equals(copy.hashCode));
    });

    test('different id makes configs unequal', () {
      final other = base.copyWith(id: 'different-id');
      expect(base, isNot(equals(other)));
    });

    test('different name makes configs unequal', () {
      final other = base.copyWith(name: 'Different');
      expect(base, isNot(equals(other)));
    });

    test('same instance is equal', () {
      expect(base, equals(base));
    });
  });

  group('ServerConfig.toString', () {
    test('includes key information', () {
      final config = ServerConfig(
        id: 'abc',
        name: 'Prod',
        host: '10.0.0.1',
        port: 22,
        username: 'root',
        createdAt: DateTime(2024),
      );
      final str = config.toString();
      expect(str, contains('abc'));
      expect(str, contains('Prod'));
      expect(str, contains('10.0.0.1:22'));
    });
  });
}
