/// Semantic-version helpers used by the in-app update flow.
///
/// Deliberately dependency-free and pure so it can be unit-tested without
/// touching platform channels (GitHub tags arrive as loose strings such as
/// `v1.2.0`, `1.2.0-beta.1` or `1.2.0+build.7`).
library;

/// Characters that may legally start a git tag but carry no version meaning.
final RegExp _tagNoise = RegExp(r'^[vV=\s]+');

/// Build metadata (`+build.7`) — ignored for ordering per SemVer §10.
final RegExp _buildMetadata = RegExp(r'\+.+$');

/// A pre-release identifier that consists purely of digits sorts numerically
/// and *before* any alphanumeric identifier.
final RegExp _digits = RegExp(r'^\d+$');

/// Strips a leading `v` (and any surrounding whitespace) from a git tag,
/// turning `v1.2.0` into `1.2.0`. Safe to call on already-bare versions.
String normalizeVersion(String raw) {
  String v = raw.trim().replaceFirst(_tagNoise, '');
  v = v.replaceFirst(_buildMetadata, '');
  return v;
}

/// Compares two version strings.
///
/// Returns `-1` when [a] < [b], `0` when they are equal, `1` when [a] > [b].
///
/// Rules:
/// * A leading `v`/`V` and any `+build` metadata are ignored.
/// * Missing numeric components are treated as `0` (`1.2` == `1.2.0`).
/// * A release outranks its own pre-release (`1.2.0` > `1.2.0-rc.1`).
/// * Pre-release identifiers follow SemVer §11 ordering.
int compareVersions(String a, String b) {
  final _Version va = _Version.parse(normalizeVersion(a));
  final _Version vb = _Version.parse(normalizeVersion(b));

  final int maxLength = va.numeric.length > vb.numeric.length
      ? va.numeric.length
      : vb.numeric.length;

  for (int i = 0; i < maxLength; i++) {
    final int x = i < va.numeric.length ? va.numeric[i] : 0;
    final int y = i < vb.numeric.length ? vb.numeric[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }

  return _comparePreRelease(va.preRelease, vb.preRelease);
}

/// True when [candidate] is strictly newer than [current].
bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;

int _comparePreRelease(String? a, String? b) {
  if (a == null && b == null) return 0;
  // A version *without* a pre-release tag has higher precedence.
  if (a == null) return 1;
  if (b == null) return -1;

  final List<String> as = a.split('.');
  final List<String> bs = b.split('.');
  final int len = as.length < bs.length ? as.length : bs.length;

  for (int i = 0; i < len; i++) {
    final int c = _compareIdentifier(as[i], bs[i]);
    if (c != 0) return c;
  }
  // Equal up to the shorter length → the longer one wins.
  if (as.length == bs.length) return 0;
  return as.length < bs.length ? -1 : 1;
}

int _compareIdentifier(String a, String b) {
  final bool aNumeric = _digits.hasMatch(a);
  final bool bNumeric = _digits.hasMatch(b);

  if (aNumeric && bNumeric) {
    final int x = int.parse(a);
    final int y = int.parse(b);
    if (x == y) return 0;
    return x < y ? -1 : 1;
  }
  // Numeric identifiers always have lower precedence than alphanumeric ones.
  if (aNumeric) return -1;
  if (bNumeric) return 1;
  return a.compareTo(b);
}

/// Internal parsed representation of a version string.
class _Version {
  const _Version({required this.numeric, required this.preRelease});

  final List<int> numeric;
  final String? preRelease;

  static _Version parse(String raw) {
    if (raw.isEmpty) return const _Version(numeric: <int>[], preRelease: null);

    String core = raw;
    String? pre;

    final int dash = core.indexOf('-');
    if (dash >= 0) {
      pre = core.substring(dash + 1);
      core = core.substring(0, dash);
      if (pre.isEmpty) pre = null;
    }

    final List<int> parts = <int>[];
    for (final String segment in core.split('.')) {
      // Keep only the leading digits so `1.0.0rc` still yields something sane.
      final RegExpMatch? m = RegExp(r'^\d+').firstMatch(segment);
      parts.add(m == null ? 0 : int.parse(m.group(0)!));
    }

    return _Version(numeric: parts, preRelease: pre);
  }
}
