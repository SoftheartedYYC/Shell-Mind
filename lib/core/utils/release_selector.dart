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
