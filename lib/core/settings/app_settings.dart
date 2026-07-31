import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

const _themeKey = 'settings.theme';
const _reduceMotionKey = 'settings.reduceMotion';
const _compactScheduleKey = 'settings.compactSchedule';
const _showWeekendKey = 'settings.showWeekend';
const _summerScheduleKey = 'settings.summerSchedule';
const _scheduleRowHeightKey = 'settings.scheduleRowHeight';
const _scheduleLayoutKey = 'settings.demo.scheduleLayout';
const _scheduleDensityKey = 'settings.demo.scheduleDensity';
const _scheduleHeaderStyleKey = 'settings.demo.scheduleHeaderStyle';
const _scheduleTransitionKey = 'settings.demo.scheduleTransition';
const _schedulePaletteKey = 'settings.demo.schedulePalette';
const _courseCardStyleKey = 'settings.demo.courseCardStyle';
const _visibleDaysKey = 'settings.demo.visibleDays';
const _showWeekdayBarKey = 'settings.demo.showWeekdayBar';
const _weatherSceneKey = 'settings.demo.weatherScene';
const _detailHeroKey = 'settings.demo.detailHero';
const _detailLayoutKey = 'settings.demo.detailLayout';
const _detailActionsKey = 'settings.demo.detailActions';
const _sheetPlacementKey = 'settings.demo.sheetPlacement';
const _sheetGlassKey = 'settings.demo.sheetGlass';
const _showHeaderKey = 'settings.demo.showHeader';
const _showWeatherKey = 'settings.demo.showWeather';
const _showHeaderActionsKey = 'settings.demo.showHeaderActions';
const _showDockLabelsKey = 'settings.demo.showDockLabels';

enum ScheduleLayoutMode { grid, agenda }

