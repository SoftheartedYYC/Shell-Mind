/// SHA-256 integrity helpers for the in-app updater (fail-closed gate).
///
/// Extracted from `update_service.dart` so the security-critical hashing and
/// comparison logic has a single, tightly scoped home. The semantics are
/// unchanged:
/// * [normalizeDigest] accepts only well-formed `sha256:<64-hex>` values;
/// * [DigestVerifier.computeSha256] streams the file in chunks (flat memory
///   for 60+ MB APKs) and returns `null` on any read failure;
/// * [DigestVerifier.constantTimeEquals] compares without leaking *where*
///   two digests diverge through timing.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Normalises the `digest` field of a release asset (`sha256:<hex>`).
///
/// Returns the bare lowercase hex string, or `null` when the value is
/// absent or not a well-formed sha256 digest. `null` makes the download
/// fail closed: our release pipeline always publishes the digest, so a
/// missing/malformed one is treated as tampering until proven otherwise.
String? normalizeDigest(dynamic raw) {
  if (raw is! String) return null;
  final String value = raw.trim().toLowerCase();
  const String prefix = 'sha256:';
  final String hex = value.startsWith(prefix)
      ? value.substring(prefix.length).trim()
      : value;
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(hex) ? hex : null;
}

/// Purely static helpers; never instantiate.
@immutable
abstract final class DigestVerifier {
  /// Streams [file] through SHA-256 and returns the lowercase hex digest.
  ///
  /// Reading in chunks keeps memory flat for 60+ MB APKs. Returns `null` only
  /// when the file disappears between download and verification or the read
  /// fails mid-hash — both are reported as an integrity failure by the caller
  /// rather than a crash.
  ///
  /// Note: elements consumed here are typed `List<int>` while the runtime
  /// chunks are `Uint8List` (a subtype), which is safe. We deliberately avoid
  /// `Stream.transform` with a cross-type converter — transformers are
  /// invariant in their input type and a runtime `Stream<Uint8List>` would
  /// throw a TypeError (see the SSE parser lesson).
  static Future<String?> computeSha256(File file) async {
    try {
      if (!await file.exists()) return null;
      final _DigestConsumer consumer = _DigestConsumer();
      final ByteConversionSink hasher = sha256.startChunkedConversion(consumer);
      await for (final List<int> chunk in file.openRead()) {
        hasher.add(chunk);
      }
      hasher.close();
      return consumer.value?.toString();
    } on FileSystemException {
      return null;
    }
  }

  /// Length-independent comparison of two hex digests.
  ///
  /// XOR-fold comparison so a mismatch does not leak *where* the bytes
  /// diverge through timing — cheap insurance for a security gate.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// A [Sink] that keeps the final crypto [Digest] it receives.
///
/// Paired with `sha256.startChunkedConversion(...)` in
/// [DigestVerifier.computeSha256]: the hash feeds chunks into the conversion
/// sink, and crypto delivers the resulting [Digest] to this consumer when
/// `close()` is called on the conversion sink.
final class _DigestConsumer implements Sink<Digest> {
  Digest? _digest;

  /// The hash produced by the conversion, `null` until it is closed.
  Digest? get value => _digest;

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}
