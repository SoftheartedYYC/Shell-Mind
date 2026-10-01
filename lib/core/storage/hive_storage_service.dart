import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Encapsulates Hive lifecycle and generic box CRUD.
///
/// Call [init] once from `main()` before `runApp`. Feature modules then
/// obtain their box through [box] / [lazyBox] and use the typed helpers
/// below instead of touching Hive directly.
class HiveStorageService {
  HiveStorageService._();

  static final HiveStorageService instance = HiveStorageService._();

  bool _initialised = false;
  bool get isInitialised => _initialised;

  /// Names of every box this service opens eagerly at startup.
  static const List<String> _eagerBoxes = <String>[
    AppConstants.hiveBoxServers,
    AppConstants.hiveBoxSessions,
    AppConstants.hiveBoxChatHistory,
    AppConstants.hiveBoxSnippets,
    AppConstants.hiveBoxMeta,
  ];

  /// Opens every eager box. Safe to call more than once.
  Future<void> init({String? subDirectory}) async {
    if (_initialised) return;
    await Hive.initFlutter(subDirectory);
    for (final String name in _eagerBoxes) {
      await Hive.openBox<dynamic>(name);
    }
    _initialised = true;
  }

  // ─── Box access ─────────────────────────────────────────────────────────

  Box<dynamic> box(String name) {
    _assertInit();
    return Hive.box<dynamic>(name);
  }

  /// Opens a box lazily if it isn't already open. Useful for one-off boxes.
  Future<Box<dynamic>> openBox(String name) async {
    _assertInit();
    if (Hive.isBoxOpen(name)) return Hive.box<dynamic>(name);
    return Hive.openBox<dynamic>(name);
  }

  Future<void> closeBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<dynamic>(name).close();
    }
  }

  Future<void> clearBox(String name) async => box(name).clear();

  Future<void> deleteBox(String name) async {
    await Hive.deleteBoxFromDisk(name);
  }

  // ─── Generic CRUD (works on any dynamic box) ────────────────────────────

  T? get<T>(String boxName, String key, {T? defaultValue}) {
    final dynamic v = box(boxName).get(key, defaultValue: defaultValue);
    return v is T ? v : defaultValue;
  }

  List<T> getAll<T>(String boxName) => box(boxName).values.whereType<T>().toList();

  Map<String, dynamic> toMap(String boxName) =>
      box(boxName).toMap().cast<String, dynamic>();

  Future<void> put(String boxName, String key, dynamic value) =>
      box(boxName).put(key, value);

  Future<void> putAll(String boxName, Map<String, dynamic> entries) =>
      box(boxName).putAll(entries);

  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  Future<void> deleteAllKeys(String boxName, Iterable<String> keys) =>
      box(boxName).deleteAll(keys);

  Future<int> add(String boxName, dynamic value) => box(boxName).add(value);

  bool hasKey(String boxName, String key) => box(boxName).containsKey(key);

  int length(String boxName) => box(boxName).length;

  /// Stream of box events for reactive UI (Riverpod `StreamProvider` friendly).
  Stream<BoxEvent> watch(String boxName, {String? key}) =>
      box(boxName).watch(key: key);

  // ─── Type adapters ──────────────────────────────────────────────────────

  /// Registers a generated adapter. Feature modules call this from their
  /// own bootstrap code before [init].
  void registerAdapter<T>(TypeAdapter<T> adapter, {bool internal = false}) {
    if (!Hive.isAdapterRegistered(adapter.typeId) || internal) {
      Hive.registerAdapter<T>(adapter, internal: internal);
    }
  }

  // ─── Housekeeping ───────────────────────────────────────────────────────

  Future<void> close() async {
    if (!_initialised) return;
    await Hive.close();
    _initialised = false;
  }

  /// Nukes every box owned by the app. Used by "Reset all data" in settings.
  Future<void> wipeEverything() async {
    _assertInit();
    for (final String name in _eagerBoxes) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).clear();
      }
    }
  }

  void _assertInit() {
    if (!_initialised) {
      throw StateError(
        'HiveStorageService.init() must be awaited before accessing boxes.',
      );
    }
  }
}

/// Riverpod provider for the singleton service.
final Provider<HiveStorageService> hiveStorageServiceProvider =
    Provider<HiveStorageService>((ref) => HiveStorageService.instance);

/// Convenience provider that returns an already-opened [Box].
Provider<Box<dynamic>> hiveBoxProvider(String name) =>
    Provider<Box<dynamic>>((ref) {
      final HiveStorageService svc = ref.watch(hiveStorageServiceProvider);
      return svc.box(name);
    });
