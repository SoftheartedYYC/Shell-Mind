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

/// Minimal GitHub release-asset builder.
Map<String, dynamic> _asset(String name, {int size = 100, String? mime}) =>
    <String, dynamic>{
      'name': name,
      'size': size,
      'content_type': mime ?? 'application/vnd.android.package-archive',
      'browser_download_url': 'https://example.com/$name',
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

  group('pickApkAsset', () {
    test('returns null for a null/empty asset list or no APK at all', () {
      expect(pickApkAsset(null), isNull);
      expect(pickApkAsset(<dynamic>[]), isNull);
      expect(pickApkAsset(<dynamic>[_asset('checksums.txt', mime: 'text/plain')]),
          isNull);
    });

    test('prefers the exact legacy universal name when given', () {
      final List<dynamic> assets = <dynamic>[
        _asset('app-arm64-v8a-release.apk', size: 20),
        _asset('Shell-Mind-v1.5.3.apk', size: 60),
      ];
      final Map<String, dynamic>? picked = pickApkAsset(
        assets,
        deviceAbi: 'arm64-v8a',
        preferredName: 'shell-mind-v1.5.3.apk',
      );
      // The device-ABI build wins over the exact legacy name: a per-ABI APK
      // is smaller to download and exactly matches the running device.
      expect(picked?['name'], 'app-arm64-v8a-release.apk');
    });

    test('device-ABI match beats universal and bigger files', () {
      final List<dynamic> assets = <dynamic>[
        _asset('app-universal-release.apk', size: 90),
        _asset('app-x86_64-release.apk', size: 40),
        _asset('app-armeabi-v7a-release.apk', size: 30),
        _asset('app-arm64-v8a-release.apk', size: 35),
      ];
      expect(pickApkAsset(assets, deviceAbi: 'arm64-v8a')?['name'],
          'app-arm64-v8a-release.apk');
      expect(pickApkAsset(assets, deviceAbi: 'x86_64')?['name'],
          'app-x86_64-release.apk');
      expect(pickApkAsset(assets, deviceAbi: 'armeabi-v7a')?['name'],
          'app-armeabi-v7a-release.apk');
    });

    test('matches ABI only on token boundaries (no false positives)', () {
      final List<dynamic> assets = <dynamic>[
        // Neither asset is a real arm64-v8a build — the ABI must appear as a
        // hyphen-delimited token, not embedded in another word.
        _asset('myarm64-v8a-tooling.apk', size: 50),
        _asset('app-universal-release.apk', size: 40),
      ];
      expect(pickApkAsset(assets, deviceAbi: 'arm64-v8a')?['name'],
          'app-universal-release.apk');
    });

    test('falls back to explicit universal when ABI is unknown', () {
      final List<dynamic> assets = <dynamic>[
        _asset('app-arm64-v8a-release.apk', size: 35),
        _asset('app-universal-release.apk', size: 90),
      ];
      // No deviceAbi: the explicit universal build is the safe choice.
      expect(pickApkAsset(assets)?['name'], 'app-universal-release.apk');
    });

    test('static ABI preference applies when nothing else matches', () {
      final List<dynamic> assets = <dynamic>[
        _asset('app-x86_64-release.apk', size: 40),
        _asset('app-armeabi-v7a-release.apk', size: 30),
        _asset('app-arm64-v8a-release.apk', size: 35),
      ];
      // Unknown device ABI and no universal: arm64 first, then armv7, x86_64.
      expect(pickApkAsset(assets)?['name'], 'app-arm64-v8a-release.apk');
      expect(
          pickApkAsset(<dynamic>[
            _asset('app-x86_64-release.apk', size: 40),
            _asset('app-armeabi-v7a-release.apk', size: 30),
          ])?['name'],
          'app-armeabi-v7a-release.apk');
      expect(
          pickApkAsset(<dynamic>[
            _asset('app-x86_64-release.apk', size: 40),
          ])?['name'],
          'app-x86_64-release.apk');
    });

    test('largest APK wins when only unlabelled APKs exist', () {
      final List<dynamic> assets = <dynamic>[
        _asset('Shell-Mind.apk', size: 25),
        _asset('bundled-big.apk', size: 80, mime: 'application/octet-stream'),
      ];
      expect(pickApkAsset(assets)?['name'], 'bundled-big.apk');
    });

    test('recognises MIME-only APK assets', () {
      final List<dynamic> assets = <dynamic>[
        _asset('shellmind-payload', size: 70, mime: 'application/octet-stream'),
        _asset('real-apk', size: 50,
            mime: 'application/vnd.android.package-archive'),
      ];
      expect(pickApkAsset(assets)?['name'], 'real-apk');
    });
  });
}
