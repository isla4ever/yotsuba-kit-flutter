import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/data/mock/mock_schedule_repository.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';
import 'package:yotsuba_schedule/features/announcements/application/local_announcement_controller.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';

void main() {
  test('summer timetable and row height persist with safe bounds', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final controller = container.read(appSettingsProvider.notifier);
    controller.setSummerSchedule(true);
    controller.setScheduleRowHeight(120);

    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restored.dispose);
    final settings = restored.read(appSettingsProvider);
    expect(settings.summerSchedule, isTrue);
    expect(settings.scheduleRowHeight, 78);
  });

  test('manual calendar changes survive remote holiday refresh', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final controller = container.read(scheduleControllerProvider.notifier);

    const manual = AcademicDayOverride(
      dateKey: '2026-10-01',
      kind: AcademicDayKind.makeUp,
      name: '校级补课',
      sourceWeekday: 1,
    );
    controller.upsertDayOverride(manual);
    controller.replaceRemoteDayOverrides(const [
      AcademicDayOverride(
        dateKey: '2026-10-01',
        kind: AcademicDayKind.holiday,
        name: '国庆节',
        isManual: false,
      ),
      AcademicDayOverride(
        dateKey: '2026-10-02',
        kind: AcademicDayKind.holiday,
        name: '国庆节',
        isManual: false,
      ),
    ]);

    final values = container.read(scheduleControllerProvider).dayOverrides;
    expect(
      values.firstWhere((item) => item.dateKey == manual.dateKey).name,
      '校级补课',
    );
    expect(values.any((item) => item.dateKey == '2026-10-02'), isTrue);
  });

  test('holiday hides courses and makeup day maps source weekday', () async {
    final holiday = await _todayFor(
      DateTime(2026, 7, 20, 9),
      const AcademicDayOverride(
        dateKey: '2026-07-20',
        kind: AcademicDayKind.holiday,
        name: '放假',
      ),
    );
    expect(holiday.courses, isEmpty);

    final makeup = await _todayFor(
      DateTime(2026, 7, 21, 9),
      const AcademicDayOverride(
        dateKey: '2026-07-21',
        kind: AcademicDayKind.makeUp,
        name: '补班',
        sourceWeekday: 1,
      ),
    );
    expect(makeup.courses.map((item) => item.course.id), contains('monday'));
  });

  test('announcement only stays hidden after explicit mute', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final controller = container.read(localAnnouncementProvider.notifier);

    controller.save(title: '新功能', content: '公告内容', publish: true);
    final published = container.read(localAnnouncementProvider).latestUnmuted!;
    expect(published.title, '新功能');

    final untouched = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(untouched.dispose);
    expect(untouched.read(localAnnouncementProvider).latestUnmuted, isNotNull);

    controller.mute(published.id);
    final muted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(muted.dispose);
    expect(muted.read(localAnnouncementProvider).latestUnmuted, isNull);
  });
}

Future<TodayViewModel> _todayFor(
  DateTime now,
  AcademicDayOverride dayOverride,
) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final data = ScheduleData(
    termStart: DateTime(2026, 7, 20),
    totalWeeks: 16,
    courses: const [
      Course(
        id: 'monday',
        name: '周一课程',
        teacher: '教师',
        room: '教室',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF2C8B7F,
      ),
    ],
    dayTasks: const [],
    coursePlans: const [],
    dayOverrides: [dayOverride],
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      mockScheduleRepositoryProvider.overrideWithValue(_FixedRepository(data)),
      clockProvider.overrideWithValue(AsyncData(now)),
    ],
  );
  final value = container.read(todayViewModelProvider);
  container.dispose();
  return value;
}

class _FixedRepository extends MockScheduleRepository {
  const _FixedRepository(this.data);

  final ScheduleData data;

  @override
  ScheduleData load() => data;
}
