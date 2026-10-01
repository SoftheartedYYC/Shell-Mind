import 'dart:math';

/// Cryptographically-seeded source used for identifier generation.
///
/// Instantiated once and reused — `Random.secure()` seeds itself from the
/// platform entropy pool, which is marginally expensive to construct.
final Random _random = Random.secure();

/// Generates an RFC-4122 version-4 (random) UUID string,
/// e.g. `f47ac10b-58cc-4372-a567-0e02b2c3d479`.
///
/// Used as the primary key for locally-created entities (servers, sessions,
/// snippets) so identifiers are stable across restarts and collision-free
/// without a central allocator.
String generateId() {
  final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));

  // Stamp the version (4) into the high nibble of byte 6 …
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // … and the RFC-4122 variant into the high bits of byte 8.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final String hex = bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

/// Short, human-friendly identifier (8 hex chars) for places where a full
/// UUID would be visually noisy (session tabs, log tags). Not guaranteed
/// unique across the whole fleet — only meant to be locally distinctive.
String generateShortId() {
  final int value = _random.nextInt(0xFFFFFFFF);
  return value.toRadixString(16).padLeft(8, '0');
}
