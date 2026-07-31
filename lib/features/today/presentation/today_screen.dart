import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/onboarding/application/today_onboarding_controller.dart';
import 'package:yotsuba_schedule/features/onboarding/presentation/spotlight_tour.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_completion_dialog.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_materials_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/data_management_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/day_planner_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/schedule_header.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_command_summary.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_course_timeline.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_dashboard_grid.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_demo_panels.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_readiness_board.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _editingLayout = false;
  final _weatherGuideKey = GlobalKey();
  final _commandGuideKey = GlobalKey();
  final _tasksGuideKey = GlobalKey();
  final _layoutGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(todayOnboardingProvider.notifier).startIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(todayViewModelProvider);
    final schedule = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final weather = ref.watch(weatherControllerProvider);
    final layout = ref.watch(todayLayoutProvider);
    final onboarding = ref.watch(todayOnboardingProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final dateLabel = DateFormat('M月d日 EEEE', 'zh_CN').format(viewModel.now);
    final weekStart = ScheduleEngine.weekStart(
      schedule.termStart,
      schedule.currentWeek,
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateRange =
        '${DateFormat('M.d').format(weekStart)}-${DateFormat('M.d').format(weekEnd)}';
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (settings.showHeader)
                ScheduleHeader(
                  week: schedule.currentWeek,
                  dateRange: dateRange,
                  weather: weather,
                  reduceMotion: settings.reduceMotion,
                  onSelectWeek: () => context.go('/schedule'),
                  onWeather: _requestWeather,
                  onManage: () => showDataManagementSheet(context),
                  style: YsHeaderStyle.standard,
                  showWeather: settings.showWeather,
                  showActions: settings.showHeaderActions,
                  weatherGuideKey: _weatherGuideKey,
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      key: const PageStorageKey('today-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth < 360 ? 10 : 12,
                        8,
                        constraints.maxWidth < 360 ? 10 : 12,
                        24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: Column(
                            children: [
                              _TodayHeading(
                                dateLabel: dateLabel,
                                week: schedule.currentWeek,
                                onGuide: () => ref
                                    .read(todayOnboardingProvider.notifier)
                                    .replay(),
                                onEditLayout: () =>
                                    setState(() => _editingLayout = true),
                                layoutKey: _layoutGuideKey,
                              ),
                              AnimatedSwitcher(
                                duration: settings.reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 280),
                                child: _editingLayout
                                    ? _TodayLayoutToolbar(
                                        key: const ValueKey('layout-toolbar'),
                                        onDone: () => setState(
                                          () => _editingLayout = false,
                                        ),
                                        onManage: _showWidgetManager,
                                        onGuide: () => ref
                                            .read(
                                              todayOnboardingProvider.notifier,
                                            )
                                            .replay(),
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
                                onReorder: (moving, visibleIndex) => ref
                                    .read(todayLayoutProvider.notifier)
                                    .moveToVisibleIndex(moving, visibleIndex),
                                onResize: (id, size) => ref
                                    .read(todayLayoutProvider.notifier)
                                    .setSize(id, size),
                                onHide: (id) => ref
                                    .read(todayLayoutProvider.notifier)
                                    .setVisible(id, false),
                                tourKeys: {
                                  TodayTileId.command: _commandGuideKey,
                                  TodayTileId.tasks: _tasksGuideKey,
                                },
                                children: {
                                  TodayTileId.command: (size) =>
                                      TodayCommandSummary(
                                        size: size,
                                        viewModel: viewModel,
                                        weatherHint: _weatherHint(
                                          weather,
                                          viewModel.now,
                                        ),
                                      ),
                                  TodayTileId.weather: (size) =>
                                      TodayWeatherPanel(
                                        size: size,
                                        weather: weather,
                                        date: viewModel.now,
                                        reduceMotion: settings.reduceMotion,
                                        onTap: _requestWeather,
                                      ),
                                  TodayTileId.timeline: (size) =>
                                      TodayCourseTimeline(
                                        size: size,
                                        courses: viewModel.courses,
                                        onOpenSchedule: () =>
                                            context.go('/schedule'),
                                      ),
                                  TodayTileId.tasks: (size) => TodayTaskPanel(
                                    size: size,
                                    tasks: viewModel.dayTasks,
                                    onAdd: () => showDayPlannerSheet(
                                      context,
                                      date: viewModel.now,
                                    ),
                                    onToggle: controller.toggleDayTask,
                                  ),
                                  TodayTileId.courseWork: (size) =>
                                      TodayCourseWorkPanel(
                                        size: size,
                                        plans: viewModel.coursePlans,
                                        courses: schedule.courses,
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
                                              .where(
                                                (item) =>
                                                    item.id == plan.courseId,
                                              )
                                              .firstOrNull;
                                          if (course != null) {
                                            showCoursePlanSheet(
                                              context,
                                              course: course,
                                            );
                                          }
                                        },
                                      ),
                                  TodayTileId.readiness: (size) =>
                                      TodayReadinessPanel(
                                        size: size,
                                        viewModel: viewModel,
                                      ),
                                  TodayTileId.weekGlance: (size) =>
                                      TodayWeekGlancePanel(
                                        size: size,
                                        courses: schedule.courses,
                                        week: schedule.currentWeek,
                                      ),
                                  TodayTileId.studyLoad: (size) =>
                                      TodayStudyLoadPanel(size: size),
                                  TodayTileId
                                      .materials: (size) => TodayMaterialsPanel(
                                    size: size,
                                    materials: [
                                      for (final item in viewModel.courses)
                                        if (item.course.materials.isNotEmpty)
                                          (item.course, item.course.materials),
                                    ],
                                    onOpenCourse: (course) =>
                                        showCourseMaterialsSheet(
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
            ],
          ),
        ),
        if (onboarding.active)
          SpotlightTour(
            key: ValueKey(onboarding.requestId),
            reduceMotion: settings.reduceMotion,
            onFinish: () => ref.read(todayOnboardingProvider.notifier).finish(),
            steps: [
              SpotlightStep(
                target: _weatherGuideKey,
                title: '天气与课程联动',
                body: '点击获取当前位置天气，今日提示、课程出行建议和页面氛围会一起更新。',
              ),
              SpotlightStep(
                target: _commandGuideKey,
                title: '先看今天还剩多少',
                body: '课程概览集中显示下一节课、剩余门数、还需上课时长和当天进度。',
              ),
              SpotlightStep(
                target: _tasksGuideKey,
                title: '待办与课程作业分开管理',
                body: '当天待办记录临时事项；课程作业保留课程关联、截止时间和完成记录。',
              ),
              SpotlightStep(
                target: _layoutGuideKey,
                title: '像桌面小组件一样排版',
                body: '进入布局模式后可拖动整张卡片，其他组件会自动让位；拖动四角改宽高，拖动下边缘只调高度。',
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _requestWeather() async {
    final controller = ref.read(weatherControllerProvider.notifier);
    final status = await controller.requestLocation();
    if (!mounted || status == WeatherStatus.ready) return;
    final locationMessage = ref.read(weatherControllerProvider).message;
    final fallbackStatus = await controller.useCampusWeather();
    if (!mounted) return;
    if (fallbackStatus == WeatherStatus.ready) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$locationMessage，已显示学校附近天气')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: appModalAnimationStyle,
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
                Text(
                  '$locationMessage；${state.message}',
                  style: TextStyle(color: palette.textSoft),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await controller.useCampusWeather();
                        },
                        child: const Text('重试学校天气'),
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
      isScrollControlled: true,
      sheetAnimationStyle: appModalAnimationStyle,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final layout = ref.watch(todayLayoutProvider);
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '管理今日组件',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '显示需要的信息，并直接选择紧凑、加高或通栏布局。',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSoft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: layout.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = layout[index];
                          return _WidgetManagerItem(
                            config: item,
                            onVisibleChanged: (value) => ref
                                .read(todayLayoutProvider.notifier)
                                .setVisible(item.id, value),
                            onSizeChanged: (size) => ref
                                .read(todayLayoutProvider.notifier)
                                .setSize(item.id, size),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
    required this.onGuide,
    super.key,
  });

  final VoidCallback onDone;
  final VoidCallback onManage;
  final VoidCallback onReset;
  final VoidCallback onGuide;

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
              '拖动换位 · 下边缘调高度',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: '查看布局操作指引',
            onPressed: onGuide,
            icon: const Icon(Icons.help_outline_rounded, size: 19),
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
    required this.dateLabel,
    required this.week,
    required this.onGuide,
    required this.onEditLayout,
    required this.layoutKey,
  });

  final String dateLabel;
  final int week;
  final VoidCallback onGuide;
  final VoidCallback onEditLayout;
  final GlobalKey layoutKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '今日',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dateLabel · 第$week周',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textFaint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TodayHeaderAction(
                tooltip: '查看今日引导',
                icon: Icons.help_outline_rounded,
                onTap: onGuide,
              ),
              const SizedBox(width: 6),
              KeyedSubtree(
                key: layoutKey,
                child: _TodayHeaderAction(
                  tooltip: '编辑今日看板',
                  onTap: onEditLayout,
                  icon: Icons.edit_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayHeaderAction extends StatelessWidget {
  const _TodayHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.82),
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: palette.textSoft),
        ),
      ),
    );
  }
}

class _WidgetManagerItem extends StatelessWidget {
  const _WidgetManagerItem({
    required this.config,
    required this.onVisibleChanged,
    required this.onSizeChanged,
  });

  final TodayTileConfig config;
  final ValueChanged<bool> onVisibleChanged;
  final ValueChanged<TodayTileSize> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tileLabel(config.id),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.visible
                            ? '当前 ${_sizeLabel(config.size)}'
                            : '已隐藏',
                        style: TextStyle(fontSize: 11, color: palette.textSoft),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: config.visible,
                  onChanged: onVisibleChanged,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final size in TodayTileSize.values)
                  ChoiceChip(
                    selected: config.size == size,
                    label: Text(_sizeLabel(size)),
                    onSelected: config.visible
                        ? (_) => onSizeChanged(size)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _tileLabel(TodayTileId id) => switch (id) {
  TodayTileId.command => '课程概览',
  TodayTileId.weather => '天气',
  TodayTileId.timeline => '课程时间轴',
  TodayTileId.readiness => '出发准备',
  TodayTileId.tasks => '当天待办',
  TodayTileId.courseWork => '课程作业',
  TodayTileId.weekGlance => '本周一览',
  TodayTileId.studyLoad => '学习投入',
  TodayTileId.materials => '携带物品',
};

String _sizeLabel(TodayTileSize size) => switch (size) {
  TodayTileSize.oneByOne => '1×1 单栏紧凑',
  TodayTileSize.oneByTwo => '1×2 单栏加高',
  TodayTileSize.twoByOne => '2×1 通栏紧凑',
  TodayTileSize.twoByTwo => '2×2 通栏加高',
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
