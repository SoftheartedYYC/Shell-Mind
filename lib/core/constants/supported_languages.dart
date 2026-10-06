import 'package:flutter/foundation.dart';

/// A language the app can be switched to.
///
/// [code] is the ISO 639-1 language code persisted in preferences (or
/// `'system'` to follow the OS locale). [nativeName] is the endonym shown in
/// the picker (every language is listed in its own script so a user can find
/// their language even before the app is in it).
@immutable
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;

  /// The language's name written in that language.
  final String nativeName;

  /// The English name, used for fallback ordering/search.
  final String englishName;
}

/// Every language the app ships, in picker order.
///
/// `system` is the implicit "follow the OS" option; every other entry maps to
/// an `app_<code>.arb` translation under `lib/l10n/`. Keep this list in sync
/// with those files.
const List<LanguageOption> kSupportedLanguages = <LanguageOption>[
  LanguageOption(code: 'system', nativeName: 'System default', englishName: 'System default'),
  LanguageOption(code: 'en', nativeName: 'English', englishName: 'English'),
  LanguageOption(code: 'zh', nativeName: '简体中文', englishName: 'Simplified Chinese'),
  LanguageOption(code: 'ja', nativeName: '日本語', englishName: 'Japanese'),
  LanguageOption(code: 'ko', nativeName: '한국어', englishName: 'Korean'),
  LanguageOption(code: 'de', nativeName: 'Deutsch', englishName: 'German'),
  LanguageOption(code: 'fr', nativeName: 'Français', englishName: 'French'),
  LanguageOption(code: 'es', nativeName: 'Español', englishName: 'Spanish'),
  LanguageOption(code: 'pt', nativeName: 'Português', englishName: 'Portuguese'),
  LanguageOption(code: 'ru', nativeName: 'Русский', englishName: 'Russian'),
  LanguageOption(code: 'it', nativeName: 'Italiano', englishName: 'Italian'),
];

/// Resolves a persisted language code to its display label (or `'system'`
/// when unset).
LanguageOption languageOptionFor(String? code) {
  for (final LanguageOption option in kSupportedLanguages) {
    if (option.code == code) return option;
  }
  return kSupportedLanguages.first;
}
