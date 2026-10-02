import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../../../ai_chat/presentation/providers/chat_providers.dart';
import '../../../ai_chat/presentation/providers/models_provider.dart';

/// UI state for the AI settings section (multi-provider aware).
class AiSettingsState {
  const AiSettingsState({
    this.provider,
    this.model,
    this.hasKey = false,
    this.maskedKey,
    this.temperature = AppConstants.defaultAiTemperature,
    this.aiAutoExecute = AppConstants.defaultAiAutoExecute,
    this.aiMaxAutoLoops = AppConstants.kDefaultMaxAutoLoops,
    this.configuredProviderIds = const <String>{},
    this.isLoading = true,
  });

  /// Currently selected provider (defaults to OpenAI while loading).
  final AiProvider? provider;

  /// Selected model id within [provider].
  final String? model;

  final bool hasKey;
  final String? maskedKey;
  final double temperature;

  /// Whether the AI agent may run parsed commands autonomously.
  final bool aiAutoExecute;

  /// Cap on automatic command-execution loops per assistant response.
  final int aiMaxAutoLoops;

  /// Ids of providers that already have a stored key — drives the green tick
  /// in the provider list.
  final Set<String> configuredProviderIds;

  final bool isLoading;

  AiProvider get effectiveProvider => provider ?? AiProviders.openai;

