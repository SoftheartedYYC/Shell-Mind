import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_storage_service.dart';

/// A user-defined AI provider persisted in Hive.
///
/// Custom providers behave exactly like the built-in ones (OpenAI-compatible
/// base URL + API key + model catalogue); only their provenance differs. The
/// persisted form is a plain JSON map so no Hive [TypeAdapter] registration is
/// required — the entry lives as a [String] inside the `app_meta` box.
@immutable
class CustomAiProvider {
  const CustomAiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.defaultModelId,
  });

  /// Stable unique key with the `custom_` prefix; also namespaces the API key
  /// stored in secure storage (`ai_api_key_custom_<n>`).
  final String id;

  /// Display name shown across settings and the chat header.
  final String name;

  /// OpenAI-compatible API root; `/chat/completions` and `/models` are
  /// appended at call time.
  final String baseUrl;

  /// Optional default model id; when null the provider's model list starts
  /// empty and the first fetched/added model becomes the default.
  final String? defaultModelId;

  /// Decodes a persisted JSON map produced by [toJson]. Returns `null` for
  /// malformed frames so a corrupt entry can never crash startup.
  static CustomAiProvider? fromJsonMap(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    final Object? name = raw['name'];
    final Object? baseUrl = raw['baseUrl'];
    if (id is! String || name is! String || baseUrl is! String) return null;
    if (id.isEmpty || name.trim().isEmpty || baseUrl.trim().isEmpty) {
      return null;
    }
    final Object? model = raw['defaultModelId'];
    return CustomAiProvider(
      id: id,
      name: name.trim(),
      baseUrl: baseUrl.trim(),
      defaultModelId: model is String && model.isNotEmpty ? model : null,
    );
  }

  /// Encodes this provider for Hive persistence (a JSON string).
  Map<String, Object?> toJsonMap() => <String, Object?>{
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        if (defaultModelId != null) 'defaultModelId': defaultModelId,
      };

  @override
  bool operator ==(Object other) =>
      other is CustomAiProvider &&
      other.id == id &&
      other.name == name &&
      other.baseUrl == baseUrl &&
      other.defaultModelId == defaultModelId;

  @override
  int get hashCode => Object.hash(id, name, baseUrl, defaultModelId);

  @override
  String toString() => 'CustomAiProvider($id, $name)';
}

/// Hive-backed CRUD for user-defined AI providers.
///
/// All entries live under a single key in the `app_meta` box (an ordered JSON
/// array), so no dedicated box or adapter is needed. Reads are served from an
/// in-memory snapshot refreshed on every mutation; the snapshot is loaded
/// eagerly at app startup via [preload] and can be re-read synchronously.
class CustomAiProviderStore {
  CustomAiProviderStore({HiveStorageService? hive})
      : _hive = hive ?? HiveStorageService.instance;

  static final CustomAiProviderStore instance =
      CustomAiProviderStore();

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxMeta;
  static const String _key = AppConstants.hiveKeyAiCustomProviders;

  List<CustomAiProvider> _cache = const <CustomAiProvider>[];

  /// Current snapshot. Empty until [preload] (or a mutation) has run.
  List<CustomAiProvider> get all => _cache;

  /// Whether the given id refers to a user-defined provider.
  static bool isCustomId(String id) =>
      id.startsWith(AppConstants.customAiProviderIdPrefix);

  /// Loads the persisted list into the in-memory snapshot. Must be called
  /// after `HiveStorageService.init()` — i.e. during app bootstrap, before
  /// any provider UI is built.
  Future<void> preload() async {
    _cache = _readAllFromBox();
  }

  /// Finds a custom provider by id, or `null` when unknown.
  CustomAiProvider? getById(String id) {
    for (final CustomAiProvider p in _cache) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Persists a new provider and updates the snapshot. The id must be unique
  /// (callers generate it via [newProviderId]); name/baseUrl must be non-blank.
  Future<void> add(CustomAiProvider provider) async {
    if (getById(provider.id) != null) {
      throw StateError('Duplicate custom provider id: ${provider.id}');
    }
    final List<CustomAiProvider> next = <CustomAiProvider>[..._cache, provider];
    await _writeAll(next);
    _cache = next;
  }

  /// Replaces an existing provider (matched by id) and updates the snapshot.
  Future<void> update(CustomAiProvider provider) async {
    final int index =
        _cache.indexWhere((CustomAiProvider p) => p.id == provider.id);
    if (index < 0) {
      throw StateError('Unknown custom provider id: ${provider.id}');
    }
    final List<CustomAiProvider> next = <CustomAiProvider>[
      ..._cache.sublist(0, index),
      provider,
      ..._cache.sublist(index + 1),
    ];
    await _writeAll(next);
    _cache = next;
  }

  /// Removes the provider with [id] (no-op when unknown) and updates the
  /// snapshot.
  Future<void> remove(String id) async {
    final List<CustomAiProvider> next =
        _cache.where((CustomAiProvider p) => p.id != id).toList(growable: false);
    if (next.length == _cache.length) return;
    await _writeAll(next);
    _cache = next;
  }

  /// Generates a fresh unique provider id (`custom_<n>`).
  String newProviderId() {
    int n = 1;
    final Set<String> taken = <String>{for (final CustomAiProvider p in _cache) p.id};
    while (taken.contains('${AppConstants.customAiProviderIdPrefix}$n')) {
      n++;
    }
    return '${AppConstants.customAiProviderIdPrefix}$n';
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  List<CustomAiProvider> _readAllFromBox() {
    final Object? raw = _hive.get<Object>(_box, _key);
    if (raw is! String || raw.isEmpty) return const <CustomAiProvider>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <CustomAiProvider>[];
      final List<CustomAiProvider> parsed = <CustomAiProvider>[
        for (final Object? entry in decoded)
          if (CustomAiProvider.fromJsonMap(entry) case final CustomAiProvider p) p,
      ];
      return List<CustomAiProvider>.unmodifiable(parsed);
    } on FormatException {
      // Corrupt frame — start over rather than crash.
      return const <CustomAiProvider>[];
    }
  }

  Future<void> _writeAll(List<CustomAiProvider> providers) {
    final String encoded = jsonEncode(<Object?>[
      for (final CustomAiProvider p in providers) p.toJsonMap(),
    ]);
    return _hive.put(_box, _key, encoded);
  }
}
