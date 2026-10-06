import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../utils/release_selector.dart';
import '../utils/result.dart';
import '../utils/version_utils.dart';
import 'device_abi.dart';
import 'update_digest.dart';
import 'update_models.dart';

// Re-export the split-out value objects and digest helpers so every existing
// importer of this entrypoint (`UpdateInfo`, `DownloadProgress`,
// `UpdateFailureReason`, …) keeps compiling untouched.
export 'update_models.dart';

// ─── Service ──────────────────────────────────────────────────────────────

/// In-app update service backed by GitHub Releases.
///
/// Responsibilities:
/// * compare the running build against `releases/latest`,
/// * stream an APK download with progress + cancellation,
/// * hand the finished file to the Android package installer.
///
/// All failures are funnelled through the app-wide [Result]/[AppFailure]
/// model so the UI never has to catch raw exceptions.
class UpdateService {
  /// Both hooks exist for tests: inject a mocked [Dio] and a canned
  /// `PackageInfo` loader instead of touching the network or the platform.
  /// [_abiLoader] likewise lets tests pin a device ABI without `dart:ffi`.
  UpdateService([this._dio, this._packageInfoLoader, this._abiLoader]);

  // GitHub Releases source of truth.
  static const String repoOwner = 'SoftheartedYYC';
  static const String repoName = 'Shell-Mind';
  static const String _apiBase =
      'https://api.github.com/repos/$repoOwner/$repoName';

  /// MIME type the Android package installer expects.
  static const String apkMimeType = 'application/vnd.android.package-archive';

  /// GitHub asks for an explicit API version; pinning it avoids surprise
  /// schema changes breaking the parser.
  static const Map<String, dynamic> _githubHeaders = <String, dynamic>{
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': AppConstants.userAgent,
  };

  /// Minimum interval between progress emissions — Dio reports on every
  /// socket read, which would thrash the widget tree.
  static const Duration _progressThrottle = Duration(milliseconds: 90);

  /// Suffix of the digest sidecar written next to a verified download
  /// (`Shell-Mind-v1.1.0.apk` → `Shell-Mind-v1.1.0.apk.sha256`). It is the
  /// cross-session receipt that lets a restored download be re-verified
  /// instead of blindly trusted (M-2, fail-closed).
  static const String _digestSidecarSuffix = '.sha256';

  /// Path of the digest sidecar paired with the APK at [apkPath].
  static String _sidecarPathFor(String apkPath) =>
      '$apkPath$_digestSidecarSuffix';

  final Dio? _dio;
  final Future<PackageInfo> Function()? _packageInfoLoader;

  /// Optional device-ABI probe (defaults to [currentDeviceAbi]). Tests inject
  /// a canned value so the asset selection can be pinned without `dart:ffi`.
  final String? Function()? _abiLoader;

  /// Memoised ABI for this service instance (the ABI cannot change at
  /// runtime; one probe is enough).
  String? _cachedAbi;

  Dio? _ownedDio;
  CancelToken? _activeDownload;

  String? _cachedVersion;
  String? _cachedBuildNumber;
  UpdateInfo? _latestKnown;

  /// Version of the newest release seen during the last successful check,
  /// regardless of whether it is newer than the running build. Lets the UI
  /// render "up to date · v1.0.0".
  String? get latestKnownVersion => _latestKnown?.version;

  /// The download currently in flight, if any. Cancel it to abort.
  CancelToken? get activeDownloadToken => _activeDownload;

  Dio get _client => _dio ?? (_ownedDio ??= _buildDownloadDio());

