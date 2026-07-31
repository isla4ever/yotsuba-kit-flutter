import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

void main() {
  test('demo configuration persists every public setting and resets', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    final controller = container.read(appSettingsProvider.notifier);

    controller.setThemeMode(ThemeMode.dark);
    controller.setReduceMotion(true);
    controller.setCompactSchedule(true);
    controller.setSummerSchedule(true);
    controller.setScheduleLayout(ScheduleLayoutMode.agenda);
    controller.setScheduleDensity(YsScheduleDensity.rich);
    controller.setScheduleRowHeight(72);
    controller.setScheduleHeaderStyle(YsHeaderStyle.expanded);
    controller.setScheduleTransition(YsTransition.cube);
    controller.setSchedulePalette(YsPalette.forest);
    controller.setCourseCardStyle(CourseCardStyle.aurora);
    controller.setVisibleDays(6);
    controller.setShowWeekdayBar(false);
    controller.setWeatherScene(false);
    controller.setDetailHero(YsDetailHero.courseColor);
    controller.setDetailLayout(YsDetailLayout.full);
    controller.setDetailActions(false);
    controller.setSheetPlacement(YsSheetPlacement.center);
    controller.setSheetGlass(false);
    controller.setShowHeader(false);
    controller.setShowWeather(false);
    controller.setShowHeaderActions(false);
    controller.setShowDockLabels(false);

    await Future<void>.delayed(Duration.zero);
    container.dispose();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final restored = container.read(appSettingsProvider);
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.reduceMotion, isTrue);
    expect(restored.compactSchedule, isTrue);
    expect(restored.summerSchedule, isTrue);
    expect(restored.scheduleLayout, ScheduleLayoutMode.agenda);
    expect(restored.scheduleDensity, YsScheduleDensity.rich);
    expect(restored.scheduleRowHeight, 72);
    expect(restored.scheduleHeaderStyle, YsHeaderStyle.expanded);
    expect(restored.scheduleTransition, YsTransition.cube);
    expect(restored.schedulePalette, YsPalette.forest);
    expect(restored.courseCardStyle, CourseCardStyle.aurora);
    expect(restored.visibleDays, 6);
    expect(restored.showWeekend, isFalse);
    expect(restored.showWeekdayBar, isFalse);
    expect(restored.weatherScene, isFalse);
    expect(restored.detailHero, YsDetailHero.courseColor);
    expect(restored.detailLayout, YsDetailLayout.full);
    expect(restored.detailActions, isFalse);
    expect(restored.sheetPlacement, YsSheetPlacement.center);
    expect(restored.sheetGlass, isFalse);
    expect(restored.showHeader, isFalse);
    expect(restored.showWeather, isFalse);
    expect(restored.showHeaderActions, isFalse);
    expect(restored.showDockLabels, isFalse);

    container.read(appSettingsProvider.notifier).resetDemoConfiguration();
    final reset = container.read(appSettingsProvider);
    expect(reset.themeMode, ThemeMode.light);
    expect(reset.reduceMotion, isFalse);
    expect(reset.scheduleLayout, ScheduleLayoutMode.grid);
    expect(reset.scheduleDensity, YsScheduleDensity.normal);
    expect(reset.scheduleHeaderStyle, YsHeaderStyle.standard);
    expect(reset.scheduleTransition, YsTransition.wave);
    expect(reset.schedulePalette, YsPalette.classic);
    expect(reset.courseCardStyle, CourseCardStyle.weather);
    expect(reset.visibleDays, 7);
    expect(reset.detailHero, YsDetailHero.weather);
    expect(reset.detailLayout, YsDetailLayout.standard);
    expect(reset.sheetPlacement, YsSheetPlacement.right);
    expect(reset.sheetGlass, isTrue);
    expect(reset.showHeader, isTrue);
    expect(reset.showWeather, isTrue);
    expect(reset.showHeaderActions, isTrue);
    expect(reset.showDockLabels, isTrue);
  });

  test(
    'stored day count and row height are constrained to mobile-safe bounds',
    () async {
      SharedPreferences.setMockInitialValues({
        'settings.demo.visibleDays': 12,
        'settings.scheduleRowHeight': 16.0,
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final settings = container.read(appSettingsProvider);
      expect(settings.visibleDays, 7);
      expect(settings.scheduleRowHeight, 44);
    },
  );
}
