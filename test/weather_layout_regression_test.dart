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
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_readiness_board.dart';

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
      expect(layout.first.size, TodayTileSize.twoByOne);
      expect(layout[1].size, TodayTileSize.oneByOne);
      expect(layout[2].size, TodayTileSize.oneByOne);
      expect(preferences.getString('today.dashboard.layout.v2'), isNotNull);
    },
  );

  test('weather response tolerates nullable forecast values', () async {
    final client = MockClient((_) async {
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
  });

  testWidgets('materials panel fits both half and full dashboard widths', (
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

    Future<void> pumpAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 152,
                child: TodayMaterialsPanel(
                  materials: [
                    (courses[0], const ['速写本', '触控笔']),
                    (courses[1], const ['Flutter 实战', 'Type-C 转接线']),
                  ],
                  compact: true,
                  onOpenCourse: (_) {},
                  onEmptyTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await pumpAt(170);
    await pumpAt(354);
    expect(find.text('今天要带什么'), findsOneWidget);
  });
}
