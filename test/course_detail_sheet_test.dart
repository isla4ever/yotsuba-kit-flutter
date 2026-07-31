import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_detail_sheet.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart'
    show YsDetailHero, YsDetailLayout, YsSheetPlacement;

const _course = Course(
  id: 'detail-course',
  name: '交互设计',
  teacher: '陈老师',
  room: '教1-201',
  weekday: 3,
  startSection: 3,
  endSection: 4,
  startWeek: 1,
  endWeek: 16,
  colorValue: 0xFF356EF5,
  materials: ['速写本', '触控笔'],
);

Future<void> _openDetail(
  WidgetTester tester, {
  required YsSheetPlacement placement,
  required YsDetailLayout layout,
  required bool glass,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCourseDetailSheet(
              context,
              course: _course,
              plans: const [],
              hero: YsDetailHero.plain,
              layout: layout,
              placement: placement,
              glass: glass,
              reduceMotion: true,
            ),
            child: const Text('打开课程'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开课程'));
  await tester.pump();
}

void main() {
  for (final placement in YsSheetPlacement.values) {
    testWidgets('${placement.name} course detail honors placement and glass', (
      tester,
    ) async {
      await _openDetail(
        tester,
        placement: placement,
        layout: YsDetailLayout.standard,
        glass: true,
      );

      expect(find.text('课程详情'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      switch (placement) {
        case YsSheetPlacement.bottom:
          expect(find.byType(BottomSheet), findsOneWidget);
        case YsSheetPlacement.center:
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Align && widget.alignment == Alignment.center,
            ),
            findsWidgets,
          );
        case YsSheetPlacement.right:
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Align && widget.alignment == Alignment.centerRight,
            ),
            findsOneWidget,
          );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('glass can be disabled for course detail', (tester) async {
    await _openDetail(
      tester,
      placement: YsSheetPlacement.center,
      layout: YsDetailLayout.standard,
      glass: false,
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('detail layouts expose three distinct information densities', (
    tester,
  ) async {
    await _openDetail(
      tester,
      placement: YsSheetPlacement.bottom,
      layout: YsDetailLayout.compact,
      glass: false,
    );
    expect(find.text('教师'), findsNothing);
    expect(find.text('教学周'), findsNothing);
    expect(find.text('上课携带'), findsNothing);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await _openDetail(
      tester,
      placement: YsSheetPlacement.bottom,
      layout: YsDetailLayout.standard,
      glass: false,
    );
    expect(find.text('教师'), findsOneWidget);
    expect(find.text('教学周'), findsOneWidget);
    expect(find.text('上课携带'), findsOneWidget);
    expect(find.text('陈老师 · 教1-201'), findsNothing);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await _openDetail(
      tester,
      placement: YsSheetPlacement.bottom,
      layout: YsDetailLayout.full,
      glass: false,
    );
    expect(find.text('陈老师 · 教1-201'), findsOneWidget);
    expect(find.byTooltip('分享课程'), findsOneWidget);
    expect(find.byTooltip('删除课程'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
