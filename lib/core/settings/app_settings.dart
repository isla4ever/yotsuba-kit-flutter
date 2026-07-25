import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'settings.theme';
const _reduceMotionKey = 'settings.reduceMotion';
const _compactScheduleKey = 'settings.compactSchedule';
const _showWeekendKey = 'settings.showWeekend';
const _summerScheduleKey = 'settings.summerSchedule';
const _scheduleRowHeightKey = 'settings.scheduleRowHeight';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reduceMotion = false,
    this.compactSchedule = false,
    this.showWeekend = true,
    this.summerSchedule = false,
    this.scheduleRowHeight = 62,
  });

  final ThemeMode themeMode;
  final bool reduceMotion;
  final bool compactSchedule;
  final bool showWeekend;
  final bool summerSchedule;
  final double scheduleRowHeight;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reduceMotion,
    bool? compactSchedule,
    bool? showWeekend,
    bool? summerSchedule,
    double? scheduleRowHeight,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      compactSchedule: compactSchedule ?? this.compactSchedule,
      showWeekend: showWeekend ?? this.showWeekend,
      summerSchedule: summerSchedule ?? this.summerSchedule,
      scheduleRowHeight: scheduleRowHeight ?? this.scheduleRowHeight,
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
      summerSchedule: preferences?.getBool(_summerScheduleKey) ?? false,
      scheduleRowHeight: preferences?.getDouble(_scheduleRowHeightKey) ?? 62,
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

  void setSummerSchedule(bool value) {
    state = state.copyWith(summerSchedule: value);
    _preferences?.setBool(_summerScheduleKey, value);
  }

  void setScheduleRowHeight(double value) {
    final normalized = value.clamp(54, 78).roundToDouble();
    state = state.copyWith(scheduleRowHeight: normalized);
    _preferences?.setDouble(_scheduleRowHeightKey, normalized);
  }
}
