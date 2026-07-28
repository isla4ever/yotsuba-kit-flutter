import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'course_detail.dart';
import 'engine.dart';
import 'models.dart';
import 'schedule_header.dart';
import 'sheet.dart';
import 'theme.dart';
import 'weather.dart';
import 'week_timetable.dart';

/// 即开即用的完整课表组合：周 Header、表格、换周、天气与内置详情。
class YsSchedule extends StatefulWidget {
  const YsSchedule({
    required this.week,
    required this.courses,
    required this.onWeekChanged,
    this.totalWeeks = 20,
    this.termStart,
    this.overrides = const [],
    this.courseTimes = standardCourseTimes,
    this.visibleDays = 7,
    this.rowHeight = 56,
    this.breakAfterSection = 4,
    this.theme = YsScheduleTheme.light,
    this.headerStyle = YsHeaderStyle.standard,
    this.headerTitle = '本学期课表',
    this.headerAdjustable = true,
    this.headerActions = const [],
    this.transition = YsTransition.wave,
    this.density = YsScheduleDensity.normal,
    this.cardEffect = YsCardEffect.none,
    this.weatherCardBackground = true,
    this.reduceMotion = false,
    this.swipeable = true,
    this.weekPickerBuiltIn = true,
    this.courseDetailBuiltIn = true,
    this.detail = const YsCourseDetailConfig(),
    this.sheets = const YsSheetConfig(),
    this.weather,
    this.weatherProvider,
    this.weatherScene = true,
    this.background,
    this.onHeaderStyleChanged,
    this.onCourseTap,
    this.onDayTap,
    this.onCourseShare,
    this.onCourseEdit,
    this.onCourseRemove,
    this.onDetailLayoutChanged,
    this.onWeatherTap,
    this.onWeatherError,
    this.onTransitionStart,
    this.onTransitionEnd,
    super.key,
  });

  final int week;
  final int totalWeeks;
  final List<YsCourse> courses;
  final ValueChanged<int> onWeekChanged;
  final DateTime? termStart;
  final List<YsDayOverride> overrides;
  final List<YsCourseTime> courseTimes;
  final int visibleDays;
  final double rowHeight;
  final int breakAfterSection;
  final YsScheduleTheme theme;
  final YsHeaderStyle headerStyle;
  final String headerTitle;
  final bool headerAdjustable;
  final List<YsHeaderAction> headerActions;
  final YsTransition transition;
  final YsScheduleDensity density;
  final YsCardEffect cardEffect;
  final bool weatherCardBackground;
  final bool reduceMotion;
  final bool swipeable;
  final bool weekPickerBuiltIn;
  final bool courseDetailBuiltIn;
  final YsCourseDetailConfig detail;
  final YsSheetConfig sheets;
  final YsWeatherSnapshot? weather;
  final YsWeatherProvider? weatherProvider;
  final bool weatherScene;
  final YsScheduleBackground? background;
  final ValueChanged<YsHeaderStyle>? onHeaderStyleChanged;
  final void Function(YsDisplayCourse, List<YsDisplayCourse>)? onCourseTap;
  final void Function(int weekday, DateTime? date)? onDayTap;
  final ValueChanged<YsDisplayCourse>? onCourseShare;
  final ValueChanged<YsDisplayCourse>? onCourseEdit;
  final ValueChanged<YsDisplayCourse>? onCourseRemove;
  final ValueChanged<YsDetailLayout>? onDetailLayoutChanged;
  final VoidCallback? onWeatherTap;
  final ValueChanged<Object>? onWeatherError;
  final ValueChanged<YsTransition>? onTransitionStart;
  final ValueChanged<YsTransition>? onTransitionEnd;

  @override
  State<YsSchedule> createState() => _YsScheduleState();
}

class _YsScheduleState extends State<YsSchedule> {
  late YsHeaderStyle _headerStyle = widget.headerStyle;
  YsWeatherSnapshot? _providerWeather;
  StreamSubscription<YsWeatherSnapshot>? _weatherSubscription;
  bool _weatherLoading = false;

  YsWeatherSnapshot? get _weather => widget.weather ?? _providerWeather;

  @override
  void initState() {
    super.initState();
    _connectWeatherProvider();
  }

