import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

const courses = <YsCourse>[
  YsCourse(
      id: 'stable',
      name: '高等数学',
      weekday: 1,
      startSection: 1,
      endSection: 2,
      startWeek: 1,
      endWeek: 20),
  YsCourse(
      id: 'week1',
      name: '体育',
      weekday: 4,
      startSection: 1,
      endSection: 2,
      startWeek: 1,
      endWeek: 1),
];

void main() {
  group('engine', () {
    test('structured books, materials and tasks preserve legacy carry items',
        () {
      const course = YsCourse(
        id: 'resources',
        name: '设计基础',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        materials: ['电脑'],
        materialDetails: [
          YsCourseMaterial(
            name: '图纸',
            kind: YsCourseMaterialKind.document,
            quantity: 2,
          ),
        ],
        books: [YsCourseBook(title: '设计方法', author: '张老师')],
        tasks: [YsCourseTask(id: 'task-1', title: '提交草图')],
      );
      expect(course.carryItems.map((item) => item.name), ['设计方法', '电脑', '图纸']);
      expect(course.tasks.single.title, '提交草图');
    });

    test('parity and week ranges', () {
      const odd = YsCourse(
          id: 'o',
          name: 'o',
          weekday: 1,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 16,
          parity: YsWeekParity.odd);
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
          YsDayOverride(
              date: '2026-03-14',
              kind: YsDayOverrideKind.makeup,
              sourceWeekday: 1),
        ],
      );
      final saturday = display.where((c) => c.weekday == 6).toList();
      expect(saturday.single.course.id, 'stable');
      expect(saturday.single.isMakeup, isTrue);
    });

    test('overlap groups are transitive', () {
      final display = buildDisplayCourses(const [
        YsCourse(
            id: 'a',
            name: 'a',
            weekday: 1,
            startSection: 1,
            endSection: 2,
            startWeek: 1,
            endWeek: 20),
        YsCourse(
            id: 'b',
            name: 'b',
            weekday: 1,
            startSection: 2,
            endSection: 3,
            startWeek: 1,
            endWeek: 20),
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
            cardEffect: YsCardEffect.none,
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
              cardEffect: YsCardEffect.none,
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
            cardEffect: YsCardEffect.none,
            onCourseTap: (course, stack) => tapped = course,
          ),
        ),
      ));
      await tester.tap(find.text('高等数学'));
      await tester.pumpAndSettle();
      expect(tapped?.course.id, 'stable');
    });

    testWidgets(
        'weather card layer and explicit effects are mutually exclusive',
        (tester) async {
      final weather = YsWeatherSnapshot(
        current: const YsCurrentWeather(kind: YsWeatherKind.heavyRain),
        daily: const [
          YsDailyWeather(date: '2026-03-02', kind: YsWeatherKind.heavyRain),
        ],
        updatedAt: DateTime(2026, 3, 2),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsWeekTimetable(
            week: 1,
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            weather: weather,
            reduceMotion: true,
          ),
        ),
      ));
      expect(find.byType(YsWeatherCardLayer), findsOneWidget);
      final defaultGlyphCount = find.byType(YsWeatherGlyph).evaluate().length;
      expect(defaultGlyphCount, 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsWeekTimetable(
            week: 1,
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            weather: weather,
            weatherCardGlyph: true,
            reduceMotion: true,
          ),
        ),
      ));
      expect(find.byType(YsWeatherGlyph), findsNWidgets(defaultGlyphCount + 1));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsWeekTimetable(
            week: 1,
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            weather: weather,
            cardEffect: YsCardEffect.glow,
            weatherCardGlyph: true,
            reduceMotion: true,
          ),
        ),
      ));
      expect(find.byType(YsWeatherCardLayer), findsNothing);
      expect(find.byType(YsWeatherGlyph), findsNWidgets(defaultGlyphCount + 1));
      expect(ysWeatherLabel(YsWeatherKind.heavyRain), '大雨');
    });

    testWidgets('renders week/day header from termStart', (tester) async {
      await tester.pumpWidget(harness(week: 2));
      await tester.pumpAndSettle();
      expect(find.text('3/10'), findsOneWidget); // 第2周周二
    });

    for (final transition in [
      YsTransition.slide,
      YsTransition.fade,
      YsTransition.cube,
      YsTransition.drop,
      YsTransition.zoom,
    ]) {
      testWidgets('${transition.name} retains the leaving week while fading',
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
                transition: transition,
                cardEffect: YsCardEffect.none,
              ),
            );
          }),
        ));

        setOuter(() => week = 2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('体育'), findsNWidgets(2));

        await tester.pumpAndSettle();
        expect(find.text('体育'), findsOneWidget);
      });
    }

    testWidgets('none switches without retaining a leaving layer',
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
              transition: YsTransition.none,
              cardEffect: YsCardEffect.none,
            ),
          );
        }),
      ));
      setOuter(() => week = 2);
      await tester.pump();
      expect(find.text('体育'), findsOneWidget);
    });
  });

  group('high-level widgets', () {
    testWidgets('course detail keeps labels and configurable empty copy',
        (tester) async {
      const emptyCourse = YsCourse(
        id: 'empty',
        name: '待完善课程',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
      );
      const display = YsDisplayCourse(
        course: emptyCourse,
        displayId: 'empty-display',
        weekday: 1,
        active: true,
      );
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: YsCourseDetailPanel(
            course: display,
            config: YsCourseDetailConfig(
              emptyText: '未填写',
              emptyTexts: {YsDetailField.location: '地点待定'},
            ),
          ),
        ),
      ));

      expect(find.text('地点'), findsOneWidget);
      expect(find.text('地点待定'), findsOneWidget);
      expect(find.text('教师'), findsOneWidget);
      expect(find.text('天气'), findsOneWidget);
      expect(find.text('课本'), findsOneWidget);
      expect(find.text('课程任务'), findsOneWidget);
      expect(find.text('未填写'), findsNWidgets(5));
    });

    testWidgets('overlap selection animates into course detail',
        (tester) async {
      const overlapping = [
        YsCourse(
          id: 'overlap-a',
          name: '课程 A',
          weekday: 1,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 16,
        ),
        YsCourse(
          id: 'overlap-b',
          name: '课程 B',
          weekday: 1,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 16,
        ),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsSchedule(
            week: 1,
            courses: overlapping,
            onWeekChanged: (_) {},
            reduceMotion: true,
          ),
        ),
      ));

      await tester.tap(find.text('课程 B'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('overlap-picker')), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, '课程 A'));
      await tester.pump();
      expect(find.byKey(const ValueKey('overlap-picker')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('course-detail-overlap-a')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('overlap-picker')), findsNothing);
      expect(find.text('返回重叠课程'), findsOneWidget);
    });

    testWidgets('course detail changes from compact to full in its header',
        (tester) async {
      const detailed = YsCourse(
        id: 'detail',
        name: '城市设计',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        note: '准备汇报图纸',
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsSchedule(
            week: 1,
            courses: const [detailed],
            onWeekChanged: (_) {},
            reduceMotion: true,
            detail: const YsCourseDetailConfig(
              layout: YsDetailLayout.compact,
            ),
          ),
        ),
      ));

      await tester.tap(find.text('城市设计'));
      await tester.pumpAndSettle();
      expect(find.text('课程详情'), findsOneWidget);
      expect(find.text('备注'), findsNothing);

      await tester.tap(find.byTooltip('切换详情档位'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全面详情'));
      await tester.pumpAndSettle();
      expect(find.text('备注'), findsOneWidget);
      expect(find.text('准备汇报图纸'), findsOneWidget);
    });

    testWidgets('Today long press enters editing and resizes from four corners',
        (tester) async {
      List<YsTodayWidgetConfig>? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsToday(
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            now: DateTime(2026, 3, 2, 9),
            widgets: const [
              YsTodayWidgetConfig(
                id: YsTodayWidgetIds.nextCourse,
                size: YsTodayWidgetSize.compact,
              ),
            ],
            reduceMotion: true,
            onWidgetsChanged: (value) => changed = value,
          ),
        ),
      ));

      await tester.longPress(find.byKey(const ValueKey('next-course')));
      await tester.pump();
      expect(find.byTooltip('完成布局调整'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('从.+角调整组件尺寸')),
        findsNWidgets(4),
      );

      await tester.drag(
        find.bySemanticsLabel('从右下角调整组件尺寸'),
        const Offset(80, 80),
      );
      await tester.pump();
      expect(changed?.single.size, YsTodayWidgetSize.twoByTwo);
    });

    testWidgets('Today shows resize handles only on the selected card',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsToday(
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            now: DateTime(2026, 3, 2, 9),
            widgets: const [
              YsTodayWidgetConfig(
                id: YsTodayWidgetIds.nextCourse,
                size: YsTodayWidgetSize.oneByOne,
              ),
              YsTodayWidgetConfig(
                id: YsTodayWidgetIds.weather,
                size: YsTodayWidgetSize.oneByOne,
              ),
            ],
            reduceMotion: true,
          ),
        ),
      ));

      await tester.tap(find.byTooltip('调整今日布局'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('从.+角调整组件尺寸')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('next-course')));
      await tester.pump();
      for (final corner in YsTodayResizeCorner.values) {
        expect(
          find.byKey(ValueKey('next-course-${corner.name}')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('weather-${corner.name}')),
          findsNothing,
        );
      }

      await tester.tap(find.byKey(const ValueKey('weather')));
      await tester.pump();
      for (final corner in YsTodayResizeCorner.values) {
        expect(
          find.byKey(ValueKey('next-course-${corner.name}')),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey('weather-${corner.name}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('Today weekly overview adapts content to the card size',
        (tester) async {
      Widget buildOverview(YsTodayWidgetSize size) => MaterialApp(
            home: Scaffold(
              body: YsToday(
                courses: courses,
                termStart: DateTime(2026, 3, 2),
                now: DateTime(2026, 3, 2, 9),
                widgets: [
                  YsTodayWidgetConfig(
                    id: YsTodayWidgetIds.weekGlance,
                    size: size,
                  ),
                ],
                reduceMotion: true,
              ),
            ),
          );

      await tester.pumpWidget(buildOverview(YsTodayWidgetSize.twoByTwo));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('week-glance-chart')),
        findsOneWidget,
      );
      expect(find.textContaining('本周共'), findsOneWidget);

      await tester.pumpWidget(buildOverview(YsTodayWidgetSize.oneByOne));
      await tester.pump();
      expect(find.byKey(const ValueKey('week-glance-chart')), findsNothing);
      expect(find.text('课程块'), findsOneWidget);
    });

    testWidgets('Today drags the whole card to reorder widgets',
        (tester) async {
      List<YsTodayWidgetConfig>? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: YsToday(
            courses: courses,
            termStart: DateTime(2026, 3, 2),
            now: DateTime(2026, 3, 2, 9),
            widgets: const [
              YsTodayWidgetConfig(
                id: YsTodayWidgetIds.nextCourse,
                size: YsTodayWidgetSize.oneByOne,
              ),
              YsTodayWidgetConfig(
                id: YsTodayWidgetIds.weather,
                size: YsTodayWidgetSize.oneByOne,
              ),
            ],
            reduceMotion: true,
            onWidgetsChanged: (value) => changed = value,
          ),
        ),
      ));

      final first = find.byKey(const ValueKey('next-course'));
      final second = find.byKey(const ValueKey('weather'));
      await tester.longPress(first);
      await tester.pump();
      final gesture = await tester.startGesture(tester.getCenter(first));
      await tester.pump(const Duration(milliseconds: 160));
      await gesture.moveTo(tester.getCenter(second));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(changed?.map((item) => item.id), [
        YsTodayWidgetIds.weather,
        YsTodayWidgetIds.nextCourse,
      ]);
    });

    testWidgets('adaptive sheets expose per-sheet placement control',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () => showYsAdaptiveSheet<void>(
                context: context,
                title: '局部弹窗',
                kind: YsSheetKind.custom,
                builder: (context, placement) => Center(
                  child: Text(placement.name),
                ),
              ),
              child: const Text('打开'),
            ),
          );
        }),
      ));

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('bottom'), findsOneWidget);
      await tester.tap(find.byTooltip('调整弹窗位置'));
      await tester.pumpAndSettle();
      expect(find.text('center'), findsOneWidget);
    });
  });
}
