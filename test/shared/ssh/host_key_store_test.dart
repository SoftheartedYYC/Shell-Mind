import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/shared/ssh/host_key_store.dart';

class _MockSecureStorage extends Mock implements SecureStorageService {}

/// Convenience byte encoder for OpenSSH-style fingerprint payloads (dartssh2
/// hands the callback an already-encoded `SHA256:<base64>` UTF-8 string).
Uint8List _fp(String fingerprint) =>
    Uint8List.fromList(utf8.encode(fingerprint));

void main() {
  group('hostKeyStoreKey', () {
    test('is keyed by host and port, not by server id', () {
      expect(hostKeyStoreKey('10.0.0.5', 22), '10.0.0.5_22');
      expect(hostKeyStoreKey('example.com', 2222), 'example.com_2222');
    });
  });

  group('InMemoryHostKeyStore', () {
    late InMemoryHostKeyStore store;

    setUp(() {
      store = InMemoryHostKeyStore();
    });

    test('get returns null for an unknown endpoint', () async {
      expect(await store.get('10.0.0.5', 22), isNull);
      expect(await store.contains('10.0.0.5', 22), isFalse);
    });

    test('set records the fingerprint; get/contains reflect it', () async {
      await store.set('10.0.0.5', 22, 'SHA256:aaa');

      expect(await store.get('10.0.0.5', 22), 'SHA256:aaa');
      expect(await store.contains('10.0.0.5', 22), isTrue);
      expect(store.length, 1);
    });

    test('endpoints are isolated by host and port', () async {
      await store.set('10.0.0.5', 22, 'SHA256:aaa');
      await store.set('10.0.0.5', 2222, 'SHA256:bbb');

      expect(await store.get('10.0.0.5', 22), 'SHA256:aaa');
      expect(await store.get('10.0.0.5', 2222), 'SHA256:bbb');
      expect(store.length, 2);
    });

    test('set overwrites the previous fingerprint', () async {
      await store.set('10.0.0.5', 22, 'SHA256:aaa');
      await store.set('10.0.0.5', 22, 'SHA256:ccc');

      expect(await store.get('10.0.0.5', 22), 'SHA256:ccc');
      expect(store.length, 1);
    });

    test('remove drops the record and is a no-op when absent', () async {
      await store.set('10.0.0.5', 22, 'SHA256:aaa');
      await store.remove('10.0.0.5', 22);

      expect(await store.get('10.0.0.5', 22), isNull);
      expect(await store.contains('10.0.0.5', 22), isFalse);

      // Removing again must not throw.
      await store.remove('10.0.0.5', 22);
      expect(store.length, 0);
    });
  });

  group('decodeHostKeyFingerprint', () {
    test('decodes valid UTF-8 payload verbatim', () {
      expect(
        decodeHostKeyFingerprint(_fp('SHA256:AbCd1234')),
        'SHA256:AbCd1234',
      );
    });

    test('degrades malformed bytes to an empty string', () {
      // 0xFF is never valid UTF-8; the empty result can never match a stored
      // record, so this degrades to a mismatch rejection instead of throwing.
      expect(
        decodeHostKeyFingerprint(Uint8List.fromList(<int>[0xFF, 0xFE])),
        '',
      );
    });
  });

  group('verifyHostKeyTrust (D2 policy)', () {
    const String host = '10.0.0.5';
    const int port = 22;
    const String known = 'SHA256:known';
    const String other = 'SHA256:other';

    late InMemoryHostKeyStore store;
    late int handlerCalls;
    late bool handlerAnswer;
    late List<HostKeyRejection> rejections;

    setUp(() {
      store = InMemoryHostKeyStore();
      handlerCalls = 0;
      handlerAnswer = true;
      rejections = <HostKeyRejection>[];
    });

    Future<bool> Function(String, int, String)? handler() =>
        (String h, int p, String f) async {
          handlerCalls++;
          return handlerAnswer;
        };

    test('first connect: approval records fingerprint and accepts', () async {
      final bool ok = await verifyHostKeyTrust(
        store: store,
        host: host,
        port: port,
        fingerprint: known,
        approvalHandler: handler(),
        onRejection: rejections.add,
      );

      expect(ok, isTrue);
      expect(handlerCalls, 1);
      expect(await store.get(host, port), known);
      expect(rejections, isEmpty);
    });

    test('first connect: rejection leaves store empty and reports rejected',
        () async {
      handlerAnswer = false;

      final bool ok = await verifyHostKeyTrust(
        store: store,
        host: host,
        port: port,
        fingerprint: known,
        approvalHandler: handler(),
        onRejection: rejections.add,
      );

      expect(ok, isFalse);
      expect(handlerCalls, 1);
      expect(await store.get(host, port), isNull);
      expect(store.length, 0);
      expect(rejections, <HostKeyRejection>[HostKeyRejection.rejected]);
    });

    test('second connect: matching fingerprint accepted without prompting',
        () async {
      await store.set(host, port, known);

      final bool ok = await verifyHostKeyTrust(
        store: store,
        host: host,
        port: port,
        fingerprint: known,
        approvalHandler: handler(),
        onRejection: rejections.add,
      );

      expect(ok, isTrue);
      expect(handlerCalls, 0); // silent pass-through on a known key
      expect(rejections, isEmpty);
    });

    test('second connect: changed fingerprint rejected as mismatch without '
        'prompting', () async {
      await store.set(host, port, known);

      final bool ok = await verifyHostKeyTrust(
        store: store,
        host: host,
        port: port,
        fingerprint: other,
        approvalHandler: handler(),
        onRejection: rejections.add,
      );

      expect(ok, isFalse);
      expect(handlerCalls, 0); // a changed key must never be asked about
      expect(rejections, <HostKeyRejection>[HostKeyRejection.mismatch]);
    });

    test('no handler: legacy auto-accept without recording', () async {
      final bool ok = await verifyHostKeyTrust(
        store: store,
        host: host,
        port: port,
        fingerprint: known,
        approvalHandler: null,
        onRejection: rejections.add,
      );

      expect(ok, isTrue);
      expect(await store.get(host, port), isNull);
      expect(store.length, 0);
      expect(rejections, isEmpty);
    });
  });

  group('SecureHostKeyStore', () {
    late _MockSecureStorage secure;
    late SecureHostKeyStore store;

    setUp(() {
      secure = _MockSecureStorage();
      store = SecureHostKeyStore(secure);
    });

    test('get delegates with the canonical key', () async {
      when(() => secure.read(hostKeyStoreKey('h', 22)))
          .thenAnswer((_) async => 'SHA256:x');

      expect(await store.get('h', 22), 'SHA256:x');
      verify(() => secure.read(hostKeyStoreKey('h', 22))).called(1);
    });

    test('set delegates with the canonical key', () async {
      when(() => secure.write(any(), any())).thenAnswer((_) async {});

      await store.set('h', 22, 'SHA256:x');

      verify(() => secure.write(hostKeyStoreKey('h', 22), 'SHA256:x'))
          .called(1);
    });

    test('remove delegates with the canonical key', () async {
      when(() => secure.delete(any())).thenAnswer((_) async {});

      await store.remove('h', 22);

      verify(() => secure.delete(hostKeyStoreKey('h', 22))).called(1);
    });

    test('contains delegates with the canonical key', () async {
      when(() => secure.contains(any())).thenAnswer((_) async => true);

      expect(await store.contains('h', 22), isTrue);
      verify(() => secure.contains(hostKeyStoreKey('h', 22))).called(1);
    });
  });
}
