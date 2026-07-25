import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';

class WeekTimetable extends StatefulWidget {
  const WeekTimetable({
    required this.termStart,
    required this.week,
    required this.courses,
    required this.visibleDays,
    required this.compact,
    required this.editing,
    required this.active,
    required this.reduceMotion,
    required this.onCourseTap,
    required this.onEmptyCellTap,
    required this.onDayTap,
    super.key,
  });

  final DateTime termStart;
  final int week;
  final List<Course> courses;
  final int visibleDays;
  final bool compact;
  final bool editing;
  final bool active;
  final bool reduceMotion;
  final ValueChanged<Course> onCourseTap;
  final void Function(int weekday, int section) onEmptyCellTap;
  final ValueChanged<int> onDayTap;

  static const railWidth = 48.0;
  static const headerHeight = 58.0;
  static const breakHeight = 34.0;
  static const topInset = 6.0;

  @override
  State<WeekTimetable> createState() => _WeekTimetableState();
}

class _WeekTimetableState extends State<WeekTimetable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _courseWave;

  @override
  void initState() {
    super.initState();
    _courseWave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: widget.active && !widget.reduceMotion ? 0.18 : 1,
    );
    if (widget.active && !widget.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _courseWave.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant WeekTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _courseWave.value = 1;
      return;
    }
    if (widget.active && (!oldWidget.active || oldWidget.week != widget.week)) {
      _courseWave.forward(from: 0.18);
    } else if (!widget.active && oldWidget.active) {
      _courseWave.value = 1;
    }
  }

  @override
  void dispose() {
    _courseWave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = widget.compact ? 54.0 : 62.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth =
            (constraints.maxWidth - WeekTimetable.railWidth) /
            widget.visibleDays;
        return Column(
          children: [
            _WeekHeader(
              termStart: widget.termStart,
              week: widget.week,
              dayWidth: dayWidth,
              visibleDays: widget.visibleDays,
              editing: widget.editing,
              onDayTap: widget.onDayTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height:
                      WeekTimetable.topInset +
                      rowHeight * courseTimes.length +
                      WeekTimetable.breakHeight,
                  child: _GridBody(
                    week: widget.week,
                    courses: widget.courses,
                    rowHeight: rowHeight,
                    dayWidth: dayWidth,
                    visibleDays: widget.visibleDays,
                    editing: widget.editing,
                    courseWave: _courseWave,
                    onCourseTap: widget.onCourseTap,
                    onEmptyCellTap: widget.onEmptyCellTap,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.termStart,
    required this.week,
    required this.dayWidth,
    required this.visibleDays,
    required this.editing,
    required this.onDayTap,
  });

  final DateTime termStart;
  final int week;
  final double dayWidth;
  final int visibleDays;
  final bool editing;
  final ValueChanged<int> onDayTap;

  static const labels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: WeekTimetable.headerHeight,
      decoration: BoxDecoration(
        color: editing ? palette.surface : palette.canvas,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: WeekTimetable.railWidth,
            alignment: Alignment.center,
            decoration: editing
                ? BoxDecoration(
                    border: Border(right: BorderSide(color: palette.border)),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '星期',
                  style: TextStyle(fontSize: 11, color: palette.textSoft),
                ),
                Text(
                  '日期',
                  style: TextStyle(fontSize: 10, color: palette.textFaint),
                ),
              ],
            ),
          ),
          for (var day = 1; day <= visibleDays; day++)
            _DayHeader(
              width: dayWidth,
              label: labels[day - 1],
              date: ScheduleEngine.dateForWeekday(termStart, week, day),
              editing: editing,
              isLast: day == visibleDays,
              onTap: () => onDayTap(day),
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.width,
    required this.label,
    required this.date,
    required this.editing,
    required this.isLast,
    required this.onTap,
  });

  final double width;
  final String label;
  final DateTime date;
  final bool editing;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isToday = DateUtils.isSameDay(DateTime.now(), date);
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isToday ? palette.scheduleAccentSoft : Colors.transparent,
            border: editing && !isLast
                ? Border(
                    right: BorderSide(
                      color: palette.border.withValues(alpha: 0.55),
                    ),
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? palette.scheduleAccent
                          : palette.textSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(fontSize: 9, color: palette.textFaint),
                  ),
                ],
              ),
              if (isToday)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.scheduleAccent,
                      shape: BoxShape.circle,
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

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.week,
    required this.courses,
    required this.rowHeight,
    required this.dayWidth,
    required this.visibleDays,
    required this.editing,
    required this.courseWave,
    required this.onCourseTap,
    required this.onEmptyCellTap,
  });

  final int week;
  final List<Course> courses;
  final double rowHeight;
  final double dayWidth;
  final int visibleDays;
  final bool editing;
  final Animation<double> courseWave;
  final ValueChanged<Course> onCourseTap;
  final void Function(int weekday, int section) onEmptyCellTap;

  double _sectionTop(int section) {
    return WeekTimetable.topInset +
        (section - 1) * rowHeight +
        (section > 4 ? WeekTimetable.breakHeight : 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visibleCourses = courses
        .where((course) => course.weekday <= visibleDays)
        .toList();
    final groups = _groupCourses(visibleCourses);

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: editing
              ? LinearGradient(colors: [palette.surface, palette.surface])
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.42],
                  colors: [
                    Color.lerp(
                      palette.surfaceRaised,
                      palette.scheduleAccentSoft,
                      0.09,
                    )!,
                    palette.canvas,
                  ],
                ),
        ),
        child: Stack(
          children: [
            for (var section = 1; section <= courseTimes.length; section++)
              Positioned(
                top: _sectionTop(section),
                left: 0,
                width: WeekTimetable.railWidth,
                height: rowHeight,
                child: _TimeRow(
                  section: section,
                  editing: editing,
                  bottomBorder: editing,
                ),
              ),
            Positioned(
              top: _sectionTop(5) - WeekTimetable.breakHeight,
              left: 0,
              width: WeekTimetable.railWidth,
              height: WeekTimetable.breakHeight,
              child: Container(
                alignment: Alignment.center,
                decoration: editing
                    ? BoxDecoration(
                        color: palette.surfaceRaised,
                        border: Border(
                          right: BorderSide(color: palette.border),
                          bottom: BorderSide(
                            color: palette.border.withValues(alpha: 0.55),
                          ),
                        ),
                      )
                    : null,
                child: Text(
                  '午休',
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
              ),
            ),
            if (editing) ...[
              for (var day = 0; day <= visibleDays; day++)
                Positioned(
                  top: WeekTimetable.topInset,
                  bottom: 0,
                  left: WeekTimetable.railWidth + day * dayWidth,
                  child: Container(
                    width: 1,
                    color: palette.border.withValues(alpha: 0.48),
                  ),
                ),
              for (var section = 1; section <= courseTimes.length; section++)
                Positioned(
                  top: _sectionTop(section) + rowHeight - 1,
                  left: WeekTimetable.railWidth,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: palette.border.withValues(alpha: 0.48),
                  ),
                ),
              Positioned(
                top: _sectionTop(5) - WeekTimetable.breakHeight,
                left: WeekTimetable.railWidth,
                right: 0,
                height: WeekTimetable.breakHeight,
                child: ColoredBox(color: palette.surfaceRaised),
              ),
              for (var day = 1; day <= visibleDays; day++)
                for (var section = 1; section <= courseTimes.length; section++)
                  Positioned(
                    top: _sectionTop(section),
                    left: WeekTimetable.railWidth + (day - 1) * dayWidth,
                    width: dayWidth,
                    height: rowHeight,
                    child: Semantics(
                      button: true,
                      label: '周$day第$section节空白时间',
                      child: InkWell(onTap: () => onEmptyCellTap(day, section)),
                    ),
                  ),
            ],
            for (final group in groups) _positionedCourse(context, group),
          ],
        ),
      ),
    );
  }

  Widget _positionedCourse(BuildContext context, List<Course> group) {
    final active = group.where((course) => course.occursInWeek(week));
    final course = active.isNotEmpty ? active.first : group.first;
    final top = _sectionTop(course.startSection);
    final span = course.endSection - course.startSection + 1;
    final includesBreak = course.startSection <= 4 && course.endSection > 4;
    final height =
        span * rowHeight + (includesBreak ? WeekTimetable.breakHeight : 0);
    return Positioned(
      top: top,
      left: WeekTimetable.railWidth + (course.weekday - 1) * dayWidth,
      width: dayWidth,
      height: height,
      child: _WaveCourseReveal(
        animation: courseWave,
        delay: math.min(
          0.19,
          (course.weekday - 1) * 0.021 + (course.startSection - 1) * 0.008,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _CourseCard(
                course: course,
                active: course.occursInWeek(week),
                onTap: () => onCourseTap(course),
              ),
            ),
            if (group.length > 1)
              Positioned(
                top: 0,
                right: 0,
                child: _OverlapBadge(count: group.length),
              ),
          ],
        ),
      ),
    );
  }

  List<List<Course>> _groupCourses(List<Course> source) {
    final map = <String, List<Course>>{};
    for (final course in source) {
      final key =
          '${course.weekday}-${course.startSection}-${course.endSection}';
      map.putIfAbsent(key, () => []).add(course);
    }
    final groups = map.values.toList();
    for (final group in groups) {
      group.sort((a, b) {
        final activeCompare = a.occursInWeek(week) == b.occursInWeek(week)
            ? 0
            : a.occursInWeek(week)
            ? -1
            : 1;
        return activeCompare != 0 ? activeCompare : a.id.compareTo(b.id);
      });
    }
    groups.sort((a, b) {
      final day = a.first.weekday.compareTo(b.first.weekday);
      return day != 0
          ? day
          : a.first.startSection.compareTo(b.first.startSection);
    });
    return groups;
  }
}

