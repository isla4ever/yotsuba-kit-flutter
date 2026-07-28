import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

/// 波浪覆盖换周：骨架（表头、时间轴、格线）常驻不动，旧周课程留在下层，
/// 新周课程按“列为主、节次为辅”的对角线次序覆盖上来，任何一帧都不出现空网格。
/// 换周前后视觉不变的格子完全静止，不参与动画；旧卡晚于新卡起淡出，两层始终交叠。
class _Wave {
  static const colStepMs = 30;
  static const rowStepMs = 7;
  static const maxDelayMs = 210;
  static const enterMs = 260;
  static const leaveMs = 200;
  static const leaveLagMs = 60;
  static const totalMs = 500;
  static const headerMs = 240;

  static const enterCurve = Cubic(0.22, 0.61, 0.36, 1);
  static const leaveCurve = Cubic(0.4, 0, 0.6, 1);

  static int delayMs({
    required int weekday,
    required int startSection,
    required bool forward,
    required int visibleDays,
  }) {
    final columnOrder = forward ? visibleDays - weekday : weekday - 1;
    final delay =
        math.max(0, columnOrder) * colStepMs +
        math.max(0, startSection - 1) * rowStepMs;
    return math.min(delay, maxDelayMs);
  }

  static Animation<double> enter(Animation<double> parent, int delayMs) {
    return CurvedAnimation(
      parent: parent,
      curve: Interval(
        delayMs / totalMs,
        (delayMs + enterMs) / totalMs,
        curve: enterCurve,
      ),
    );
  }

  static Animation<double> leave(Animation<double> parent, int delayMs) {
    return CurvedAnimation(
      parent: parent,
      curve: Interval(
        (delayMs + leaveLagMs) / totalMs,
        (delayMs + leaveLagMs + leaveMs) / totalMs,
        curve: leaveCurve,
      ),
    );
  }
}

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
    required this.reduceMotion,
    required this.onCourseTap,
    required this.onEmptyCellTap,
    required this.onDayTap,
    this.onSwipeWeek,
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
  final bool reduceMotion;
  final ValueChanged<Course> onCourseTap;
  final void Function(int weekday, int startSection, int endSection)
  onEmptyCellTap;
  final ValueChanged<int> onDayTap;

  /// 非编辑模式下水平滑动换周，参数为 +1（下一周）或 -1（上一周）。
  final ValueChanged<int>? onSwipeWeek;
  final GlobalKey? dayGuideKey;
  final GlobalKey? courseGuideKey;

  static const railWidth = 48.0;
  static const headerHeight = 66.0;
  static const breakHeight = 34.0;
  static const topInset = 6.0;

  @override
  State<WeekTimetable> createState() => _WeekTimetableState();
}

