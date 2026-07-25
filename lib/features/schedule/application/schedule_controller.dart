import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/data/local/schedule_local_repository.dart';
import 'package:yotsuba_schedule/data/mock/mock_schedule_repository.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';

@immutable
class ScheduleState {
  const ScheduleState({
    required this.termStart,
    required this.totalWeeks,
    required this.currentWeek,
    required this.courses,
    required this.dayTasks,
    required this.coursePlans,
    required this.dayOverrides,
  });

  final DateTime termStart;
  final int totalWeeks;
  final int currentWeek;
  final List<Course> courses;
  final List<DayTask> dayTasks;
  final List<CoursePlan> coursePlans;
  final List<AcademicDayOverride> dayOverrides;

  ScheduleState copyWith({
    DateTime? termStart,
    int? totalWeeks,
    int? currentWeek,
    List<Course>? courses,
    List<DayTask>? dayTasks,
    List<CoursePlan>? coursePlans,
    List<AcademicDayOverride>? dayOverrides,
  }) {
    return ScheduleState(
      termStart: termStart ?? this.termStart,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      currentWeek: currentWeek ?? this.currentWeek,
      courses: courses ?? this.courses,
      dayTasks: dayTasks ?? this.dayTasks,
      coursePlans: coursePlans ?? this.coursePlans,
      dayOverrides: dayOverrides ?? this.dayOverrides,
    );
  }

  ScheduleData get data => ScheduleData(
    termStart: termStart,
    totalWeeks: totalWeeks,
    courses: courses,
    dayTasks: dayTasks,
    coursePlans: coursePlans,
    dayOverrides: dayOverrides,
  );
}

final mockScheduleRepositoryProvider = Provider(
  (ref) => const MockScheduleRepository(),
);

final scheduleLocalRepositoryProvider = Provider((ref) {
  return ScheduleLocalRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(mockScheduleRepositoryProvider),
  );
});

final scheduleControllerProvider =
    NotifierProvider<ScheduleController, ScheduleState>(ScheduleController.new);

class ScheduleController extends Notifier<ScheduleState> {
  ScheduleLocalRepository get _repository =>
      ref.read(scheduleLocalRepositoryProvider);

  @override
  ScheduleState build() {
    final data = ref.watch(scheduleLocalRepositoryProvider).load();
    final week = ScheduleEngine.currentWeek(
      data.termStart,
      DateTime.now(),
      data.totalWeeks,
    );
    return ScheduleState(
      termStart: data.termStart,
      totalWeeks: data.totalWeeks,
      currentWeek: week,
      courses: data.courses,
      dayTasks: data.dayTasks,
      coursePlans: data.coursePlans,
      dayOverrides: data.dayOverrides,
    );
  }

  void setWeek(int week) {
    state = state.copyWith(currentWeek: week.clamp(1, state.totalWeeks));
  }

  void replaceScheduleData(ScheduleData data) {
    state = ScheduleState(
      termStart: data.termStart,
      totalWeeks: data.totalWeeks,
      currentWeek: ScheduleEngine.currentWeek(
        data.termStart,
        DateTime.now(),
        data.totalWeeks,
      ),
      courses: data.courses,
      dayTasks: data.dayTasks,
      coursePlans: data.coursePlans,
      dayOverrides: data.dayOverrides,
    );
    _persist();
  }

  void goToCurrentWeek() {
    setWeek(
      ScheduleEngine.currentWeek(
        state.termStart,
        DateTime.now(),
        state.totalWeeks,
      ),
    );
  }

  void updateAcademicTerm(DateTime termStart, int totalWeeks) {
    final normalized = DateTime(
      termStart.year,
      termStart.month,
      termStart.day - (termStart.weekday - 1),
    );
    final weeks = totalWeeks.clamp(1, 30);
    state = state.copyWith(
      termStart: normalized,
      totalWeeks: weeks,
      currentWeek: ScheduleEngine.currentWeek(
        normalized,
        DateTime.now(),
        weeks,
      ),
    );
    _persist();
  }

  void replaceRemoteDayOverrides(List<AcademicDayOverride> remote) {
    final remoteYears = remote.map((item) => item.date.year).toSet();
    final manual = state.dayOverrides.where(
      (item) => item.isManual || !remoteYears.contains(item.date.year),
    );
    final manualKeys = manual.map((item) => item.dateKey).toSet();
    final merged = <AcademicDayOverride>[
      ...manual,
      ...remote.where((item) => !manualKeys.contains(item.dateKey)),
    ]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    state = state.copyWith(dayOverrides: merged);
    _persist();
  }

