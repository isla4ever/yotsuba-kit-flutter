import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';
import 'package:yotsuba_schedule/features/onboarding/presentation/spotlight_tour.dart';

void main() {
  testWidgets(
    'tour scrolls an offscreen target into view before measuring it',
    (tester) async {
      final firstKey = GlobalKey();
      final secondKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        key: firstKey,
                        width: double.infinity,
                        height: 90,
                      ),
                      const SizedBox(height: 900),
                      SizedBox(
                        key: secondKey,
                        width: double.infinity,
                        height: 120,
                      ),
                      const SizedBox(height: 180),
                    ],
                  ),
                ),
                SpotlightTour(
                  reduceMotion: true,
                  onFinish: () {},
                  steps: [
                    SpotlightStep(target: firstKey, title: '第一步', body: '首屏目标'),
                    SpotlightStep(
                      target: secondKey,
                      title: '第二步',
                      body: '屏幕下方的目标',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      final targetRect = tester.getRect(find.byKey(secondKey));
      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(targetRect.top, greaterThanOrEqualTo(0));
      expect(targetRect.bottom, lessThanOrEqualTo(viewportHeight));
      expect(find.text('第二步'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
