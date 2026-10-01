import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/utils/result.dart';

/// Coarse lifecycle of the update flow, drives which panel the UI renders.
enum UpdateStatus {
  /// Nothing has happened yet (or the user dismissed the result).
  idle,

  /// Talking to the GitHub API.
  checking,

  /// A newer release was found.
  updateAvailable,

  /// APK bytes are streaming to disk.
  downloading,

  /// Download finished, waiting for the user to launch the installer.
  readyToInstall,

  /// The check/download/install is current, or an error is displayed.
  upToDate,

  /// Something failed; [UpdateState.failure] carries the detail.
  error,
}

/// Immutable UI state for the whole update feature.
class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.progress,
    this.failure,
    this.currentVersion = AppConstants.appVersion,
    this.currentBuildNumber = '${AppConstants.appBuildNumber}',
    this.latestKnownVersion,
    this.lastCheckedAt,
    this.downloadedFilePath,
    this.isInstalling = false,
    this.pendingPrompt = false,
    this.hasBootstrapped = false,
  });

  final UpdateStatus status;

  /// Populated whenever a newer release has been discovered. Kept across
  /// `downloading` / `readyToInstall` / `error` transitions so the panel can
  /// keep showing the version + notes.
  final UpdateInfo? updateInfo;

  /// Live download telemetry (only meaningful while [status] is downloading).
  final DownloadProgress? progress;

  /// Structured error for [ErrorBanner]-style rendering.
  final AppFailure? failure;

  final String currentVersion;
  final String currentBuildNumber;

  /// Newest release observed on GitHub, even when it is not newer than the
  /// running build — lets the UI say "up to date · v1.0.0".
  final String? latestKnownVersion;

  final DateTime? lastCheckedAt;

  /// Absolute path of a finished APK download. Survives a restart via
  /// [UpdateNotifier.restoreDownload].
  final String? downloadedFilePath;

  final bool isInstalling;

  /// Set by a *silent* background check that found an update. The app-level
  /// prompt consumes it via [UpdateNotifier.consumePrompt].
  final bool pendingPrompt;

  /// True once the initial version lookup finished.
  final bool hasBootstrapped;

  /// True while any network/install work is in flight.
  bool get isBusy =>
      status == UpdateStatus.checking ||
      status == UpdateStatus.downloading ||
      isInstalling;

  bool get canCheck => !isBusy;

  /// A complete, installable APK is on disk.
  bool get hasDownloadedFile =>
      downloadedFilePath != null && downloadedFilePath!.isNotEmpty;

  bool get hasUpdate => updateInfo != null;

  String? get errorMessage => failure?.message;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? updateInfo,
    bool clearUpdateInfo = false,
    DownloadProgress? progress,
    bool clearProgress = false,
    AppFailure? failure,
    bool clearFailure = false,
    String? currentVersion,
    String? currentBuildNumber,
    String? latestKnownVersion,
    DateTime? lastCheckedAt,
    String? downloadedFilePath,
    bool clearDownloadedFile = false,
    bool? isInstalling,
    bool? pendingPrompt,
    bool? hasBootstrapped,
  }) =>
      UpdateState(
        status: status ?? this.status,
        updateInfo: clearUpdateInfo ? null : (updateInfo ?? this.updateInfo),
        progress: clearProgress ? null : (progress ?? this.progress),
        failure: clearFailure ? null : (failure ?? this.failure),
        currentVersion: currentVersion ?? this.currentVersion,
        currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
        latestKnownVersion: latestKnownVersion ?? this.latestKnownVersion,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
        downloadedFilePath: clearDownloadedFile
            ? null
            : (downloadedFilePath ?? this.downloadedFilePath),
        isInstalling: isInstalling ?? this.isInstalling,
        pendingPrompt: pendingPrompt ?? this.pendingPrompt,
        hasBootstrapped: hasBootstrapped ?? this.hasBootstrapped,
      );
}

/// Drives the check → download → install pipeline.
///
/// The service layer returns [Result]s; this notifier is the only place that
/// translates them into [UpdateState] transitions, so widgets stay free of
/// error-handling branches.
class UpdateNotifier extends Notifier<UpdateState> {
  UpdateService get _service => ref.read(updateServiceProvider);

