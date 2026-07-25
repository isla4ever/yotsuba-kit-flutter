import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/app/app.dart';
import 'package:yotsuba_schedule/app/router.dart';
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
    appRouter.go('/');
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

  testWidgets('keeps the today dashboard in two columns at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300));

    final tasks = tester.getTopLeft(find.text('还要做什么'));
    final courseWork = tester.getTopLeft(find.text('临近截止'));
    expect((tasks.dy - courseWork.dy).abs(), lessThan(8));
    expect(courseWork.dx, greaterThan(tasks.dx));
    expect(tester.takeException(), isNull);
  });
}
