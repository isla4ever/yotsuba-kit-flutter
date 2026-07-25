import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';

class WeekTimetable extends StatefulWidget {
  const WeekTimetable({
    required this.termStart,
    required this.week,
    required this.courses,
    required this.visibleDays,
    required this.rowHeight,
    required this.courseTimes,
    required this.dayOverrides,
    required this.weather,
    required this.editing,
    required this.pageController,
    required this.reduceMotion,
    required this.onCourseTap,
    required this.onEmptyCellTap,
    required this.onDayTap,
    this.dayGuideKey,
    this.courseGuideKey,
    super.key,
  });

  final DateTime termStart;
  final int week;
  final List<Course> courses;
  final int visibleDays;
  final double rowHeight;
  final List<CourseTime> courseTimes;
  final List<AcademicDayOverride> dayOverrides;
  final WeatherSnapshot? weather;
  final bool editing;
  final PageController pageController;
  final bool reduceMotion;
  final ValueChanged<Course> onCourseTap;
  final void Function(int weekday, int startSection, int endSection)
  onEmptyCellTap;
  final ValueChanged<int> onDayTap;
  final GlobalKey? dayGuideKey;
  final GlobalKey? courseGuideKey;

  static const railWidth = 48.0;
  static const headerHeight = 66.0;
  static const breakHeight = 34.0;
  static const topInset = 6.0;

  @override
  State<WeekTimetable> createState() => _WeekTimetableState();
}

class _WeekTimetableState extends State<WeekTimetable> {
  late _PageRevealAnimation _courseWave;
  int? _selectionDay;
  int? _selectionAnchor;
  int? _selectionEnd;

  @override
  void initState() {
    super.initState();
    _courseWave = _PageRevealAnimation(
      controller: widget.pageController,
      pageIndex: widget.week - 1,
      reduceMotion: widget.reduceMotion,
    );
  }

