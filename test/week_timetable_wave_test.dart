import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/week_timetable.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart'
    show YsTransition;

const _stableCourse = Course(
  id: 'stable',
  name: '高等数学',
  teacher: '陈老师',
  room: '教1-201',
  weekday: 1,
  startSection: 1,
  endSection: 2,
  startWeek: 1,
  endWeek: 20,
  colorValue: 0xFFDD4A68,
);

const _weekOneCourse = Course(
  id: 'week1-only',
  name: '体育',
  teacher: '孙老师',
  room: '操场',
  weekday: 4,
  startSection: 1,
  endSection: 2,
  startWeek: 1,
  endWeek: 1,
  colorValue: 0xFFB8860B,
);

class _Harness extends StatefulWidget {
  const _Harness({
    required this.initialWeek,
    required this.reduceMotion,
    this.transition = YsTransition.wave,
  });

  final int initialWeek;
  final bool reduceMotion;
  final YsTransition transition;

  static _HarnessState of(WidgetTester tester) =>
      tester.state<_HarnessState>(find.byType(_Harness));

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int week = widget.initialWeek;

  void setWeek(int value) => setState(() => week = value);

  @override
  Widget build(BuildContext context) {
    return WeekTimetable(
      termStart: DateTime(2026, 3, 2),
      week: week,
      courses: const [_stableCourse, _weekOneCourse],
      visibleDays: 7,
      rowHeight: 52,
      courseTimes: standardCourseTimes,
      dayOverrides: const [],
      weather: null,
      editing: false,
      reduceMotion: widget.reduceMotion,
      transition: widget.transition,
      onCourseTap: (_) {},
      onEmptyCellTap: (_, _, _) {},
      onDayTap: (_) {},
    );
  }
}

