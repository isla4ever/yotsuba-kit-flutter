import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'config.dart';
import 'engine.dart';
import 'models.dart';
import 'theme.dart';
import 'weather.dart';

class _Wave {
  static const colStepMs = 30;
  static const rowStepMs = 7;
  static const maxDelayMs = 210;
  static const enterMs = 260;
  static const leaveMs = 260;
  static const leaveLagMs = 0;
  static const totalMs = 500;

  static const enterCurve = Cubic(0.22, 0.61, 0.36, 1);
  static const leaveCurve = enterCurve;

  static int delayMs({
    required int weekday,
    required int startSection,
    required bool forward,
    required int visibleDays,
  }) {
    final columnOrder = forward ? visibleDays - weekday : weekday - 1;
    final delay = math.max(0, columnOrder) * colStepMs +
        math.max(0, startSection - 1) * rowStepMs;
    return math.min(delay, maxDelayMs);
  }
}

/// 波浪覆盖换周课表（只读展示 + 手势/回调）。
///
/// 设计不变量（与 npm 版一致）：
/// 骨架常驻；旧周垫底、新卡逐列扫入，任何一帧不出现空网格；
/// 换周前后视觉不变的格子完全静止；重叠格以顶卡原子渲染。
class YsWeekTimetable extends StatefulWidget {
  const YsWeekTimetable({
    required this.week,
    required this.courses,
    this.termStart,
    this.overrides = const [],
    this.courseTimes = standardCourseTimes,
    this.visibleDays = 7,
    this.rowHeight = 56,
    this.breakAfterSection = 4,
    this.theme = YsScheduleTheme.light,
    this.transition = YsTransition.wave,
    this.density = YsScheduleDensity.normal,
    this.cardEffect = YsCardEffect.none,
    this.weatherCardBackground = true,
    this.weatherCardGlyph = false,
    this.weather,
    this.reduceMotion = false,
    this.swipeable = true,
    this.inactiveBadge = '非本周',
    this.makeupBadge = '补班',
    this.breakLabel = '午休',
    this.weekdayLabels = const ['一', '二', '三', '四', '五', '六', '日'],
    this.onWeekRequested,
    this.onCourseTap,
    this.onDayTap,
    this.onTransitionStart,
    this.onTransitionEnd,
    super.key,
  });

  final int week;
  final List<YsCourse> courses;
  final DateTime? termStart;
  final List<YsDayOverride> overrides;
  final List<YsCourseTime> courseTimes;
  final int visibleDays;
  final double rowHeight;
  final int breakAfterSection;
  final YsScheduleTheme theme;
  final YsTransition transition;
  final YsScheduleDensity density;
  final YsCardEffect cardEffect;
  final bool weatherCardBackground;
  final bool weatherCardGlyph;
  final YsWeatherSnapshot? weather;
  final bool reduceMotion;
  final bool swipeable;
  final String inactiveBadge;
  final String makeupBadge;
  final String breakLabel;
  final List<String> weekdayLabels;

  /// 滑动请求换周：+1 下一周 / -1 上一周（受控，宿主自行 clamp 并回传 week）。
  final ValueChanged<int>? onWeekRequested;
  final void Function(YsDisplayCourse course, List<YsDisplayCourse> stack)?
      onCourseTap;
  final void Function(int weekday, DateTime? date)? onDayTap;
  final ValueChanged<YsTransition>? onTransitionStart;
  final ValueChanged<YsTransition>? onTransitionEnd;

  static const railWidth = 48.0;
  static const headerHeight = 58.0;
  static const breakHeight = 34.0;
  static const topInset = 6.0;

  @override
  State<YsWeekTimetable> createState() => _YsWeekTimetableState();
}

