import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences_service.dart';

/// Riverpod Notifier that manages the app's [Locale] preference.
///
/// `null` means "follow the system locale". Loads the persisted preference on
/// first build and writes back whenever the user changes the language.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.locale;
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLocale(locale);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