  @override
  void didUpdateWidget(covariant WeekTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController ||
        oldWidget.week != widget.week ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      _courseWave = _PageRevealAnimation(
        controller: widget.pageController,
        pageIndex: widget.week - 1,
        reduceMotion: widget.reduceMotion,
      );
    }
    if (!widget.editing && oldWidget.editing) {
      _selectionDay = null;
      _selectionAnchor = null;
      _selectionEnd = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = widget.rowHeight;
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
              dayOverrides: widget.dayOverrides,
              weather: widget.weather,
              onDayTap: widget.onDayTap,
              dayGuideKey: widget.dayGuideKey,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height:
                      WeekTimetable.topInset +
                      rowHeight * widget.courseTimes.length +
                      WeekTimetable.breakHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPressStart: widget.editing
                        ? (details) => _beginSelection(
                            details.localPosition,
                            dayWidth,
                            rowHeight,
                          )
                        : null,
                    onLongPressMoveUpdate: widget.editing
                        ? (details) => _updateSelection(
                            details.localPosition,
                            dayWidth,
                            rowHeight,
                          )
                        : null,
                    child: _GridBody(
                      week: widget.week,
                      courses: widget.courses,
                      rowHeight: rowHeight,
                      dayWidth: dayWidth,
                      visibleDays: widget.visibleDays,
                      editing: widget.editing,
                      termStart: widget.termStart,
                      dayOverrides: widget.dayOverrides,
                      courseTimes: widget.courseTimes,
                      courseWave: _courseWave,
                      selectionDay: _selectionDay,
                      selectionStart: _selectionStart,
                      selectionEnd: _selectionEnd,
                      onCourseTap: widget.onCourseTap,
                      onEmptyCellTap: widget.onEmptyCellTap,
                      onSelectionTap: _openSelection,
                      courseGuideKey: widget.courseGuideKey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int? get _selectionStart {
    if (_selectionAnchor == null || _selectionEnd == null) return null;
    return math.min(_selectionAnchor!, _selectionEnd!);
  }

  void _beginSelection(Offset position, double dayWidth, double rowHeight) {
    final cell = _cellAt(position, dayWidth, rowHeight);
    if (cell == null || _sectionOccupied(cell.$1, cell.$2)) return;
    setState(() {
      _selectionDay = cell.$1;
      _selectionAnchor = cell.$2;
      _selectionEnd = cell.$2;
    });
  }

  void _updateSelection(Offset position, double dayWidth, double rowHeight) {
    final day = _selectionDay;
    final anchor = _selectionAnchor;
    final cell = _cellAt(position, dayWidth, rowHeight);
    if (day == null || anchor == null || cell == null || cell.$1 != day) return;
    final direction = cell.$2 >= anchor ? 1 : -1;
    var candidate = anchor;
    for (
      var section = anchor;
      section != cell.$2 + direction;
      section += direction
    ) {
      if (_sectionOccupied(day, section)) break;
      candidate = section;
    }
    if (candidate != _selectionEnd) {
      setState(() => _selectionEnd = candidate);
    }
  }

  (int, int)? _cellAt(Offset position, double dayWidth, double rowHeight) {
    if (position.dx < WeekTimetable.railWidth || position.dy < 0) return null;
    final day =
        ((position.dx - WeekTimetable.railWidth) / dayWidth).floor() + 1;
    if (day < 1 || day > widget.visibleDays) return null;
    var bodyY = position.dy - WeekTimetable.topInset;
    if (bodyY < 0) return null;
    final breakTop = rowHeight * 4;
    if (bodyY >= breakTop && bodyY < breakTop + WeekTimetable.breakHeight) {
      return null;
    }
    if (bodyY >= breakTop + WeekTimetable.breakHeight) {
      bodyY -= WeekTimetable.breakHeight;
    }
    final section = (bodyY / rowHeight).floor() + 1;
    if (section < 1 || section > widget.courseTimes.length) return null;
    return (day, section);
  }

  bool _sectionOccupied(int day, int section) {
    final date = ScheduleEngine.dateForWeekday(
      widget.termStart,
      widget.week,
      day,
    );
    final dayOverride = widget.dayOverrides
        .where((item) => item.dateKey == ScheduleEngine.dateKey(date))
        .firstOrNull;
    if (dayOverride?.kind == AcademicDayKind.holiday) return false;
    final sourceWeekday = dayOverride?.kind == AcademicDayKind.makeUp
        ? dayOverride?.sourceWeekday ?? day
        : day;
    return widget.courses.any(
      (course) =>
          course.weekday == sourceWeekday &&
          course.occursInWeek(widget.week) &&
          section >= course.startSection &&
          section <= course.endSection,
    );
  }

  void _openSelection() {
    final day = _selectionDay;
    final start = _selectionStart;
    final end = _selectionEnd;
    if (day == null || start == null || end == null) return;
    widget.onEmptyCellTap(day, start, end);
    _clearSelection();
  }

  void _clearSelection() {
    if (_selectionDay == null) return;
    setState(() {
      _selectionDay = null;
      _selectionAnchor = null;
      _selectionEnd = null;
    });
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.termStart,
    required this.week,
    required this.dayWidth,
    required this.visibleDays,
    required this.editing,
    required this.dayOverrides,
    required this.weather,
    required this.onDayTap,
    this.dayGuideKey,
  });

  final DateTime termStart;
  final int week;
  final double dayWidth;
  final int visibleDays;
  final bool editing;
  final List<AcademicDayOverride> dayOverrides;
  final WeatherSnapshot? weather;
  final ValueChanged<int> onDayTap;
  final GlobalKey? dayGuideKey;

  static const labels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: WeekTimetable.headerHeight,
      decoration: BoxDecoration(
        color: editing ? palette.surface : Colors.transparent,
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
            Builder(
              builder: (context) {
                final date = ScheduleEngine.dateForWeekday(
                  termStart,
                  week,
                  day,
                );
                return _DayHeader(
                  key: day == 1 ? dayGuideKey : null,
                  width: dayWidth,
                  label: labels[day - 1],
                  date: date,
                  dayOverride: dayOverrides
                      .where(
                        (item) => item.dateKey == ScheduleEngine.dateKey(date),
                      )
                      .firstOrNull,
                  weather: weather?.weatherForDate(
                    ScheduleEngine.dateKey(date),
                  ),
                  editing: editing,
                  isLast: day == visibleDays,
                  onTap: () => onDayTap(day),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    super.key,
    required this.width,
    required this.label,
    required this.date,
    required this.dayOverride,
    required this.weather,
    required this.editing,
    required this.isLast,
    required this.onTap,
  });

  final double width;
  final String label;
  final DateTime date;
  final AcademicDayOverride? dayOverride;
  final DailyWeather? weather;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isToday
                              ? palette.scheduleAccent
                              : palette.textSoft,
                        ),
                      ),
                      if (weather != null) ...[
                        const SizedBox(width: 2),
                        WeatherGlyph(
                          kind: weatherPresentation(weather!.weatherCode).kind,
                          size: 13,
                          animate: false,
                          color: palette.textFaint,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(fontSize: 9, color: palette.textFaint),
                  ),
                  if (dayOverride != null)
                    Text(
                      dayOverride!.kind == AcademicDayKind.makeUp
                          ? '补班'
                          : dayOverride!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: dayOverride!.kind == AcademicDayKind.makeUp
                            ? palette.warning
                            : palette.danger,
                      ),
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
    required this.termStart,
    required this.courses,
    required this.dayOverrides,
    required this.courseTimes,
    required this.rowHeight,
    required this.dayWidth,
    required this.visibleDays,
    required this.editing,
    required this.courseWave,
    required this.selectionDay,
    required this.selectionStart,
    required this.selectionEnd,
    required this.onCourseTap,
    required this.onEmptyCellTap,
    required this.onSelectionTap,
    this.courseGuideKey,
  });