class _YsWeekTimetableState extends State<YsWeekTimetable>
    with SingleTickerProviderStateMixin {
  // 必须在 initState 初始化：late final 惰性初始化若首次访问发生在 dispose，
  // 会在已停用的元素上查找 TickerMode 祖先而崩溃
  late final AnimationController _wave;
  late YsCourseColorResolver _colors = YsCourseColorResolver(widget.theme);

  double get _resolvedHeaderHeight => switch (widget.density) {
        YsScheduleDensity.minimal => 48,
        YsScheduleDensity.normal => YsWeekTimetable.headerHeight,
        YsScheduleDensity.rich => 68,
      };

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _Wave.totalMs),
      value: 1,
    );
  }

  int? _leavingWeek;
  bool _forward = true;
  double _dragDx = 0;

  @override
  void didUpdateWidget(covariant YsWeekTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _colors = YsCourseColorResolver(widget.theme);
    }
    if (oldWidget.week != widget.week) {
      _forward = widget.week > oldWidget.week;
      if (widget.reduceMotion || widget.transition == YsTransition.none) {
        _leavingWeek = null;
        _wave.value = 1;
      } else {
        _leavingWeek = oldWidget.week;
        widget.onTransitionStart?.call(widget.transition);
        _wave.forward(from: 0).whenCompleteOrCancel(() {
          if (mounted && _wave.value >= 1) {
            setState(() => _leavingWeek = null);
            widget.onTransitionEnd?.call(widget.transition);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  int get _maxSection {
    var max = widget.courseTimes.length;
    for (final course in widget.courses) {
      if (course.endSection > max) {
        max = course.endSection;
      }
    }
    return max;
  }

  double _sectionTop(int section) {
    return YsWeekTimetable.topInset +
        (section - 1) * widget.rowHeight +
        (section > widget.breakAfterSection ? YsWeekTimetable.breakHeight : 0);
  }

  double get _bodyHeight =>
      YsWeekTimetable.topInset +
      _maxSection * widget.rowHeight +
      YsWeekTimetable.breakHeight;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return LayoutBuilder(builder: (context, constraints) {
      final dayWidth = (constraints.maxWidth - YsWeekTimetable.railWidth) /
          widget.visibleDays;
      return ColoredBox(
        color: theme.canvas,
        child: Column(children: [
          _buildHeader(dayWidth),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: _bodyHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart:
                      widget.swipeable ? (_) => _dragDx = 0 : null,
                  onHorizontalDragUpdate: widget.swipeable
                      ? (details) => _dragDx += details.delta.dx
                      : null,
                  onHorizontalDragEnd: widget.swipeable
                      ? (details) => _settleSwipe(details, constraints.maxWidth)
                      : null,
                  child: _buildGrid(dayWidth),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  void _settleSwipe(DragEndDetails details, double width) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDx.abs() < width * 0.2 && velocity.abs() < 520.0) {
      return;
    }
    final movement = _dragDx != 0 ? _dragDx : -velocity;
    widget.onWeekRequested?.call(movement < 0 ? 1 : -1);
  }

  Widget _buildHeader(double dayWidth) {
    final theme = widget.theme;
    final now = DateTime.now();
    return Container(
      height: _resolvedHeaderHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(children: [
        SizedBox(
          width: YsWeekTimetable.railWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('星期', style: TextStyle(fontSize: 11, color: theme.text3)),
              if (widget.termStart != null)
                Text('日期', style: TextStyle(fontSize: 10, color: theme.text3)),
            ],
          ),
        ),
        for (var day = 1; day <= widget.visibleDays; day++)
          _buildDay(day, dayWidth, now, theme),
      ]),
    );
  }

  Widget _buildDay(
      int day, double dayWidth, DateTime now, YsScheduleTheme theme) {
    final date = widget.termStart == null
        ? null
        : dateFor(widget.termStart!, widget.week, day);
    final isToday = date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final daily = date == null
        ? null
        : widget.weather?.weatherForDate(formatDateKey(date));
    return SizedBox(
      width: dayWidth,
      height: _resolvedHeaderHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            widget.onDayTap == null ? null : () => widget.onDayTap!(day, date),
        child: ColoredBox(
          color: isToday ? theme.accentSoft : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.weekdayLabels[day - 1],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isToday ? theme.accent : theme.text2,
                ),
              ),
              if (date != null)
                Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(fontSize: 9, color: theme.text3),
                ),
              if (daily != null && widget.density != YsScheduleDensity.minimal)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    YsWeatherGlyph(
                      kind: daily.kind,
                      size: 10,
                      animate: !widget.reduceMotion,
                      color: isToday ? theme.accent : theme.text3,
                    ),
                    if (widget.density == YsScheduleDensity.rich &&
                        daily.highC != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${daily.highC!.round()}°',
                        style: TextStyle(
                          fontSize: 8,
                          color: isToday ? theme.accent : theme.text3,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(double dayWidth) {
    final theme = widget.theme;
    final cells = _cellViews(widget.week);
    final allLeavingCells =
        _leavingWeek != null ? _cellViews(_leavingWeek!) : const <_CellView>[];
    final currentByCell = {for (final cell in cells) cell.cellKey: cell};
    final leavingCells = allLeavingCells
        .where(
            (cell) => _canPaintLeavingCell(cell, currentByCell[cell.cellKey]))
        .toList(growable: false);
    final currentSignatures = {
      for (final cell in cells) cell.cellKey: cell.signature,
    };
    final leavingSignatures = {
      for (final cell in allLeavingCells) cell.cellKey: cell.signature,
    };

    return ClipRect(
      child: Stack(children: [
        for (var section = 1; section <= _maxSection; section++)
          Positioned(
            top: _sectionTop(section),
            left: 0,
            width: YsWeekTimetable.railWidth,
            height: widget.rowHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$section',
                  style: TextStyle(
                    height: 1,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.text2,
                  ),
                ),
                if (section <= widget.courseTimes.length) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${widget.courseTimes[section - 1].start}\n${widget.courseTimes[section - 1].end}',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(height: 1.2, fontSize: 8, color: theme.text3),
                  ),
                ],
              ],
            ),
          ),
        Positioned(
          top: _sectionTop(widget.breakAfterSection + 1) -
              YsWeekTimetable.breakHeight,
          left: 0,
          width: YsWeekTimetable.railWidth,
          height: YsWeekTimetable.breakHeight,
          child: Center(
            child: Text(
              widget.breakLabel,
              style: TextStyle(fontSize: 9, color: theme.text3),
            ),
          ),
        ),
        if (widget.transition == YsTransition.wave) ...[
          // 波浪模式跳过视觉完全不变的格子，其余旧卡延迟淡出。
          for (final cell in leavingCells)
            if (currentSignatures[cell.cellKey] != cell.signature)
              _positionedCell(cell, dayWidth, leaving: true),
          for (final cell in cells)
            _positionedCell(
              cell,
              dayWidth,
              leaving: false,
              animate: _leavingWeek != null &&
                  leavingSignatures[cell.cellKey] != cell.signature,
            ),
        ] else ...[
          if (leavingCells.isNotEmpty)
            _pageLayer(leavingCells, dayWidth, leaving: true),
          _pageLayer(
            cells,
            dayWidth,
            leaving: false,
            animate: leavingCells.isNotEmpty,
          ),
        ],
      ]),
    );
  }

  bool _canPaintLeavingCell(_CellView leaving, _CellView? current) {
    return leaving.top.active || current == null || !current.top.active;
  }

  List<_CellView> _cellViews(int week) {
    final model = buildWeekModel(
      widget.courses,
      week,
      termStart: widget.termStart,
      overrides: widget.overrides,
    );
    final map = <String, List<YsDisplayCourse>>{};
    for (final course in model.courses) {
      if (course.weekday > widget.visibleDays) {
        continue;
      }
      final key =
          '${course.weekday}-${course.course.startSection}-${course.course.endSection}';
      map.putIfAbsent(key, () => []).add(course);
    }
    final cells = [
      for (final group in map.values) _CellView(group: group, week: week),
    ]..sort((a, b) {
        final day = a.top.weekday.compareTo(b.top.weekday);
        return day != 0
            ? day
            : a.top.course.startSection.compareTo(b.top.course.startSection);
      });
    return cells;
  }

  Widget _positionedCell(
    _CellView cell,
    double dayWidth, {
    required bool leaving,
    bool animate = false,
    bool wave = true,
  }) {
    final course = cell.top;
    final top = _sectionTop(course.course.startSection);
    final span = course.course.endSection - course.course.startSection + 1;
    final includesBreak =
        course.course.startSection <= widget.breakAfterSection &&
            course.course.endSection > widget.breakAfterSection;
    final height = span * widget.rowHeight +
        (includesBreak ? YsWeekTimetable.breakHeight : 0);
    final date = widget.termStart == null
        ? null
        : dateFor(widget.termStart!, cell.week, course.weekday);
    final startTime = course.course.startSection <= widget.courseTimes.length
        ? widget.courseTimes[course.course.startSection - 1].start
        : null;
    final courseDateTime = date == null || startTime == null
        ? null
        : _atCourseTime(date, startTime);
    final daily = courseDateTime == null
        ? null
        : widget.weather?.weatherForDateTime(courseDateTime);

    Widget child = _CourseCard(
      cell: cell,
      color: _colors.resolve(course.course.name, explicit: course.course.color),
      theme: widget.theme,
      inactiveBadge: widget.inactiveBadge,
      makeupBadge: widget.makeupBadge,
      density: widget.density,
      effect: widget.cardEffect,
      weatherCardBackground: widget.weatherCardBackground,
      weatherCardGlyph: widget.weatherCardGlyph,
      reduceMotion: widget.reduceMotion || leaving,
      narrow: dayWidth < 58,
      weather: daily,
      onTap: leaving || widget.onCourseTap == null
          ? null
          : () => widget.onCourseTap!(course, cell.group),
    );

    if (wave && (leaving || animate)) {
      final delay = _Wave.delayMs(
        weekday: course.weekday,
        startSection: course.course.startSection,
        forward: _forward,
        visibleDays: widget.visibleDays,
      );
      final reveal = CurvedAnimation(
        parent: _wave,
        curve: leaving
            ? Interval(
                (delay + _Wave.leaveLagMs) / _Wave.totalMs,
                (delay + _Wave.leaveLagMs + _Wave.leaveMs) / _Wave.totalMs,
                curve: _Wave.leaveCurve,
              )
            : Interval(
                delay / _Wave.totalMs,
                (delay + _Wave.enterMs) / _Wave.totalMs,
                curve: _Wave.enterCurve,
              ),
      );
      child = AnimatedBuilder(
        animation: reveal,
        child: child,
        builder: (context, inner) {
          final value = reveal.value;
          if (leaving) {
            return Opacity(opacity: 1 - value, child: inner);
          }
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 4),
              child: inner,
            ),
          );
        },
      );
    }

    return Positioned(
      top: top,
      left: YsWeekTimetable.railWidth + (course.weekday - 1) * dayWidth,
      width: dayWidth,
      height: height,
      child: IgnorePointer(ignoring: leaving, child: child),
    );
  }

  Widget _pageLayer(
    List<_CellView> cells,
    double dayWidth, {
    required bool leaving,
    bool animate = true,
  }) {
    Widget layer = Stack(
      children: [
        for (final cell in cells)
          _positionedCell(
            cell,
            dayWidth,
            leaving: leaving,
            wave: false,
          ),
      ],
    );
    if (animate) {
      layer = AnimatedBuilder(
        animation: _wave,
        child: layer,
        builder: (context, child) {
          final value = Curves.easeOutCubic.transform(_wave.value);
          return _buildPageTransform(child!, value, leaving);
        },
      );
    }
    return Positioned.fill(child: layer);
  }

  Widget _buildPageTransform(Widget child, double value, bool leaving) {
    final direction = _forward ? 1.0 : -1.0;
    final opacity = leaving ? 1 - value : value;
    Widget transformed = child;
    switch (widget.transition) {
      case YsTransition.slide:
        transformed = Transform.translate(
          offset: Offset(
            leaving ? -direction * value * 24 : direction * (1 - value) * 28,
            0,
          ),
          child: child,
        );
        break;
      case YsTransition.fade:
        transformed = child;
        break;
      case YsTransition.cube:
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(
            leaving
                ? -direction * value * 0.58
                : direction * (1 - value) * 0.72,
          );
        transformed = Transform(
          transform: matrix,
          alignment:
              direction > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: child,
        );
        break;
      case YsTransition.drop:
        transformed = Transform.translate(
          offset: Offset(0, leaving ? value * 14 : -(1 - value) * 20),
          child: Transform.scale(
            scale: leaving ? 1 - value * 0.015 : 0.98 + value * 0.02,
            child: child,
          ),
        );
        break;
      case YsTransition.zoom:
        transformed = Transform.scale(
          scale: leaving ? 1 + value * 0.045 : 0.88 + value * 0.12,
          child: child,
        );
        break;
      case YsTransition.wave || YsTransition.none:
        transformed = child;
        break;
    }
    return Opacity(opacity: opacity.clamp(0, 1).toDouble(), child: transformed);
  }
}

