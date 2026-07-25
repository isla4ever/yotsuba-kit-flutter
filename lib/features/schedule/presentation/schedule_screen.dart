import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/onboarding/application/schedule_onboarding_controller.dart';
import 'package:yotsuba_schedule/features/onboarding/presentation/spotlight_tour.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_detail_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_form_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/course_materials_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/data_management_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/day_planner_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/schedule_action_dock.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/schedule_header.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/widgets/week_timetable.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late final PageController _weekController;
  bool _editing = false;
  bool _toolMenuOpen = false;
  final _weekGuideKey = GlobalKey();
  final _timetableGuideKey = GlobalKey();
  final _toolsGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final week = ref.read(scheduleControllerProvider).currentWeek;
    _weekController = PageController(initialPage: week - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(scheduleOnboardingProvider.notifier).startIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _weekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final weather = ref.watch(weatherControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final onboarding = ref.watch(scheduleOnboardingProvider);
    final start = ScheduleEngine.weekStart(
      schedule.termStart,
      schedule.currentWeek,
    );
    final end = start.add(const Duration(days: 6));
    final range =
        '${DateFormat('M.d').format(start)}-${DateFormat('M.d').format(end)}';
    final sceneDate =
        DateTime.now().isAfter(start.subtract(const Duration(days: 1))) &&
            DateTime.now().isBefore(end.add(const Duration(days: 1)))
        ? DateTime.now()
        : start;
    final dailyWeather = weather.weatherForDate(
      ScheduleEngine.dateKey(sceneDate),
    );
    final sceneKind = dailyWeather != null
        ? weatherPresentation(dailyWeather.weatherCode).kind
        : weather.snapshot == null
        ? WeatherKind.neutral
        : weatherPresentation(weather.snapshot!.currentWeatherCode).kind;

    return WeatherScene(
      kind: sceneKind,
      reduceMotion: settings.reduceMotion,
      intensity: _editing ? 0 : 0.82,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                KeyedSubtree(
                  key: _weekGuideKey,
                  child: ScheduleHeader(
                    week: schedule.currentWeek,
                    dateRange: range,
                    weather: weather,
                    reduceMotion: settings.reduceMotion,
                    onSelectWeek: () => _showWeekPicker(schedule, controller),
                    onWeather: () => ref
                        .read(weatherControllerProvider.notifier)
                        .requestLocation(),
                    onManage: () => showDataManagementSheet(context),
                  ),
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: _timetableGuideKey,
                    child: AnimatedContainer(
                      duration: settings.reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      color: _editing
                          ? context.palette.canvas.withValues(alpha: 0.96)
                          : Colors.transparent,
                      child: PageView.builder(
                        controller: _weekController,
                        itemCount: schedule.totalWeeks,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        onPageChanged: (index) => controller.setWeek(index + 1),
                        itemBuilder: (context, index) {
                          final week = index + 1;
                          return WeekTimetable(
                            key: ValueKey('week-$week'),
                            termStart: schedule.termStart,
                            week: week,
                            courses: schedule.courses,
                            visibleDays: settings.showWeekend ? 7 : 5,
                            compact: settings.compactSchedule,
                            editing: _editing,
                            active: schedule.currentWeek == week,
                            reduceMotion: settings.reduceMotion,
                            onCourseTap: (course) => _showCourse(course, week),
                            onDayTap: (weekday) => showDayPlannerSheet(
                              context,
                              date: ScheduleEngine.dateForWeekday(
                                schedule.termStart,
                                week,
                                weekday,
                              ),
                            ),
                            onEmptyCellTap: (weekday, section) => _addCourse(
                              controller,
                              schedule,
                              weekday: weekday,
                              section: section,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ScheduleActionDock(
                key: _toolsGuideKey,
                editing: _editing,
                menuOpen: _toolMenuOpen,
                onToggleMenu: () =>
                    setState(() => _toolMenuOpen = !_toolMenuOpen),
                onToggleEdit: () => setState(() {
                  _editing = !_editing;
                  _toolMenuOpen = false;
                }),
                onOpenSettings: () {
                  setState(() => _toolMenuOpen = false);
                  context.go('/settings');
                },
                onReplayGuide: () {
                  setState(() => _toolMenuOpen = false);
                  ref.read(scheduleOnboardingProvider.notifier).replay();
                },
                onAdd: () => _addCourse(controller, schedule),
              ),
            ),
            if (onboarding.active)
              SpotlightTour(
                key: ValueKey(onboarding.requestId),
                reduceMotion: settings.reduceMotion,
                onFinish: () =>
                    ref.read(scheduleOnboardingProvider.notifier).finish(),
                steps: [
                  SpotlightStep(
                    target: _weekGuideKey,
                    title: '先认识课表顶部',
                    body: '点击周数可快速跳转，天气按钮会匹配当前位置，右侧入口管理导入、分享和日历。',
                  ),
                  SpotlightStep(
                    target: _timetableGuideKey,
                    title: '跟手浏览每一周',
                    body: '左右拖动时页面会紧跟手势。点击星期日期安排当天计划，点击课程查看计划和携带物品。',
                  ),
                  SpotlightStep(
                    target: _toolsGuideKey,
                    title: '编辑与新增课程',
                    body: '工具按钮可切换编辑模式，也能随时重新播放本引导；加号用于手动新增课程。',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCourse(
    ScheduleController controller,
    ScheduleState schedule, {
    int? weekday,
    int? section,
  }) async {
    setState(() => _toolMenuOpen = false);
    final course = await showCourseFormSheet(
      context,
      currentWeek: schedule.currentWeek,
      totalWeeks: schedule.totalWeeks,
      initialWeekday: weekday,
      initialStartSection: section,
    );
    if (course != null) controller.addCourse(course);
  }

  Future<void> _showCourse(Course course, int week) async {
    final schedule = ref.read(scheduleControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final date = ScheduleEngine.dateForWeekday(
      schedule.termStart,
      week,
      course.weekday,
    );
    final weatherState = ref.read(weatherControllerProvider);
    final weather = weatherState.weatherForDate(ScheduleEngine.dateKey(date));
    final action = await showCourseDetailSheet(
      context,
      course: course,
      plans: schedule.coursePlans
          .where((plan) => plan.courseId == course.id)
          .toList(),
      weather: weather,
      weatherHint: _weatherHint(weatherState),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case CourseDetailAction.edit:
        final edited = await showCourseFormSheet(
          context,
          currentWeek: schedule.currentWeek,
          totalWeeks: schedule.totalWeeks,
          initial: course,
        );
        if (edited != null) controller.updateCourse(edited);
      case CourseDetailAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除课程？'),
            content: Text('“${course.name}”及其课程计划将从本机移除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirmed == true) controller.deleteCourse(course.id);
      case CourseDetailAction.plans:
        await showCoursePlanSheet(context, course: course);
      case CourseDetailAction.materials:
        await showCourseMaterialsSheet(context, course: course);
    }
  }

  String _weatherHint(WeatherState weather) {
    return switch (weather.status) {
      WeatherStatus.idle => '点击顶部天气按钮后查看课程当日预报',
      WeatherStatus.loading => '正在匹配当前位置天气',
      WeatherStatus.denied => '定位权限未开启，暂时无法匹配天气',
      WeatherStatus.unavailable => '当前设备不支持定位天气',
      WeatherStatus.error => '天气暂时不可用，点击顶部天气按钮可重试',
      WeatherStatus.ready => '该日期尚未进入未来预报范围',
    };
  }

  Future<void> _showWeekPicker(
    ScheduleState schedule,
    ScheduleController controller,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        final palette = context.palette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择教学周', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.28,
                  ),
                  itemCount: schedule.totalWeeks,
                  itemBuilder: (context, index) {
                    final week = index + 1;
                    final active = week == schedule.currentWeek;
                    return InkWell(
                      onTap: () => Navigator.pop(context, week),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? palette.scheduleAccent
                              : palette.surfaceMuted,
                          border: Border.all(
                            color: active
                                ? palette.scheduleAccent
                                : palette.border,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '$week',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : palette.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    controller.setWeek(selected);
    if (!_weekController.hasClients) return;
    final current = (_weekController.page ?? (schedule.currentWeek - 1))
        .round();
    if ((selected - 1 - current).abs() <= 1) {
      await _weekController.animateToPage(
        selected - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _weekController.jumpToPage(selected - 1);
    }
  }
}