  final int week;
  final DateTime termStart;
  final List<Course> courses;
  final List<AcademicDayOverride> dayOverrides;
  final List<CourseTime> courseTimes;
  final double rowHeight;
  final double dayWidth;
  final int visibleDays;
  final bool editing;
  final Animation<double> courseWave;
  final int? selectionDay;
  final int? selectionStart;
  final int? selectionEnd;
  final ValueChanged<Course> onCourseTap;
  final void Function(int weekday, int startSection, int endSection)
  onEmptyCellTap;
  final VoidCallback onSelectionTap;
  final GlobalKey? courseGuideKey;

  double _sectionTop(int section) {
    return WeekTimetable.topInset +
        (section - 1) * rowHeight +
        (section > 4 ? WeekTimetable.breakHeight : 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visibleCourses = _displayCourses();
    final groups = _groupCourses(visibleCourses);

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: editing
              ? LinearGradient(colors: [palette.surface, palette.surface])
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
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
                  time: courseTimes[section - 1],
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
                      child: InkWell(
                        onTap: () => onEmptyCellTap(day, section, section),
                      ),
                    ),
                  ),
            ],
            if (editing &&
                selectionDay != null &&
                selectionStart != null &&
                selectionEnd != null)
              Positioned(
                top: _sectionTop(selectionStart!),
                left: WeekTimetable.railWidth + (selectionDay! - 1) * dayWidth,
                width: dayWidth,
                height:
                    (selectionEnd! - selectionStart! + 1) * rowHeight +
                    (selectionStart! <= 4 && selectionEnd! > 4
                        ? WeekTimetable.breakHeight
                        : 0),
                child: _SelectionHighlight(
                  startSection: selectionStart!,
                  endSection: selectionEnd!,
                  onTap: onSelectionTap,
                ),
              ),
            for (var index = 0; index < groups.length; index++)
              _positionedCourse(
                context,
                groups[index],
                key: index == 0 ? courseGuideKey : null,
              ),
          ],
        ),
      ),
    );
  }

  List<Course> _displayCourses() {
    final result = <Course>[];
    for (var day = 1; day <= visibleDays; day++) {
      final date = ScheduleEngine.dateForWeekday(termStart, week, day);
      final override = dayOverrides
          .where((item) => item.dateKey == ScheduleEngine.dateKey(date))
          .firstOrNull;
      if (override?.kind == AcademicDayKind.holiday) continue;
      final sourceWeekday = override?.kind == AcademicDayKind.makeUp
          ? override?.sourceWeekday ?? day
          : day;
      result.addAll(
        courses
            .where((course) => course.weekday == sourceWeekday)
            .map((course) => course.copyWith(weekday: day)),
      );
    }
    return result;
  }

  Widget _positionedCourse(
    BuildContext context,
    List<Course> group, {
    Key? key,
  }) {
    final active = group.where((course) => course.occursInWeek(week));
    final course = active.isNotEmpty ? active.first : group.first;
    final top = _sectionTop(course.startSection);
    final span = course.endSection - course.startSection + 1;
    final includesBreak = course.startSection <= 4 && course.endSection > 4;
    final height =
        span * rowHeight + (includesBreak ? WeekTimetable.breakHeight : 0);
    return Positioned(
      key: key,
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

class _SelectionHighlight extends StatelessWidget {
  const _SelectionHighlight({
    required this.startSection,
    required this.endSection,
    required this.onTap,
  });

  final int startSection;
  final int endSection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = startSection == endSection
        ? '第 $startSection 节'
        : '第 $startSection-$endSection 节';
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: palette.scheduleAccentSoft.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: palette.scheduleAccent, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_rounded,
                  size: 20,
                  color: palette.scheduleAccent,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: palette.scheduleAccent,
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
        final value = Curves.easeInOutCubic.transform(normalized);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 6),
            child: Transform.scale(
              scale: 0.996 + value * 0.004,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _PageRevealAnimation extends Animation<double> {
  _PageRevealAnimation({
    required this.controller,
    required this.pageIndex,
    required this.reduceMotion,
  });

  final PageController controller;
  final int pageIndex;
  final bool reduceMotion;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}

  @override
  AnimationStatus get status => value >= 1
      ? AnimationStatus.completed
      : value <= 0
      ? AnimationStatus.dismissed
      : AnimationStatus.forward;

  @override
  double get value {
    if (reduceMotion) return 1;
    final page = controller.hasClients
        ? controller.page ?? controller.initialPage.toDouble()
        : controller.initialPage.toDouble();
    final proximity = (1 - (page - pageIndex).abs()).clamp(0.0, 1.0);
    return ((proximity - 0.04) / 0.84).clamp(0.0, 1.0);
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.section,
    required this.time,
    required this.editing,
    required this.bottomBorder,
  });

  final int section;
  final CourseTime time;
  final bool editing;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