  @override
  void didUpdateWidget(covariant YsSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headerStyle != widget.headerStyle) {
      _headerStyle = widget.headerStyle;
    }
    if (oldWidget.weatherProvider != widget.weatherProvider) {
      _connectWeatherProvider();
    }
  }

  Future<void> _connectWeatherProvider() async {
    await _weatherSubscription?.cancel();
    _weatherSubscription = widget.weatherProvider?.snapshots?.listen((value) {
      if (mounted) setState(() => _providerWeather = value);
    });
    if (widget.weather == null && widget.weatherProvider != null) {
      await _refreshWeather();
    }
  }

  Future<void> _refreshWeather() async {
    if (_weatherLoading || widget.weatherProvider == null) return;
    _weatherLoading = true;
    try {
      final value = await widget.weatherProvider!.getSnapshot();
      if (mounted) setState(() => _providerWeather = value);
    } catch (error) {
      widget.onWeatherError?.call(error);
    } finally {
      _weatherLoading = false;
    }
  }

  @override
  void dispose() {
    _weatherSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        YsScheduleHeader(
          week: widget.week,
          totalWeeks: widget.totalWeeks,
          title: widget.headerTitle,
          termStart: widget.termStart,
          style: _headerStyle,
          theme: widget.theme,
          weather: _weather,
          actions: widget.headerActions,
          adjustable: widget.headerAdjustable,
          onPrevious:
              widget.week > 1 ? () => _requestWeek(widget.week - 1) : null,
          onNext: widget.week < widget.totalWeeks
              ? () => _requestWeek(widget.week + 1)
              : null,
          onWeekTap: widget.weekPickerBuiltIn ? _showWeekPicker : null,
          onWeatherTap: widget.onWeatherTap ??
              (widget.weatherProvider == null ? null : _refreshWeather),
          onStyleChanged: (value) {
            setState(() => _headerStyle = value);
            widget.onHeaderStyleChanged?.call(value);
          },
        ),
        Expanded(
          child: YsWeekTimetable(
            week: widget.week,
            courses: widget.courses,
            termStart: widget.termStart,
            overrides: widget.overrides,
            courseTimes: widget.courseTimes,
            visibleDays: widget.visibleDays,
            rowHeight: widget.rowHeight,
            breakAfterSection: widget.breakAfterSection,
            theme: widget.theme,
            transition: widget.transition,
            density: widget.density,
            cardEffect: widget.cardEffect,
            weatherCardBackground: widget.weatherCardBackground,
            weather: _weather,
            reduceMotion: widget.reduceMotion,
            swipeable: widget.swipeable,
            onWeekRequested: (delta) => _requestWeek(widget.week + delta),
            onCourseTap: _openCourse,
            onDayTap: widget.onDayTap,
            onTransitionStart: widget.onTransitionStart,
            onTransitionEnd: widget.onTransitionEnd,
          ),
        ),
      ],
    );

    Widget scene = content;
    final kind = _weather?.current?.kind;
    if (widget.weatherScene && kind != null) {
      scene = YsWeatherScene(
        kind: kind,
        theme: widget.theme,
        reduceMotion: widget.reduceMotion,
        child: scene,
      );
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: widget.theme.canvas),
          if (widget.background?.image != null)
            Opacity(
              opacity: widget.background!.opacity.clamp(0, 1).toDouble(),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: widget.background!.blur,
                  sigmaY: widget.background!.blur,
                ),
                child: Image(
                  image: widget.background!.image!,
                  fit: widget.background!.fit,
                  alignment: widget.background!.alignment,
                ),
              ),
            ),
          scene,
        ],
      ),
    );
  }

  void _requestWeek(int week) {
    widget.onWeekChanged(week.clamp(1, widget.totalWeeks));
  }

  Future<void> _showWeekPicker() {
    return showYsAdaptiveSheet<void>(
      context: context,
      title: '选择周次',
      icon: Icons.calendar_view_week_outlined,
      kind: YsSheetKind.weekPicker,
      theme: widget.theme,
      config: widget.sheets,
      builder: (context, placement) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: placement == YsSheetPlacement.right ? 4 : 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
        ),
        itemCount: widget.totalWeeks,
        itemBuilder: (context, index) {
          final week = index + 1;
          return Semantics(
            selected: week == widget.week,
            button: true,
            label: '第 $week 周',
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _requestWeek(week);
              },
              borderRadius: BorderRadius.circular(7),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: week == widget.week
                      ? widget.theme.accent
                      : widget.theme.surface2,
                  border: Border.all(color: widget.theme.border),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '$week',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: week == widget.week
                          ? Colors.white
                          : widget.theme.text1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCourse(
    YsDisplayCourse course,
    List<YsDisplayCourse> stack,
  ) {
    widget.onCourseTap?.call(course, stack);
    if (!widget.courseDetailBuiltIn) return;
    final date = widget.termStart == null
        ? null
        : dateFor(widget.termStart!, widget.week, course.weekday);
    final daily =
        date == null ? null : _weather?.weatherForDate(formatDateKey(date));
    showYsCourseDetail(
      context: context,
      course: course,
      stack: stack,
      courseTimes: widget.courseTimes,
      date: date,
      weather: daily,
      theme: widget.theme,
      detail: widget.detail,
      sheets: widget.sheets,
      onShare: widget.onCourseShare,
      onEdit: widget.onCourseEdit,
      onRemove: widget.onCourseRemove,
      onLayoutChanged: widget.onDetailLayoutChanged,
    );
  }
}