  static Dio _buildDownloadDio() => Dio(
        BaseOptions(
          connectTimeout: AppConstants.httpConnectTimeout,
          // Large APKs over slow links: only the *gap* between chunks is
          // bounded, so a generous window avoids killing healthy downloads.
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: AppConstants.httpSendTimeout,
          headers: <String, dynamic>{
            'User-Agent': AppConstants.userAgent,
          },
          // Follow the release CDN redirect chain.
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

  /// Frees the internally-created HTTP client. Safe to call more than once.
  void dispose() {
    _activeDownload?.cancel('service disposed');
    _ownedDio?.close(force: true);
    _ownedDio = null;
  }

  // ─── Current build info ─────────────────────────────────────────────────

  /// Version of the running build (`1.0.0`), falling back to
  /// [AppConstants.appVersion] when the platform plugin is unavailable.
  Future<String> currentVersion() async {
    final String? cached = _cachedVersion;
    if (cached != null) return cached;
    final PackageInfo info = await _readPackageInfo();
    return _cachedVersion = info.version;
  }

  /// Build number of the running build (`1`).
  Future<String> currentBuildNumber() async {
    final String? cached = _cachedBuildNumber;
    if (cached != null) return cached;
    final PackageInfo info = await _readPackageInfo();
    return _cachedBuildNumber = info.buildNumber;
  }

  Future<PackageInfo> _readPackageInfo() {
    final Future<PackageInfo> Function()? loader = _packageInfoLoader;
    if (loader != null) return loader();
    return PackageInfo.fromPlatform();
  }

  // ─── Update check ───────────────────────────────────────────────────────

  /// Queries `releases/latest` and compares it against the running build.
  ///
  /// Returns `Success(null)` when the app is already up to date and
  /// `Success(UpdateInfo)` when a newer release with an APK asset exists.
  /// Network/API problems come back as `Failure`.
  ///
  /// Robustness: GitHub's `/releases/latest` returns **404** in several
  /// situations that do *not* mean "no release exists" — most notably when the
  /// newest release is a draft/pre-release, or when the repository is private
  /// and the request is unauthenticated. A bare 404 therefore triggers a
  /// fallback to `/releases?per_page=10`, from which the newest eligible
  /// (non-draft, and non-prerelease unless opted in) release is selected via
  /// the pure [selectLatestRelease] helper. Only when the fallback *also*
  /// yields nothing do we surface a genuine "no releases yet" state, tagged
  /// with [UpdateFailureReason.noReleases] so the UI can localise it. Any
  /// network/timeout/DNS failure is propagated untouched (never coerced into
  /// `notFound`).
  Future<Result<UpdateInfo?>> checkForUpdate({
    bool includePrerelease = false,
    CancelToken? cancelToken,
  }) async {
    return Result.guard<UpdateInfo?>(
      () async {
        Map<String, dynamic>? release;
        try {
          final Response<dynamic> response = await _client.get<dynamic>(
            '$_apiBase/releases/latest',
            options: Options(headers: _githubHeaders),
            cancelToken: cancelToken,
          );
          final dynamic data = response.data;
          if (data is Map<String, dynamic>) {
            release = data;
          } else if (data is! List) {
            throw AppFailureException(const AppFailure(
              kind: FailureKind.validation,
              message: 'GitHub returned an unexpected payload.',
              details: <String, dynamic>{
                'reason': UpdateFailureReason.badPayload,
              },
            ));
          }
        } on DioException catch (e) {
          if (!_isNotFound(e)) rethrow;
          // `/releases/latest` 404 → fall back to the full release list.
          release = await _fetchFallbackRelease(
            includePrerelease: includePrerelease,
            cancelToken: cancelToken,
          );
        }

        if (release == null) {
          // Both endpoints agree there is nothing installable to offer. This
          // is a legitimate state, not a transport error.
          throw AppFailureException(const AppFailure(
            kind: FailureKind.notFound,
            message: 'No releases published yet.',
            details: <String, dynamic>{
              'reason': UpdateFailureReason.noReleases,
            },
          ));
        }

        final UpdateInfo info = _parseRelease(release);
        _latestKnown = info;

        if (info.isPrerelease && !includePrerelease) return null;
        if (info.downloadUrl.isEmpty) {
          // A release exists but carries no installable asset — nothing the
          // user can act on, so treat it as "up to date" rather than an error.
          return null;
        }

        final String current = await currentVersion();
        return isNewerVersion(info.version, current) ? info : null;
      },
      onError: (Object e, StackTrace st) => _mapError(e, st),
    );
  }

  /// Fallback path: lists recent releases and picks the newest eligible one.
  ///
  /// Returns `null` when the list is empty or everything is filtered out
  /// (draft/pre-release). A non-404 transport failure is rethrown so the
  /// caller maps it to a network/timeout failure rather than "no releases".
  Future<Map<String, dynamic>?> _fetchFallbackRelease({
    required bool includePrerelease,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        '$_apiBase/releases',
        queryParameters: const <String, dynamic>{'per_page': 10},
        options: Options(headers: _githubHeaders),
        cancelToken: cancelToken,
      );
      final dynamic data = response.data;
      if (data is! List) return null;
      return selectLatestRelease(
        data,
        includePrerelease: includePrerelease,
      );
    } on DioException catch (e) {
      if (_isNotFound(e)) return null;
      rethrow;
    }
  }

  /// Whether [e] is a definitive HTTP 404 response (as opposed to a DNS,
  /// timeout or connection error that merely *looks* like a miss).
  static bool _isNotFound(DioException e) =>
      e.type == DioExceptionType.badResponse && e.response?.statusCode == 404;

  UpdateInfo _parseRelease(Map<String, dynamic> json) {
    final String tagName = (json['tag_name'] ?? json['name'] ?? '') as String;
    final String version = normalizeVersion(tagName);

    // Defensive against schema noise: a non-list `assets` field degrades to
    // "no installable asset" exactly like the pre-split implementation did.
    final Object? assets = json['assets'];
    final Map<String, dynamic>? apk = pickApkAsset(
      assets is List ? assets : null,
      deviceAbi: _deviceAbi(),
      preferredName: '$repoName-v$version.apk',
    );

    return UpdateInfo(
      version: version,
      tagName: tagName,
      releaseNotes: _normalizeNotes(json['body']),
      downloadUrl: (apk?['browser_download_url'] ?? '') as String,
      fileSize: _asInt(apk?['size']),
      publishedAt: _parseDate(json['published_at'] ?? json['created_at']),
      assetName: (apk?['name'] ?? '') as String,
      releaseUrl: (json['html_url'] ?? '') as String,
      isPrerelease: json['prerelease'] == true,
      digest: normalizeDigest(apk?['digest']),
    );
  }

  /// The device's ABI, probed once per service instance. Tests inject a
  /// canned loader; production uses the `dart:ffi` [currentDeviceAbi] probe.
  String? _deviceAbi() =>
      _cachedAbi ??= (_abiLoader?.call() ?? currentDeviceAbi());

  static int _asInt(dynamic v) => switch (v) {
        final int i => i,
        final num n => n.toInt(),
        final String s => int.tryParse(s) ?? 0,
        _ => 0,
      };

  static String _normalizeNotes(dynamic body) {
    if (body is! String) return '';
    // Strip the HTML comment blocks GitHub editors leave behind and collapse
    // runs of blank lines so the dialog stays compact.
    final String cleaned = body
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return cleaned;
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  // ─── Download ───────────────────────────────────────────────────────────

  /// Streams the APK to app-private storage, emitting [DownloadProgress]
  /// ticks along the way.
  ///
  /// The returned stream always terminates with exactly one of:
  /// a completion event ([DownloadProgress.filePath]), a cancellation event,
  /// or a failure event. It never throws.
  ///
  /// Integrity (fail-closed, D3): the download is verified against
  /// [expectedDigest] before it is allowed through:
  /// * match → the completion event carries [DownloadProgress.filePath];
  /// * mismatch → the file is deleted and a
  ///   [UpdateFailureReason.digestMismatch] failure is emitted;
  /// * missing/empty digest → the file is deleted and a
  ///   [UpdateFailureReason.digestMissing] failure is emitted. Our release
  ///   pipeline always publishes a `sha256:<hex>` digest on the APK asset,
  ///   so an absent digest means the release metadata is unexpected and we
  ///   refuse to install.
  ///
  /// Callers that parsed a release are expected to forward
  /// [UpdateInfo.digest].
  Stream<DownloadProgress> downloadApk(
    String downloadUrl, {
    String? fileName,
    String? expectedDigest,
    CancelToken? cancelToken,
  }) {
    final StreamController<DownloadProgress> controller =
        StreamController<DownloadProgress>();

    final CancelToken token = cancelToken ?? CancelToken();
    _activeDownload = token;

    final Stopwatch clock = Stopwatch()..start();
    int lastBytes = 0;
    DateTime lastSample = DateTime.now();
    double speed = 0;
    DateTime lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

    void emit(DownloadProgress p) {
      if (controller.isClosed) return;
      controller.add(p);
    }

    Future<void> run() async {
      final String target = fileName ?? _fileNameFromUrl(downloadUrl);
      // Hoisted so the catch blocks can sweep up a half-written file.
      String? targetPath;
      try {
        final Directory dir = await _downloadDirectory();
        final File file = File('${dir.path}${Platform.pathSeparator}$target');
        targetPath = file.path;

        // Remove a stale/partial artefact from an earlier attempt so the
        // installer never sees a truncated APK. The old digest receipt goes
        // too — it is re-written only after the new bytes verify.
        if (await file.exists()) {
          await file.delete();
        }
        await _deleteDigestSidecar(targetPath);

        emit(const DownloadProgress());

        await _client.download(
          downloadUrl,
          file.path,
          cancelToken: token,
          deleteOnError: true,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            // GitHub redirects to a signed CDN URL that must not be cached.
            headers: <String, dynamic>{'Cache-Control': 'no-cache'},
          ),
          onReceiveProgress: (int received, int total) {
            final DateTime now = DateTime.now();
            final int micros = now.difference(lastSample).inMicroseconds;
            final double dt = micros / Duration.microsecondsPerSecond;
            if (dt >= 0.35) {
              // Exponential moving average keeps the readout steady.
              final double instant = (received - lastBytes) / dt;
              speed = speed == 0 ? instant : speed * 0.6 + instant * 0.4;
              lastBytes = received;
              lastSample = now;
            }

            final bool due =
                now.difference(lastEmit) >= _progressThrottle ||
                    (total > 0 && received >= total);
            if (!due) return;
            lastEmit = now;

            emit(DownloadProgress(
              downloaded: received,
              total: total,
              speedBytesPerSecond: speed,
              elapsed: clock.elapsed,
            ));
          },
        );

        if (!await file.exists()) {
          emit(_failed(const AppFailure(
            kind: FailureKind.storage,
            message: 'Download finished but the file is missing.',
          )));
          return;
        }

        // A zero-byte file means the transfer silently produced nothing.
        final int written = await file.length();
        if (written <= 0) {
          await file.delete();
          emit(_failed(const AppFailure(
            kind: FailureKind.network,
            message: 'Downloaded file is empty. Please try again.',
          )));
          return;
        }

        // ── Integrity gate (fail-closed) ──────────────────────────────────
        // * digest match    → pass
        // * digest mismatch → delete the file, report digestMismatch
        // * digest missing  → delete the file, report digestMissing (D3)
        // Either way a tampered/unexpected download never reaches the
        // installer. There is no opt-out: a `null`/empty digest is treated
        // exactly like a missing published digest and refused (D3).
        final String? wanted = expectedDigest?.trim().toLowerCase();
        if (wanted == null || wanted.isEmpty) {
          await deleteDownload(targetPath);
          emit(_failed(const AppFailure(
            kind: FailureKind.validation,
            message: 'Downloaded update has no published digest; refusing '
                'to install (fail-closed).',
            details: <String, dynamic>{
              'reason': UpdateFailureReason.digestMissing,
            },
          )));
          return;
        }

        final String? actual = await DigestVerifier.computeSha256(file);
        if (actual == null || !DigestVerifier.constantTimeEquals(actual, wanted)) {
          await deleteDownload(targetPath);
          emit(_failed(const AppFailure(
            kind: FailureKind.validation,
            message: 'Downloaded update failed the SHA-256 integrity '
                'check and was deleted.',
            details: <String, dynamic>{
              'reason': UpdateFailureReason.digestMismatch,
            },
          )));
          return;
        }

        // Persist the verified digest as a sidecar receipt so a later
        // session can re-verify this file before restoring it. Without the
        // receipt a restart refuses to reinstall (fail-closed, M-2).
        await _writeDigestSidecar(targetPath, wanted);

        clock.stop();
        emit(DownloadProgress(
          downloaded: written,
          total: written,
          isComplete: true,
          filePath: file.path,
          speedBytesPerSecond: speed,
          elapsed: clock.elapsed,
        ));
      } on DioException catch (e, st) {
        if (CancelToken.isCancel(e)) {
          // Leave no truncated APK behind after an abort.
          await deleteDownload(targetPath);
          emit(const DownloadProgress(isCancelled: true));
        } else {
          await deleteDownload(targetPath);
          emit(_failed(_mapError(e, st)));
        }
      } catch (e, st) {
        await deleteDownload(targetPath);
        emit(_failed(_mapError(e, st)));
      } finally {
        if (_activeDownload == token) _activeDownload = null;
        await controller.close();
      }
    }

    // Fire-and-forget; every outcome is reported through the stream.
    unawaited(run());
    return controller.stream;
  }

  DownloadProgress _failed(AppFailure failure) => DownloadProgress(
        error: failure.message,
        failure: failure,
      );

  /// Cancels the in-flight download, if any.
  void cancelDownload([String reason = 'cancelled by user']) {
    final CancelToken? token = _activeDownload;
    if (token != null && !token.isCancelled) {
      token.cancel(reason);
    }
  }

  /// Picks a writable, installer-reachable directory.
  ///
  /// App-specific external storage is preferred: it survives cache eviction
  /// during a long download and is already covered by open_filex's
  /// FileProvider paths, so no runtime storage permission is needed.
  Future<Directory> _downloadDirectory() async {
    if (Platform.isAndroid) {
      final Directory? external = await _tryDir(getExternalStorageDirectory);
      if (external != null) return external;
    }
    final Directory? support = await _tryDir(getApplicationSupportDirectory);
    if (support != null) return support;
    final Directory? temp = await _tryDir(getTemporaryDirectory);
    if (temp != null) return temp;
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory?> _tryDir(
      Future<Directory?> Function() provider) async {
    try {
      final Directory? dir = await provider();
      if (dir == null) return null;
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// Derives a safe file name from a download URL, defaulting to the
  /// `Shell-Mind-v{version}.apk` convention.
  static String _fileNameFromUrl(String url) {
    try {
      final List<String> segments = Uri.parse(url)
          .path
          .split('/')
          .where((String s) => s.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        final String decoded = Uri.decodeComponent(segments.last);
        if (decoded.toLowerCase().endsWith('.apk')) return _sanitize(decoded);
      }
    } catch (_) {
      // fall through
    }
    return '$repoName-update.apk';
  }

  /// Strips path separators and other characters that are illegal in a file
  /// name — the value ultimately comes from a remote server.
  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');

  // ─── Install ────────────────────────────────────────────────────────────

  /// Whether this platform can install a sideloaded APK at all.
  bool get canInstallApk => !kIsWeb && Platform.isAndroid;

  /// True when the user has already allowed "install unknown apps".
  ///
  /// Always `false` on non-Android platforms.
  Future<bool> canRequestInstall() async {
    if (!canInstallApk) return false;
    try {
      final PermissionStatus status =
          await Permission.requestInstallPackages.status;
      return status.isGranted;
    } catch (_) {
      // Some OEM builds reject the query; assume "not granted" and let the
      // install attempt surface the real problem.
      return false;
    }
  }

  /// Ensures the `REQUEST_INSTALL_PACKAGES` permission is granted, opening the
  /// system settings screen when the user has to flip the switch manually.
  ///
  /// Returns `Success(true)` when installation may proceed.
  Future<Result<bool>> ensureInstallPermission() async {
    if (!canInstallApk) {
      return const Result<bool>.failure(AppFailure(
        kind: FailureKind.permission,
        message: 'Installing APKs is only supported on Android.',
      ));
    }

    return Result.guard<bool>(() async {
      PermissionStatus status = await Permission.requestInstallPackages.status;
      if (status.isGranted) return true;

      status = await Permission.requestInstallPackages.request();
      if (status.isGranted) return true;

      // Android exposes this as a settings toggle rather than a dialog, so a
      // denial means "send the user to Settings".
      await openAppSettings();
      return false;
    }, onError: (Object e, StackTrace st) => _mapError(e, st));
  }

  /// Hands [filePath] to the Android package installer.
  ///
  /// `Success(true)` means the installer was launched — the user still has to
  /// confirm the installation, so this is not a guarantee of success.
  Future<Result<bool>> installApk(String filePath) async {
    if (!canInstallApk) {
      return const Result<bool>.failure(AppFailure(
        kind: FailureKind.permission,
        message: 'Installing APKs is only supported on Android.',
      ));
    }

    final File file = File(filePath);
    if (!await file.exists()) {
      return Result<bool>.failure(AppFailure.notFound(
        message: 'The downloaded file is no longer available.',
      ));
    }

    final Result<bool> permission = await ensureInstallPermission();
    if (permission.isFailure || permission.getOrElse(false) == false) {
      return permission.isFailure
          ? Result<bool>.failure(permission.failureOrNull!.failure)
          : const Result<bool>.failure(AppFailure(
              kind: FailureKind.permission,
              message:
                  'Allow "install unknown apps" for Shell-Mind, then retry.',
            ));
    }

    return Result.guard<bool>(() async {
      final OpenResult result = await OpenFilex.open(
        filePath,
        type: apkMimeType,
      );
      switch (result.type) {
        case ResultType.done:
          return true;
        case ResultType.fileNotFound:
          throw AppFailureException(AppFailure.notFound(
            message: 'APK not found at ${file.uri.pathSegments.last}.',
          ));
        case ResultType.permissionDenied:
          throw AppFailureException(const AppFailure(
            kind: FailureKind.permission,
            message: 'Android blocked the installer. Check app permissions.',
          ));
        case ResultType.noAppToOpen:
          throw AppFailureException(const AppFailure(
            kind: FailureKind.unexpected,
            message: 'No package installer available on this device.',
          ));
        case ResultType.error:
          throw AppFailureException(AppFailure(
            kind: FailureKind.unexpected,
            message: 'Could not start the installer: ${result.message}',
          ));
      }
    }, onError: (Object e, StackTrace st) => _mapError(e, st));
  }

  /// Removes a previously downloaded APK and its digest sidecar (best
  /// effort).
  Future<void> deleteDownload(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final File file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup failures are never worth surfacing to the user.
    }
    await _deleteDigestSidecar(filePath);
  }

  /// Resolves the absolute path of an APK that was downloaded during an
  /// earlier run, or `null` when it is gone. Lets the UI jump straight to
  /// "install" after a restart instead of re-downloading.
  Future<String?> locateDownload(String fileName) async {
    if (fileName.isEmpty) return null;
    try {
      final Directory dir = await _downloadDirectory();
      final File file =
          File('${dir.path}${Platform.pathSeparator}${_sanitize(fileName)}');
      if (await file.exists() && await file.length() > 0) return file.path;
    } catch (_) {
      // A missing file is a normal outcome, not an error.
    }
    return null;
  }

  /// Resolves a previously downloaded APK **only when it still passes the
  /// same SHA-256 integrity gate the download itself went through**.
  ///
  /// Cross-session restore must never blindly trust a file found on disk
  /// (M-2): between sessions the artefact may have been replaced, corrupted
  /// or truncated. The verification mirrors the download-time gate:
  ///
  /// * the digest sidecar must exist and match [expectedDigest] — a missing
  ///   sidecar means the APK predates this gate or its receipt was lost,
  ///   and is refused (fail-closed);
  /// * the APK bytes are re-hashed and must still match that digest.
  ///
  /// On any failure the APK and its sidecar are deleted so an unverifiable
  /// artefact can neither reach the installer nor linger, and `null` is
  /// returned.
  Future<String?> locateVerifiedDownload(
    String fileName, {
    required String? expectedDigest,
  }) async {
    final String? path = await locateDownload(fileName);
    if (path == null) return null;
    try {
      final File file = File(path);

      // Gate 1: the sidecar receipt must agree with the release digest.
      final String? wanted = expectedDigest?.trim().toLowerCase();
      final String? recorded =
          normalizeDigest(await _readDigestSidecar(path));
      if (wanted == null ||
          wanted.isEmpty ||
          recorded == null ||
          !DigestVerifier.constantTimeEquals(recorded, wanted)) {
        await deleteDownload(path);
        return null;
      }

      // Gate 2: the bytes on disk must still hash to that digest.
      final String? actual = await DigestVerifier.computeSha256(file);
      if (actual == null ||
          !DigestVerifier.constantTimeEquals(actual, wanted)) {
        await deleteDownload(path);
        return null;
      }

      return path;
    } catch (_) {
      return null;
    }
  }

  /// Reads the raw sidecar text next to the APK at [apkPath], `null` when
  /// absent or unreadable. Normalisation/validation is the caller's job.
  Future<String?> _readDigestSidecar(String apkPath) async {
    try {
      final File sidecar = File(_sidecarPathFor(apkPath));
      if (!await sidecar.exists()) return null;
      return await sidecar.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Writes [digest] as the sidecar receipt of the APK at [apkPath].
  ///
  /// Best effort: a failed write only means the file will not be restorable
  /// in a later session (fail-closed), never installable without proof.
  Future<void> _writeDigestSidecar(String apkPath, String digest) async {
    try {
      await File(_sidecarPathFor(apkPath)).writeAsString(digest, flush: true);
    } catch (_) {
      // The download itself is still valid for this session.
    }
  }

  /// Deletes the sidecar paired with the APK at [apkPath] (best effort).
  Future<void> _deleteDigestSidecar(String apkPath) async {
    try {
      final File sidecar = File(_sidecarPathFor(apkPath));
      if (await sidecar.exists()) await sidecar.delete();
    } catch (_) {
      // Cleanup failures are never worth surfacing to the user.
    }
  }

  // ─── Download cache inspection ──────────────────────────────────

  /// Absolute path of the directory where APK downloads are cached. Exposed so
  /// the settings "storage & privacy" screen can report and clear it. Never
  /// throws — resolves lazily and creates the directory on demand.
  Future<Directory> downloadDirectory() => _downloadDirectory();

  /// Lists every cached `.apk` currently on disk (newest downloads included).
  ///
  /// Best-effort: any I/O error yields an empty list rather than throwing, so
  /// a size readout can never break the settings screen.
  Future<List<File>> cachedApks() async {
    try {
      final Directory dir = await _downloadDirectory();
      if (!await dir.exists()) return const <File>[];
      final List<File> apks = <File>[];
      await for (final FileSystemEntity e in dir.list(followLinks: false)) {
        if (e is File && e.path.toLowerCase().endsWith('.apk')) apks.add(e);
      }
      return apks;
    } catch (_) {
      return const <File>[];
    }
  }

  /// Total bytes occupied by cached update APKs.
  Future<int> downloadCacheBytes() async {
    int total = 0;
    for (final File f in await cachedApks()) {
      try {
        total += await f.length();
      } catch (_) {
        // Skip unreadable entries.
      }
    }
    return total;
  }

  /// Deletes every cached update APK, returning the number of bytes freed.
  ///
  /// Hive data and secure storage are untouched — this only reclaims the
  /// sideloaded installer packages. Any in-flight download token is left
  /// alone; callers cancel first if needed.
  Future<int> clearDownloadCache() async {
    int freed = 0;
    for (final File f in await cachedApks()) {
      try {
        freed += await f.length();
        await f.delete();
        await _deleteDigestSidecar(f.path);
      } catch (_) {
        // A file that vanished mid-sweep is not worth surfacing.
      }
    }
    return freed;
  }

  // ─── Error mapping ──────────────────────────────────────────────────────

  AppFailure _mapError(Object error, StackTrace stack) {
    if (error is AppFailure) return error.copyWith(stackTrace: stack);
    if (error is AppFailureException) return error.failure;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          return AppFailure.cancelled(cause: error);
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          final Duration limit =
              _client.options.connectTimeout ?? AppConstants.httpConnectTimeout;
          return AppFailure.timeout(
            limit,
            cause: error,
            stackTrace: stack,
          );
        case DioExceptionType.badCertificate:
          return AppFailure.network(error, stackTrace: stack);
        case DioExceptionType.connectionError:
          return AppFailure.network(error, stackTrace: stack);
        case DioExceptionType.badResponse:
          return _mapHttpStatus(error);
        case DioExceptionType.unknown:
          final Object? osError = error.error;
          if (osError is SocketException) {
            return AppFailure.network(osError, stackTrace: stack);
          }
          if (osError is FileSystemException) {
            return AppFailure.storage(
              'Could not write the update file to storage.',
              cause: osError,
            );
          }
          return AppFailure.network(error, stackTrace: stack);
      }
    }

    if (error is FileSystemException) {
      return AppFailure.storage(
        'Could not write the update file to storage.',
        cause: error,
      );
    }

    return AppFailure.unexpected(error, stackTrace: stack);
  }

  AppFailure _mapHttpStatus(DioException error) {
    final int? status = error.response?.statusCode;
    switch (status) {
      case 403:
      case 429:
        // Unauthenticated GitHub API access is capped at 60 req/h per IP.
        final String reset = _rateLimitReset(error.response);
        return AppFailure(
          kind: FailureKind.network,
          message: reset.isEmpty
              ? 'GitHub API rate limit reached. Try again later.'
              : 'GitHub API rate limit reached. Try again $reset.',
          code: status,
          cause: error,
          details: const <String, dynamic>{
            'reason': UpdateFailureReason.rateLimit,
          },
          recoverable: true,
        );
      case 404:
        return AppFailure.notFound(
          message: 'No releases published for $repoName yet.',
          cause: error,
        ).copyWith(details: const <String, dynamic>{
          'reason': UpdateFailureReason.noReleases,
        });
      case 401:
        return AppFailure.auth(
          message: 'GitHub rejected the request.',
          cause: error,
        );
      default:
        if (status != null && status >= 500) {
          return AppFailure(
            kind: FailureKind.network,
            message: 'GitHub is unavailable ($status). Try again shortly.',
            code: status,
            cause: error,
            recoverable: true,
          );
        }
        return AppFailure.network(error, stackTrace: error.stackTrace);
    }
  }

  static String _rateLimitReset(Response<dynamic>? response) {
    final String? raw = response?.headers.value('x-ratelimit-reset');
    final int? epoch = int.tryParse(raw ?? '');
    if (epoch == null) return '';
    final DateTime at =
        DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toLocal();
    final String hh = at.hour.toString().padLeft(2, '0');
    final String mm = at.minute.toString().padLeft(2, '0');
    return 'after $hh:$mm';
  }
}

/// Exposes the app-wide [UpdateService].
final Provider<UpdateService> updateServiceProvider =
    Provider<UpdateService>((Ref ref) {
  final UpdateService service = UpdateService();
  ref.onDispose(service.dispose);
  return service;
});
