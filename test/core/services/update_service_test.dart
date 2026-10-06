// Unit tests for the update flow's SHA-256 integrity gate (fail-closed, D3).
//
// The network layer is mocked with mocktail (`_MockDio`); the download target
// is a real temporary directory wired through the path_provider method
// channel, so the file-level behaviour (hash over the real bytes, delete on
// mismatch) is exercised end-to-end.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shell_mind/core/services/update_service.dart';
import 'package:shell_mind/core/utils/result.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Canonical fixture payload + its digests. `badDigest` is a valid-looking
  // 64-hex string that differs from the real one, so the mismatch path is
  // exercised against a genuine hash comparison.
  final List<int> apkBytes =
      utf8.encode('ShellMind fake apk payload for integrity tests');
  final String goodDigest = sha256.convert(apkBytes).toString();
  final String badDigest = goodDigest.substring(0, 63) +
      (goodDigest.endsWith('0') ? '1' : '0');

  late Directory tmpDir;
  late _MockDio mockDio;
  late UpdateService service;
  String? capturedDownloadPath;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(false);
    registerFallbackValue(Options());
    registerFallbackValue(CancelToken());
    registerFallbackValue((int count, int total) {});
  });

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('update_service_test');

    // Wire path_provider to the temp directory. On the test host
    // (Platform.isAndroid == false) the service never calls
    // getExternalStorageDirectory, so the single app-facing channel covers
    // every directory lookup it performs.
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return tmpDir.path;
    });

    mockDio = _MockDio();
    service = UpdateService(mockDio);
    capturedDownloadPath = null;
  });

  tearDown(() async {
    // Reset the platform-channel mock so it cannot leak into other suites.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  PackageInfo packageInfo(String version) => PackageInfo(
        appName: 'ShellMind',
        packageName: 'com.shellmind.shell_mind',
        version: version,
        buildNumber: '10',
      );

  Map<String, dynamic> releaseJson({String? digest}) => <String, dynamic>{
        'tag_name': 'v1.5.3',
        'name': 'Shell-Mind v1.5.3',
        'body': 'Bug fixes.',
        'published_at': '2026-01-01T00:00:00Z',
        'prerelease': false,
        'html_url':
            'https://github.com/SoftheartedYYC/Shell-Mind/releases/tag/v1.5.3',
        'assets': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Shell-Mind-v1.5.3.apk',
            'browser_download_url':
                'https://example.com/Shell-Mind-v1.5.3.apk',
            'content_type': 'application/vnd.android.package-archive',
            'size': apkBytes.length,
            'digest': ?digest,
          },
        ],
      };

  /// Stubs `Dio.download` to write the fixture bytes to the requested path
  /// (like a real transfer) and fire one progress tick.
  void stubDownloadToDisk() {
    when(() => mockDio.download(any(), any(),
          cancelToken: any(named: 'cancelToken'),
          deleteOnError: any(named: 'deleteOnError'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((Invocation inv) async {
      final String savePath = inv.positionalArguments[1] as String;
      capturedDownloadPath = savePath;
      await File(savePath).writeAsBytes(apkBytes, flush: true);
      final void Function(int, int)? onProgress =
          inv.namedArguments[#onReceiveProgress] as void Function(int, int)?;
      onProgress?.call(apkBytes.length, apkBytes.length);
      // Dio.download's signature returns a Response; the real transfer only
      // fails before completing, which is not part of these scenarios.
      return Response<dynamic>(
        requestOptions: RequestOptions(path: savePath),
      );
    });
  }

  group('checkForUpdate — asset digest parsing', () {
    test('parses sha256:<hex> from the selected asset and normalises it',
        () async {
      when(() => mockDio.get<dynamic>(any(),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'))).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: releaseJson(digest: 'SHA256:${goodDigest.toUpperCase()}'),
          requestOptions: RequestOptions(path: ''),
        ),
      );
      final UpdateService checkService =
          UpdateService(mockDio, () async => packageInfo('1.5.2'));

      final Result<UpdateInfo?> result = await checkService.checkForUpdate();

      final UpdateInfo? info = result.valueOrNull;
      expect(info, isNotNull);
      // Prefix stripped, lowercased, stored as the bare hex digest.
      expect(info!.digest, goodDigest);
    });

    test('malformed digest normalises to null (refused later, fail-closed)',
        () async {
      when(() => mockDio.get<dynamic>(any(),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'))).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: releaseJson(digest: 'not-a-digest'),
          requestOptions: RequestOptions(path: ''),
        ),
      );
      final UpdateService checkService =
          UpdateService(mockDio, () async => packageInfo('1.5.2'));

      final Result<UpdateInfo?> result = await checkService.checkForUpdate();

      final UpdateInfo? info = result.valueOrNull;
      expect(info, isNotNull,
          reason: 'the check phase still offers the update');
      expect(info!.digest, isNull,
          reason: 'a malformed digest must not be trusted');
    });
  });

  group('downloadApk — integrity gate (fail-closed)', () {
    test('matching digest completes the download and keeps the file',
        () async {
      stubDownloadToDisk();

      final List<DownloadProgress> events = await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: goodDigest,
          )
          .toList();

      final DownloadProgress last = events.last;
      expect(last.isComplete, isTrue, reason: 'events: $events');
      expect(last.error, isNull);
      expect(last.filePath, capturedDownloadPath);
      expect(File(capturedDownloadPath!).existsSync(), isTrue,
          reason: 'a verified download must be kept for the installer');
    });

    test('mismatching digest is refused and the file is deleted', () async {
      stubDownloadToDisk();

      final List<DownloadProgress> events = await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: badDigest,
          )
          .toList();

      final DownloadProgress last = events.last;
      expect(last.isComplete, isFalse, reason: 'events: $events');
      expect(last.error, isNotNull);
      expect(last.failure, isNotNull);
      expect(last.failure!.kind, FailureKind.validation);
      expect(last.failure!.details['reason'],
          UpdateFailureReason.digestMismatch);
      expect(File(capturedDownloadPath!).existsSync(), isFalse,
          reason: 'a tampered download must never reach the installer');
    });

    test('missing digest is refused (D3) and the file is deleted', () async {
      stubDownloadToDisk();

      final List<DownloadProgress> events = await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            // No digest published — our release pipeline always ships one,
            // so this is treated as an anomaly and refused.
            expectedDigest: null,
          )
          .toList();

      final DownloadProgress last = events.last;
      expect(last.isComplete, isFalse, reason: 'events: $events');
      expect(last.error, isNotNull);
      expect(last.failure, isNotNull);
      expect(last.failure!.kind, FailureKind.validation);
      expect(
          last.failure!.details['reason'], UpdateFailureReason.digestMissing);
      expect(File(capturedDownloadPath!).existsSync(), isFalse,
          reason: 'an unverified download must never reach the installer');
    });
  });

  group('downloadApk — digest sidecar receipt', () {
    test('a verified download writes the sidecar with the bare digest',
        () async {
      stubDownloadToDisk();

      await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: goodDigest,
          )
          .toList();

      final File sidecar = File('$capturedDownloadPath.sha256');
      expect(sidecar.existsSync(), isTrue,
          reason: 'the verified download must leave a digest receipt');
      expect(sidecar.readAsStringSync().trim(), goodDigest);
    });

    test('a refused download leaves no sidecar behind', () async {
      stubDownloadToDisk();

      await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: badDigest,
          )
          .toList();

      expect(File(capturedDownloadPath!).existsSync(), isFalse);
      expect(File('$capturedDownloadPath.sha256').existsSync(), isFalse,
          reason: 'no receipt for a file that was never verified');
    });

    test('re-downloading the same asset replaces the stale receipt',
        () async {
      stubDownloadToDisk();

      // First transfer verifies and writes a receipt...
      await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: goodDigest,
          )
          .toList();
      expect(File('$capturedDownloadPath.sha256').existsSync(), isTrue);

      // ...the second one is refused and must sweep both artefacts.
      await service
          .downloadApk(
            'https://example.com/Shell-Mind-v1.5.3.apk',
            fileName: 'Shell-Mind-v1.5.3.apk',
            expectedDigest: badDigest,
          )
          .toList();

      expect(File(capturedDownloadPath!).existsSync(), isFalse);
      expect(File('$capturedDownloadPath.sha256').existsSync(), isFalse);
    });
  });

  group('locateVerifiedDownload — cross-session restore gate', () {
    const String assetName = 'Shell-Mind-v1.5.3.apk';

    Future<String> seedOnDisk({String? sidecarDigest, List<int>? bytes}) async {
      final File f =
          File('${tmpDir.path}${Platform.pathSeparator}$assetName');
      await f.writeAsBytes(bytes ?? apkBytes, flush: true);
      if (sidecarDigest != null) {
        await File('${f.path}.sha256')
            .writeAsString(sidecarDigest, flush: true);
      }
      return f.path;
    }

    test('restores when the sidecar matches and the bytes still verify',
        () async {
      final String path = await seedOnDisk(sidecarDigest: goodDigest);

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, path);
      expect(File(path).existsSync(), isTrue);
    });

    test('accepts a sha256-prefixed sidecar (normalised)', () async {
      await seedOnDisk(sidecarDigest: 'sha256:$goodDigest');

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNotNull);
    });

    test('refuses and deletes when the sidecar records another digest',
        () async {
      final String path = await seedOnDisk(sidecarDigest: badDigest);

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNull);
      expect(File(path).existsSync(), isFalse,
          reason: 'a receipt mismatch is treated as tampering');
      expect(File('$path.sha256').existsSync(), isFalse);
    });

    test('refuses and deletes when no sidecar exists (pre-gate leftover)',
        () async {
      final String path = await seedOnDisk();

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNull, reason: 'fail-closed: no receipt, no restore');
      expect(File(path).existsSync(), isFalse,
          reason: 'the unverifiable leftover is cleaned up');
    });

    test('refuses and deletes when the APK bytes were tampered with',
        () async {
      final String path =
          await seedOnDisk(sidecarDigest: goodDigest, bytes: <int>[1, 2, 3]);

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNull);
      expect(File(path).existsSync(), isFalse);
    });

    test('refuses a malformed sidecar', () async {
      final String path = await seedOnDisk(sidecarDigest: 'not-a-digest');

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNull);
      expect(File(path).existsSync(), isFalse);
    });

    test('refuses when the release digest itself is missing', () async {
      final String path = await seedOnDisk(sidecarDigest: goodDigest);

      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: null,
      );

      expect(restored, isNull);
      expect(File(path).existsSync(), isFalse);
    });

    test('returns null without touching anything when no APK exists',
        () async {
      final String? restored = await service.locateVerifiedDownload(
        assetName,
        expectedDigest: goodDigest,
      );

      expect(restored, isNull);
    });
  });

  group('sidecar cleanup pairing', () {
    const String assetName = 'Shell-Mind-v1.5.3.apk';

    test('deleteDownload removes the APK and its receipt together', () async {
      final File f =
          File('${tmpDir.path}${Platform.pathSeparator}$assetName');
      await f.writeAsBytes(apkBytes, flush: true);
      await File('${f.path}.sha256').writeAsString(goodDigest, flush: true);

      await service.deleteDownload(f.path);

      expect(f.existsSync(), isFalse);
      expect(File('${f.path}.sha256').existsSync(), isFalse);
    });

    test('clearDownloadCache sweeps receipts with the APKs', () async {
      final File f =
          File('${tmpDir.path}${Platform.pathSeparator}$assetName');
      await f.writeAsBytes(apkBytes, flush: true);
      await File('${f.path}.sha256').writeAsString(goodDigest, flush: true);

      final int freed = await service.clearDownloadCache();

      expect(freed, apkBytes.length);
      expect(f.existsSync(), isFalse);
      expect(File('${f.path}.sha256').existsSync(), isFalse,
          reason: 'no orphan receipt may survive the sweep');
    });
  });
}
