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
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
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

  String get aiProvider =>
      getStringOr(AppConstants.prefKeyAiProvider, 'openai');

  Future<void> setAiProvider(String provider) =>
      setString(AppConstants.prefKeyAiProvider, provider);

  String get aiModel =>
      getStringOr(AppConstants.prefKeyAiModel, AppConstants.defaultChatModel);

  Future<void> setAiModel(String model) =>
      setString(AppConstants.prefKeyAiModel, model);

  double get aiTemperature => getDoubleOr(
        AppConstants.prefKeyAiTemperature,
        AppConstants.defaultAiTemperature,
      );

  Future<void> setAiTemperature(double t) =>
      setDouble(AppConstants.prefKeyAiTemperature, t.clamp(0.0, 2.0));

  // ─── Session state ──────────────────────────────────────────────────────

  String? get lastOpenedServerId =>
      _p.getString(AppConstants.prefKeyLastOpenedServerId);

  Future<void> setLastOpenedServerId(String id) =>
      setString(AppConstants.prefKeyLastOpenedServerId, id);

  bool get onboardingComplete =>
      getBoolOr(AppConstants.prefKeyOnboardingComplete, false);

  Future<void> setOnboardingComplete(bool value) =>
      setBool(AppConstants.prefKeyOnboardingComplete, value);
}

/// Riverpod provider for the singleton.
final Provider<PreferencesService> preferencesServiceProvider =
    Provider<PreferencesService>((ref) => PreferencesService.instance);
