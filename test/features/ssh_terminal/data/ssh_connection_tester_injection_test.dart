import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_connection_tester.dart';
import 'package:shell_mind/shared/ssh/host_key_store.dart';

/// Unit tests for [SshConnectionTester]'s host-key trust injection seam.
///
/// The production probe (a real socket dial) is not exercised here — these
/// tests drive the test-only [SshConnectionTester.debugVerifyHostKey] hook to
/// assert the wiring contract:
/// - no store bridged  → legacy accept-any behaviour (unit tests stay free);
/// - store + matching record → silent accept, approval handler never called;
/// - store + different fingerprint → hard reject (possible MITM);
/// - store + unknown endpoint → approval handler decides, `true` records
///   the fingerprint (first-connect confirmation, TOFU).
void main() {
  const String host = '10.0.0.42';
  const int port = 22;
  final Uint8List fingerprint = Uint8List.fromList(
    List<int>.generate(32, (int i) => i),
  );

  group('SshConnectionTester host-key injection', () {
    test('without a store the probe accepts any key (legacy behaviour)',
        () async {
      const SshConnectionTester tester = SshConnectionTester();

      final bool accepted =
          await tester.debugVerifyHostKey(host, port, fingerprint);

      expect(accepted, isTrue);
    });

    test('without a store the approval handler is never bridged', () async {
      var handlerCalls = 0;
      const SshConnectionTester tester = SshConnectionTester(
        hostKeyApprovalHandler: null,
      );

      await tester.debugVerifyHostKey(host, port, fingerprint);

      expect(handlerCalls, 0);
    });

    test('matching stored fingerprint is accepted without prompting',
        () async {
      final InMemoryHostKeyStore store = InMemoryHostKeyStore();
      await store.set(host, port, 'SHA256:known-fingerprint');

      var handlerCalls = 0;
      final SshConnectionTester tester = SshConnectionTester(
        hostKeyStore: store,
        hostKeyApprovalHandler: (String h, int p, String fp) async {
          handlerCalls++;
          return true; // sentinel — must never be reached in this scenario
        },
      );

      final bool accepted = await tester.debugVerifyHostKey(
        host,
        port,
        Uint8List.fromList('SHA256:known-fingerprint'.codeUnits),
      );

      expect(accepted, isTrue);
      expect(handlerCalls, 0);
    });

    test('changed fingerprint is rejected and the handler is bypassed',
        () async {
      final InMemoryHostKeyStore store = InMemoryHostKeyStore();
      await store.set(host, port, 'SHA256:known-fingerprint');

      var handlerCalls = 0;
      final SshConnectionTester tester = SshConnectionTester(
        hostKeyStore: store,
        hostKeyApprovalHandler: (String h, int p, String fp) async {
          handlerCalls++;
          return true; // sentinel — must never be reached in this scenario
        },
      );

      final bool accepted = await tester.debugVerifyHostKey(
        host,
        port,
        Uint8List.fromList('SHA256:something-else'.codeUnits),
      );

      expect(accepted, isFalse);
      // A changed key must never be silently re-trusted: the approval dialog
      // is only for *unknown* endpoints, never for mismatches.
      expect(handlerCalls, 0);
    });

    test('unknown endpoint defers to the approval handler and records trust',
        () async {
      final InMemoryHostKeyStore store = InMemoryHostKeyStore();
      String? approvedFingerprint;

      final SshConnectionTester tester = SshConnectionTester(
        hostKeyStore: store,
        hostKeyApprovalHandler: (String h, int p, String fp) async {
          approvedFingerprint = fp;
          return true;
        },
      );

      final bool accepted = await tester.debugVerifyHostKey(
        host,
        port,
        Uint8List.fromList('SHA256:new-fingerprint'.codeUnits),
      );

      expect(accepted, isTrue);
      // The handler saw the decoded OpenSSH-style fingerprint...
      expect(approvedFingerprint, 'SHA256:new-fingerprint');
      // ...and the approval was persisted into the shared store.
      expect(await store.get(host, port), 'SHA256:new-fingerprint');
    });

    test('unknown endpoint declined by the handler is rejected and unrecorded',
        () async {
      final InMemoryHostKeyStore store = InMemoryHostKeyStore();

      final SshConnectionTester tester = SshConnectionTester(
        hostKeyStore: store,
        hostKeyApprovalHandler: (String h, int p, String fp) async => false,
      );

      final bool accepted = await tester.debugVerifyHostKey(
        host,
        port,
        Uint8List.fromList('SHA256:new-fingerprint'.codeUnits),
      );

      expect(accepted, isFalse);
      // Trust is never recorded without an explicit confirmation.
      expect(await store.get(host, port), isNull);
    });
  });
}
