import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';
import 'package:yotsuba_schedule/data/weather/weather_repository.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_command_summary.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_course_timeline.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_dashboard_grid.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_demo_panels.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_readiness_board.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';

class _FakeWeatherLocation implements WeatherLocationGateway {
  const _FakeWeatherLocation();

  @override
  Future<WeatherLocationPermission> checkPermission() async =>
      WeatherLocationPermission.allowed;

  @override
  Future<WeatherCoordinates?> currentCoordinates() async =>
      const WeatherCoordinates(latitude: 31.23, longitude: 121.47);

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> openSettings({required bool locationService}) async => true;

  @override
  Future<WeatherLocationPermission> requestPermission() async =>
      WeatherLocationPermission.allowed;
}

void main() {
  test(
    'legacy dashboard layout keeps order while adopting the new grid sizes',
    () async {
      SharedPreferences.setMockInitialValues({
        'today.dashboard.layout.v1': jsonEncode([
          {'id': 'materials', 'size': 'twoByFour', 'visible': false},
          {'id': 'courseWork', 'size': 'twoByFour', 'visible': true},
          {'id': 'tasks', 'size': 'twoByFour', 'visible': true},
        ]),
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final layout = container.read(todayLayoutProvider);
      expect(layout.take(3).map((item) => item.id), [
        TodayTileId.materials,
        TodayTileId.courseWork,
        TodayTileId.tasks,
      ]);
      expect(layout.first.visible, isFalse);
      expect(layout.first.size, TodayTileSize.twoByTwo);
      expect(layout[1].size, TodayTileSize.twoByTwo);
      expect(layout[2].size, TodayTileSize.twoByTwo);
      expect(preferences.getString('today.dashboard.layout.v4'), isNotNull);
    },
  );

  test('reordering visible widgets keeps hidden widget slots intact', () async {
    SharedPreferences.setMockInitialValues({
      'today.dashboard.layout.v3': jsonEncode([
        {'id': 'command', 'size': 'twoByTwo', 'visible': true},
        {'id': 'materials', 'size': 'twoByOne', 'visible': false},
        {'id': 'tasks', 'size': 'oneByOne', 'visible': true},
        {'id': 'courseWork', 'size': 'oneByOne', 'visible': true},
        {'id': 'timeline', 'size': 'twoByTwo', 'visible': true},
      ]),
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    container
        .read(todayLayoutProvider.notifier)
        .moveToVisibleIndex(TodayTileId.timeline, 1);
    final layout = container.read(todayLayoutProvider);
    expect(layout[1].id, TodayTileId.materials);
    expect(layout[1].visible, isFalse);
    expect(layout.where((item) => item.visible).map((item) => item.id), [
      TodayTileId.command,
      TodayTileId.timeline,
      TodayTileId.tasks,
      TodayTileId.courseWork,
      TodayTileId.weather,
      TodayTileId.readiness,
      TodayTileId.weekGlance,
      TodayTileId.studyLoad,
    ]);
  });

  test('weather response tolerates nullable forecast values', () async {
    final client = MockClient((request) async {
      expect(
        request.url.queryParameters['hourly'],
        'temperature_2m,weather_code',
      );
      return http.Response(
        jsonEncode({
          'latitude': 34.6,
          'longitude': 119.2,
          'timezone': 'Asia/Shanghai',
          'current': {'temperature_2m': 26.5, 'weather_code': 1},
          'daily': {
            'time': ['2026-07-26', '2026-07-27'],
            'weather_code': [95, null],
            'temperature_2m_max': [32.0, null],
            'temperature_2m_min': [22.0, 23.0],
            'precipitation_probability_max': [77, null],
          },
          'hourly': {
            'time': ['2026-07-26T08:00', '2026-07-26T15:00'],
            'weather_code': [0, 71],
            'temperature_2m': [24.0, 2.0],
          },
        }),
        200,
      );
    });

    final snapshot = await WeatherRepository(
      httpClient: client,
    ).fetch(latitude: 34.6, longitude: 119.2);
    expect(snapshot.currentTemperature, 26.5);
    expect(snapshot.daily.first.precipitationProbability, 77);
    expect(snapshot.daily.last.weatherCode, 0);
    expect(snapshot.daily.last.temperatureMax, 0);
    expect(snapshot.hourly.map((item) => item.weatherCode), [0, 71]);
    expect(
      snapshot.weatherForDateTime(DateTime(2026, 7, 26, 14, 30))?.weatherCode,
      71,
    );
  });

  test(
    'authorized device weather replaces the first-launch simulation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final client = MockClient((request) async {
        expect(request.url.queryParameters['latitude'], '31.23');
        expect(request.url.queryParameters['longitude'], '121.47');
        return http.Response(
          jsonEncode({
            'latitude': 31.23,
            'longitude': 121.47,
            'timezone': 'Asia/Shanghai',
            'current': {'temperature_2m': 19.0, 'weather_code': 63},
            'daily': {
              'time': ['2026-07-31'],
              'weather_code': [63],
              'temperature_2m_max': [21.0],
              'temperature_2m_min': [17.0],
              'precipitation_probability_max': [76],
            },
            'hourly': {
              'time': ['2026-07-31T08:00'],
              'weather_code': [63],
              'temperature_2m': [18.0],
            },
          }),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          weatherLocationGatewayProvider.overrideWithValue(
            const _FakeWeatherLocation(),
          ),
          weatherRepositoryProvider.overrideWithValue(
            WeatherRepository(httpClient: client),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(weatherControllerProvider).demoMode, isTrue);
      expect(
        await container
            .read(weatherControllerProvider.notifier)
            .requestLocation(),
        WeatherStatus.ready,
      );
      final current = container.read(weatherControllerProvider);
      expect(current.demoMode, isFalse);
      expect(current.campusFallback, isFalse);
      expect(current.snapshot?.currentWeatherCode, 63);
      expect(current.snapshot?.latitude, 31.23);
      expect(preferences.getString('weather.source.v1'), 'device');
    },
  );

  testWidgets('dashboard widgets fit every supported tile size at 320px', (
    tester,
  ) async {
    const courses = [
      Course(
        id: 'interaction',
        name: '交互设计',
        teacher: '沈老师',
        room: '艺术楼 112',
        weekday: 3,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF356EF5,
      ),
      Course(
        id: 'mobile',
        name: '移动应用开发',
        teacher: '林老师',
        room: '海韵楼 A204',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFFE56B4A,
      ),
    ];

    final plans = [
      CoursePlan(
        id: 'plan-1',
        courseId: courses.first.id,
        title: '完成交互原型与说明文档',
        estimatedMinutes: 90,
        dueAt: DateTime(2026, 7, 28),
      ),
    ];
    const tasks = [
      DayTask(id: 'task-1', dateKey: '2026-07-26', title: '整理课堂笔记并提交反馈'),
    ];
    final timeline = [
      TodayCourse(
        course: courses.first,
        startMinutes: 480,
        endMinutes: 570,
        status: TodayCourseStatus.upcoming,
        timeLabel: '08:00-09:30',
      ),
    ];
    final viewModel = TodayViewModel(
      now: DateTime(2026, 7, 26, 7, 30),
      courses: timeline,
      dayTasks: tasks,
      coursePlans: plans,
      progress: 0.35,
      remainingMinutes: 90,
      gapSuggestion: '提前准备课程资料',
    );
    final weather = WeatherState(
      status: WeatherStatus.ready,
      demoMode: true,
      snapshot: WeatherSnapshot(
        latitude: 34.6,
        longitude: 119.2,
        timezone: 'Asia/Shanghai',
        currentTemperature: 26,
        currentWeatherCode: 2,
        fetchedAt: DateTime(2026, 7, 26),
        daily: const [
          DailyWeather(
            dateKey: '2026-07-26',
            weatherCode: 2,
            temperatureMax: 30,
            temperatureMin: 23,
            precipitationProbability: 22,
          ),
        ],
      ),
    );

    Future<void> pumpTile(TodayTileSize size, Widget child) async {
      // Mirrors TodayDashboardGrid at the supported 320px viewport:
      // 10px page gutters, 10px column gap and 112px rows.
      final width = size.columns == 1 ? 145.0 : 300.0;
      final height = size.rows == 1 ? 112.0 : 234.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${child.runtimeType} must fit $size',
      );
    }

    for (final size in TodayTileSize.values) {
      await pumpTile(
        size,
        TodayCommandSummary(
          size: size,
          viewModel: viewModel,
          weatherHint: '午后可能有阵雨，记得带伞',
        ),
      );
      await pumpTile(
        size,
        TodayCourseTimeline(
          size: size,
          courses: timeline,
          onOpenSchedule: () {},
        ),
      );
      await pumpTile(
        size,
        TodayTaskPanel(
          size: size,
          tasks: tasks,
          onAdd: () {},
          onToggle: (_) {},
        ),
      );
      await pumpTile(
        size,
        TodayCourseWorkPanel(
          size: size,
          plans: plans,
          courses: courses,
          onToggle: (_) {},
          onOpen: (_) {},
        ),
      );
      await pumpTile(
        size,
        TodayMaterialsPanel(
          size: size,
          materials: [
            (courses[0], const ['速写本', '触控笔']),
            (courses[1], const ['Flutter 实战', 'Type-C 转接线']),
          ],
          onOpenCourse: (_) {},
          onEmptyTap: () {},
        ),
      );
      await pumpTile(
        size,
        TodayWeatherPanel(
          size: size,
          weather: weather,
          date: viewModel.now,
          reduceMotion: true,
          onTap: () {},
        ),
      );
      await pumpTile(
        size,
        TodayReadinessPanel(size: size, viewModel: viewModel),
      );
      await pumpTile(
        size,
        TodayWeekGlancePanel(size: size, courses: courses, week: 2),
      );
      await pumpTile(size, TodayStudyLoadPanel(size: size));
    }
  });

  testWidgets(
    'dashboard previews drag placement and corner resize before commit',
    (tester) async {
      TodayTileId? movedId;
      int? movedIndex;
      TodayTileId? resizedId;
      TodayTileSize? resizedSize;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 296,
                child: TodayDashboardGrid(
                  layout: const [
                    TodayTileConfig(
                      id: TodayTileId.tasks,
                      size: TodayTileSize.oneByOne,
                    ),
                    TodayTileConfig(
                      id: TodayTileId.courseWork,
                      size: TodayTileSize.oneByOne,
                    ),
                  ],
                  editing: true,
                  reduceMotion: true,
                  onRequestEdit: () {},
                  onReorder: (id, index) {
                    movedId = id;
                    movedIndex = index;
                  },
                  onResize: (id, size) {
                    resizedId = id;
                    resizedSize = size;
                  },
                  onHide: (_) {},
                  children: {
                    TodayTileId.tasks: (_) =>
                        const ColoredBox(color: Color(0xFFEFF4FF)),
                    TodayTileId.courseWork: (_) =>
                        const ColoredBox(color: Color(0xFFFFF4EA)),
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final taskTile = find.byKey(const ValueKey(TodayTileId.tasks));
      final workTile = find.byKey(const ValueKey(TodayTileId.courseWork));
      final drag = await tester.startGesture(tester.getCenter(workTile));
      await tester.pump(const Duration(milliseconds: 140));
      await drag.moveTo(tester.getCenter(taskTile));
      await tester.pump();
      await drag.up();
      await tester.pump();

      expect(movedId, TodayTileId.courseWork);
      expect(movedIndex, 0);

      final resizeHandle = find.bySemanticsLabel('从右下角缩放当天待办');
      expect(resizeHandle, findsOneWidget);
      final resize = await tester.startGesture(tester.getCenter(resizeHandle));
      await tester.pump();
      await resize.moveBy(const Offset(36, 36));
      await tester.pump();
      await resize.moveBy(const Offset(36, 36));
      await tester.pump();
      await resize.up();
      await tester.pump();

      expect(resizedId, TodayTileId.tasks);
      expect(resizedSize, TodayTileSize.twoByTwo);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'full-width tile is one drop region and bottom handle only changes height',
    (tester) async {
      TodayTileId? movedId;
      int? movedIndex;
      TodayTileId? resizedId;
      TodayTileSize? resizedSize;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: TodayDashboardGrid(
                  layout: const [
                    TodayTileConfig(
                      id: TodayTileId.tasks,
                      size: TodayTileSize.oneByOne,
                    ),
                    TodayTileConfig(
                      id: TodayTileId.courseWork,
                      size: TodayTileSize.oneByOne,
                    ),
                    TodayTileConfig(
                      id: TodayTileId.materials,
                      size: TodayTileSize.twoByOne,
                    ),
                  ],
                  editing: true,
                  reduceMotion: true,
                  onRequestEdit: () {},
                  onReorder: (id, index) {
                    movedId = id;
                    movedIndex = index;
                  },
                  onResize: (id, size) {
                    resizedId = id;
                    resizedSize = size;
                  },
                  onHide: (_) {},
                  children: {
                    TodayTileId.tasks: (_) =>
                        const ColoredBox(color: Color(0xFFEFF4FF)),
                    TodayTileId.courseWork: (_) =>
                        const ColoredBox(color: Color(0xFFFFF4EA)),
                    TodayTileId.materials: (_) =>
                        const ColoredBox(color: Color(0xFFF0F6EE)),
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final taskTile = find.byKey(const ValueKey(TodayTileId.tasks));
      final materialsTile = find.byKey(const ValueKey(TodayTileId.materials));
      final materialsRect = tester.getRect(materialsTile);
      final drag = await tester.startGesture(tester.getCenter(taskTile));
      await tester.pump(const Duration(milliseconds: 140));
      await drag.moveTo(
        Offset(materialsRect.right - 12, materialsRect.top + 30),
      );
      await tester.pump();
      await drag.up();
      await tester.pump();

      expect(movedId, TodayTileId.tasks);
      expect(movedIndex, 1);

      final heightHandle = find.descendant(
        of: taskTile,
        matching: find.bySemanticsLabel('上下拖动调整组件高度'),
      );
      expect(heightHandle, findsOneWidget);
      final resize = await tester.startGesture(tester.getCenter(heightHandle));
      await resize.moveBy(const Offset(0, 34));
      await tester.pump();
      await resize.moveBy(const Offset(0, 34));
      await tester.pump();
      await resize.up();
      await tester.pump();

      expect(resizedId, TodayTileId.tasks);
      expect(resizedSize, TodayTileSize.oneByTwo);
      expect(tester.takeException(), isNull);
    },
  );
}
