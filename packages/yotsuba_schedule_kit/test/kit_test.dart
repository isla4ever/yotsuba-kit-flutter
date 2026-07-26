import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

const courses = <YsCourse>[
  YsCourse(id: 'stable', name: '高等数学', weekday: 1, startSection: 1, endSection: 2, startWeek: 1, endWeek: 20),
  YsCourse(id: 'week1', name: '体育', weekday: 4, startSection: 1, endSection: 2, startWeek: 1, endWeek: 1),
];

void main() {
  group('engine', () {
    test('parity and week ranges', () {
      const odd = YsCourse(id: 'o', name: 'o', weekday: 1, startSection: 1, endSection: 2, startWeek: 1, endWeek: 16, parity: YsWeekParity.odd);
      expect(isCourseActive(odd, 1), isTrue);
      expect(isCourseActive(odd, 2), isFalse);
      expect(isCourseActive(odd, 17), isFalse);
    });

    test('makeup day copies only active source courses', () {
      final display = buildDisplayCourses(
        courses,
        2,
        termStart: DateTime(2026, 3, 2),
        overrides: const [
          YsDayOverride(date: '2026-03-14', kind: YsDayOverrideKind.makeup, sourceWeekday: 1),
        ],
      );
      final saturday = display.where((c) => c.weekday == 6).toList();
      expect(saturday.single.course.id, 'stable');
      expect(saturday.single.isMakeup, isTrue);
    });

    test('overlap groups are transitive', () {
      final display = buildDisplayCourses(const [
        YsCourse(id: 'a', name: 'a', weekday: 1, startSection: 1, endSection: 2, startWeek: 1, endWeek: 20),
        YsCourse(id: 'b', name: 'b', weekday: 1, startSection: 2, endSection: 3, startWeek: 1, endWeek: 20),
      ], 1);
      expect(buildOverlapGroups(display).single.courses.length, 2);
    });

    test('weekOf clamps to term bounds', () {
      final start = DateTime(2026, 3, 2);
      expect(weekOf(DateTime(2026, 3, 9), start, 20), 2);
      expect(weekOf(DateTime(2025, 1, 1), start, 20), 1);
    });
  });

  group('ysWeekTimetable', () {
    Widget harness({required int week, ValueChanged<int>? onWeek}) {
      return MaterialApp(
        home: Scaffold(
          body: YsWeekTimetable(
            week: week,
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            onWeekRequested: onWeek,
          ),
        ),
      );
    }

    testWidgets('wave keeps old cards beneath while new sweep in',
        (tester) async {
      var week = 1;
      late StateSetter setOuter;
      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(builder: (context, setState) {
          setOuter = setState;
          return Scaffold(
            body: YsWeekTimetable(
              week: week,
              courses: courses,
              termStart: DateTime(2026, 3, 2),
            ),
          );
        }),
      ));
      expect(find.text('体育'), findsOneWidget);

      setOuter(() => week = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // 变化格：旧卡在下层，新卡进场中 → 同名卡两份；稳定卡只有一份
      expect(find.text('体育'), findsNWidgets(2));
      expect(find.text('高等数学'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('体育'), findsOneWidget);
      expect(find.text('非本周'), findsOneWidget);
    });

    testWidgets('reports course taps with the overlap stack', (tester) async {
      YsDisplayCourse? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsWeekTimetable(
            week: 1,
            courses: courses,
            onCourseTap: (course, stack) => tapped = course,
          ),
        ),
      ));
      await tester.tap(find.text('高等数学'));
      await tester.pumpAndSettle();
      expect(tapped?.course.id, 'stable');
    });

    testWidgets('renders week/day header from termStart', (tester) async {
      await tester.pumpWidget(harness(week: 2));
      await tester.pumpAndSettle();
      expect(find.text('3/10'), findsOneWidget); // 第2周周二
    });
  });
}
