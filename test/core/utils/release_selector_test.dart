import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/utils/release_selector.dart';

/// Minimal GitHub `/releases` document builder.
Map<String, dynamic> _release({
  required String tag,
  bool draft = false,
  bool prerelease = false,
}) =>
    <String, dynamic>{
      'tag_name': tag,
      'draft': draft,
      'prerelease': prerelease,
    };

void main() {
  group('isDraftRelease / isPrereleaseRelease', () {
    test('detects drafts', () {
      expect(isDraftRelease(_release(tag: 'v1', draft: true)), isTrue);
      expect(isDraftRelease(_release(tag: 'v1')), isFalse);
    });

    test('detects pre-releases', () {
      expect(isPrereleaseRelease(_release(tag: 'v1', prerelease: true)), isTrue);
      expect(isPrereleaseRelease(_release(tag: 'v1')), isFalse);
    });
  });

  group('isEligibleRelease', () {
    test('accepts a stable, published release', () {
      expect(isEligibleRelease(_release(tag: 'v1.1.0')), isTrue);
    });

    test('always rejects drafts', () {
      expect(isEligibleRelease(_release(tag: 'v1', draft: true)), isFalse);
      // Even with the pre-release opt-in, a draft stays hidden.
      expect(
        isEligibleRelease(_release(tag: 'v1', draft: true),
            includePrerelease: true),
        isFalse,
      );
    });

    test('rejects pre-releases unless opted in', () {
      final Map<String, dynamic> rc = _release(tag: 'v2.0.0-rc.1', prerelease: true);
      expect(isEligibleRelease(rc), isFalse);
      expect(isEligibleRelease(rc, includePrerelease: true), isTrue);
    });
  });

  group('selectLatestRelease', () {
    test('returns null for a null or empty list', () {
      expect(selectLatestRelease(null), isNull);
      expect(selectLatestRelease(<dynamic>[]), isNull);
    });

    test('picks the first entry (newest) from an ordered list', () {
      final List<dynamic> releases = <dynamic>[
        _release(tag: 'v1.1.0'),
        _release(tag: 'v1.0.0'),
      ];
      expect(selectLatestRelease(releases)?['tag_name'], 'v1.1.0');
    });

    test('skips leading drafts and pre-releases to find the newest stable', () {
      // Mirrors the real fallback case: `/releases/latest` 404s because the
      // head is a draft/pre-release, but an older stable release exists.
      final List<dynamic> releases = <dynamic>[
        _release(tag: 'v2.0.0', draft: true),
        _release(tag: 'v1.9.0-rc.1', prerelease: true),
        _release(tag: 'v1.1.0'),
        _release(tag: 'v1.0.0'),
      ];
      expect(selectLatestRelease(releases)?['tag_name'], 'v1.1.0');
    });

    test('honours includePrerelease by returning the pre-release head', () {
      final List<dynamic> releases = <dynamic>[
        _release(tag: 'v2.0.0-rc.1', prerelease: true),
        _release(tag: 'v1.1.0'),
      ];
      expect(
        selectLatestRelease(releases, includePrerelease: true)?['tag_name'],
        'v2.0.0-rc.1',
      );
    });

    test('still skips drafts even when pre-releases are allowed', () {
      final List<dynamic> releases = <dynamic>[
        _release(tag: 'v2.0.0', draft: true),
        _release(tag: 'v1.9.0-rc.1', prerelease: true),
      ];
      expect(
        selectLatestRelease(releases, includePrerelease: true)?['tag_name'],
        'v1.9.0-rc.1',
      );
    });

    test('returns null when every release is filtered out', () {
      final List<dynamic> releases = <dynamic>[
        _release(tag: 'v2.0.0', draft: true),
        _release(tag: 'v1.9.0-rc.1', prerelease: true),
      ];
      expect(selectLatestRelease(releases), isNull);
    });

    test('ignores malformed (non-map) entries defensively', () {
      final List<dynamic> releases = <dynamic>[
        'not-a-release',
        42,
        null,
        _release(tag: 'v1.1.0'),
      ];
      expect(selectLatestRelease(releases)?['tag_name'], 'v1.1.0');
    });
  });
}
