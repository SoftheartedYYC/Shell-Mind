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
import '../utils/result.dart';
import '../utils/version_utils.dart';

// ─── Value objects ────────────────────────────────────────────────────────

/// Metadata describing a GitHub release that is newer than the running build.
@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSize,
    required this.publishedAt,
    required this.assetName,
    this.releaseUrl = '',
    this.isPrerelease = false,
  });

  /// Bare version string (`1.1.0`) — the `v` prefix is stripped.
  final String version;

  /// Git tag as published on GitHub (`v1.1.0`).
  final String tagName;

  /// Release body, rendered as (lightweight) markdown-free plain text.
  final String releaseNotes;

  /// Direct `browser_download_url` of the APK asset.
  final String downloadUrl;

  /// Asset size in bytes; `0` when GitHub did not report one.
  final int fileSize;

  final DateTime publishedAt;

  /// File name of the asset, e.g. `Shell-Mind-v1.1.0.apk`.
  final String assetName;

  /// Human-facing release page (`https://github.com/.../releases/tag/v1.1.0`).
  final String releaseUrl;

  final bool isPrerelease;

  UpdateInfo copyWith({
    String? version,
    String? tagName,
    String? releaseNotes,
    String? downloadUrl,
    int? fileSize,
    DateTime? publishedAt,
    String? assetName,
    String? releaseUrl,
    bool? isPrerelease,
  }) =>
      UpdateInfo(
        version: version ?? this.version,
        tagName: tagName ?? this.tagName,
        releaseNotes: releaseNotes ?? this.releaseNotes,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        fileSize: fileSize ?? this.fileSize,
        publishedAt: publishedAt ?? this.publishedAt,
        assetName: assetName ?? this.assetName,
        releaseUrl: releaseUrl ?? this.releaseUrl,
        isPrerelease: isPrerelease ?? this.isPrerelease,
      );

  @override
  bool operator ==(Object other) =>
      other is UpdateInfo &&
      other.tagName == tagName &&
      other.downloadUrl == downloadUrl;

  @override
  int get hashCode => Object.hash(tagName, downloadUrl);

  @override
  String toString() => 'UpdateInfo($tagName, ${fileSize}B)';
}

/// A single tick of the APK download.
///
/// Emitted with increasing [downloaded] values, then exactly once as either
/// a completion ([isComplete] with a non-null [filePath]), a cancellation
/// ([isCancelled]) or a failure ([error] / [failure]).
@immutable
class DownloadProgress {
  const DownloadProgress({
    this.downloaded = 0,
    this.total = 0,
    this.isComplete = false,
    this.isCancelled = false,
    this.filePath,
    this.error,
    this.failure,
    this.speedBytesPerSecond = 0,
    this.elapsed = Duration.zero,
  });

  const DownloadProgress.initial() : this();

  /// Bytes written to disk so far.
  final int downloaded;

  /// Total bytes, `0` while unknown (chunked / no Content-Length).
  final int total;

  /// `0.0`–`1.0`. Always `0.0` when [total] is unknown.
  double get percentage =>
      total <= 0 ? 0.0 : (downloaded / total).clamp(0.0, 1.0).toDouble();

  /// True while the transfer is still running (not complete/cancelled/failed).
  bool get isActive => !isComplete && !isCancelled && error == null;

  /// Whether [total] is known, i.e. a determinate bar can be drawn.
  bool get isDeterminate => total > 0;

  final bool isComplete;
  final bool isCancelled;

  /// Absolute path of the finished APK (only when [isComplete]).
  final String? filePath;

  /// Human-readable error message (only on failure).
  final String? error;

  /// Structured counterpart of [error] for [ErrorBanner]-style rendering.
  final AppFailure? failure;

  /// Smoothed transfer rate, used for the `1.4 MB/s` readout.
  final double speedBytesPerSecond;

  final Duration elapsed;

  /// Remaining time estimate, or `null` when it cannot be computed.
  Duration? get remaining {
    if (!isDeterminate || speedBytesPerSecond <= 0) return null;
    final int left = total - downloaded;
    if (left <= 0) return Duration.zero;
    return Duration(milliseconds: (left / speedBytesPerSecond * 1000).round());
  }

  DownloadProgress copyWith({
    int? downloaded,
    int? total,
    bool? isComplete,
    bool? isCancelled,
    String? filePath,
    String? error,
    AppFailure? failure,
    double? speedBytesPerSecond,
    Duration? elapsed,
  }) =>
      DownloadProgress(
        downloaded: downloaded ?? this.downloaded,
        total: total ?? this.total,
        isComplete: isComplete ?? this.isComplete,
        isCancelled: isCancelled ?? this.isCancelled,
        filePath: filePath ?? this.filePath,
        error: error ?? this.error,
        failure: failure ?? this.failure,
        speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
        elapsed: elapsed ?? this.elapsed,
      );

  @override
  String toString() =>
      'DownloadProgress(${(percentage * 100).toStringAsFixed(1)}%, '
      '$downloaded/$total, complete: $isComplete)';
}

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
  UpdateService([this._dio, this._packageInfoLoader]);

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

  final Dio? _dio;
  final Future<PackageInfo> Function()? _packageInfoLoader;

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
  Future<Result<UpdateInfo?>> checkForUpdate({
    bool includePrerelease = false,
    CancelToken? cancelToken,
  }) async {
    return Result.guard<UpdateInfo?>(
      () async {
        final Response<dynamic> response = await _client.get<dynamic>(
          '$_apiBase/releases/latest',
          options: Options(headers: _githubHeaders),
          cancelToken: cancelToken,
        );

        final dynamic data = response.data;
        if (data is! Map<String, dynamic>) {
          throw AppFailureException(
            const AppFailure(
              kind: FailureKind.validation,
              message: 'GitHub returned an unexpected payload.',
            ),
          );
        }

        final UpdateInfo info = _parseRelease(data);
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

  UpdateInfo _parseRelease(Map<String, dynamic> json) {
    final String tagName = (json['tag_name'] ?? json['name'] ?? '') as String;
    final String version = normalizeVersion(tagName);

    final Map<String, dynamic>? apk = _pickApkAsset(json['assets'], version);

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
    );
  }

  /// Chooses the most likely "universal" APK from a release's asset list.
  ///
  /// Preference order: exact `Shell-Mind-v{version}.apk` → any asset with the
  /// android package MIME type → any `*.apk` (largest wins, which favours a
  /// fat/universal build over per-ABI splits).
  Map<String, dynamic>? _pickApkAsset(dynamic assets, String version) {
    if (assets is! List) return null;

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

    final String preferred =
        '$repoName-v$version.apk'.toLowerCase();
    for (final Map<String, dynamic> a in apks) {
      if (((a['name'] ?? '') as String).toLowerCase() == preferred) return a;
    }

    apks.sort((Map<String, dynamic> x, Map<String, dynamic> y) =>
        _asInt(y['size']).compareTo(_asInt(x['size'])));
    return apks.first;
  }

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
  Stream<DownloadProgress> downloadApk(
    String downloadUrl, {
    String? fileName,
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
        // installer never sees a truncated APK.
        if (await file.exists()) {
          await file.delete();
        }

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

  /// Removes a previously downloaded APK (best effort).
  Future<void> deleteDownload(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final File file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup failures are never worth surfacing to the user.
    }
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
        );
      case 404:
        return AppFailure.notFound(
          message: 'No releases published for $repoName yet.',
          cause: error,
        );
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