DateTime _atCourseTime(DateTime date, String time) {
  final parts = time.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// 一个格位在某周的显示快照（顶卡 + 重叠数），用于新旧对比与稳定判定。
class _CellView {
  _CellView({required this.group, required this.week});

  final List<YsDisplayCourse> group;
  final int week;

  YsDisplayCourse get top {
    for (final course in group.reversed) {
      if (course.active) {
        return course;
      }
    }
    return group.last;
  }

  String get cellKey =>
      '${top.weekday}-${top.course.startSection}-${top.course.endSection}';

  String get signature =>
      '${top.displayId}|${top.active}|${group.length}|$cellKey';
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.cell,
    required this.color,
    required this.theme,
    required this.inactiveBadge,
    required this.makeupBadge,
    required this.density,
    required this.effect,
    required this.weatherCardBackground,
    required this.weatherCardGlyph,
    required this.reduceMotion,
    required this.narrow,
    this.weather,
    this.onTap,
  });

  final _CellView cell;
  final Color color;
  final YsScheduleTheme theme;
  final String inactiveBadge;
  final String makeupBadge;
  final YsScheduleDensity density;
  final YsCardEffect effect;
  final bool weatherCardBackground;
  final bool weatherCardGlyph;
  final bool reduceMotion;
  final bool narrow;
  final YsDailyWeather? weather;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final course = cell.top;
    final active = course.isMakeup || course.active;
    final status =
        course.isMakeup ? makeupBadge : (active ? '' : inactiveBadge);
    final baseBackground = course.isMakeup
        ? Color.lerp(color, theme.warning, 0.76)!
        : active
            ? color
            : theme.surface3;
    final showWeatherBackground =
        weather != null && weatherCardBackground && effect == YsCardEffect.none;
    final background = baseBackground;
    final foreground = active ? Colors.white : theme.text2;
    Widget? weatherLayer;
    if (showWeatherBackground) {
      weatherLayer = YsWeatherCardLayer(
        kind: weather!.kind,
        theme: theme,
        reduceMotion: reduceMotion,
      );
      if (!active) {
        weatherLayer = Opacity(
          opacity: 0.16,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: weatherLayer,
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.all(narrow ? 2 : 3),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Material(
            color: background,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: active
                    ? background.withValues(alpha: 0.72)
                    : theme.borderStrong,
                style:
                    course.course.custom ? BorderStyle.none : BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = narrow || constraints.maxHeight < 104;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(4, 5, 4, compact ? 13 : 14),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: compact ? 9 : 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (status.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.black.withValues(alpha: 0.34)
                                    : theme.surface1,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: compact ? 6 : 7,
                                  fontWeight: FontWeight.w800,
                                  color: active ? Colors.white : theme.text1,
                                ),
                              ),
                            ),
                          Text(
                            course.course.name,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: compact ? 1.08 : 1.2,
                              fontSize: compact ? 8 : 11,
                              fontWeight: FontWeight.w800,
                              color: foreground,
                            ),
                          ),
                          if (!compact &&
                              density != YsScheduleDensity.minimal &&
                              course.course.location != null)
                            Text(
                              '@${course.course.location}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: foreground.withValues(alpha: 0.86),
                              ),
                            ),
                          if (density == YsScheduleDensity.rich &&
                              ((!compact && course.course.teacher != null) ||
                                  course.course.carryItems.isNotEmpty))
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!compact && course.course.teacher != null)
                                  Flexible(
                                    child: Text(
                                      course.course.teacher!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color:
                                            foreground.withValues(alpha: 0.78),
                                      ),
                                    ),
                                  ),
                                if (!compact &&
                                    course.course.teacher != null &&
                                    course.course.carryItems.isNotEmpty)
                                  const SizedBox(width: 3),
                                if (course.course.carryItems.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.86),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '带',
                                      style: TextStyle(
                                        height: 1,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (weatherLayer != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: weatherLayer,
              ),
            ),
          ),
        if (active && effect != YsCardEffect.none && !reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _CardEffectOverlay(effect: effect),
              ),
            ),
          ),
        if (density != YsScheduleDensity.minimal)
          Positioned(
            right: 2,
            bottom: 4,
            left: 2,
            child: IgnorePointer(
              child: Text(
                '(${course.course.startWeek}-${course.course.endWeek}周)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: foreground.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        if (active && weather != null && weatherCardGlyph && !narrow)
          Positioned(
            top: 4,
            left: 4,
            child: IgnorePointer(
              child: YsWeatherGlyph(
                kind: weather!.kind,
                size: 12,
                animate: !reduceMotion,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        if (cell.group.length > 1)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1C232D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              ),
              child: Text(
                '${cell.group.length}',
                style: const TextStyle(
                  height: 1,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _CardEffectOverlay extends StatefulWidget {
  const _CardEffectOverlay({required this.effect});

  final YsCardEffect effect;

  @override
  State<_CardEffectOverlay> createState() => _CardEffectOverlayState();
}

class _CardEffectOverlayState extends State<_CardEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final decoration = switch (widget.effect) {
          YsCardEffect.shimmer => BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.8 + value * 3.6, -1),
                end: Alignment(-0.8 + value * 3.6, 1),
                colors: const [
                  Colors.transparent,
                  Color(0x42FFFFFF),
                  Colors.transparent,
                ],
              ),
            ),
          YsCardEffect.glow => BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.03 + math.sin(value * math.pi * 2).abs() * 0.09,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12 + value * 0.16),
                width: 1.4,
              ),
            ),
          YsCardEffect.aurora => BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + value * 2, -1),
                end: Alignment(1 - value * 2, 1),
                colors: const [
                  Color(0x0027E6A6),
                  Color(0x3327E6A6),
                  Color(0x264C6FFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          YsCardEffect.breathe => BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.02 + (math.sin(value * math.pi * 2) + 1) * 0.035,
              ),
            ),
          YsCardEffect.none => const BoxDecoration(),
        };
        return DecoratedBox(decoration: decoration);
      },
    );
  }
}
