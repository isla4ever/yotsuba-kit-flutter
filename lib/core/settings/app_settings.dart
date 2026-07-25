import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'settings.theme';
const _reduceMotionKey = 'settings.reduceMotion';
const _compactScheduleKey = 'settings.compactSchedule';
const _showWeekendKey = 'settings.showWeekend';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reduceMotion = false,
    this.compactSchedule = false,
    this.showWeekend = true,
  });

  final ThemeMode themeMode;
  final bool reduceMotion;
  final bool compactSchedule;
  final bool showWeekend;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reduceMotion,
    bool? compactSchedule,
    bool? showWeekend,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      compactSchedule: compactSchedule ?? this.compactSchedule,
      showWeekend: showWeekend ?? this.showWeekend,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  SharedPreferences? get _preferences => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final storedTheme = preferences?.getString(_themeKey);
    return AppSettings(
      themeMode: switch (storedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      reduceMotion: preferences?.getBool(_reduceMotionKey) ?? false,
      compactSchedule: preferences?.getBool(_compactScheduleKey) ?? false,
      showWeekend: preferences?.getBool(_showWeekendKey) ?? true,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _preferences?.setString(_themeKey, mode.name);
  }

  void setReduceMotion(bool value) {
    state = state.copyWith(reduceMotion: value);
    _preferences?.setBool(_reduceMotionKey, value);
  }

  void setCompactSchedule(bool value) {
    state = state.copyWith(compactSchedule: value);
    _preferences?.setBool(_compactScheduleKey, value);
  }

  void setShowWeekend(bool value) {
    state = state.copyWith(showWeekend: value);
    _preferences?.setBool(_showWeekendKey, value);
  }
}
