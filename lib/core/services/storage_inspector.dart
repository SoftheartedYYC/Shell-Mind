import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'update_service.dart';

/// A snapshot of how much disk the app's reclaimable data occupies.
class CacheBreakdown {
  const CacheBreakdown({
    this.hiveBytes = 0,
    this.downloadBytes = 0,
  });

  /// Combined size of the Hive box files (server configs, chat history, …).
  final int hiveBytes;

  /// Combined size of downloaded update APKs still cached on disk.
  final int downloadBytes;

  /// Grand total shown at the top of the storage dialog.
  int get totalBytes => hiveBytes + downloadBytes;

  @override
  String toString() =>
      'CacheBreakdown(hive: $hiveBytes, downloads: $downloadBytes)';
}

/// Reports (and helps reclaim) the app's on-disk footprint for the
/// "Storage & privacy" settings screen.
///
/// The byte-counting core ([sumFiles]) is a pure, dependency-free static so it
/// can be exercised against a real temporary directory in unit tests without
/// any platform channel. The platform-specific directory resolution
/// ([getApplicationDocumentsDirectory]) is isolated in [hiveBytes] and fails
/// soft (returns `0`) so a missing plugin can never crash the settings UI.
class StorageInspector {
  StorageInspector({UpdateService? updateService}) : _update = updateService;

  final UpdateService? _update;

  /// Hive box files use these extensions (`.hive` for the live box, `.hivec`
  /// for a compacted one). See `hive_ce`'s `backend_manager`.
  static bool _isHiveFile(String path) {
    final String lower = path.toLowerCase();
    return lower.endsWith('.hive') || lower.endsWith('.hivec');
  }

  /// Sums the sizes of files in [dir].
  ///
  /// Pure and testable: walks the directory (optionally [recursive]) and adds
  /// up every [File] whose path satisfies [include] (defaults to "all files").
  /// Any I/O error on an individual entry is skipped, and a non-existent
  /// directory yields `0` rather than throwing.
  static Future<int> sumFiles(
    Directory dir, {
    bool recursive = false,
    bool Function(String path)? include,
  }) async {
    try {
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final FileSystemEntity e
          in dir.list(recursive: recursive, followLinks: false)) {
        if (e is! File) continue;
        if (include != null && !include(e.path)) continue;
        try {
          total += await e.length();
        } catch (_) {
          // An entry that disappeared mid-scan is simply not counted.
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Total size of the Hive box files under the app documents directory.
  Future<int> hiveBytes() async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      return await sumFiles(dir, include: _isHiveFile);
    } catch (_) {
      // path_provider is unavailable (e.g. unit tests) — report nothing.
      return 0;
    }
  }

  /// Total size of cached update APKs, delegated to [UpdateService].
  Future<int> downloadBytes() async {
    final UpdateService? svc = _update;
    if (svc == null) return 0;
    return svc.downloadCacheBytes();
  }

  /// Full storage snapshot for the dialog.
  Future<CacheBreakdown> inspect() async {
    return CacheBreakdown(
      hiveBytes: await hiveBytes(),
      downloadBytes: await downloadBytes(),
    );
  }

  /// Deletes cached update APKs (Hive data is preserved), returning the number
  /// of bytes freed. No-op when no [UpdateService] is wired.
  Future<int> clearDownloadCache() async {
    final UpdateService? svc = _update;
    if (svc == null) return 0;
    return svc.clearDownloadCache();
  }
}

/// App-wide [StorageInspector], wired to the shared [UpdateService].
final Provider<StorageInspector> storageInspectorProvider =
    Provider<StorageInspector>((Ref ref) {
  final UpdateService updates = ref.watch(updateServiceProvider);
  return StorageInspector(updateService: updates);
});