  void upsertDayOverride(AcademicDayOverride value) {
    final items = [...state.dayOverrides];
    final index = items.indexWhere((item) => item.dateKey == value.dateKey);
    if (index == -1) {
      items.add(value);
    } else {
      items[index] = value;
    }
    items.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    state = state.copyWith(dayOverrides: items);
    _persist();
  }

  void deleteDayOverride(String dateKey) {
    state = state.copyWith(
      dayOverrides: state.dayOverrides
          .where((item) => item.dateKey != dateKey)
          .toList(),
    );
    _persist();
  }

  void addCourse(Course course) {
    state = state.copyWith(courses: [...state.courses, course]);
    _persist();
  }

  void updateCourse(Course course) {
    state = state.copyWith(
      courses: state.courses
          .map((item) => item.id == course.id ? course : item)
          .toList(),
    );
    _persist();
  }

  void updateCourseMaterials(String courseId, List<String> materials) {
    state = state.copyWith(
      courses: state.courses.map((course) {
        return course.id == courseId
            ? course.copyWith(materials: List.unmodifiable(materials))
            : course;
      }).toList(),
    );
    _persist();
  }

  void deleteCourse(String courseId) {
    state = state.copyWith(
      courses: state.courses.where((course) => course.id != courseId).toList(),
      coursePlans: state.coursePlans
          .where((plan) => plan.courseId != courseId)
          .toList(),
    );
    _persist();
  }

  void addDayTask(DateTime date, String title) {
    final value = title.trim();
    if (value.isEmpty) return;
    final task = DayTask(
      id: _newId('day'),
      dateKey: ScheduleEngine.dateKey(date),
      title: value,
    );
    state = state.copyWith(dayTasks: [...state.dayTasks, task]);
    _persist();
  }

  void updateDayTask(String taskId, String title) {
    final value = title.trim();
    if (value.isEmpty) return;
    state = state.copyWith(
      dayTasks: state.dayTasks.map((task) {
        return task.id == taskId ? task.copyWith(title: value) : task;
      }).toList(),
    );
    _persist();
  }

  void toggleDayTask(String taskId) {
    state = state.copyWith(
      dayTasks: state.dayTasks.map((task) {
        return task.id == taskId
            ? task.copyWith(completed: !task.completed)
            : task;
      }).toList(),
    );
    _persist();
  }

  void deleteDayTask(String taskId) {
    state = state.copyWith(
      dayTasks: state.dayTasks.where((task) => task.id != taskId).toList(),
    );
    _persist();
  }

  void saveCoursePlan(CoursePlan plan) {
    final exists = state.coursePlans.any((item) => item.id == plan.id);
    state = state.copyWith(
      coursePlans: exists
          ? state.coursePlans
                .map((item) => item.id == plan.id ? plan : item)
                .toList()
          : [...state.coursePlans, plan],
    );
    _persist();
  }

  void deleteCoursePlan(String planId) {
    state = state.copyWith(
      coursePlans: state.coursePlans
          .where((plan) => plan.id != planId)
          .toList(),
    );
    _persist();
  }

  void toggleCoursePlan(String planId) {
    final plan = state.coursePlans
        .where((item) => item.id == planId)
        .firstOrNull;
    if (plan != null) {
      setCoursePlanCompleted(planId, !plan.completed);
    }
  }

  void setCoursePlanCompleted(String planId, bool completed) {
    state = state.copyWith(
      coursePlans: state.coursePlans.map((plan) {
        if (plan.id != planId) return plan;
        return plan.copyWith(
          completed: completed,
          completedAt: completed ? DateTime.now() : null,
          clearCompletedAt: !completed,
        );
      }).toList(),
    );
    _persist();
  }

  void toggleCoursePlanSubtask(String planId, String subtaskId) {
    state = state.copyWith(
      coursePlans: state.coursePlans.map((plan) {
        if (plan.id != planId) return plan;
        return plan.copyWith(
          subtasks: plan.subtasks.map((subtask) {
            return subtask.id == subtaskId
                ? subtask.copyWith(completed: !subtask.completed)
                : subtask;
          }).toList(),
        );
      }).toList(),
    );
    _persist();
  }