class _WeekTimetableState extends State<WeekTimetable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _Wave.totalMs),
    value: 1,
  );
  int? _leavingWeek;
  bool _waveForward = true;
  double _swipeDx = 0;

  int? _selectionDay;
  int? _selectionAnchor;
  int? _selectionEnd;

  @override
  void didUpdateWidget(covariant WeekTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) {
      _waveForward = widget.week > oldWidget.week;
      if (widget.reduceMotion) {
        _leavingWeek = null;
        _wave.value = 1;
      } else {
        _leavingWeek = oldWidget.week;
        _wave.forward(from: 0).whenCompleteOrCancel(() {
          if (mounted && _wave.value >= 1) {
            setState(() => _leavingWeek = null);
          }
        });
      }
    }
    if (!widget.editing && oldWidget.editing) {
      _selectionDay = null;
      _selectionAnchor = null;
      _selectionEnd = null;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
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
              wave: _wave,
              waving: _leavingWeek != null,
              waveForward: _waveForward,
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
                    onHorizontalDragStart:
                        widget.editing || widget.onSwipeWeek == null
                        ? null
                        : (_) => _swipeDx = 0,
                    onHorizontalDragUpdate:
                        widget.editing || widget.onSwipeWeek == null
                        ? null
                        : (details) => _swipeDx += details.delta.dx,
                    onHorizontalDragEnd:
                        widget.editing || widget.onSwipeWeek == null
                        ? null
                        : (details) =>
                              _settleSwipe(details, constraints.maxWidth),
                    child: _GridBody(
                      week: widget.week,
                      leavingWeek: _leavingWeek,
                      wave: _wave,
                      waveForward: _waveForward,
                      courses: widget.courses,
                      rowHeight: rowHeight,
                      dayWidth: dayWidth,
                      visibleDays: widget.visibleDays,
                      editing: widget.editing,
                      termStart: widget.termStart,
                      dayOverrides: widget.dayOverrides,
                      courseTimes: widget.courseTimes,
                      weather: widget.weather,
                      reduceMotion: widget.reduceMotion,
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

  void _settleSwipe(DragEndDetails details, double width) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldTurn = _swipeDx.abs() >= width * 0.2 || velocity.abs() >= 520.0;
    if (!shouldTurn) return;
    final movement = _swipeDx != 0 ? _swipeDx : -velocity;
    widget.onSwipeWeek?.call(movement < 0 ? 1 : -1);
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
    required this.wave,
    required this.waving,
    required this.waveForward,
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
  final Animation<double> wave;
  final bool waving;
  final bool waveForward;
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
                final header = _DayHeader(
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
                if (!waving) return header;
                // 表头文字原地更新，只随波浪方向做轻微提亮，不整层淡出
                final delay = _Wave.delayMs(
                  weekday: day,
                  startSection: 1,
                  forward: waveForward,
                  visibleDays: visibleDays,
                );
                final reveal = CurvedAnimation(
                  parent: wave,
                  curve: Interval(
                    delay / _Wave.totalMs,
                    (delay + _Wave.headerMs) / _Wave.totalMs,
                    curve: _Wave.enterCurve,
                  ),
                );
                return AnimatedBuilder(
                  animation: reveal,
                  child: header,
                  builder: (context, child) => Opacity(
                    opacity: 0.35 + 0.65 * reveal.value,
                    child: child,
                  ),
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

/// 一个格位（同天同节次范围）在某一周的显示快照，用于新旧对比与稳定判定。
class _CellView {
  _CellView({required this.group, required this.week});

  final List<Course> group;
  final int week;

  Course get top {
    final active = group.where((course) => course.occursInWeek(week));
    return active.isNotEmpty ? active.first : group.first;
  }

  String get cellKey => '${top.weekday}-${top.startSection}-${top.endSection}';

  /// 顶卡、本周状态、角标数任一变化都视为“有变化”，需要参与波浪
  String get signature =>
      '${top.id}|${top.occursInWeek(week)}|${group.length}|$cellKey';
}

class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.week,
    required this.leavingWeek,
    required this.wave,
    required this.waveForward,
    required this.termStart,
    required this.courses,
    required this.dayOverrides,
    required this.courseTimes,
    required this.weather,
    required this.reduceMotion,
    required this.rowHeight,
    required this.dayWidth,
    required this.visibleDays,
    required this.editing,
    required this.selectionDay,
    required this.selectionStart,
    required this.selectionEnd,
    required this.onCourseTap,
    required this.onEmptyCellTap,
    required this.onSelectionTap,
    this.courseGuideKey,
  });

  final int week;
  final int? leavingWeek;
  final Animation<double> wave;
  final bool waveForward;
  final DateTime termStart;
  final List<Course> courses;
  final List<AcademicDayOverride> dayOverrides;
  final List<CourseTime> courseTimes;
  final WeatherSnapshot? weather;
  final bool reduceMotion;
  final double rowHeight;
  final double dayWidth;
  final int visibleDays;
  final bool editing;
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
    final cells = _cellViews(week);
    final leavingCells = leavingWeek != null
        ? _cellViews(leavingWeek!)
        : const <_CellView>[];
    final currentSignatures = {
      for (final cell in cells) cell.cellKey: cell.signature,
    };
    final leavingSignatures = {
      for (final cell in leavingCells) cell.cellKey: cell.signature,
    };

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
            // 旧周内容垫底：稳定格与新周像素一致，直接跳过；其余延迟淡出
            for (final cell in leavingCells)
              if (currentSignatures[cell.cellKey] != cell.signature)
                _positionedCell(
                  context,
                  cell,
                  reveal: _Wave.leave(
                    wave,
                    _Wave.delayMs(
                      weekday: cell.top.weekday,
                      startSection: cell.top.startSection,
                      forward: waveForward,
                      visibleDays: visibleDays,
                    ),
                  ),
                  leaving: true,
                ),
            for (var index = 0; index < cells.length; index++)
              _positionedCell(
                context,
                cells[index],
                key: index == 0 ? courseGuideKey : null,
                reveal:
                    leavingWeek != null &&
                        leavingSignatures[cells[index].cellKey] !=
                            cells[index].signature
                    ? _Wave.enter(
                        wave,
                        _Wave.delayMs(
                          weekday: cells[index].top.weekday,
                          startSection: cells[index].top.startSection,
                          forward: waveForward,
                          visibleDays: visibleDays,
                        ),
                      )
                    : null,
                leaving: false,
              ),
          ],
        ),
      ),
    );
  }

  List<_CellView> _cellViews(int targetWeek) {
    final visible = _displayCourses(targetWeek);
    final map = <String, List<Course>>{};
    for (final course in visible) {
      final key =
          '${course.weekday}-${course.startSection}-${course.endSection}';
      map.putIfAbsent(key, () => []).add(course);
    }
    final groups = map.values.toList();
    for (final group in groups) {
      group.sort((a, b) {
        final activeCompare =
            a.occursInWeek(targetWeek) == b.occursInWeek(targetWeek)
            ? 0
            : a.occursInWeek(targetWeek)
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
    return [
      for (final group in groups) _CellView(group: group, week: targetWeek),
    ];
  }

  List<Course> _displayCourses(int targetWeek) {
    final result = <Course>[];
    for (var day = 1; day <= visibleDays; day++) {
      final date = ScheduleEngine.dateForWeekday(termStart, targetWeek, day);
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

  Widget _positionedCell(
    BuildContext context,
    _CellView cell, {
    Key? key,
    required Animation<double>? reveal,
    required bool leaving,
  }) {
    final course = cell.top;
    final top = _sectionTop(course.startSection);
    final span = course.endSection - course.startSection + 1;
    final includesBreak = course.startSection <= 4 && course.endSection > 4;
    final height =
        span * rowHeight + (includesBreak ? WeekTimetable.breakHeight : 0);
    final date = ScheduleEngine.dateForWeekday(
      termStart,
      cell.week,
      course.weekday,
    );
    final dailyWeather = weather?.weatherForDate(ScheduleEngine.dateKey(date));
    Widget child = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: leaving,
            child: _CourseCard(
              course: course,
              active: course.occursInWeek(cell.week),
              weather: dailyWeather,
              reduceMotion: reduceMotion || leaving,
              onTap: () => onCourseTap(course),
            ),
          ),
        ),
        if (cell.group.length > 1)
          Positioned(
            top: 0,
            right: 0,
            child: _OverlapBadge(count: cell.group.length),
          ),
      ],
    );
    if (reveal != null) {
      child = _WaveReveal(reveal: reveal, leaving: leaving, child: child);
    }
    return Positioned(
      key: key,
      top: top,
      left: WeekTimetable.railWidth + (course.weekday - 1) * dayWidth,
      width: dayWidth,
      height: height,
      child: child,
    );
  }
}

class _WaveReveal extends StatelessWidget {
  const _WaveReveal({
    required this.reveal,
    required this.leaving,
    required this.child,
  });

  final Animation<double> reveal;
  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final value = reveal.value;
        if (leaving) {
          return Opacity(opacity: 1 - value, child: child);
        }
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
    );
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
    required this.reduceMotion,
    required this.onTap,
    this.weather,
  });

  final Course course;
  final bool active;
  final bool reduceMotion;
  final DailyWeather? weather;
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (active && weather != null)
                IgnorePointer(
                  child: WeatherCardLayer(
                    kind: weatherPresentation(weather!.weatherCode).kind,
                    reduceMotion: reduceMotion,
                  ),
                ),
              Padding(
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
            ],
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
