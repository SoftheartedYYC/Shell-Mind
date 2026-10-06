import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Thin, typed façade over [SharedPreferences] for user-facing settings:
/// theme mode, terminal font size, AI model preferences, and flags.
///
/// Unlike [HiveStorageService], nothing here is business data — it's all
/// small scalar preferences, so a key/value store is the right tool.
class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final SharedPreferences? p = _prefs;
    if (p == null) {
      throw StateError(
        'PreferencesService.init() must be awaited before use.',
      );
    }
    return p;
  }

  // ─── Generic primitives ─────────────────────────────────────────────────

  String? getString(String key) => _p.getString(key);
  int? getInt(String key) => _p.getInt(key);
  double? getDouble(String key) => _p.getDouble(key);
  bool? getBool(String key) => _p.getBool(key);
  List<String>? getStringList(String key) => _p.getStringList(key);

  Future<bool> setString(String key, String value) => _p.setString(key, value);
  Future<bool> setInt(String key, int value) => _p.setInt(key, value);
  Future<bool> setDouble(String key, double value) =>
      _p.setDouble(key, value);
  Future<bool> setBool(String key, bool value) => _p.setBool(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);
  Future<bool> remove(String key) => _p.remove(key);
  Future<bool> clear() => _p.clear();

  String getStringOr(String key, String fallback) =>
      _p.getString(key) ?? fallback;
  double getDoubleOr(String key, double fallback) =>
      _p.getDouble(key) ?? fallback;
  int getIntOr(String key, int fallback) => _p.getInt(key) ?? fallback;
  bool getBoolOr(String key, bool fallback) => _p.getBool(key) ?? fallback;

  // ─── Theme ──────────────────────────────────────────────────────────────

  ThemeMode get themeMode {
    switch (_p.getString(AppConstants.prefKeyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) => _p.setString(
        AppConstants.prefKeyThemeMode,
        mode.name,
      );

  // ─── Terminal preferences ───────────────────────────────────────────────

  double get terminalFontSize => getDoubleOr(
        AppConstants.prefKeyTerminalFontSize,
        AppConstants.defaultTerminalFontSize,
      );

  Future<void> setTerminalFontSize(double size) {
    final double clamped = size.clamp(
      AppConstants.minTerminalFontSize,
      AppConstants.maxTerminalFontSize,
    );
    return setDouble(AppConstants.prefKeyTerminalFontSize, clamped);
  }

  String get terminalFontFamily => getStringOr(
        AppConstants.prefKeyTerminalFontFamily,
        'RobotoMono',
      );

  Future<void> setTerminalFontFamily(String family) =>
      setString(AppConstants.prefKeyTerminalFontFamily, family);

  bool get hapticFeedback =>
      getBoolOr(AppConstants.prefKeyHapticFeedback, true);

  Future<void> setHapticFeedback(bool value) =>
      setBool(AppConstants.prefKeyHapticFeedback, value);

  // ─── AI preferences ─────────────────────────────────────────────────────

  /// Id of the currently selected AI provider (see `AiProviders`).
  String get selectedProviderId => getStringOr(
        AppConstants.prefKeyAiSelectedProvider,
        AppConstants.defaultAiProviderId,
      );

  Future<void> setSelectedProviderId(String providerId) =>
      setString(AppConstants.prefKeyAiSelectedProvider, providerId);

  /// Model id remembered for [providerId], or `null` when unset. Callers fall
  /// back to the provider's default model so `core` stays free of feature
  /// dependencies.
  String? getSelectedModel(String providerId) {
    final String? perProvider = _p.getString(AppConstants.aiModelKey(providerId));
    if (perProvider != null && perProvider.isNotEmpty) return perProvider;
    // Backward compatibility: the legacy single model pref maps to OpenAI.
    if (providerId == AppConstants.defaultAiProviderId) {
      final String? legacy = _p.getString(AppConstants.prefKeyAiModel);
      if (legacy != null && legacy.isNotEmpty) return legacy;
    }
    return null;
  }

  Future<void> setSelectedModel(String providerId, String modelId) =>
      setString(AppConstants.aiModelKey(providerId), modelId);

  /// User-added custom model ids for [providerId], in insertion order.
  /// Stored as a plain string list under `ai_custom_models_<providerId>`.
  List<String> getCustomModels(String providerId) =>
      getStringList(AppConstants.aiCustomModelsKey(providerId)) ??
      const <String>[];

  /// Replaces the custom model list for [providerId].
  Future<void> setCustomModels(String providerId, List<String> modelIds) =>
      setStringList(AppConstants.aiCustomModelsKey(providerId), modelIds);

  /// Legacy provider/model accessors retained for backward compatibility.
  String get aiProvider =>
      getStringOr(AppConstants.prefKeyAiProvider, AppConstants.defaultAiProviderId);

  Future<void> setAiProvider(String provider) =>
      setString(AppConstants.prefKeyAiProvider, provider);

  double get aiTemperature => getDoubleOr(
        AppConstants.prefKeyAiTemperature,
        AppConstants.defaultAiTemperature,
      );

  Future<void> setAiTemperature(double t) =>
      setDouble(AppConstants.prefKeyAiTemperature, t.clamp(0.0, 2.0));

  /// Whether the AI agent may run parsed commands autonomously.
  bool get aiAutoExecute => getBoolOr(
        AppConstants.prefKeyAiAutoExecute,
        AppConstants.defaultAiAutoExecute,
      );

  Future<void> setAiAutoExecute(bool value) =>
      setBool(AppConstants.prefKeyAiAutoExecute, value);

  /// Maximum number of automatic command-execution loops per response.
  int get aiMaxAutoLoops => getIntOr(
        AppConstants.prefKeyAiMaxAutoLoops,
        AppConstants.kDefaultMaxAutoLoops,
      );

  Future<void> setAiMaxAutoLoops(int value) {
    final int clamped =
        value.clamp(AppConstants.kMinMaxAutoLoops, AppConstants.kMaxMaxAutoLoops);
    return setInt(AppConstants.prefKeyAiMaxAutoLoops, clamped);
  }

  /// Whether the AI agent may dial an offline-but-configured server with its
  /// saved credentials before executing a command block targeting it.
  bool get aiAutoConnect => getBoolOr(
        AppConstants.prefKeyAiAutoConnect,
        AppConstants.defaultAiAutoConnect,
      );

  Future<void> setAiAutoConnect(bool value) =>
      setBool(AppConstants.prefKeyAiAutoConnect, value);

  // ─── Session state ──────────────────────────────────────────────────────

  /// Returns the user-selected locale, or `null` to follow the system.
  Locale? get locale {
    final String? code = _p.getString(AppConstants.prefKeyLocale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  /// Persists the locale preference. Pass `null` to follow the system.
  Future<void> setLocale(Locale? locale) {
    if (locale == null) {
      return _p.remove(AppConstants.prefKeyLocale);
    }
    return _p.setString(AppConstants.prefKeyLocale, locale.languageCode);
  }

  String? get lastOpenedServerId =>
      _p.getString(AppConstants.prefKeyLastOpenedServerId);

  Future<void> setLastOpenedServerId(String id) =>
      setString(AppConstants.prefKeyLastOpenedServerId, id);

  bool get onboardingComplete =>
      getBoolOr(AppConstants.prefKeyOnboardingComplete, false);

  Future<void> setOnboardingComplete(bool value) =>
      setBool(AppConstants.prefKeyOnboardingComplete, value);

  // ─── Privacy ────────────────────────────────────────────────────────────

  /// When true, user-facing surfaces display masked host/IP addresses.
  bool get hideIpAddresses =>
      getBoolOr(AppConstants.prefKeyHideIpAddresses, false);

  Future<void> setHideIpAddresses(bool value) =>
      setBool(AppConstants.prefKeyHideIpAddresses, value);

  // ─── SSH reconnect ─────────────────────────────────────────────────────

  /// When true, dropped SSH sessions auto-reconnect with exponential backoff.
  bool get sshAutoReconnect => getBoolOr(
        AppConstants.prefKeySshAutoReconnect,
        AppConstants.defaultSshAutoReconnect,
      );

  Future<void> setSshAutoReconnect(bool value) =>
      setBool(AppConstants.prefKeySshAutoReconnect, value);

  /// Maximum reconnect attempts per dropped session; `0` means unlimited.
  int get sshReconnectMaxAttempts => getIntOr(
        AppConstants.prefKeySshReconnectMaxAttempts,
        AppConstants.kDefaultSshReconnectMaxAttempts,
      );

  Future<void> setSshReconnectMaxAttempts(int value) {
    final int clamped = value.clamp(
      0,
      AppConstants.kMaxSshReconnectMaxAttempts,
    );
    return setInt(AppConstants.prefKeySshReconnectMaxAttempts, clamped);
  }

  // ─── Security ───────────────────────────────────────────────────────────

  /// When true, the app requires fingerprint/face verification at launch and
  /// whenever it returns to the foreground (biometric app lock).
  bool get authLockEnabled =>
      getBoolOr(AppConstants.prefKeyAuthLockEnabled, false);

  Future<void> setAuthLockEnabled(bool value) =>
      setBool(AppConstants.prefKeyAuthLockEnabled, value);
}

/// Riverpod provider for the singleton.
final Provider<PreferencesService> preferencesServiceProvider =
    Provider<PreferencesService>((ref) => PreferencesService.instance);
