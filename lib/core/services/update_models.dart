import 'package:flutter/foundation.dart';

import '../utils/result.dart';

// ─── Failure reason markers ─────────────────────────────────────────────

/// Stable string markers stored in [AppFailure.details] under the `reason`
/// key. The service layer cannot reach `BuildContext`, so it tags failures
/// with a machine-readable reason and the UI maps that to a localised string
/// (see `describeUpdateFailure`). Keeping the vocabulary here means both the
/// producer and the localiser agree on the exact tokens.
abstract final class UpdateFailureReason {
  /// GitHub reports no published release for the repository (both the
  /// `/releases/latest` and the `/releases` fallback returned 404, or every
  /// release was a filtered-out draft/pre-release).
  static const String noReleases = 'noReleases';

  /// Unauthenticated GitHub API rate limit (HTTP 403/429) was hit.
  static const String rateLimit = 'rateLimit';

  /// The response body could not be understood.
  static const String badPayload = 'badPayload';

  /// The downloaded APK's SHA-256 did not match the digest published on the
  /// GitHub release asset. The file has already been deleted.
  static const String digestMismatch = 'digestMismatch';

  /// The release asset carries no `digest` field at all. Our own release
  /// pipeline always publishes one, so a missing digest is an anomaly and the
  /// update is refused (fail-closed).
  static const String digestMissing = 'digestMissing';
}

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
    this.digest,
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

  /// `sha256:<hex>` digest published on the release asset, when GitHub
  /// provides one. Compared against the downloaded file before the APK is
  /// allowed through; `null` means the update is refused (fail-closed).
  final String? digest;

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
    String? digest,
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
        digest: digest ?? this.digest,
      );

  @override
  bool operator ==(Object other) =>
      other is UpdateInfo &&
      other.tagName == tagName &&
      other.downloadUrl == downloadUrl;

  @override
  int get hashCode => Object.hash(tagName, downloadUrl);

  @override
  String toString() =>
      'UpdateInfo($tagName, ${fileSize}B, digest: ${digest ?? 'none'})';
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
