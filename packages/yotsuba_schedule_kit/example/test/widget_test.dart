import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule_kit_example/main.dart';

void main() {
  testWidgets('showcase switches between schedule and Today', (tester) async {
    await tester.pumpWidget(const YotsubaKitShowcase());
    expect(find.text('Yotsuba 课程表'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('今日'), findsWidgets);
    expect(find.byTooltip('设置'), findsOneWidget);
  });
}
