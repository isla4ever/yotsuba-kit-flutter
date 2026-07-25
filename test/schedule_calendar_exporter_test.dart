import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/data/calendar/schedule_calendar_entry.dart';
import 'package:yotsuba_schedule/data/calendar/schedule_calendar_exporter.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';

void main() {
  test('calendar entries obey week patterns, holidays, and makeup days', () {
    final data = ScheduleData(
      termStart: DateTime(2026, 7, 20),
      totalWeeks: 2,
      courses: const [
        Course(
          id: 'monday-odd',
          name: '单周周一课',
          teacher: '教师',
          room: 'A101',
          weekday: 1,
          startSection: 5,
          endSection: 6,
          startWeek: 1,
          endWeek: 2,
          pattern: WeekPattern.odd,
          colorValue: 0xFF2C8B7F,
          materials: ['教材'],
        ),
      ],
      dayTasks: const [],
      coursePlans: const [],
      dayOverrides: const [
        AcademicDayOverride(
          dateKey: '2026-07-20',
          kind: AcademicDayKind.holiday,
          name: '放假',
        ),
        AcademicDayOverride(
          dateKey: '2026-07-21',
          kind: AcademicDayKind.makeUp,
          name: '补周一课',
          sourceWeekday: 1,
        ),
      ],
    );

    final entries = ScheduleCalendarBuilder.build(data, summerCourseTimes);

    expect(entries, hasLength(1));
    expect(entries.single.title, '单周周一课');
    expect(entries.single.start, DateTime(2026, 7, 21, 15));
    expect(entries.single.end, DateTime(2026, 7, 21, 16, 40));
    expect(entries.single.description, contains('补周一课'));
    expect(entries.single.description, contains('携带：教材'));
  });

  test('course plan creates separate work and deadline events', () {
    final data = ScheduleData(
      termStart: DateTime(2026, 7, 20),
      totalWeeks: 1,
      courses: const [
        Course(
          id: 'design',
          name: '设计基础',
          teacher: '',
          room: '',
          weekday: 1,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 1,
          colorValue: 0xFF2C8B7F,
        ),
      ],
      dayTasks: const [],
      coursePlans: [
        CoursePlan(
          id: 'plan-1',
          courseId: 'design',
          title: '完成作业',
          notes: '上传 PDF',
          estimatedMinutes: 60,
          scheduledStart: DateTime(2026, 7, 21, 19),
          scheduledEnd: DateTime(2026, 7, 21, 20),
          dueAt: DateTime(2026, 7, 22, 18),
          reminderOffsets: const [60, 1440, 60],
        ),
      ],
    );

    final entries = ScheduleCalendarBuilder.build(data, standardCourseTimes);
    final plan = entries.singleWhere(
      (entry) => entry.kind == ScheduleCalendarEntryKind.plan,
    );
    final deadline = entries.singleWhere(
      (entry) => entry.kind == ScheduleCalendarEntryKind.deadline,
    );

    expect(plan.title, '计划：完成作业');
    expect(deadline.title, '截止：完成作业');
    expect(deadline.start, DateTime(2026, 7, 22, 18));
    expect(deadline.reminders, const [Duration(days: 1), Duration(hours: 1)]);
  });

  test('ICS export includes alarms and escapes content', () {
    final value = IcsCalendarSerializer.serialize([
      ScheduleCalendarEntry(
        id: 'deadline:1',
        kind: ScheduleCalendarEntryKind.deadline,
        title: '截止：作业, A',
        start: DateTime(2026, 7, 22, 18),
        end: DateTime(2026, 7, 22, 18, 15),
        description: '说明;\n第二行',
        reminders: const [Duration(hours: 1)],
      ),
    ]);

    expect(value, contains('SUMMARY:截止：作业\\, A'));
    expect(value, contains('DESCRIPTION:说明\\;\\n第二行'));
    expect(value, contains('TRIGGER:-PT60M'));
  });
}
