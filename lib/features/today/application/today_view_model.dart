import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

enum TodayCourseStatus { finished, ongoing, upcoming }

class TodayCourse {
  const TodayCourse({
    required this.course,
    required this.startMinutes,
    required this.endMinutes,
    required this.status,
    required this.timeLabel,
  });

  final Course course;
  final int startMinutes;
  final int endMinutes;
  final TodayCourseStatus status;
  final String timeLabel;
}

class TodayViewModel {
  const TodayViewModel({
    required this.now,
    required this.courses,
    required this.dayTasks,
    required this.coursePlans,
    required this.progress,
    required this.remainingMinutes,
    required this.gapSuggestion,
  });

  final DateTime now;
  final List<TodayCourse> courses;
  final List<DayTask> dayTasks;
  final List<CoursePlan> coursePlans;
  final double progress;
  final int remainingMinutes;
  final String gapSuggestion;

  TodayCourse? get ongoing => courses
      .where((item) => item.status == TodayCourseStatus.ongoing)
      .firstOrNull;

  TodayCourse? get next => courses
      .where((item) => item.status == TodayCourseStatus.upcoming)
      .firstOrNull;

  TodayCourse? get lead => ongoing ?? next;

  int get remainingCourses =>
      courses.where((item) => item.status != TodayCourseStatus.finished).length;
}

final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime(2026, 7, 27, 7, 35);
});

final todayViewModelProvider = Provider<TodayViewModel>((ref) {
  final schedule = ref.watch(scheduleControllerProvider);
  final settings = ref.watch(appSettingsProvider);
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  final todayMinutes = now.hour * 60 + now.minute;
  final calendarWeek = ScheduleEngine.currentWeek(
    schedule.termStart,
    now,
    schedule.totalWeeks,
  );
  final times = settings.summerSchedule
      ? summerCourseTimes
      : standardCourseTimes;
  final dateKey = ScheduleEngine.dateKey(now);
  final override = schedule.dayOverrides
      .where((item) => item.dateKey == dateKey)
      .firstOrNull;
  final sourceWeekday = override?.kind == AcademicDayKind.makeUp
      ? override?.sourceWeekday ?? now.weekday
      : now.weekday;
  final isHoliday = override?.kind == AcademicDayKind.holiday;
  final active =
      schedule.courses
          .where((course) {
            return !isHoliday &&
                course.weekday == sourceWeekday &&
                course.occursInWeek(calendarWeek);
          })
          .map((course) {
            final start = ScheduleEngine.minutesOf(
              times[course.startSection - 1].start,
            );
            final end = ScheduleEngine.minutesOf(
              times[course.endSection - 1].end,
            );
            final status = todayMinutes >= end
                ? TodayCourseStatus.finished
                : todayMinutes >= start
                ? TodayCourseStatus.ongoing
                : TodayCourseStatus.upcoming;
            return TodayCourse(
              course: course,
              startMinutes: start,
              endMinutes: end,
              status: status,
              timeLabel:
                  '${times[course.startSection - 1].start}-${times[course.endSection - 1].end}',
            );
          })
          .toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  var totalMinutes = 0;
  var elapsedMinutes = 0;
  var remainingMinutes = 0;
  for (final item in active) {
    final length = item.endMinutes - item.startMinutes;
    totalMinutes += length;
    if (item.status == TodayCourseStatus.finished) {
      elapsedMinutes += length;
    } else if (item.status == TodayCourseStatus.ongoing) {
      elapsedMinutes += todayMinutes - item.startMinutes;
      remainingMinutes += item.endMinutes - todayMinutes;
    } else {
      remainingMinutes += length;
    }
  }

  final pendingPlans =
      schedule.coursePlans.where((plan) => !plan.completed).toList()
        ..sort((a, b) {
          final dueA = a.dueAt ?? DateTime(9999);
          final dueB = b.dueAt ?? DateTime(9999);
          return dueA.compareTo(dueB);
        });
  final nextCourse = active
      .where((item) => item.status == TodayCourseStatus.upcoming)
      .firstOrNull;
  final gapMinutes = nextCourse == null
      ? 0
      : nextCourse.startMinutes - todayMinutes;
  final matchingPlan = pendingPlans
      .where((plan) => plan.estimatedMinutes <= gapMinutes - 10)
      .firstOrNull;

  return TodayViewModel(
    now: now,
    courses: active,
    dayTasks: schedule.dayTasks
        .where((task) => task.dateKey == ScheduleEngine.dateKey(now))
        .toList(),
    coursePlans: pendingPlans,
    progress: totalMinutes == 0 ? 1 : elapsedMinutes / totalMinutes,
    remainingMinutes: remainingMinutes,
    gapSuggestion: switch ((nextCourse, matchingPlan)) {
      (final course?, final plan?) =>
        '距离 ${course.course.name} 还有 $gapMinutes 分钟，可以先完成“${plan.title}”。',
      (final course?, null) =>
        '距离 ${course.course.name} 还有 $gapMinutes 分钟，适合整理笔记或提前出发。',
      _ when active.isNotEmpty => '今天的课程已结束，留一点时间整理课堂收获。',
      _ => '今天没有课程，可以为最重要的计划留出一段专注时间。',
    },
  );
});

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
