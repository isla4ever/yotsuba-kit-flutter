import 'models.dart';

/// 学期语义引擎：与 @iyotsuba/schedule-core 行为逐项对齐的纯函数集合。

String formatDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// 学期第 [week] 周星期 [weekday] 对应的日期（termStart 应为第 1 周周一）。
DateTime dateFor(DateTime termStart, int week, int weekday) {
  final start = DateTime(termStart.year, termStart.month, termStart.day);
  return start.add(Duration(days: (week - 1) * 7 + weekday - 1));
}

/// 某日期落在学期第几周（clamp 到 [1, totalWeeks]）。
int weekOf(DateTime date, DateTime termStart, int totalWeeks) {
  final target = DateTime(date.year, date.month, date.day);
  final start = DateTime(termStart.year, termStart.month, termStart.day);
  final diffDays = target.difference(start).inDays;
  final week = (diffDays / 7).floor() + 1;
  return week.clamp(1, totalWeeks);
}

/// 课程在指定周是否实际上课（周次范围 + 单双周）。
bool isCourseActive(YsCourse course, int week) {
  if (week < course.startWeek || week > course.endWeek) {
    return false;
  }
  switch (course.parity) {
    case YsWeekParity.odd:
      return week.isOdd;
    case YsWeekParity.even:
      return week.isEven;
    case YsWeekParity.every:
      return true;
  }
}

/// 生成某周的展示课程：假日清空当天，补班日替换为来源星期在该周真实生效的课程。
List<YsDisplayCourse> buildDisplayCourses(
  List<YsCourse> courses,
  int week, {
  DateTime? termStart,
  List<YsDayOverride> overrides = const [],
}) {
  final overrideByWeekday = <int, YsDayOverride>{};
  if (termStart != null) {
    for (var weekday = 1; weekday <= 7; weekday++) {
      final key = formatDateKey(dateFor(termStart, week, weekday));
      for (final override in overrides) {
        if (override.date == key) {
          overrideByWeekday[weekday] = override;
        }
      }
    }
  }

  final result = <YsDisplayCourse>[];
  for (final course in courses) {
    if (overrideByWeekday.containsKey(course.weekday)) {
      continue;
    }
    result.add(YsDisplayCourse(
      course: course,
      displayId: course.id,
      weekday: course.weekday,
      active: isCourseActive(course, week),
    ));
  }

  for (final entry in overrideByWeekday.entries) {
    final override = entry.value;
    if (override.kind != YsDayOverrideKind.makeup ||
        override.sourceWeekday == null) {
      continue;
    }
    for (final course in courses) {
      if (course.weekday != override.sourceWeekday ||
          !isCourseActive(course, week)) {
        continue;
      }
      result.add(YsDisplayCourse(
        course: course,
        displayId: '${course.id}@makeup-${override.date}',
        weekday: entry.key,
        active: true,
        makeupDate: override.date,
        makeupName: override.name,
      ));
    }
  }

  return result;
}

bool _overlaps(YsDisplayCourse a, YsDisplayCourse b) {
  return a.weekday == b.weekday &&
      a.course.startSection <= b.course.endSection &&
      b.course.startSection <= a.course.endSection;
}

/// 连通分量式重叠分组。
List<YsOverlapGroup> buildOverlapGroups(List<YsDisplayCourse> courses) {
  final groups = <YsOverlapGroup>[];
  final visited = <String>{};
  for (final course in courses) {
    if (visited.contains(course.displayId)) {
      continue;
    }
    final group = <YsDisplayCourse>[];
    final queue = [course];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current.displayId)) {
        continue;
      }
      group.add(current);
      for (final candidate in courses) {
        if (!visited.contains(candidate.displayId) &&
            _overlaps(current, candidate)) {
          queue.add(candidate);
        }
      }
    }
    if (group.length > 1) {
      var startSection = group.first.course.startSection;
      var endSection = group.first.course.endSection;
      for (final member in group) {
        if (member.course.startSection < startSection) {
          startSection = member.course.startSection;
        }
        if (member.course.endSection > endSection) {
          endSection = member.course.endSection;
        }
      }
      groups.add(YsOverlapGroup(
        id: '${course.weekday}-$startSection-$endSection',
        weekday: course.weekday,
        startSection: startSection,
        endSection: endSection,
        courses: group,
      ));
    }
  }
  return groups;
}

/// 组装某周完整模型：非本周在前、本周在后（保证本周卡渲染在上层）。
YsWeekModel buildWeekModel(
  List<YsCourse> courses,
  int week, {
  DateTime? termStart,
  List<YsDayOverride> overrides = const [],
}) {
  final displayCourses = buildDisplayCourses(
    courses,
    week,
    termStart: termStart,
    overrides: overrides,
  )..sort((a, b) => (a.active ? 1 : 0).compareTo(b.active ? 1 : 0));
  return YsWeekModel(
    week: week,
    courses: displayCourses,
    overlapGroups: buildOverlapGroups(displayCourses),
  );
}

const standardCourseTimes = <YsCourseTime>[
  YsCourseTime('08:00', '08:45'),
  YsCourseTime('08:55', '09:40'),
  YsCourseTime('10:00', '10:45'),
  YsCourseTime('10:55', '11:40'),
  YsCourseTime('14:30', '15:15'),
  YsCourseTime('15:25', '16:10'),
  YsCourseTime('16:20', '17:05'),
  YsCourseTime('17:15', '18:00'),
  YsCourseTime('18:10', '18:55'),
  YsCourseTime('19:30', '20:15'),
  YsCourseTime('20:25', '21:10'),
  YsCourseTime('21:20', '22:05'),
];