  AiSettingsState copyWith({
    AiProvider? provider,
    String? model,
    bool? hasKey,
    String? maskedKey,
    bool clearKey = false,
    double? temperature,
    bool? aiAutoExecute,
    int? aiMaxAutoLoops,
    Set<String>? configuredProviderIds,
    bool? isLoading,
  }) =>
      AiSettingsState(
        provider: provider ?? this.provider,
        model: model ?? this.model,
        hasKey: hasKey ?? this.hasKey,
        maskedKey: clearKey ? null : (maskedKey ?? this.maskedKey),
        temperature: temperature ?? this.temperature,
        aiAutoExecute: aiAutoExecute ?? this.aiAutoExecute,
        aiMaxAutoLoops: aiMaxAutoLoops ?? this.aiMaxAutoLoops,
        configuredProviderIds: configuredProviderIds ?? this.configuredProviderIds,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Loads/saves the multi-provider AI configuration: the selected provider +
/// per-provider model live in [PreferencesService], each provider's API key in
/// [SecureStorageService], and temperature in preferences.
class AiSettingsController extends Notifier<AiSettingsState> {
  SecureStorageService get _secure => ref.read(secureStorageServiceProvider);
  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  @override
  AiSettingsState build() {
    _load();
    return const AiSettingsState();
  }

  Future<void> _load() async {
    final AiProvider provider = AiProviders.getById(_prefs.selectedProviderId);
    final String? storedModel = _prefs.getSelectedModel(provider.id);
    // Resolve against the built-in catalogue but keep custom/fetched model ids.
    final AiModel model = resolveStoredModel(provider, storedModel);
    final String? key = await _secure.getProviderApiKey(provider.id);
    final Set<String> configured = await _configuredProviderIds();

    state = state.copyWith(
      provider: provider,
      model: model.id,
      hasKey: key != null && key.trim().isNotEmpty,
      maskedKey: key == null ? null : maskApiKey(key),
      temperature: _prefs.aiTemperature,
      aiAutoExecute: _prefs.aiAutoExecute,
      aiMaxAutoLoops: _prefs.aiMaxAutoLoops,
      configuredProviderIds: configured,
      isLoading: false,
    );
  }

  /// Probes every provider's stored key so the list can show configured state.
  Future<Set<String>> _configuredProviderIds() async {
    final Set<String> ids = <String>{};
    for (final AiProvider p in AiProviders.all) {
      final String? k = await _secure.getProviderApiKey(p.id);
      if (k != null && k.trim().isNotEmpty) ids.add(p.id);
    }
    return ids;
  }

  /// Switches the active provider, reloading its model + key.
  Future<void> selectProvider(String providerId) async {
    if (state.provider?.id == providerId) return;
    await _prefs.setSelectedProviderId(providerId);
    final AiProvider provider = AiProviders.getById(providerId);
    final String? storedModel = _prefs.getSelectedModel(provider.id);
    final AiModel model = resolveStoredModel(provider, storedModel);
    final String? key = await _secure.getProviderApiKey(provider.id);

    state = state.copyWith(
      provider: provider,
      model: model.id,
      hasKey: key != null && key.trim().isNotEmpty,
      maskedKey: key == null ? null : maskApiKey(key),
      clearKey: key == null,
    );
    _invalidateDependents();
  }

  /// Persists a new API key for the current provider.
  Future<bool> saveKey(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    final String providerId = state.effectiveProvider.id;
    await _secure.saveProviderApiKey(providerId, trimmed);
    final Set<String> configured = <String>{...state.configuredProviderIds, providerId};
    state = state.copyWith(
      hasKey: true,
      maskedKey: maskApiKey(trimmed),
      configuredProviderIds: configured,
    );
    _invalidateDependents();
    return true;
  }

  /// Removes the stored key for the current provider.
  Future<void> clearKey() async {
    final String providerId = state.effectiveProvider.id;
    await _secure.deleteProviderApiKey(providerId);
    final Set<String> configured = <String>{...state.configuredProviderIds}
      ..remove(providerId);
    state = state.copyWith(
      hasKey: false,
      clearKey: true,
      configuredProviderIds: configured,
    );
    _invalidateDependents();
  }

  Future<void> setModel(String modelId) async {
    final String providerId = state.effectiveProvider.id;
    await _prefs.setSelectedModel(providerId, modelId);
    state = state.copyWith(model: modelId);
    _invalidateDependents();
  }

  Future<void> setTemperature(double value) async {
    final double clamped = value.clamp(0.0, 2.0);
    await _prefs.setAiTemperature(clamped);
    state = state.copyWith(temperature: clamped);
    // Temperature is baked into the AiService at construction time.
    ref.invalidate(aiServiceProvider);
  }

  /// Toggles the AI agent's autonomous command-execution mode.
  Future<void> setAiAutoExecute(bool value) async {
    await _prefs.setAiAutoExecute(value);
    state = state.copyWith(aiAutoExecute: value);
  }

  /// Sets the cap on automatic command-execution loops (clamped to the
  /// [AppConstants.kMinMaxAutoLoops, AppConstants.kMaxMaxAutoLoops] range).
  Future<void> setMaxAutoLoops(int value) async {
    final int clamped =
        value.clamp(AppConstants.kMinMaxAutoLoops, AppConstants.kMaxMaxAutoLoops);
    await _prefs.setAiMaxAutoLoops(clamped);
    state = state.copyWith(aiMaxAutoLoops: clamped);
  }

  /// The chat page caches provider/model/key status; keep them in sync.
  void _invalidateDependents() {
    ref.invalidate(selectedProviderProvider);
    ref.invalidate(selectedModelProvider);
    ref.invalidate(apiKeyProvider);
    ref.invalidate(aiServiceProvider);
    ref.invalidate(apiKeyConfiguredProvider);
    // Model catalogue depends on provider + key + custom list; refresh it so a
    // provider switch or key change re-fetches the live `/models` listing.
    ref.invalidate(customModelsProvider);
    ref.invalidate(availableModelsProvider);
  }
}

final NotifierProvider<AiSettingsController, AiSettingsState> aiSettingsProvider =
    NotifierProvider<AiSettingsController, AiSettingsState>(AiSettingsController.new);

/// Masks an API key as `sk-****abcd`, keeping only the last four chars.
String maskApiKey(String key) {
  final String trimmed = key.trim();
  if (trimmed.length <= 4) return '****';
  final String tail = trimmed.substring(trimmed.length - 4);
  return 'sk-****$tail';
}