class _WaveCourseReveal extends StatelessWidget {
  const _WaveCourseReveal({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final Animation<double> animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final normalized = ((animation.value - delay) / (1 - delay)).clamp(
          0.0,
          1.0,
        );
        final value = Curves.easeOutCubic.transform(normalized);
        return Opacity(
          opacity: 0.72 + value * 0.28,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.section,
    required this.editing,
    required this.bottomBorder,
  });

  final int section;
  final bool editing;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final time = courseTimes[section - 1];
    return Container(
      decoration: editing
          ? BoxDecoration(
              border: Border(
                right: BorderSide(color: palette.border),
                bottom: BorderSide(
                  color: palette.border.withValues(alpha: 0.55),
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$section',
            style: TextStyle(
              height: 1,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${time.start}\n${time.end}',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.2,
              fontSize: 8,
              color: palette.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
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
    final span = math.max(1, course.endSection - course.startSection + 1);
    final cardColor = active ? Color(course.colorValue) : palette.surfaceRaised;
    final foreground = active ? Colors.white : palette.textSoft;
    final status = active ? '' : '非本周';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: active
                ? cardColor.withValues(alpha: 0.72)
                : palette.borderStrong,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 5, 5, span == 1 ? 15 : 18),
            child: Stack(
              children: [
                if (status.isNotEmpty)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 14,
                      constraints: const BoxConstraints(minWidth: 34),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: status.isEmpty ? 0 : 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.name,
                        maxLines: span == 1 ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: span == 1 ? 1.15 : 1.22,
                          fontSize: span == 1 ? 10 : 12,
                          fontWeight: FontWeight.w800,
                          color: foreground,
                        ),
                      ),
                      if (span > 1 && course.room.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '@${course.room}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.15,
                            fontSize: 9,
                            color: foreground.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    '(${course.startWeek}-${course.endWeek}周)',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: span == 1 ? 7 : 8,
                      color: foreground.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlapBadge extends StatelessWidget {
  const _OverlapBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFFF3F5F7) : const Color(0xFF1C232D),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.36 : 0.82),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: TextStyle(
          height: 1,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: dark ? const Color(0xFF17191D) : Colors.white,
        ),
      ),
    );
  }
}
