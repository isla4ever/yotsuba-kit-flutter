import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
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

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _editing = false;
  bool _toolMenuOpen = false;
  final _screenGuideKey = GlobalKey();
  final _weekGuideKey = GlobalKey();
  final _courseGuideKey = GlobalKey();
  final _dayGuideKey = GlobalKey();
  final _weatherGuideKey = GlobalKey();
  final _toolsGuideKey = GlobalKey();
  final _addGuideKey = GlobalKey();
  final _dataGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(scheduleOnboardingProvider.notifier).startIfNeeded();
      }
    });
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
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            key: _screenGuideKey,
            children: [
              ScheduleHeader(
                week: schedule.currentWeek,
                dateRange: range,
                weather: weather,
                reduceMotion: settings.reduceMotion,
                onSelectWeek: () => _showWeekPicker(schedule, controller),
                onWeather: _requestWeather,
                onManage: () => showDataManagementSheet(context),
                weekGuideKey: _weekGuideKey,
                weatherGuideKey: _weatherGuideKey,
                dataGuideKey: _dataGuideKey,
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: settings.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  color: _editing
                      ? context.palette.canvas.withValues(alpha: 0.96)
                      : Colors.transparent,
                  child: WeekTimetable(
                    termStart: schedule.termStart,
                    week: schedule.currentWeek,
                    courses: schedule.courses,
                    dayOverrides: schedule.dayOverrides,
                    weather: weather.snapshot,
                    visibleDays: settings.showWeekend ? 7 : 5,
                    rowHeight: settings.scheduleRowHeight,
                    courseTimes: settings.summerSchedule
                        ? summerCourseTimes
                        : standardCourseTimes,
                    editing: _editing,
                    reduceMotion: settings.reduceMotion,
                    onSwipeWeek: (direction) =>
                        controller.setWeek(schedule.currentWeek + direction),
                    onCourseTap: (course) =>
                        _showCourse(course, schedule.currentWeek),
                    onDayTap: (weekday) => showDayPlannerSheet(
                      context,
                      date: ScheduleEngine.dateForWeekday(
                        schedule.termStart,
                        schedule.currentWeek,
                        weekday,
                      ),
                    ),
                    onEmptyCellTap: (weekday, start, end) => _addCourse(
                      controller,
                      schedule,
                      weekday: weekday,
                      section: start,
                      endSection: end,
                    ),
                    dayGuideKey: _dayGuideKey,
                    courseGuideKey: _courseGuideKey,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: ScheduleActionDock(
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
              toolsGuideKey: _toolsGuideKey,
              addGuideKey: _addGuideKey,
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
                  target: _screenGuideKey,
                  title: '快速认识你的课表',
                  body: '依次了解换周、课程、天气、计划和编辑。可随时关闭，之后也能从工具中重新打开。',
                ),
                SpotlightStep(
                  target: _weekGuideKey,
                  title: '切换教学周',
                  body: '点击周数可快速跳转；左右滑动课表，则适合连续浏览前后周。',
                ),
                SpotlightStep(
                  target: _courseGuideKey,
                  title: '查看课程详情',
                  body: '点击课程查看时间、地点和当日天气，也能继续管理作业计划与携带物品。',
                ),
                SpotlightStep(
                  target: _dayGuideKey,
                  title: '安排当天计划',
                  body: '点击星期与日期，可记录这一天的待办，完成后直接勾选。',
                ),
                SpotlightStep(
                  target: _weatherGuideKey,
                  title: '课程天气联动',
                  body: '授权定位后显示当前天气；预报范围内的课程详情也会给出出行提示。',
                ),
                SpotlightStep(
                  target: _toolsGuideKey,
                  title: '编辑课表',
                  body: '在工具里切换编辑模式，即可长按空白节次并向下拖选。本引导也可在这里重新打开。',
                ),
                SpotlightStep(
                  target: _addGuideKey,
                  title: '手动新增课程',
                  body: '点击加号新增课程，可设置星期、节次、周次、单双周和课程颜色。',
                ),
                SpotlightStep(
                  target: _dataGuideKey,
                  title: '导入、备份与日历',
                  body: '在这里导入或备份本地 JSON，并把课程和计划导出为系统日历。',
                ),
                SpotlightStep(
                  target: _screenGuideKey,
                  title: '今日指挥台',
                  body: '进入“今日”后，集中查看下一节课、剩余课程、未完成计划和上课准备。',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addCourse(
    ScheduleController controller,
    ScheduleState schedule, {
    int? weekday,
    int? section,
    int? endSection,
  }) async {
    setState(() => _toolMenuOpen = false);
    final course = await showCourseFormSheet(
      context,
      currentWeek: schedule.currentWeek,
      totalWeeks: schedule.totalWeeks,
      initialWeekday: weekday,
      initialStartSection: section,
      initialEndSection: endSection,
      usedColorValues: schedule.courses.map((item) => item.colorValue).toSet(),
    );
    if (course != null) controller.addCourse(course);
  }

  Future<void> _showCourse(Course course, int week) async {
    final schedule = ref.read(scheduleControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final original = schedule.courses.firstWhere(
      (item) => item.id == course.id,
      orElse: () => course,
    );
    final date = ScheduleEngine.dateForWeekday(
      schedule.termStart,
      week,
      course.weekday,
    );
    final weatherState = ref.read(weatherControllerProvider);
    final settings = ref.read(appSettingsProvider);
    final resolvedCourseTimes = settings.summerSchedule
        ? summerCourseTimes
        : standardCourseTimes;
    final startTime = course.startSection <= resolvedCourseTimes.length
        ? resolvedCourseTimes[course.startSection - 1].start
        : null;
    final weather = startTime == null
        ? weatherState.weatherForDate(ScheduleEngine.dateKey(date))
        : weatherState.snapshot?.weatherForDateTime(
            _courseDateTime(date, startTime),
          );
    final action = await showCourseDetailSheet(
      context,
      course: original,
      plans: schedule.coursePlans
          .where((plan) => plan.courseId == original.id)
          .toList(),
      weather: weather,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case CourseDetailAction.edit:
        final edited = await showCourseFormSheet(
          context,
          currentWeek: schedule.currentWeek,
          totalWeeks: schedule.totalWeeks,
          initial: original,
          usedColorValues: schedule.courses
              .where((item) => item.id != original.id)
              .map((item) => item.colorValue)
              .toSet(),
        );
        if (edited != null) controller.updateCourse(edited);
      case CourseDetailAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          animationStyle: appModalAnimationStyle,
          builder: (context) => AlertDialog(
            title: const Text('删除课程？'),
            content: Text('“${original.name}”及其课程计划将从本机移除。'),
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
        if (confirmed == true) controller.deleteCourse(original.id);
      case CourseDetailAction.plans:
        await showCoursePlanSheet(context, course: original);
      case CourseDetailAction.materials:
        await showCourseMaterialsSheet(context, course: original);
    }
  }

  DateTime _courseDateTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _requestWeather() async {
    final controller = ref.read(weatherControllerProvider.notifier);
    final status = await controller.requestLocation();
    if (!mounted || status == WeatherStatus.ready) return;
    final locationMessage = ref.read(weatherControllerProvider).message;
    final fallbackStatus = await controller.useCampusWeather();
    if (!mounted) return;
    final message = fallbackStatus == WeatherStatus.ready
        ? '$locationMessage，已显示学校附近天气'
        : ref.read(weatherControllerProvider).message;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showWeekPicker(
    ScheduleState schedule,
    ScheduleController controller,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: appModalAnimationStyle,
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
    if (selected == null || !mounted) return;
    controller.setWeek(selected);
  }
}
