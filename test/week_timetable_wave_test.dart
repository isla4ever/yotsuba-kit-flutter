import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/week_timetable.dart';

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
  const _Harness({required this.initialWeek, required this.reduceMotion});

  final int initialWeek;
  final bool reduceMotion;

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
      onCourseTap: (_) {},
      onEmptyCellTap: (_, _, _) {},
      onDayTap: (_) {},
    );
  }
}

Future<void> _pumpTimetable(
  WidgetTester tester, {
  required bool reduceMotion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: _Harness(initialWeek: 1, reduceMotion: reduceMotion),
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
}
