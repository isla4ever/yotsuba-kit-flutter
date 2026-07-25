import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/app/router.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_theme.dart';

class YotsubaScheduleApp extends ConsumerWidget {
  const YotsubaScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'Yotsuba Schedule',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeAnimationDuration: settings.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
    );
  }
}
