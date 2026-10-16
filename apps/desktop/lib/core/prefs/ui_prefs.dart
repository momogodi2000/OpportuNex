import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret preferences needed before sign-in (D-16): language and theme follow the OS
/// until the user picks one; the last used profile pre-selects the sign-in screen.
@immutable
class UiPrefs {
  const UiPrefs({
    this.localeCode,
    this.themeMode = ThemeMode.system,
    this.lastProfileId,
    this.sidebarCollapsed = false,
    this.closeToTray = true,
  });

  final String? localeCode;
  final ThemeMode themeMode;
  final String? lastProfileId;
  final bool sidebarCollapsed;

  /// Closing the window hides it to the system tray so monitors and reminders keep running (EF-13.06).
  final bool closeToTray;

  Locale get locale {
    final code = localeCode ?? PlatformDispatcher.instance.locale.languageCode;
    return Locale(code == 'en' ? 'en' : 'fr');
  }

  UiPrefs copyWith({String? localeCode, ThemeMode? themeMode, String? lastProfileId, bool? sidebarCollapsed, bool? closeToTray}) =>
      UiPrefs(
        localeCode: localeCode ?? this.localeCode,
        themeMode: themeMode ?? this.themeMode,
        lastProfileId: lastProfileId ?? this.lastProfileId,
        sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
        closeToTray: closeToTray ?? this.closeToTray,
      );
}

ThemeMode themeModeFromName(String? name) => switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeModeName(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

class UiPrefsController extends Notifier<UiPrefs> {
  SharedPreferences? _prefs;

  @override
  UiPrefs build() {
    _load();
    return const UiPrefs();
  }

  Future<void> _load() async {
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      state = UiPrefs(
        localeCode: prefs.getString('locale'),
        themeMode: themeModeFromName(prefs.getString('theme')),
        lastProfileId: prefs.getString('last_profile'),
        sidebarCollapsed: prefs.getBool('sidebar_collapsed') ?? false,
        closeToTray: prefs.getBool('close_to_tray') ?? true,
      );
    } on Object {
      // Preferences are a convenience; defaults are fine if the store is unavailable.
    }
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await _prefs?.setString('locale', code);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString('theme', themeModeName(mode));
  }

  Future<void> setLastProfile(String id) async {
    state = state.copyWith(lastProfileId: id);
    await _prefs?.setString('last_profile', id);
  }

  Future<void> setCloseToTray(bool value) async {
    state = state.copyWith(closeToTray: value);
    await _prefs?.setBool('close_to_tray', value);
  }

  Future<void> toggleSidebar() async {
    state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
    await _prefs?.setBool('sidebar_collapsed', state.sidebarCollapsed);
  }
}

final uiPrefsProvider = NotifierProvider<UiPrefsController, UiPrefs>(UiPrefsController.new);
