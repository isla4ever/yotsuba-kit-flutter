import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/data/calendar/schedule_calendar_entry.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';

class ScheduleCalendarBuilder {
  const ScheduleCalendarBuilder._();

  static List<ScheduleCalendarEntry> build(
    ScheduleData data,
    List<CourseTime> times,
  ) {
    final entries = <ScheduleCalendarEntry>[];
    final overrides = {
      for (final item in data.dayOverrides) item.dateKey: item,
    };

    for (var week = 1; week <= data.totalWeeks; week++) {
      for (var day = 1; day <= 7; day++) {
        final date = ScheduleEngine.dateForWeekday(data.termStart, week, day);
        final dateKey = ScheduleEngine.dateKey(date);
        final dayOverride = overrides[dateKey];
        if (dayOverride?.kind == AcademicDayKind.holiday) continue;

        final sourceWeekday = dayOverride?.kind == AcademicDayKind.makeUp
            ? dayOverride?.sourceWeekday ?? day
            : day;
        for (final course in data.courses) {
          if (course.weekday != sourceWeekday ||
              !course.occursInWeek(week) ||
              !_hasValidSections(course, times)) {
            continue;
          }
          final start = _atTime(date, times[course.startSection - 1].start);
          final end = _atTime(date, times[course.endSection - 1].end);
          final details = <String>[
            if (course.teacher.trim().isNotEmpty) course.teacher.trim(),
            '第${course.startSection}-${course.endSection}节',
            if (course.materials.isNotEmpty) '携带：${course.materials.join('、')}',
            if (dayOverride?.kind == AcademicDayKind.makeUp)
              dayOverride?.name.trim().isNotEmpty == true
                  ? dayOverride!.name.trim()
                  : '补班调课',
          ];
          entries.add(
            ScheduleCalendarEntry(
              id: 'course:${course.id}:$dateKey',
              kind: ScheduleCalendarEntryKind.course,
              title: course.name,
              start: start,
              end: end,
              description: details.join(' · '),
              location: course.room.trim(),
              reminders: const [Duration(minutes: 15)],
            ),
          );
        }
      }
    }

    for (final plan in data.coursePlans.where(
      (item) => item.calendarSyncEnabled,
    )) {
      final courseName = data.courses
          .where((course) => course.id == plan.courseId)
          .map((course) => course.name)
          .firstOrNull;
      final description = <String>[
        courseName ?? '课程计划',
        if (plan.notes.trim().isNotEmpty) plan.notes.trim(),
      ].join(' · ');

      final scheduledStart = plan.scheduledStart;
      final scheduledEnd = plan.scheduledEnd;
      if (scheduledStart != null &&
          scheduledEnd != null &&
          scheduledEnd.isAfter(scheduledStart)) {
        entries.add(
          ScheduleCalendarEntry(
            id: 'plan:${plan.id}',
            kind: ScheduleCalendarEntryKind.plan,
            title: '计划：${plan.title}',
            start: scheduledStart,
            end: scheduledEnd,
            description: description,
          ),
        );
      }

      final dueAt = plan.dueAt;
      if (dueAt != null) {
        entries.add(
          ScheduleCalendarEntry(
            id: 'deadline:${plan.id}',
            kind: ScheduleCalendarEntryKind.deadline,
            title: '截止：${plan.title}',
            start: dueAt,
            end: dueAt.add(const Duration(minutes: 15)),
            description: description,
            reminders:
                plan.reminderOffsets
                    .where((minutes) => minutes >= 0)
                    .toSet()
                    .map((minutes) => Duration(minutes: minutes))
                    .toList()
                  ..sort((a, b) => b.compareTo(a)),
          ),
        );
      }
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  static bool _hasValidSections(Course course, List<CourseTime> times) {
    return course.startSection >= 1 &&
        course.endSection >= course.startSection &&
        course.endSection <= times.length;
  }

  static DateTime _atTime(DateTime date, String value) {
    final parts = value.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, parts[0], parts[1]);
  }
}

class IcsCalendarSerializer {
  const IcsCalendarSerializer._();

  static String serialize(List<ScheduleCalendarEntry> entries) {
    final timestamp = _icalDate(DateTime.now());
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('PRODID:-//Yotsuba Schedule//CN');

    for (final entry in entries) {
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${_escapeIcal(entry.id)}@yotsuba-schedule')
        ..writeln('DTSTAMP:$timestamp')
        ..writeln('DTSTART:${_icalDate(entry.start)}')
        ..writeln('DTEND:${_icalDate(entry.end)}')
        ..writeln('SUMMARY:${_escapeIcal(entry.title)}');
      if (entry.location.isNotEmpty) {
        buffer.writeln('LOCATION:${_escapeIcal(entry.location)}');
      }
      if (entry.description.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escapeIcal(entry.description)}');
      }
      for (final reminder in entry.reminders) {
        buffer
          ..writeln('BEGIN:VALARM')
          ..writeln('ACTION:DISPLAY')
          ..writeln('DESCRIPTION:${_escapeIcal(entry.title)}')
          ..writeln('TRIGGER:-PT${reminder.inMinutes}M')
          ..writeln('END:VALARM');
      }
      buffer.writeln('END:VEVENT');
    }
    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _icalDate(DateTime value) =>
      "${DateFormat("yyyyMMdd'T'HHmmss").format(value.toUtc())}Z";

  static String _escapeIcal(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');
}