  StreamSubscription<DownloadProgress>? _subscription;
  bool _downloadInFlight = false;

  /// Guards the once-per-session background check.
  static bool _autoCheckRan = false;

  @override
  UpdateState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    // Kick off the version lookup + silent update check without blocking
    // the first frame.
    Future<void>.microtask(_bootstrap);
    return const UpdateState();
  }

  Future<void> _bootstrap() async {
    final UpdateService service = _service;
    String version = state.currentVersion;
    String build = state.currentBuildNumber;
    try {
      version = await service.currentVersion();
      build = await service.currentBuildNumber();
    } catch (_) {
      // Keep the pubspec-derived fallbacks.
    }

    state = state.copyWith(
      currentVersion: version,
      currentBuildNumber: build,
      hasBootstrapped: true,
    );

    if (_autoCheckRan) return;
    _autoCheckRan = true;
    await checkForUpdate(silent: true);
  }

  // ─── Check ──────────────────────────────────────────────────────────────

  /// Queries GitHub for the latest release.
  ///
  /// When [silent] is true, failures are swallowed — a background check must
  /// never paint an error banner the user did not ask for.
  Future<void> checkForUpdate({bool silent = false}) async {
    if (state.status == UpdateStatus.downloading) return;

    if (!silent) {
      state = state.copyWith(
        status: UpdateStatus.checking,
        clearFailure: true,
      );
    }

    final UpdateService service = _service;
    final Result<UpdateInfo?> result = await service.checkForUpdate();

    // A newer check may have superseded this one while it was in flight.
    if (!silent && state.status != UpdateStatus.checking) return;

    result.when(
      success: (UpdateInfo? info) {
        final String? latest = service.latestKnownVersion;
        if (info == null) {
          state = state.copyWith(
            status: UpdateStatus.upToDate,
            latestKnownVersion: latest,
            lastCheckedAt: DateTime.now(),
            clearFailure: true,
            clearProgress: true,
          );
          return;
        }

        // The APK for this release may already be on disk from a previous
        // session — skip straight to "install".
        state = state.copyWith(
          status: UpdateStatus.updateAvailable,
          updateInfo: info,
          latestKnownVersion: latest,
          lastCheckedAt: DateTime.now(),
          clearFailure: true,
          clearProgress: true,
          clearDownloadedFile: true,
          pendingPrompt: silent,
        );
        // An APK for this exact release may already sit on disk from a previous
        // session, in which case the panel (and the prompt) jump straight to
        // "install" instead of offering a redundant download.
        Future<void>.microtask(() => _tryRestoreDownload(info.assetName));
      },
      failure: (AppFailure failure) {
        if (silent) return;
        state = state.copyWith(
          status: UpdateStatus.error,
          failure: failure,
          lastCheckedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> _tryRestoreDownload(String assetName) async {
    if (assetName.isEmpty) return;
    final String? path = await _service.locateDownload(assetName);
    if (path == null) return;
    // Only useful if the user has not already started a fresh download.
    if (state.status == UpdateStatus.downloading) return;
    if (state.updateInfo?.assetName != assetName) return;
    state = state.copyWith(
      status: UpdateStatus.readyToInstall,
      downloadedFilePath: path,
      clearFailure: true,
      progress: const DownloadProgress(isComplete: true),
    );
  }

  /// Re-checks an already-known release against what is on disk. Called when
  /// the settings panel is opened after a restart.
  Future<void> restoreDownload() async {
    final UpdateInfo? info = state.updateInfo;
    if (info == null) return;
    await _tryRestoreDownload(info.assetName);
  }

  // ─── Download ───────────────────────────────────────────────────────────

  /// Starts (or restarts) the APK download for the pending update.
  Future<void> downloadUpdate() async {
    final UpdateInfo? info = state.updateInfo;
    if (info == null) return;
    if (state.status == UpdateStatus.downloading) return;

    await _subscription?.cancel();
    _subscription = null;

    // A completed file from an earlier attempt is reused instead of
    // re-downloading the same bytes.
    if (state.hasDownloadedFile) {
      state = state.copyWith(status: UpdateStatus.readyToInstall);
      return;
    }

    _downloadInFlight = true;

    state = state.copyWith(
      status: UpdateStatus.downloading,
      clearFailure: true,
      clearDownloadedFile: true,
      progress: const DownloadProgress(),
    );

    // Pin the file name to the release asset so `locateDownload` can find it
    // again after a restart, even if the CDN URL is rewritten or encoded.
    final String? fileName = info.assetName.isEmpty ? null : info.assetName;
    final Stream<DownloadProgress> stream =
        _service.downloadApk(info.downloadUrl, fileName: fileName);

    _subscription = stream.listen(
      _onProgress,
      onError: (Object e) {
        _downloadInFlight = false;
        state = state.copyWith(
          status: UpdateStatus.error,
          failure: AppFailure.unexpected(e),
        );
      },
      cancelOnError: true,
    );
  }

  void _onProgress(DownloadProgress p) {
    // Ticks that arrive after a cancellation belong to a dead transfer.
    if (!_downloadInFlight) return;

    if (p.isComplete) {
      _downloadInFlight = false;
      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        progress: p,
        downloadedFilePath: p.filePath,
        clearFailure: true,
      );
      return;
    }

    if (p.isCancelled) {
      _downloadInFlight = false;
      state = state.copyWith(
        status: UpdateStatus.updateAvailable,
        clearProgress: true,
        clearDownloadedFile: true,
        clearFailure: true,
      );
      return;
    }

    if (p.error != null) {
      _downloadInFlight = false;
      state = state.copyWith(
        status: UpdateStatus.error,
        failure: p.failure ??
            AppFailure(
              kind: FailureKind.network,
              message: p.error ?? 'Download failed.',
            ),
        progress: p,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.downloading,
      progress: p,
    );
  }

  /// Aborts an in-flight download and deletes the partial file.
  Future<void> cancelDownload() async {
    _downloadInFlight = false;
    _service.cancelDownload();
    await _subscription?.cancel();
    _subscription = null;

    state = state.copyWith(
      status: state.updateInfo == null
          ? UpdateStatus.idle
          : UpdateStatus.updateAvailable,
      clearProgress: true,
      clearDownloadedFile: true,
      clearFailure: true,
    );
  }

  // ─── Install ────────────────────────────────────────────────────────────

  /// Launches the Android package installer for the downloaded APK.
  ///
  /// Returns `true` when the installer was handed the file.
  Future<bool> installUpdate() async {
    final String? path = state.downloadedFilePath;
    if (path == null || path.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        failure: const AppFailure(
          kind: FailureKind.notFound,
          message: 'Nothing to install yet — download the update first.',
        ),
      );
      return false;
    }

    state = state.copyWith(isInstalling: true, clearFailure: true);

    final Result<bool> result = await _service.installApk(path);
    final bool launched = result.getOrElse(false);

    state = launched
        ? state.copyWith(isInstalling: false)
        : state.copyWith(
            isInstalling: false,
            status: UpdateStatus.error,
            failure: result.failureOrNull?.failure ??
                const AppFailure(
                  kind: FailureKind.unexpected,
                  message: 'Could not start the installer.',
                ),
          );
    return launched;
  }

  /// Drops the downloaded APK and returns to "update available".
  Future<void> discardDownload() async {
    await _service.deleteDownload(state.downloadedFilePath);
    state = state.copyWith(
      status: state.updateInfo == null
          ? UpdateStatus.idle
          : UpdateStatus.updateAvailable,
      clearDownloadedFile: true,
      clearProgress: true,
      clearFailure: true,
    );
  }

  /// Clears a terminal state (error / up-to-date) back to idle.
  void dismiss() {
    if (state.status == UpdateStatus.downloading) return;
    state = state.copyWith(
      status: state.updateInfo == null
          ? UpdateStatus.idle
          : UpdateStatus.updateAvailable,
      clearFailure: true,
    );
  }

  /// Marks the background prompt as shown so it is not raised twice.
  void consumePrompt() {
    if (!state.pendingPrompt) return;
    state = state.copyWith(pendingPrompt: false);
  }

  /// True when an Android install can be triggered on this platform.
  bool get canInstallApk => _service.canInstallApk;
}

final NotifierProvider<UpdateNotifier, UpdateState> updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
