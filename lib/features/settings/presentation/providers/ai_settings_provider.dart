import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../ai_chat/presentation/providers/chat_providers.dart';

/// Models offered in the picker. Order defines the UI sequence.
const List<String> kAvailableChatModels = <String>[
  'gpt-4o-mini',
  'gpt-4o',
  'gpt-3.5-turbo',
];

/// UI state for the AI settings section.
class AiSettingsState {
  const AiSettingsState({
    this.hasKey = false,
    this.maskedKey,
    this.model = AppConstants.defaultChatModel,
    this.temperature = AppConstants.defaultAiTemperature,
    this.isLoading = true,
  });

  final bool hasKey;
  final String? maskedKey;
  final String model;
  final double temperature;
  final bool isLoading;

  AiSettingsState copyWith({
    bool? hasKey,
    String? maskedKey,
    bool clearKey = false,
    String? model,
    double? temperature,
    bool? isLoading,
  }) =>
      AiSettingsState(
        hasKey: hasKey ?? this.hasKey,
        maskedKey: clearKey ? null : (maskedKey ?? this.maskedKey),
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Loads/saves the AI provider configuration (key in secure storage, model +
/// temperature in preferences).
class AiSettingsController extends Notifier<AiSettingsState> {
  SecureStorageService get _secure => ref.read(secureStorageServiceProvider);
  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  @override
  AiSettingsState build() {
    _load();
    return const AiSettingsState();
  }

  Future<void> _load() async {
    final String? key = await _secure.getApiKey();
    state = state.copyWith(
      hasKey: key != null && key.trim().isNotEmpty,
      maskedKey: key == null ? null : maskApiKey(key),
      model: _prefs.aiModel,
      temperature: _prefs.aiTemperature,
      isLoading: false,
    );
  }

  /// Persists a new API key and refreshes dependent providers.
  Future<bool> saveKey(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    await _secure.saveApiKey(trimmed);
    state = state.copyWith(
      hasKey: true,
      maskedKey: maskApiKey(trimmed),
    );
    _invalidateDependents();
    return true;
  }

  /// Removes the stored key.
  Future<void> clearKey() async {
    await _secure.deleteApiKey();
    state = state.copyWith(hasKey: false, clearKey: true);
    _invalidateDependents();
  }

  Future<void> setModel(String model) async {
    await _prefs.setAiModel(model);
    state = state.copyWith(model: model);
    _invalidateDependents();
  }

  Future<void> setTemperature(double value) async {
    final double clamped = value.clamp(0.0, 2.0);
    await _prefs.setAiTemperature(clamped);
    state = state.copyWith(temperature: clamped);
  }

  /// The chat page caches key status + model; keep them in sync.
  void _invalidateDependents() {
    ref.invalidate(apiKeyConfiguredProvider);
    ref.invalidate(activeModelProvider);
  }
}

final NotifierProvider<AiSettingsController, AiSettingsState>
    aiSettingsProvider =
    NotifierProvider<AiSettingsController, AiSettingsState>(
        AiSettingsController.new);

/// Masks an API key as `sk-****abcd`, keeping only the last four chars.
String maskApiKey(String key) {
  final String trimmed = key.trim();
  if (trimmed.length <= 4) return '****';
  final String tail = trimmed.substring(trimmed.length - 4);
  return 'sk-****$tail';
}
