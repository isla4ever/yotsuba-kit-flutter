/// 单双周规则。
enum YsWeekParity { every, odd, even }

/// 组件库标准课程模型。
class YsCourse {
  const YsCourse({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.startWeek,
    required this.endWeek,
    this.parity = YsWeekParity.every,
    this.teacher,
    this.location,
    this.color,
    this.custom = false,
  });

  /// 稳定唯一 id。
  final String id;
  final String name;
  final String? teacher;
  final String? location;

  /// 1-7，周一为 1。
  final int weekday;
  final int startSection;
  final int endSection;
  final int startWeek;
  final int endWeek;
  final YsWeekParity parity;

  /// ARGB 颜色值；空则由主题调色板按课程名稳定分配。
  final int? color;
  final bool custom;

  YsCourse copyWith({int? weekday}) {
    return YsCourse(
      id: id,
      name: name,
      teacher: teacher,
      location: location,
      weekday: weekday ?? this.weekday,
      startSection: startSection,
      endSection: endSection,
      startWeek: startWeek,
      endWeek: endWeek,
      parity: parity,
      color: color,
      custom: custom,
    );
  }
}

class YsCourseTime {
  const YsCourseTime(this.start, this.end);

  final String start;
  final String end;
}

enum YsDayOverrideKind { makeup, holiday }

/// 调休 / 补班 / 假日。
class YsDayOverride {
  const YsDayOverride({
    required this.date,
    required this.kind,
    this.sourceWeekday,
    this.name,
  });

  /// YYYY-MM-DD。
  final String date;
  final YsDayOverrideKind kind;

  /// makeup：课程来自哪个星期（1-7）。
  final int? sourceWeekday;
  final String? name;
}

/// 某周展示用课程（补班复制后 weekday 为展示星期）。
class YsDisplayCourse {
  const YsDisplayCourse({
    required this.course,
    required this.displayId,
    required this.weekday,
    required this.active,
    this.makeupDate,
  });

  final YsCourse course;
  final String displayId;
  final int weekday;
  final bool active;
  final String? makeupDate;

  bool get isMakeup => makeupDate != null;
}

class YsOverlapGroup {
  const YsOverlapGroup({
    required this.id,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.courses,
  });

  final String id;
  final int weekday;
  final int startSection;
  final int endSection;
  final List<YsDisplayCourse> courses;
}

class YsWeekModel {
  const YsWeekModel({
    required this.week,
    required this.courses,
    required this.overlapGroups,
  });

  final int week;
  final List<YsDisplayCourse> courses;
  final List<YsOverlapGroup> overlapGroups;
}