  void postponeCoursePlan(String planId, {int days = 1}) {
    state = state.copyWith(
      coursePlans: state.coursePlans.map((plan) {
        if (plan.id != planId) return plan;
        final base = plan.dueAt ?? DateTime.now();
        return plan.copyWith(
          dueAt: base.add(Duration(days: days)),
          clearDueSession: true,
          postponeCount: plan.postponeCount + 1,
        );
      }).toList(),
    );
    _persist();
  }

  DateTime? autoScheduleCoursePlan(String planId) {
    final plan = state.coursePlans
        .where((item) => item.id == planId)
        .firstOrNull;
    if (plan == null || plan.completed) return null;
    final slot = _findFreeSlot(plan);
    if (slot == null) return null;
    saveCoursePlan(
      plan.copyWith(scheduledStart: slot.$1, scheduledEnd: slot.$2),
    );
    return slot.$1;
  }

  void clearCoursePlanSchedule(String planId) {
    final plan = state.coursePlans
        .where((item) => item.id == planId)
        .firstOrNull;
    if (plan != null) saveCoursePlan(plan.copyWith(clearSchedule: true));
  }

  (DateTime, DateTime)? _findFreeSlot(CoursePlan plan) {
    final now = DateTime.now();
    final duration = Duration(minutes: plan.estimatedMinutes.clamp(15, 480));
    for (var offset = 0; offset < 14; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (plan.dueAt != null && day.isAfter(plan.dueAt!)) break;
      final startOfWindow = DateTime(day.year, day.month, day.day, 8);
      final endOfWindow = DateTime(day.year, day.month, day.day, 21, 30);
      var candidate = offset == 0 && now.isAfter(startOfWindow)
          ? _ceilToQuarter(now.add(const Duration(minutes: 15)))
          : startOfWindow;
      final busy = _busyRangesForDay(day, excludingPlanId: plan.id)
        ..sort((a, b) => a.$1.compareTo(b.$1));
      for (final range in busy) {
        if (!candidate.add(duration).isAfter(range.$1)) break;
        if (candidate.isBefore(range.$2)) candidate = _ceilToQuarter(range.$2);
      }
      final finish = candidate.add(duration);
      if (!finish.isAfter(endOfWindow) &&
          (plan.dueAt == null || !finish.isAfter(plan.dueAt!))) {
        return (candidate, finish);
      }
    }
    return null;
  }

  List<(DateTime, DateTime)> _busyRangesForDay(
    DateTime day, {
    required String excludingPlanId,
  }) {
    final ranges = <(DateTime, DateTime)>[];
    final week = day.difference(state.termStart).inDays ~/ 7 + 1;
    if (week >= 1 && week <= state.totalWeeks) {
      final dateKey = ScheduleEngine.dateKey(day);
      final dayOverride = state.dayOverrides
          .where((item) => item.dateKey == dateKey)
          .firstOrNull;
      final sourceWeekday = dayOverride?.kind == AcademicDayKind.makeUp
          ? dayOverride?.sourceWeekday ?? day.weekday
          : day.weekday;
      final times = ref.read(appSettingsProvider).summerSchedule
          ? summerCourseTimes
          : standardCourseTimes;
      for (final course in state.courses) {
        if (dayOverride?.kind == AcademicDayKind.holiday ||
            course.weekday != sourceWeekday ||
            !course.occursInWeek(week)) {
          continue;
        }
        final start = _atTime(day, times[course.startSection - 1].start);
        final end = _atTime(day, times[course.endSection - 1].end);
        ranges.add((start, end));
      }
    }
    for (final plan in state.coursePlans) {
      if (plan.id == excludingPlanId ||
          plan.scheduledStart == null ||
          plan.scheduledEnd == null ||
          !_isSameDay(plan.scheduledStart!, day)) {
        continue;
      }
      ranges.add((plan.scheduledStart!, plan.scheduledEnd!));
    }
    return ranges;
  }

  DateTime _atTime(DateTime day, String value) {
    final parts = value.split(':').map(int.parse).toList();
    return DateTime(day.year, day.month, day.day, parts[0], parts[1]);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _ceilToQuarter(DateTime value) {
    final remainder = value.minute % 15;
    final minutes = remainder == 0 ? 0 : 15 - remainder;
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ).add(Duration(minutes: minutes));
  }

  Future<void> resetMockData() async {
    await _repository.reset();
    ref.invalidateSelf();
  }

  void _persist() {
    unawaited(_repository.save(state.data));
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
