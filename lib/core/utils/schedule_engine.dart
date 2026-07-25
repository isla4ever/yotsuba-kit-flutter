import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';

class ScheduleEngine {
  const ScheduleEngine._();

  static int currentWeek(DateTime termStart, DateTime date, int totalWeeks) {
    final normalizedStart = DateTime(
      termStart.year,
      termStart.month,
      termStart.day,
    );
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final week = normalizedDate.difference(normalizedStart).inDays ~/ 7 + 1;
    return week.clamp(1, totalWeeks);
  }

  static DateTime weekStart(DateTime termStart, int week) {
    return DateTime(
      termStart.year,
      termStart.month,
      termStart.day,
    ).add(Duration(days: (week - 1) * 7));
  }

  static DateTime dateForWeekday(DateTime termStart, int week, int weekday) {
    return weekStart(termStart, week).add(Duration(days: weekday - 1));
  }

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static List<Course> coursesForWeek(List<Course> courses, int week) {
    return courses.where((course) => course.occursInWeek(week)).toList()
      ..sort((a, b) {
        final day = a.weekday.compareTo(b.weekday);
        return day != 0 ? day : a.startSection.compareTo(b.startSection);
      });
  }

  static int minutesOf(String value) {
    final parts = value.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }
}
