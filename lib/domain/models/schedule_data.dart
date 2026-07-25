import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';

class ScheduleData {
  const ScheduleData({
    required this.termStart,
    required this.totalWeeks,
    required this.courses,
    required this.dayTasks,
    required this.coursePlans,
    this.dayOverrides = const [],
  });

  final DateTime termStart;
  final int totalWeeks;
  final List<Course> courses;
  final List<DayTask> dayTasks;
  final List<CoursePlan> coursePlans;
  final List<AcademicDayOverride> dayOverrides;

  Map<String, Object> toJson() => {
    'termStart': termStart.toIso8601String(),
    'totalWeeks': totalWeeks,
    'courses': courses.map((item) => item.toJson()).toList(),
    'dayTasks': dayTasks.map((item) => item.toJson()).toList(),
    'coursePlans': coursePlans.map((item) => item.toJson()).toList(),
    'dayOverrides': dayOverrides.map((item) => item.toJson()).toList(),
  };

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      termStart: DateTime.parse(json['termStart'] as String),
      totalWeeks: json['totalWeeks'] as int,
      courses: (json['courses'] as List<dynamic>)
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList(),
      dayTasks: (json['dayTasks'] as List<dynamic>)
          .map((item) => DayTask.fromJson(item as Map<String, dynamic>))
          .toList(),
      coursePlans: (json['coursePlans'] as List<dynamic>)
          .map((item) => CoursePlan.fromJson(item as Map<String, dynamic>))
          .toList(),
      dayOverrides: (json['dayOverrides'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AcademicDayOverride.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