Future<void> _pumpTimetable(
  WidgetTester tester, {
  required bool reduceMotion,
  YsTransition transition = YsTransition.wave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: _Harness(
          initialWeek: 1,
          reduceMotion: reduceMotion,
          transition: transition,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('week wave keeps old cards beneath while new cards sweep in', (
    tester,
  ) async {
    await _pumpTimetable(tester, reduceMotion: false);
    expect(find.text('体育'), findsOneWidget);

    _Harness.of(tester).setWeek(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // 变化格：旧周卡还在下层，新周卡已开始进场 → 同名卡短暂存在两份
    expect(find.text('体育'), findsNWidgets(2));
    // 波浪中途任何一刻，网格上都有内容（旧卡 + 稳定卡）
    expect(find.text('高等数学'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('体育'), findsOneWidget);
    expect(find.text('非本周'), findsOneWidget);
  });

  testWidgets('unchanged cells stay static during the wave', (tester) async {
    await _pumpTimetable(tester, reduceMotion: false);
    _Harness.of(tester).setWeek(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // 稳定格不参与动画：只渲染一份，且没有被波浪的 Opacity 包裹
    expect(find.text('高等数学'), findsOneWidget);
    final fadedAncestors = tester
        .widgetList<Opacity>(
          find.ancestor(of: find.text('高等数学'), matching: find.byType(Opacity)),
        )
        .where((opacity) => opacity.opacity < 1);
    expect(fadedAncestors, isEmpty);

    await tester.pumpAndSettle();
  });

  testWidgets(
    'inactive leaving overlap never flashes above a new active card',
    (tester) async {
      const overlapping = [
        Course(
          id: 'z-active-week-one',
          name: '本周课程',
          teacher: '陈老师',
          room: '教1-101',
          weekday: 4,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 1,
          colorValue: 0xFF486FCB,
        ),
        Course(
          id: 'a-inactive-leaving',
          name: '底层非本周课程',
          teacher: '李老师',
          room: '教1-102',
          weekday: 4,
          startSection: 1,
          endSection: 2,
          startWeek: 3,
          endWeek: 3,
          colorValue: 0xFF8F6D4E,
        ),
      ];
      var week = 2;
      late StateSetter setOuter;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Scaffold(
                body: WeekTimetable(
                  termStart: DateTime(2026, 3, 2),
                  week: week,
                  courses: overlapping,
                  visibleDays: 7,
                  rowHeight: 52,
                  courseTimes: standardCourseTimes,
                  dayOverrides: const [],
                  weather: null,
                  editing: false,
                  reduceMotion: false,
                  onCourseTap: (_) {},
                  onEmptyCellTap: (_, _, _) {},
                  onDayTap: (_) {},
                ),
              );
            },
          ),
        ),
      );
      expect(find.text('底层非本周课程'), findsOneWidget);

      setOuter(() => week = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('本周课程'), findsOneWidget);
      expect(find.text('底层非本周课程'), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('reduce motion swaps weeks instantly without wave layers', (
    tester,
  ) async {
    await _pumpTimetable(tester, reduceMotion: true);
    _Harness.of(tester).setWeek(2);
    await tester.pump();

    // 直接切换：任何时刻都不存在旧周残留层（同名卡只有一份）
    expect(find.text('体育'), findsOneWidget);
    expect(find.text('非本周'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('体育'), findsOneWidget);
  });

  for (final transition in YsTransition.values) {
    testWidgets('${transition.name} transition keeps the timetable stable', (
      tester,
    ) async {
      await _pumpTimetable(tester, reduceMotion: false, transition: transition);
      _Harness.of(tester).setWeek(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('高等数学'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('非本周'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final visibleDays in [5, 6, 7]) {
    testWidgets('$visibleDays-day layout keeps weekend cards weather-linked', (
      tester,
    ) async {
      final courses = [
        for (var day = 1; day <= 7; day++)
          Course(
            id: 'day-$day',
            name: '第$day日课程',
            teacher: '陈老师',
            room: '教$day-101',
            weekday: day,
            startSection: 1,
            endSection: 2,
            startWeek: 1,
            endWeek: 20,
            colorValue: 0xFF486FCB,
          ),
      ];
      final weather = WeatherSnapshot(
        latitude: 39.1,
        longitude: 117.2,
        timezone: 'Asia/Shanghai',
        currentTemperature: 28,
        currentWeatherCode: 0,
        fetchedAt: DateTime(2026, 3, 2),
        daily: [
          for (var day = 0; day < 7; day++)
            DailyWeather(
              dateKey: '2026-03-${(2 + day).toString().padLeft(2, '0')}',
              weatherCode: day,
              temperatureMin: 18,
              temperatureMax: 26,
            ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 720,
              child: WeekTimetable(
                termStart: DateTime(2026, 3, 2),
                week: 1,
                courses: courses,
                visibleDays: visibleDays,
                rowHeight: 52,
                courseTimes: standardCourseTimes,
                dayOverrides: const [],
                weather: weather,
                editing: false,
                reduceMotion: true,
                onCourseTap: (_) {},
                onEmptyCellTap: (_, _, _) {},
                onDayTap: (_) {},
              ),
            ),
          ),
        ),
      );

      for (var day = 1; day <= visibleDays; day++) {
        expect(find.text('第$day日课程'), findsOneWidget);
      }
      expect(find.byType(WeatherCardLayer), findsNWidgets(visibleDays));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inactive courses keep weather structure in a muted filter', (
    tester,
  ) async {
    final weather = WeatherSnapshot(
      latitude: 39.1,
      longitude: 117.2,
      timezone: 'Asia/Shanghai',
      currentTemperature: 30,
      currentWeatherCode: 0,
      fetchedAt: DateTime(2026, 3, 9),
      daily: const [
        DailyWeather(
          dateKey: '2026-03-12',
          weatherCode: 0,
          temperatureMin: 20,
          temperatureMax: 31,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: WeekTimetable(
            termStart: DateTime(2026, 3, 2),
            week: 2,
            courses: const [_weekOneCourse],
            visibleDays: 7,
            rowHeight: 52,
            courseTimes: standardCourseTimes,
            dayOverrides: const [],
            weather: weather,
            editing: false,
            reduceMotion: true,
            onCourseTap: (_) {},
            onEmptyCellTap: (_, _, _) {},
            onDayTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('非本周'), findsOneWidget);
    expect(find.byType(WeatherCardLayer), findsOneWidget);
    final mutedOpacity = find.ancestor(
      of: find.byType(WeatherCardLayer),
      matching: find.byType(Opacity),
    );
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(tester.widget<Opacity>(mutedOpacity.first).opacity, 0.16);
  });
}
