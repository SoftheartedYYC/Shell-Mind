import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/domain/server_transfer.dart';

void main() {
  group('ServerTransfer', () {
    test('round-trips server metadata without credentials', () {
      final ServerConfig server = ServerConfig(
        id: 's1',
        name: 'prod-web',
        host: '10.0.0.4',
        port: 2222,
        username: 'deploy',
        authType: AuthType.privateKey,
        group: 'prod',
        createdAt: DateTime(2026, 1, 2),
        lastConnectedAt: DateTime(2026, 1, 3),
      );

      final String json = ServerTransfer.encode(<ServerConfig>[server]);
      // The credentials-free invariant: no secret field ever reaches the file.
      // (`authType` legitimately carries the value "privateKey" — that is the
      // auth *mode*, not key material — so check field names, not substrings.)
      final Map<String, dynamic> doc =
          jsonDecode(json) as Map<String, dynamic>;
      final Map<String, dynamic> item =
          (doc['items'] as List<dynamic>).first as Map<String, dynamic>;
      expect(item.containsKey('password'), isFalse);
      expect(item.containsKey('privateKey'), isFalse);
      expect(item.containsKey('passphrase'), isFalse);

      final List<ServerConfig> decoded = ServerTransfer.decode(json);
      expect(decoded, hasLength(1));
      final ServerConfig d = decoded.single;
      expect(d.name, 'prod-web');
      expect(d.host, '10.0.0.4');
      expect(d.port, 2222);
      expect(d.username, 'deploy');
      expect(d.authType, AuthType.privateKey);
      expect(d.group, 'prod');
    });

    test('re-issues fresh ids so imported servers never reuse secrets', () {
      final ServerConfig server = ServerConfig(
        id: 's1',
        name: 'x',
        host: 'h',
        username: 'u',
        createdAt: DateTime(2026),
      );
      final ServerConfig decoded = ServerTransfer
          .decode(ServerTransfer.encode(<ServerConfig>[server]))
          .single;
      expect(decoded.id, isNot('s1'));
      expect(decoded.id, isNotEmpty);
    });

    test('defaults authType to password for unknown values', () {
      const String json = '''
      {"format": "shellmind-servers", "version": 1,
       "items": [ {"name": "x", "host": "h", "username": "u", "authType": "nope"} ]}
      ''';
      final ServerConfig decoded = ServerTransfer.decode(json).single;
      expect(decoded.authType, AuthType.password);
    });

    test('rejects foreign documents', () {
      expect(
        () => ServerTransfer.decode('{"format": "other"}'),
        throwsFormatException,
      );
    });
  });
}
