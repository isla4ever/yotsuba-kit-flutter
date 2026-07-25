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
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_command_summary.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_course_timeline.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_dashboard_grid.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_readiness_board.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _editingLayout = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(todayViewModelProvider);
    final schedule = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final weather = ref.watch(weatherControllerProvider);
    final layout = ref.watch(todayLayoutProvider);
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
                        onWeatherTap: _requestWeather,
                      ),
                      AnimatedSwitcher(
                        duration: settings.reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 280),
                        child: _editingLayout
                            ? _TodayLayoutToolbar(
                                key: const ValueKey('layout-toolbar'),
                                onDone: () =>
                                    setState(() => _editingLayout = false),
                                onManage: _showWidgetManager,
                                onReset: () => ref
                                    .read(todayLayoutProvider.notifier)
                                    .reset(),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('layout-toolbar-empty'),
                              ),
                      ),
                      SizedBox(height: _editingLayout ? 12 : 6),
                      TodayDashboardGrid(
                        layout: layout,
                        editing: _editingLayout,
                        reduceMotion: settings.reduceMotion,
                        onRequestEdit: () =>
                            setState(() => _editingLayout = true),
                        onMove: (moving, target) => ref
                            .read(todayLayoutProvider.notifier)
                            .moveBefore(moving, target),
                        onResize: (id, delta) => ref
                            .read(todayLayoutProvider.notifier)
                            .resizeByDelta(id, delta),
                        onHide: (id) => ref
                            .read(todayLayoutProvider.notifier)
                            .setVisible(id, false),
                        children: {
                          TodayTileId.command: TodayCommandSummary(
                            viewModel: viewModel,
                            weatherHint: _weatherHint(weather, viewModel.now),
                          ),
                          TodayTileId.timeline: TodayCourseTimeline(
                            courses: viewModel.courses,
                            onOpenSchedule: () => context.go('/schedule'),
                          ),
                          TodayTileId.tasks: TodayTaskPanel(
                            tasks: viewModel.dayTasks,
                            compact:
                                layout
                                    .where(
                                      (item) => item.id == TodayTileId.tasks,
                                    )
                                    .firstOrNull
                                    ?.size
                                    .rows ==
                                1,
                            onAdd: () => showDayPlannerSheet(
                              context,
                              date: viewModel.now,
                            ),
                            onToggle: controller.toggleDayTask,
                          ),
                          TodayTileId.courseWork: TodayCourseWorkPanel(
                            plans: viewModel.coursePlans,
                            courses: schedule.courses,
                            compact:
                                layout
                                    .where(
                                      (item) =>
                                          item.id == TodayTileId.courseWork,
                                    )
                                    .firstOrNull
                                    ?.size
                                    .rows ==
                                1,
                            onToggle: (plan) async {
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
                            onOpen: (plan) {
                              final course = schedule.courses
                                  .where((item) => item.id == plan.courseId)
                                  .firstOrNull;
                              if (course != null) {
                                showCoursePlanSheet(context, course: course);
                              }
                            },
                          ),
                          TodayTileId.materials: TodayMaterialsPanel(
                            materials: [
                              for (final item in viewModel.courses)
                                if (item.course.materials.isNotEmpty)
                                  (item.course, item.course.materials),
                            ],
                            onOpenCourse: (course) => showCourseMaterialsSheet(
                              context,
                              course: course,
                            ),
                            onEmptyTap: () => context.go('/schedule'),
                          ),
                        },
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

  Future<void> _requestWeather() async {
    final controller = ref.read(weatherControllerProvider.notifier);
    final status = await controller.requestLocation();
    if (!mounted || status == WeatherStatus.ready) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        final state = ref.read(weatherControllerProvider);
        final palette = context.palette;
        final canOpenSettings = {
          WeatherStatus.deniedForever,
          WeatherStatus.serviceDisabled,
        }.contains(state.status);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: palette.scheduleAccent,
                  size: 26,
                ),
                const SizedBox(height: 10),
                Text(
                  '暂时无法使用当前位置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(state.message, style: TextStyle(color: palette.textSoft)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await controller.useCampusWeather();
                        },
                        child: const Text('使用学校天气'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (canOpenSettings &&
                              await controller.openPermissionSettings()) {
                            return;
                          }
                          await controller.requestLocation();
                        },
                        child: Text(canOpenSettings ? '开启定位' : '重新尝试'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWidgetManager() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final layout = ref.watch(todayLayoutProvider);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('管理今日组件', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '显示需要的信息，回到看板后可拖动排序和右下角调整尺寸。',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSoft,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in layout)
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_tileLabel(item.id)),
                      subtitle: Text('当前尺寸 ${item.size.label}'),
                      value: item.visible,
                      onChanged: (value) => ref
                          .read(todayLayoutProvider.notifier)
                          .setVisible(item.id, value),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TodayLayoutToolbar extends StatelessWidget {
  const _TodayLayoutToolbar({
    required this.onDone,
    required this.onManage,
    required this.onReset,
    super.key,
  });

  final VoidCallback onDone;
  final VoidCallback onManage;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.94),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            color: palette.scheduleAccent,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              '布局',
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: '管理组件',
            onPressed: onManage,
            icon: const Icon(Icons.widgets_outlined, size: 19),
          ),
          IconButton(
            tooltip: '恢复默认布局',
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 19),
          ),
          FilledButton.tonal(onPressed: onDone, child: const Text('完成')),
        ],
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
                        switch (weather.status) {
                          WeatherStatus.denied ||
                          WeatherStatus.deniedForever => '需定位',
                          WeatherStatus.serviceDisabled => '开定位',
                          WeatherStatus.error ||
                          WeatherStatus.unavailable => '重试',
                          _ => '天气',
                        },
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

String _tileLabel(TodayTileId id) => switch (id) {
  TodayTileId.command => '课程概览',
  TodayTileId.timeline => '课程时间轴',
  TodayTileId.tasks => '当天待办',
  TodayTileId.courseWork => '课程作业',
  TodayTileId.materials => '携带物品',
};

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
