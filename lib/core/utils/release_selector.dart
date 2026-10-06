/// Pure helpers that choose which GitHub release to offer as an update.
///
/// Deliberately dependency-free (no Dio, no Flutter) so the selection logic —
/// the part most prone to regressions — can be unit-tested against canned JSON
/// payloads. The functions operate on the raw `Map<String, dynamic>` documents
/// returned by the GitHub REST API and never touch the network.
library;

/// `true` when the release is an unpublished draft.
///
/// GitHub's `/releases/latest` endpoint already excludes drafts, but the
/// `/releases` fallback list includes them, so they must be filtered here.
bool isDraftRelease(Map<String, dynamic> release) => release['draft'] == true;

/// `true` when the release is explicitly flagged as a pre-release.
bool isPrereleaseRelease(Map<String, dynamic> release) =>
    release['prerelease'] == true;

/// Whether [release] is a candidate the user may be offered.
///
/// Drafts are always rejected. Pre-releases are only accepted when
/// [includePrerelease] is set (mirrors the opt-in toggle in the update flow).
bool isEligibleRelease(
  Map<String, dynamic> release, {
  bool includePrerelease = false,
}) {
  if (isDraftRelease(release)) return false;
  if (!includePrerelease && isPrereleaseRelease(release)) return false;
  return true;
}

/// Picks the release to offer from a GitHub `/releases` list.
///
/// The REST API returns releases newest-first, so the first eligible entry is
/// also the most recent one. Non-map entries (defensive against schema noise)
/// are skipped. Returns `null` when nothing qualifies — which the caller
/// interprets as "no published release yet", a legitimate state rather than an
/// error.
Map<String, dynamic>? selectLatestRelease(
  List<dynamic>? releases, {
  bool includePrerelease = false,
}) {
  if (releases == null) return null;
  for (final dynamic entry in releases) {
    if (entry is! Map<String, dynamic>) continue;
    if (isEligibleRelease(entry, includePrerelease: includePrerelease)) {
      return entry;
    }
  }
  return null;
}

// ─── APK asset selection ──────────────────────────────────────────────────

/// Static per-ABI preference order for when the device ABI is unknown
/// (undetectable at runtime): the majority of active Android devices are
/// 64-bit Arm, then legacy 32-bit Arm, then x86_64 (emulators).
const List<String> abiPreferenceOrder = <String>[
  'arm64-v8a',
  'armeabi-v7a',
  'x86_64',
];

/// Chooses the most likely installable APK from a release's asset list.
///
/// Preference order (first hit wins):
/// 1. a per-ABI build whose name carries [deviceAbi] (e.g.
///    `app-arm64-v8a-release.apk` / `Shell-Mind-v1.2.3-arm64-v8a.apk`),
/// 2. the exact legacy universal name [preferredName]
///    (`Shell-Mind-v{version}.apk`),
/// 3. any asset explicitly named "universal",
/// 4. a per-ABI build in [abiPreferenceOrder] (static fallback when the
///    device ABI could not be detected),
/// 5. the largest `*.apk` (also covering MIME-only matches).
///
/// The functions stay dependency-free so the whole selection chain can be
/// unit-tested against canned JSON payloads.
Map<String, dynamic>? pickApkAsset(
  List<dynamic>? assets, {
  String? deviceAbi,
  String? preferredName,
}) {
  if (assets == null) return null;

  final List<Map<String, dynamic>> apks = <Map<String, dynamic>>[];
  for (final dynamic a in assets) {
    if (a is! Map<String, dynamic>) continue;
    final String name = ((a['name'] ?? '') as String).toLowerCase();
    final String contentType = ((a['content_type'] ?? '') as String);
    final bool looksLikeApk = name.endsWith('.apk');
    final bool hasApkMime = contentType.contains('android.package-archive');
    if (looksLikeApk || hasApkMime) apks.add(a);
  }
  if (apks.isEmpty) return null;

  if (deviceAbi != null) {
    final Map<String, dynamic>? exact = _findByAbi(apks, deviceAbi);
    if (exact != null) return exact;
  }

  if (preferredName != null) {
    final String wanted = preferredName.toLowerCase();
    for (final Map<String, dynamic> a in apks) {
      if (((a['name'] ?? '') as String).toLowerCase() == wanted) return a;
    }
  }

  final Map<String, dynamic>? universal = _findUniversal(apks);
  if (universal != null) return universal;

  for (final String abi in abiPreferenceOrder) {
    final Map<String, dynamic>? fallback = _findByAbi(apks, abi);
    if (fallback != null) return fallback;
  }

  apks.sort((Map<String, dynamic> x, Map<String, dynamic> y) =>
      _assetSize(y).compareTo(_assetSize(x)));
  return apks.first;
}

/// Whether [name] carries [abi] as a hyphen-delimited token, e.g.
/// `app-arm64-v8a-release.apk` matches `arm64-v8a` while `myarm64-v8a.apk`
/// does not (no token boundary).
bool _nameMentionsAbi(String name, String abi) => RegExp(
      '(?:^|-)${RegExp.escape(abi)}(?:[.-])',
    ).hasMatch(name);

Map<String, dynamic>? _findByAbi(
  List<Map<String, dynamic>> apks,
  String abi,
) {
  for (final Map<String, dynamic> a in apks) {
    final String name = ((a['name'] ?? '') as String).toLowerCase();
    if (_nameMentionsAbi(name, abi)) return a;
  }
  return null;
}

Map<String, dynamic>? _findUniversal(List<Map<String, dynamic>> apks) {
  for (final Map<String, dynamic> a in apks) {
    final String name = ((a['name'] ?? '') as String).toLowerCase();
    if (name.contains('universal')) return a;
  }
  return null;
}

int _assetSize(Map<String, dynamic> a) => switch (a['size']) {
      final int i => i,
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };
