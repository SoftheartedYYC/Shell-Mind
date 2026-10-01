import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/utils/version_utils.dart';

void main() {
  group('normalizeVersion', () {
    test('strips a leading v', () {
      expect(normalizeVersion('v1.2.3'), '1.2.3');
    });

    test('strips a leading capital V', () {
      expect(normalizeVersion('V1.2.3'), '1.2.3');
    });

    test('leaves an already-bare version alone', () {
      expect(normalizeVersion('1.2.3'), '1.2.3');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeVersion('  v1.2.3\n'), '1.2.3');
    });

    test('drops build metadata', () {
      expect(normalizeVersion('1.2.3+build.7'), '1.2.3');
      expect(normalizeVersion('v1.0.0+20261002'), '1.0.0');
    });

    test('keeps the pre-release segment', () {
      expect(normalizeVersion('v1.2.3-rc.1'), '1.2.3-rc.1');
    });
  });

  group('compareVersions', () {
    test('returns 0 for identical versions', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('returns 0 across a v prefix', () {
      expect(compareVersions('v1.0.0', '1.0.0'), 0);
    });

    test('returns 0 when build metadata differs', () {
      expect(compareVersions('1.0.0+1', '1.0.0+999'), 0);
    });

    test('compares the major component first', () {
      expect(compareVersions('2.0.0', '1.9.9'), 1);
      expect(compareVersions('1.9.9', '2.0.0'), -1);
    });

    test('compares the minor component second', () {
      expect(compareVersions('1.10.0', '1.9.0'), 1);
      expect(compareVersions('1.2.0', '1.10.0'), -1);
    });

    test('compares the patch component last', () {
      expect(compareVersions('1.0.10', '1.0.9'), 1);
      expect(compareVersions('1.0.1', '1.0.2'), -1);
    });

    test('compares numerically rather than lexicographically', () {
      // A string compare would rank "10" below "9".
      expect(compareVersions('1.0.10', '1.0.9'), 1);
      expect(compareVersions('10.0.0', '9.0.0'), 1);
    });

    test('treats missing components as zero', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1', '1.0.0'), 0);
      expect(compareVersions('1.2', '1.2.1'), -1);
    });

    test('ranks a release above its own pre-release', () {
      expect(compareVersions('1.2.0', '1.2.0-rc.1'), 1);
      expect(compareVersions('1.2.0-beta', '1.2.0'), -1);
    });

    test('orders pre-release identifiers per SemVer 11', () {
      // alpha < beta < rc < release
      expect(compareVersions('1.0.0-alpha', '1.0.0-beta'), -1);
      expect(compareVersions('1.0.0-beta', '1.0.0-rc.1'), -1);
      expect(compareVersions('1.0.0-alpha.1', '1.0.0-alpha.2'), -1);
    });

    test('orders numeric pre-release identifiers numerically', () {
      expect(compareVersions('1.0.0-rc.9', '1.0.0-rc.10'), -1);
    });

    test('ranks numeric identifiers below alphanumeric ones', () {
      expect(compareVersions('1.0.0-2', '1.0.0-alpha'), -1);
    });

    test('ranks a longer pre-release above its own prefix', () {
      expect(compareVersions('1.0.0-alpha.1', '1.0.0-alpha'), 1);
    });

    test('tolerates a stray non-numeric segment', () {
      expect(compareVersions('1.0.0rc', '1.0.0'), 0);
      expect(compareVersions('1.x.0', '1.0.0'), 0);
    });

    test('handles an empty string as the lowest version', () {
      expect(compareVersions('', '0.0.1'), -1);
      expect(compareVersions('0.0.1', ''), 1);
      expect(compareVersions('', ''), 0);
    });

    test('is antisymmetric', () {
      const pairs = <List<String>>[
        <String>['v1.0.0', 'v1.0.1'],
        <String>['1.2.0-rc.1', '1.2.0'],
        <String>['2.0.0', '10.0.0'],
      ];
      for (final pair in pairs) {
        expect(
          compareVersions(pair[0], pair[1]),
          -compareVersions(pair[1], pair[0]),
          reason: '${pair[0]} vs ${pair[1]}',
        );
      }
    });
  });

  group('isNewerVersion', () {
    test('is true for a higher release', () {
      expect(isNewerVersion('v1.1.0', 'v1.0.0'), isTrue);
    });

    test('is false for the same version', () {
      expect(isNewerVersion('1.0.0', 'v1.0.0'), isFalse);
    });

    test('is false for an older version', () {
      expect(isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('is false when the candidate is only a pre-release of current', () {
      expect(isNewerVersion('1.0.0-rc.1', '1.0.0'), isFalse);
    });
  });
}
