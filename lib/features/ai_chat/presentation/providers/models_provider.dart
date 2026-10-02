import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/ai_service.dart';
import '../../domain/entities/ai_provider.dart';
import 'chat_providers.dart';

/// Merges the fetched, built-in and user-custom model catalogues into a single
/// ordered, de-duplicated list.
///
/// Ordering policy (first occurrence wins):
///  1. [fetchedIds] — whatever the provider returned, in provider order;
///  2. [provider]'s built-in models that were not already listed;
///  3. [customIds] — user-added models that were not already listed.
///
/// A fetched id that matches a built-in model reuses the built-in [AiModel] so
/// its friendly [AiModel.name]/[AiModel.description] survive; otherwise a bare
/// `AiModel(id, name: id)` is synthesised. Exposed at library scope so it can be
/// unit-tested without a Riverpod container.
List<AiModel> mergeAvailableModels(
  AiProvider provider,
  List<String> fetchedIds,
  Iterable<String> customIds,
) {
  final Map<String, AiModel> builtInById = <String, AiModel>{
    for (final AiModel m in provider.models) m.id: m,
  };

  final List<AiModel> merged = <AiModel>[];
  final Set<String> seen = <String>{};

  void add(String id) {
    final String trimmed = id.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) return;
    seen.add(trimmed);
    merged.add(builtInById[trimmed] ?? AiModel(id: trimmed, name: trimmed));
  }

  for (final String id in fetchedIds) {
    add(id);
  }
  for (final AiModel m in provider.models) {
    add(m.id);
  }
  for (final String id in customIds) {
    add(id);
  }
  return merged;
}

/// Per-provider list of user-added custom model ids.
///
/// Rebuilds when the selected provider changes (it watches
/// [selectedProviderProvider]); add/remove persist through
/// [PreferencesService] and update the exposed state so the merged
/// [availableModelsProvider] recomputes reactively.
class CustomModelsController extends Notifier<List<String>> {
  @override
  List<String> build() {
    final AiProvider provider = ref.watch(selectedProviderProvider);
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    return prefs.getCustomModels(provider.id);
  }

  /// Appends [modelId] to [providerId]'s custom list (trims, ignores blanks and
  /// duplicates). No-op when already present.
  Future<void> addCustomModel(String providerId, String modelId) async {
    final String id = modelId.trim();
    if (id.isEmpty) return;

    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    final List<String> current = prefs.getCustomModels(providerId);
    if (current.contains(id)) return;

    final List<String> next = <String>[...current, id];
    await prefs.setCustomModels(providerId, next);
    _syncIfCurrent(providerId, next);
  }

  /// Removes [modelId] from [providerId]'s custom list.
  Future<void> removeCustomModel(String providerId, String modelId) async {
    final PreferencesService prefs = ref.read(preferencesServiceProvider);
    final List<String> current = prefs.getCustomModels(providerId);
    final List<String> next =
        current.where((String m) => m != modelId).toList(growable: false);
    if (next.length == current.length) return;

    await prefs.setCustomModels(providerId, next);
    _syncIfCurrent(providerId, next);
  }

  /// Publishes the new list only when it belongs to the active provider, so a
  /// background provider's edits don't leak into the current UI.
  void _syncIfCurrent(String providerId, List<String> next) {
    if (ref.read(selectedProviderProvider).id == providerId) {
      state = next;
    }
  }
}

/// The custom-model list for the currently selected provider.
final NotifierProvider<CustomModelsController, List<String>>
    customModelsProvider =
    NotifierProvider<CustomModelsController, List<String>>(
  CustomModelsController.new,
);

/// Snapshot of the resolved model catalogue for the settings picker.
class AvailableModelsState {
  const AvailableModelsState({
    required this.models,
    required this.customIds,
    this.fetchError,
  });

  /// Merged, ordered list to render (built-in ∪ fetched ∪ custom).
  final List<AiModel> models;

  /// Ids the user added manually — drives the "custom" badge + delete action.
  final Set<String> customIds;

  /// Set when a credential exists but the live fetch failed. The UI keeps
  /// showing the fallback list and offers a retry; never blocks usage.
  final AppFailure? fetchError;

  bool isCustom(String id) => customIds.contains(id);
}

/// Resolves the selectable model list for the current provider + credential.
///
/// With a key: calls [AiService.fetchModels] and unions the result with the
/// built-in catalogue and the user's custom models. Without a key (or on
/// failure) it falls back to built-in + custom and surfaces [fetchError] so the
/// UI can hint + retry. Always resolves to data (never throws) — the fetch
/// outcome is carried inside [AvailableModelsState].
class AvailableModelsController extends AsyncNotifier<AvailableModelsState> {
  @override
  Future<AvailableModelsState> build() async {
    final AiProvider provider = ref.watch(selectedProviderProvider);
    final Set<String> customIds =
        ref.watch(customModelsProvider).toSet();
    final String apiKey = await ref.watch(apiKeyProvider.future) ?? '';

    List<String> fetched = const <String>[];
    AppFailure? fetchError;

    if (apiKey.trim().isNotEmpty) {
      final AiService service = AiService(
        client: ref.read(dioClientProvider),
        provider: provider,
        apiKey: apiKey,
        model: '',
        temperature: 0,
      );
      final Result<List<String>> result = await service.fetchModels();
      result.when(
        success: (List<String> ids) => fetched = ids,
        failure: (AppFailure f) => fetchError = f,
      );
    }

    return AvailableModelsState(
      models: mergeAvailableModels(provider, fetched, customIds),
      customIds: customIds,
      fetchError: fetchError,
    );
  }

  /// Re-runs the fetch (e.g. from the refresh button or the retry action).
  void refresh() => ref.invalidateSelf();
}

/// The merged model catalogue driving the settings model picker.
final AsyncNotifierProvider<AvailableModelsController, AvailableModelsState>
    availableModelsProvider =
    AsyncNotifierProvider<AvailableModelsController, AvailableModelsState>(
  AvailableModelsController.new,
);