enum CourseCardStyle { weather, none, shimmer, glow, aurora, breathe }

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.reduceMotion = false,
    this.compactSchedule = false,
    this.showWeekend = true,
    this.summerSchedule = false,
    this.scheduleRowHeight = 56,
    this.scheduleLayout = ScheduleLayoutMode.grid,
    this.scheduleDensity = YsScheduleDensity.normal,
    this.scheduleHeaderStyle = YsHeaderStyle.standard,
    this.scheduleTransition = YsTransition.wave,
    this.schedulePalette = YsPalette.classic,
    this.courseCardStyle = CourseCardStyle.weather,
    this.visibleDays = 7,
    this.showWeekdayBar = true,
    this.weatherScene = true,
    this.detailHero = YsDetailHero.weather,
    this.detailLayout = YsDetailLayout.standard,
    this.detailActions = true,
    this.sheetPlacement = YsSheetPlacement.right,
    this.sheetGlass = true,
    this.showHeader = true,
    this.showWeather = true,
    this.showHeaderActions = true,
    this.showDockLabels = true,
  });

  final ThemeMode themeMode;
  final bool reduceMotion;
  final bool compactSchedule;
  final bool showWeekend;
  final bool summerSchedule;
  final double scheduleRowHeight;
  final ScheduleLayoutMode scheduleLayout;
  final YsScheduleDensity scheduleDensity;
  final YsHeaderStyle scheduleHeaderStyle;
  final YsTransition scheduleTransition;
  final YsPalette schedulePalette;
  final CourseCardStyle courseCardStyle;
  final int visibleDays;
  final bool showWeekdayBar;
  final bool weatherScene;
  final YsDetailHero detailHero;
  final YsDetailLayout detailLayout;
  final bool detailActions;
  final YsSheetPlacement sheetPlacement;
  final bool sheetGlass;
  final bool showHeader;
  final bool showWeather;
  final bool showHeaderActions;
  final bool showDockLabels;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reduceMotion,
    bool? compactSchedule,
    bool? showWeekend,
    bool? summerSchedule,
    double? scheduleRowHeight,
    ScheduleLayoutMode? scheduleLayout,
    YsScheduleDensity? scheduleDensity,
    YsHeaderStyle? scheduleHeaderStyle,
    YsTransition? scheduleTransition,
    YsPalette? schedulePalette,
    CourseCardStyle? courseCardStyle,
    int? visibleDays,
    bool? showWeekdayBar,
    bool? weatherScene,
    YsDetailHero? detailHero,
    YsDetailLayout? detailLayout,
    bool? detailActions,
    YsSheetPlacement? sheetPlacement,
    bool? sheetGlass,
    bool? showHeader,
    bool? showWeather,
    bool? showHeaderActions,
    bool? showDockLabels,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      compactSchedule: compactSchedule ?? this.compactSchedule,
      showWeekend: showWeekend ?? this.showWeekend,
      summerSchedule: summerSchedule ?? this.summerSchedule,
      scheduleRowHeight: scheduleRowHeight ?? this.scheduleRowHeight,
      scheduleLayout: scheduleLayout ?? this.scheduleLayout,
      scheduleDensity: scheduleDensity ?? this.scheduleDensity,
      scheduleHeaderStyle: scheduleHeaderStyle ?? this.scheduleHeaderStyle,
      scheduleTransition: scheduleTransition ?? this.scheduleTransition,
      schedulePalette: schedulePalette ?? this.schedulePalette,
      courseCardStyle: courseCardStyle ?? this.courseCardStyle,
      visibleDays: visibleDays ?? this.visibleDays,
      showWeekdayBar: showWeekdayBar ?? this.showWeekdayBar,
      weatherScene: weatherScene ?? this.weatherScene,
      detailHero: detailHero ?? this.detailHero,
      detailLayout: detailLayout ?? this.detailLayout,
      detailActions: detailActions ?? this.detailActions,
      sheetPlacement: sheetPlacement ?? this.sheetPlacement,
      sheetGlass: sheetGlass ?? this.sheetGlass,
      showHeader: showHeader ?? this.showHeader,
      showWeather: showWeather ?? this.showWeather,
      showHeaderActions: showHeaderActions ?? this.showHeaderActions,
      showDockLabels: showDockLabels ?? this.showDockLabels,
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
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      reduceMotion: preferences?.getBool(_reduceMotionKey) ?? false,
      compactSchedule: preferences?.getBool(_compactScheduleKey) ?? false,
      showWeekend: preferences?.getBool(_showWeekendKey) ?? true,
      summerSchedule: preferences?.getBool(_summerScheduleKey) ?? false,
      scheduleRowHeight: (preferences?.getDouble(_scheduleRowHeightKey) ?? 56)
          .clamp(44, 78),
      scheduleLayout: _readEnum(
        ScheduleLayoutMode.values,
        preferences?.getString(_scheduleLayoutKey),
        ScheduleLayoutMode.grid,
      ),
      scheduleDensity: _readEnum(
        YsScheduleDensity.values,
        preferences?.getString(_scheduleDensityKey),
        YsScheduleDensity.normal,
      ),
      scheduleHeaderStyle: _readEnum(
        YsHeaderStyle.values,
        preferences?.getString(_scheduleHeaderStyleKey),
        YsHeaderStyle.standard,
      ),
      scheduleTransition: _readEnum(
        YsTransition.values,
        preferences?.getString(_scheduleTransitionKey),
        YsTransition.wave,
      ),
      schedulePalette: _readEnum(
        YsPalette.values,
        preferences?.getString(_schedulePaletteKey),
        YsPalette.classic,
      ),
      courseCardStyle: _readEnum(
        CourseCardStyle.values,
        preferences?.getString(_courseCardStyleKey),
        CourseCardStyle.weather,
      ),
      visibleDays:
          (preferences?.getInt(_visibleDaysKey) ??
                  ((preferences?.getBool(_showWeekendKey) ?? true) ? 7 : 5))
              .clamp(5, 7),
      showWeekdayBar: preferences?.getBool(_showWeekdayBarKey) ?? true,
      weatherScene: preferences?.getBool(_weatherSceneKey) ?? true,
      detailHero: _readEnum(
        YsDetailHero.values,
        preferences?.getString(_detailHeroKey),
        YsDetailHero.weather,
      ),
      detailLayout: _readEnum(
        YsDetailLayout.values,
        preferences?.getString(_detailLayoutKey),
        YsDetailLayout.standard,
      ),
      detailActions: preferences?.getBool(_detailActionsKey) ?? true,
      sheetPlacement: _readEnum(
        YsSheetPlacement.values,
        preferences?.getString(_sheetPlacementKey),
        YsSheetPlacement.right,
      ),
      sheetGlass: preferences?.getBool(_sheetGlassKey) ?? true,
      showHeader: preferences?.getBool(_showHeaderKey) ?? true,
      showWeather: preferences?.getBool(_showWeatherKey) ?? true,
      showHeaderActions: preferences?.getBool(_showHeaderActionsKey) ?? true,
      showDockLabels: preferences?.getBool(_showDockLabelsKey) ?? true,
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
    state = state.copyWith(showWeekend: value, visibleDays: value ? 7 : 5);
    _preferences?.setBool(_showWeekendKey, value);
    _preferences?.setInt(_visibleDaysKey, value ? 7 : 5);
  }

  void setSummerSchedule(bool value) {
    state = state.copyWith(summerSchedule: value);
    _preferences?.setBool(_summerScheduleKey, value);
  }

  void setScheduleRowHeight(double value) {
    final normalized = value.clamp(44, 78).roundToDouble();
    state = state.copyWith(scheduleRowHeight: normalized);
    _preferences?.setDouble(_scheduleRowHeightKey, normalized);
  }

  void setScheduleLayout(ScheduleLayoutMode value) {
    state = state.copyWith(scheduleLayout: value);
    _preferences?.setString(_scheduleLayoutKey, value.name);
  }

  void setScheduleDensity(YsScheduleDensity value) {
    final rowHeight = switch (value) {
      YsScheduleDensity.minimal => 48.0,
      YsScheduleDensity.normal => 56.0,
      YsScheduleDensity.rich => 64.0,
    };
    state = state.copyWith(
      scheduleDensity: value,
      scheduleRowHeight: rowHeight,
    );
    _preferences?.setString(_scheduleDensityKey, value.name);
    _preferences?.setDouble(_scheduleRowHeightKey, rowHeight);
  }

  void setScheduleHeaderStyle(YsHeaderStyle value) {
    state = state.copyWith(scheduleHeaderStyle: value);
    _preferences?.setString(_scheduleHeaderStyleKey, value.name);
  }

  void cycleScheduleHeaderStyle() {
    final values = [
      YsHeaderStyle.compact,
      YsHeaderStyle.standard,
      YsHeaderStyle.expanded,
    ];
    final current = state.scheduleHeaderStyle == YsHeaderStyle.none
        ? 0
        : values.indexOf(state.scheduleHeaderStyle);
    setScheduleHeaderStyle(values[(current + 1) % values.length]);
  }

  void setScheduleTransition(YsTransition value) {
    state = state.copyWith(scheduleTransition: value);
    _preferences?.setString(_scheduleTransitionKey, value.name);
  }

  void setSchedulePalette(YsPalette value) {
    state = state.copyWith(schedulePalette: value);
    _preferences?.setString(_schedulePaletteKey, value.name);
  }

  void setCourseCardStyle(CourseCardStyle value) {
    state = state.copyWith(courseCardStyle: value);
    _preferences?.setString(_courseCardStyleKey, value.name);
  }

  void setVisibleDays(int value) {
    final normalized = value.clamp(5, 7);
    state = state.copyWith(
      visibleDays: normalized,
      showWeekend: normalized == 7,
    );
    _preferences?.setInt(_visibleDaysKey, normalized);
    _preferences?.setBool(_showWeekendKey, normalized == 7);
  }

  void setShowWeekdayBar(bool value) => _setBool(
    value,
    _showWeekdayBarKey,
    (settings) => settings.copyWith(showWeekdayBar: value),
  );

  void setWeatherScene(bool value) => _setBool(
    value,
    _weatherSceneKey,
    (settings) => settings.copyWith(weatherScene: value),
  );

  void setDetailHero(YsDetailHero value) {
    state = state.copyWith(detailHero: value);
    _preferences?.setString(_detailHeroKey, value.name);
  }

  void setDetailLayout(YsDetailLayout value) {
    state = state.copyWith(detailLayout: value);
    _preferences?.setString(_detailLayoutKey, value.name);
  }

  void setDetailActions(bool value) => _setBool(
    value,
    _detailActionsKey,
    (settings) => settings.copyWith(detailActions: value),
  );

  void setSheetPlacement(YsSheetPlacement value) {
    state = state.copyWith(sheetPlacement: value);
    _preferences?.setString(_sheetPlacementKey, value.name);
  }

  void setSheetGlass(bool value) => _setBool(
    value,
    _sheetGlassKey,
    (settings) => settings.copyWith(sheetGlass: value),
  );

  void setShowHeader(bool value) => _setBool(
    value,
    _showHeaderKey,
    (settings) => settings.copyWith(showHeader: value),
  );

  void setShowWeather(bool value) => _setBool(
    value,
    _showWeatherKey,
    (settings) => settings.copyWith(showWeather: value),
  );

  void setShowHeaderActions(bool value) => _setBool(
    value,
    _showHeaderActionsKey,
    (settings) => settings.copyWith(showHeaderActions: value),
  );

  void setShowDockLabels(bool value) => _setBool(
    value,
    _showDockLabelsKey,
    (settings) => settings.copyWith(showDockLabels: value),
  );

  void resetDemoConfiguration() {
    const defaults = AppSettings();
    state = defaults;
    setThemeMode(defaults.themeMode);
    setReduceMotion(defaults.reduceMotion);
    setCompactSchedule(defaults.compactSchedule);
    setShowWeekend(defaults.showWeekend);
    setSummerSchedule(defaults.summerSchedule);
    setScheduleRowHeight(defaults.scheduleRowHeight);
    setScheduleLayout(defaults.scheduleLayout);
    setScheduleDensity(defaults.scheduleDensity);
    setScheduleHeaderStyle(defaults.scheduleHeaderStyle);
    setScheduleTransition(defaults.scheduleTransition);
    setSchedulePalette(defaults.schedulePalette);
    setCourseCardStyle(defaults.courseCardStyle);
    setVisibleDays(defaults.visibleDays);
    setShowWeekdayBar(defaults.showWeekdayBar);
    setWeatherScene(defaults.weatherScene);
    setDetailHero(defaults.detailHero);
    setDetailLayout(defaults.detailLayout);
    setDetailActions(defaults.detailActions);
    setSheetPlacement(defaults.sheetPlacement);
    setSheetGlass(defaults.sheetGlass);
    setShowHeader(defaults.showHeader);
    setShowWeather(defaults.showWeather);
    setShowHeaderActions(defaults.showHeaderActions);
    setShowDockLabels(defaults.showDockLabels);
  }

  void _setBool(
    bool value,
    String key,
    AppSettings Function(AppSettings settings) update,
  ) {
    state = update(state);
    _preferences?.setBool(key, value);
  }
}

T _readEnum<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
