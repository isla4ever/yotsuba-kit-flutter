import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';

class ScheduleAgenda extends StatelessWidget {
  const ScheduleAgenda({
    required this.termStart,
    required this.week,
    required this.visibleDays,
    required this.courses,
    required this.dayOverrides,
    required this.onCourseTap,
    required this.onDayTap,
    super.key,
  });

  final DateTime termStart;
  final int week;
  final int visibleDays;
  final List<Course> courses;
  final List<AcademicDayOverride> dayOverrides;
  final ValueChanged<Course> onCourseTap;
  final ValueChanged<int> onDayTap;

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('schedule-agenda'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
      itemCount: visibleDays,
      itemBuilder: (context, index) => _buildDay(context, index + 1),
    );
  }

  Widget _buildDay(BuildContext context, int day) {
    final palette = context.palette;
    final date = ScheduleEngine.dateForWeekday(termStart, week, day);
    final dateKey = ScheduleEngine.dateKey(date);
    final override = dayOverrides
        .where((item) => item.dateKey == dateKey)
        .firstOrNull;
    final sourceDay = override?.kind == AcademicDayKind.makeUp
        ? override?.sourceWeekday ?? day
        : day;
    final values =
        override?.kind == AcademicDayKind.holiday
              ? const <Course>[]
              : courses.where((item) => item.weekday == sourceDay).toList()
          ..sort((a, b) => a.startSection.compareTo(b.startSection));
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onDayTap(day),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 3, 2, 8),
              child: Row(
                children: [
                  Text(
                    _weekdays[day - 1],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 10, color: palette.textFaint),
                  ),
                  if (override != null) ...[
                    const SizedBox(width: 7),
                    Text(
                      override.kind == AcademicDayKind.makeUp
                          ? '补班 · 按周$sourceDay上课'
                          : override.name,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: override.kind == AcademicDayKind.makeUp
                            ? palette.warning
                            : palette.danger,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${values.length} 门',
                    style: TextStyle(fontSize: 10, color: palette.textFaint),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: palette.border),
          if (values.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
              child: Text(
                override?.kind == AcademicDayKind.holiday ? '今日放假' : '无课程',
                style: TextStyle(fontSize: 11, color: palette.textFaint),
              ),
            )
          else
            for (final course in values)
              _AgendaCourseRow(
                course: course,
                active: course.occursInWeek(week),
                onTap: () => onCourseTap(
                  sourceDay == day ? course : course.copyWith(weekday: day),
                ),
              ),
        ],
      ),
    );
  }
}

class _AgendaCourseRow extends StatelessWidget {
  const _AgendaCourseRow({
    required this.course,
    required this.active,
    required this.onTap,
  });

  final Course course;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: '${course.name}，第${course.startSection}到${course.endSection}节',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  '${course.startSection}-${course.endSection} 节',
                  style: TextStyle(fontSize: 11, color: palette.textFaint),
                ),
              ),
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? Color(course.colorValue)
                      : palette.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? palette.text : palette.textSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        course.teacher,
                        course.room,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: palette.textFaint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? palette.scheduleAccentSoft
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  active ? '本周' : '非本周',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: active ? palette.scheduleAccent : palette.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
