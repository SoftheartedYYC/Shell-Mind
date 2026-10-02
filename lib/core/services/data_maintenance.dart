import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_storage_service.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/result.dart';

/// Orchestrates destructive "clear all data" maintenance.
///
/// The three wipe steps are injected as plain closures rather than concrete
/// service references, which keeps the orchestration logic trivially testable
/// (pass recording/throwing closures) without having to mock the singleton
/// storage services — whose private constructors make them awkward to fake.
class DataMaintenance {
  const DataMaintenance({
    required this.wipeHive,
    required this.clearSecure,
    required this.clearPrefs,
  });

  /// Empties every Hive box (clear, not delete — the boxes stay usable).
  final Future<void> Function() wipeHive;

  /// Deletes every secret from the platform keystore.
  final Future<void> Function() clearSecure;

  /// Removes every SharedPreferences key.
  final Future<void> Function() clearPrefs;

  /// Runs all three wipes in sequence, surfacing the first failure as a
  /// [Failure] instead of letting an exception escape to the UI.
  ///
  /// Order matters: Hive first (business data), then the keystore secrets that
  /// reference it, then the lightweight preferences. A later step still runs
  /// only if the earlier ones succeed, so a half-wiped state is never left
  /// silently — the caller gets the error and can retry.
  Future<Result<void>> clearAll() => Result.guard<void>(() async {
        await wipeHive();
        await clearSecure();
        await clearPrefs();
      });
}

/// App-wide [DataMaintenance] wired to the real storage singletons.
final Provider<DataMaintenance> dataMaintenanceProvider =
    Provider<DataMaintenance>((Ref ref) {
  final HiveStorageService hive = ref.watch(hiveStorageServiceProvider);
  final SecureStorageService secure = ref.watch(secureStorageServiceProvider);
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return DataMaintenance(
    wipeHive: hive.wipeEverything,
    clearSecure: secure.deleteAll,
    clearPrefs: prefs.clear,
  );
});
