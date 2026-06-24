import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageStorageService {
  static const _localeKey = 'aparthub_locale';
  static const _fallbackLocale = Locale('id');
  static const _supportedLanguageCodes = {'id', 'en'};

  Future<Locale> loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);
    if (languageCode == null ||
        !_supportedLanguageCodes.contains(languageCode)) {
      return _fallbackLocale;
    }
    return Locale(languageCode);
  }

  Future<void> saveLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = _supportedLanguageCodes.contains(locale.languageCode)
        ? locale.languageCode
        : _fallbackLocale.languageCode;
    await preferences.setString(_localeKey, languageCode);
  }
}
