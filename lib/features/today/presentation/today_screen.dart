import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_completion_dialog.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_materials_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/day_planner_sheet.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_command_summary.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_course_timeline.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_readiness_board.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(todayViewModelProvider);
    final schedule = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final weather = ref.watch(weatherControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final dateLabel = DateFormat('M月d日 · EEEE', 'zh_CN').format(viewModel.now);
    final greeting = switch (viewModel.now.hour) {
      < 6 => '夜深了',
      < 12 => '早上好',
      < 18 => '下午好',
      _ => '晚上好',
    };
    final sceneKind = weather.snapshot == null
        ? WeatherKind.neutral
        : weatherPresentation(weather.snapshot!.currentWeatherCode).kind;

    return WeatherScene(
      kind: sceneKind,
      reduceMotion: settings.reduceMotion,
      intensity: 0.9,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              key: const PageStorageKey('today-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      _TodayHeading(
                        greeting: greeting,
                        dateLabel: dateLabel,
                        weather: weather,
                        reduceMotion: settings.reduceMotion,
                        onWeatherTap: () => ref
                            .read(weatherControllerProvider.notifier)
                            .requestLocation(),
                      ),
                      const SizedBox(height: 12),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 108,
                              child: TodayCommandSummary(
                                viewModel: viewModel,
                                weatherHint: _weatherHint(
                                  weather,
                                  viewModel.now,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 92,
                              child: TodayCourseTimeline(
                                courses: viewModel.courses,
                                onOpenSchedule: () => context.go('/schedule'),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        TodayCommandSummary(
                          viewModel: viewModel,
                          weatherHint: _weatherHint(weather, viewModel.now),
                        ),
                        const SizedBox(height: 16),
                        TodayCourseTimeline(
                          courses: viewModel.courses,
                          onOpenSchedule: () => context.go('/schedule'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TodayReadinessBoard(
                        dayTasks: viewModel.dayTasks,
                        coursePlans: viewModel.coursePlans,
                        courses: schedule.courses,
                        todayCourses: viewModel.courses,
                        wide: wide,
                        onAddTask: () =>
                            showDayPlannerSheet(context, date: viewModel.now),
                        onToggleTask: controller.toggleDayTask,
                        onTogglePlan: (plan) async {
                          if (!plan.completed &&
                              !await confirmCoursePlanCompletion(
                                context,
                                plan,
                              )) {
                            return;
                          }
                          controller.setCoursePlanCompleted(
                            plan.id,
                            !plan.completed,
                          );
                        },
                        onOpenPlan: (plan) {
                          final course = schedule.courses
                              .where((item) => item.id == plan.courseId)
                              .firstOrNull;
                          if (course != null) {
                            showCoursePlanSheet(context, course: course);
                          }
                        },
                        onOpenMaterials: (course) =>
                            showCourseMaterialsSheet(context, course: course),
                        onOpenSchedule: () => context.go('/schedule'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TodayHeading extends StatelessWidget {
  const _TodayHeading({
    required this.greeting,
    required this.dateLabel,
    required this.weather,
    required this.reduceMotion,
    required this.onWeatherTap,
  });

  final String greeting;
  final String dateLabel;
  final WeatherState weather;
  final bool reduceMotion;
  final VoidCallback onWeatherTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 98,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textSoft,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '今日指挥台',
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 12, color: palette.textFaint),
                ),
              ],
            ),
          ),
          _WeatherChip(
            weather: weather,
            reduceMotion: reduceMotion,
            onTap: onWeatherTap,
          ),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.weather,
    required this.reduceMotion,
    required this.onTap,
  });

  final WeatherState weather;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final snapshot = weather.snapshot;
    final presentation = snapshot == null
        ? null
        : weatherPresentation(snapshot.currentWeatherCode);
    return Semantics(
      button: true,
      label: snapshot == null
          ? '获取当前位置天气'
          : '${presentation!.label}，${snapshot.currentTemperature.round()}度',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          constraints: const BoxConstraints(minWidth: 94),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.88),
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: weather.status == WeatherStatus.loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: palette.todayAccent,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WeatherGlyph(
                      kind: presentation?.kind ?? WeatherKind.neutral,
                      size: 23,
                      animate: !reduceMotion && snapshot != null,
                      color: palette.textSoft,
                    ),
                    const SizedBox(width: 6),
                    if (snapshot != null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${snapshot.currentTemperature.round()}°',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                            ),
                          ),
                          Text(
                            presentation!.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: palette.textFaint,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '天气',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textSoft,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _weatherHint(WeatherState state, DateTime date) {
  final daily = state.weatherForDate(DateFormat('yyyy-MM-dd').format(date));
  if (daily == null) {
    return state.message.isEmpty ? '授权定位后查看今日出行提示' : state.message;
  }
  final label = weatherPresentation(daily.weatherCode).label;
  final rain = daily.precipitationProbability;
  final rainHint = rain == null || rain < 30 ? '' : ' · 降水概率 $rain%';
  return '$label ${daily.temperatureMin.round()}°-${daily.temperatureMax.round()}°$rainHint';
}
