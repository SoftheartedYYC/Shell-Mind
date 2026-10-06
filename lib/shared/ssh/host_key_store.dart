import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/storage/secure_storage_service.dart';

/// Persistence contract for SSH host-key fingerprints, keyed by endpoint.
///
/// Entries are keyed by `<host>_<port>` — **not** by server id — so deleting
/// a server and re-adding it with the same address keeps the recorded trust
/// (matching OpenSSH's `known_hosts` semantics).
///
/// The stored value is the full OpenSSH-style SHA-256 fingerprint as produced
/// by `dartssh2`'s handshake, e.g. `SHA256:abcdef…` (base64 without padding).
abstract interface class HostKeyStore {
  /// The stored fingerprint for [host]:[port], or `null` when the endpoint is
  /// not yet trusted.
  Future<String?> get(String host, int port);

  /// Records [fingerprint] as the trusted key for [host]:[port].
  Future<void> set(String host, int port, String fingerprint);

  /// Removes the trust record for [host]:[port] ("reset host trust" in the
  /// server edit page). No-op when nothing is recorded.
  Future<void> remove(String host, int port);

  /// Whether a trust record exists for [host]:[port].
  Future<bool> contains(String host, int port);
}

/// Canonical storage key for [host]:[port].
String hostKeyStoreKey(String host, int port) => '${host}_$port';

/// [HostKeyStore] backed by [SecureStorageService] — fingerprints live in the
/// device keystore alongside the other SSH secrets.
class SecureHostKeyStore implements HostKeyStore {
  SecureHostKeyStore(this._secure);

  final SecureStorageService _secure;

  @override
  Future<String?> get(String host, int port) =>
      _secure.read(hostKeyStoreKey(host, port));

  @override
  Future<void> set(String host, int port, String fingerprint) =>
      _secure.write(hostKeyStoreKey(host, port), fingerprint);

  @override
  Future<void> remove(String host, int port) =>
      _secure.delete(hostKeyStoreKey(host, port));

  @override
  Future<bool> contains(String host, int port) =>
      _secure.contains(hostKeyStoreKey(host, port));
}

/// In-memory [HostKeyStore] for tests and as the default no-persistence
/// fallback injected into [SshClientManager].
class InMemoryHostKeyStore implements HostKeyStore {
  final Map<String, String> _entries = <String, String>{};

  @override
  Future<String?> get(String host, int port) async => _entries[key(host, port)];

  @override
  Future<void> set(String host, int port, String fingerprint) async {
    _entries[key(host, port)] = fingerprint;
  }

  @override
  Future<void> remove(String host, int port) async {
    _entries.remove(key(host, port));
  }

  @override
  Future<bool> contains(String host, int port) async =>
      _entries.containsKey(key(host, port));

  /// Test-only: number of recorded fingerprints.
  @visibleForTesting
  int get length => _entries.length;

  static String key(String host, int port) => hostKeyStoreKey(host, port);
}

/// Decodes `dartssh2`'s host-key fingerprint bytes into the canonical
/// `SHA256:<base64>` string. Returns an empty string when the bytes are not
/// valid UTF-8 (never expected in practice — dartssh2 encodes the fingerprint
/// itself). An empty value can never match a stored record, so malformed
/// input degrades to a mismatch rejection rather than crashing the handshake.
String decodeHostKeyFingerprint(Uint8List fingerprint) {
  try {
    return utf8.decode(fingerprint, allowMalformed: false);
  } on FormatException {
    return '';
  }
}

/// How a host-key verification ended in rejection, used for error
/// localisation.
enum HostKeyRejection {
  /// No record existed yet and the user declined to trust the key.
  rejected,

  /// A record existed but the presented fingerprint differed — possible
  /// man-in-the-middle or a server reinstall.
  mismatch,
}

/// Shared D2 host-key trust policy — first-connect confirmation, silent
/// match, hard reject on change.
///
/// * No record for [host]:[port] → ask via [approvalHandler]; `true` records
///   the fingerprint and accepts, `false` reports
///   [HostKeyRejection.rejected] through [onRejection] and rejects.
/// * Record matches [fingerprint] → accept without prompting.
/// * Record differs → report [HostKeyRejection.mismatch] through
///   [onRejection] and reject ([approvalHandler] is never consulted — a
///   changed key must never be silently trusted).
///
/// Returns whether the connection may proceed.
Future<bool> verifyHostKeyTrust({
  required HostKeyStore store,
  required String host,
  required int port,
  required String fingerprint,
  required Future<bool> Function(String host, int port, String fingerprint)?
      approvalHandler,
  void Function(HostKeyRejection outcome)? onRejection,
}) async {
  final String? stored = await store.get(host, port);

  if (stored == null) {
    final Future<bool> Function(String, int, String)? handler =
        approvalHandler;
    if (handler == null) return true; // legacy auto-accept when unbridged
    if (await handler(host, port, fingerprint)) {
      await store.set(host, port, fingerprint);
      return true;
    }
    onRejection?.call(HostKeyRejection.rejected);
    return false;
  }

  if (stored == fingerprint) return true;
  onRejection?.call(HostKeyRejection.mismatch);
  return false;
}
