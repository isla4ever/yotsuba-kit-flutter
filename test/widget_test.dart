import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/app/app.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';

void main() {
  late SharedPreferences preferences;

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'settings.reduceMotion': true,
      'onboarding.schedule.completed.v1': true,
      'weather.autoRequest.v1': true,
    });
    preferences = await SharedPreferences.getInstance();
  });

  Widget testApp() => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    child: const YotsubaScheduleApp(),
  );

  testWidgets('renders the three primary destinations', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('今日'), findsOneWidget);
    expect(find.text('课表'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('今日指挥台'), findsOneWidget);
    expect(find.text('课程时间轴'), findsOneWidget);
  });

  testWidgets('switches from today to the weekly timetable', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('课表'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('周'), findsWidgets);
    expect(find.text('移动应用开发'), findsOneWidget);
  });
}
