import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  const AppSettings({required this.themeMode, required this.locale});
  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final FlutterSecureStorage _storage;
  SettingsNotifier(this._storage)
    : super(
        const AppSettings(
          themeMode: ThemeMode.system,
          locale: Locale('fr', 'FR'),
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _storage.read(key: 'settings_theme_mode');
    final lang = await _storage.read(key: 'settings_language');

    ThemeMode loadedTheme = ThemeMode.system;
    if (theme == 'light') loadedTheme = ThemeMode.light;
    if (theme == 'dark') loadedTheme = ThemeMode.dark;

    Locale loadedLocale = const Locale('fr', 'FR');
    if (lang == 'en') loadedLocale = const Locale('en', 'US');

    state = AppSettings(themeMode: loadedTheme, locale: loadedLocale);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _storage.write(key: 'settings_theme_mode', value: val);
  }

  Future<void> updateLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _storage.write(key: 'settings_language', value: locale.languageCode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(const FlutterSecureStorage());
});
