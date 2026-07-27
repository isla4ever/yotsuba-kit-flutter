import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'engine.dart';
import 'models.dart';
import 'theme.dart';
import 'weather.dart';

enum YsTodayWidgetSize {
  compact,
  standard,
  large,
  oneByOne,
  oneByTwo,
  twoByOne,
  twoByTwo,
}

extension YsTodayWidgetSizeLayout on YsTodayWidgetSize {
  int get columns => switch (this) {
        YsTodayWidgetSize.compact ||
        YsTodayWidgetSize.oneByOne ||
        YsTodayWidgetSize.oneByTwo =>
          1,
        _ => 2,
      };

  int get rows => switch (this) {
        YsTodayWidgetSize.large ||
        YsTodayWidgetSize.oneByTwo ||
        YsTodayWidgetSize.twoByTwo =>
          2,
        _ => 1,
      };
}

enum YsTodayResizeCorner { topLeft, topRight, bottomLeft, bottomRight }

abstract final class YsTodayWidgetIds {
  static const nextCourse = 'next-course';
  static const timeline = 'today-timeline';
  static const readiness = 'readiness';
  static const plans = 'plans';
  static const courseTasks = 'course-tasks';
  static const weekGlance = 'week-glance';
  static const weather = 'weather';
}

class YsTodayWidgetConfig {
  const YsTodayWidgetConfig({
    required this.id,
    this.enabled = true,
    this.size = YsTodayWidgetSize.standard,
  });

  final String id;
  final bool enabled;
  final YsTodayWidgetSize size;

  YsTodayWidgetConfig copyWith({
    String? id,
    bool? enabled,
    YsTodayWidgetSize? size,
  }) =>
      YsTodayWidgetConfig(
        id: id ?? this.id,
        enabled: enabled ?? this.enabled,
        size: size ?? this.size,
      );
}

class YsTodayBuildContext {
  const YsTodayBuildContext({
    required this.now,
    required this.week,
    required this.weekday,
    required this.todayCourses,
    required this.weekModel,
    required this.plans,
    required this.theme,
    required this.size,
    this.weather,
  });

  final DateTime now;
  final int week;
  final int weekday;
  final List<YsDisplayCourse> todayCourses;
  final YsWeekModel weekModel;
  final List<YsDayPlan> plans;
  final YsScheduleTheme theme;
  final YsTodayWidgetSize size;
  final YsWeatherSnapshot? weather;
}

typedef YsTodayWidgetBuilder = Widget Function(
  BuildContext context,
  YsTodayBuildContext data,
);

class YsToday extends StatefulWidget {
  const YsToday({
    required this.courses,
    required this.termStart,
    this.totalWeeks = 20,
    this.overrides = const [],
    this.courseTimes = standardCourseTimes,
    this.widgets = const [
      YsTodayWidgetConfig(
        id: YsTodayWidgetIds.nextCourse,
        size: YsTodayWidgetSize.compact,
      ),
      YsTodayWidgetConfig(
        id: YsTodayWidgetIds.weather,
        size: YsTodayWidgetSize.compact,
      ),
      YsTodayWidgetConfig(id: YsTodayWidgetIds.timeline),
      YsTodayWidgetConfig(id: YsTodayWidgetIds.readiness),
      YsTodayWidgetConfig(id: YsTodayWidgetIds.plans),
      YsTodayWidgetConfig(id: YsTodayWidgetIds.courseTasks),
      YsTodayWidgetConfig(id: YsTodayWidgetIds.weekGlance),
    ],
    this.dayPlans = const {},
    this.weather,
    this.now,
    this.title = '今日',
    this.theme = YsScheduleTheme.light,
    this.arrangeable = true,
    this.weatherScene = true,
    this.reduceMotion = false,
    this.emptyText,
    this.emptyTexts = const {},
    this.customBuilders = const {},
    this.onWidgetsChanged,
    this.onLayoutEditing,
    this.onCourseTap,
    this.onWidgetTap,
    this.onWidgetMove,
    this.onWidgetResize,
    super.key,
  });

  final List<YsCourse> courses;
  final DateTime termStart;
  final int totalWeeks;
  final List<YsDayOverride> overrides;
  final List<YsCourseTime> courseTimes;
  final List<YsTodayWidgetConfig> widgets;
  final YsDayPlanMap dayPlans;
  final YsWeatherSnapshot? weather;
  final DateTime? now;
  final String title;
  final YsScheduleTheme theme;
  final bool arrangeable;
  final bool weatherScene;
  final bool reduceMotion;
  final String? emptyText;
  final Map<String, String> emptyTexts;
  final Map<String, YsTodayWidgetBuilder> customBuilders;
  final ValueChanged<List<YsTodayWidgetConfig>>? onWidgetsChanged;
  final ValueChanged<bool>? onLayoutEditing;
  final ValueChanged<YsDisplayCourse>? onCourseTap;
  final ValueChanged<String>? onWidgetTap;
  final void Function(String id, int from, int to)? onWidgetMove;
  final void Function(
    String id,
    YsTodayWidgetSize size,
    YsTodayResizeCorner corner,
  )? onWidgetResize;

  @override
  State<YsToday> createState() => _YsTodayState();
}

class _YsTodayState extends State<YsToday> {
  late List<YsTodayWidgetConfig> _widgets = List.of(widget.widgets);
  bool _editing = false;

  @override
  void didUpdateWidget(covariant YsToday oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameWidgets(oldWidget.widgets, widget.widgets)) {
      _widgets = List.of(widget.widgets);
    }
  }

  bool _sameWidgets(
    List<YsTodayWidgetConfig> first,
    List<YsTodayWidgetConfig> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id ||
          first[index].enabled != second[index].enabled ||
          first[index].size != second[index].size) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now ?? DateTime.now();
    final week = weekOf(now, widget.termStart, widget.totalWeeks);
    final weekday = now.weekday;
    final model = buildWeekModel(
      widget.courses,
      week,
      termStart: widget.termStart,
      overrides: widget.overrides,
    );
    final todayCourses = model.courses
        .where((course) => course.weekday == weekday && course.active)
        .toList()
      ..sort((a, b) => a.course.startSection.compareTo(b.course.startSection));
    final plans = widget.dayPlans[formatDateKey(now)] ?? const <YsDayPlan>[];

    Widget content = ColoredBox(
      color: widget.theme.canvas.withValues(alpha: 0.92),
      child: Column(
        children: [
          _buildHeader(todayCourses, plans),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var index = 0; index < _widgets.length; index++)
                      if (_widgets[index].enabled)
                        _buildTile(
                          context,
                          constraints.maxWidth - 24,
                          index,
                          YsTodayBuildContext(
                            now: now,
                            week: week,
                            weekday: weekday,
                            todayCourses: todayCourses,
                            weekModel: model,
                            plans: plans,
                            theme: widget.theme,
                            size: _widgets[index].size,
                            weather: widget.weather,
                          ),
                        ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
    final kind = widget.weather?.current?.kind;
    if (widget.weatherScene && kind != null) {
      content = YsWeatherScene(
        kind: kind,
        theme: widget.theme,
        reduceMotion: widget.reduceMotion,
        child: content,
      );
    }
    return content;
  }

  Widget _buildHeader(
    List<YsDisplayCourse> todayCourses,
    List<YsDayPlan> plans,
  ) {
    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.theme.surface1.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: widget.theme.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: widget.theme.text1,
                      ),
                    ),
                    Text(
                      '${todayCourses.length} 门课 · '
                      '${plans.where((item) => !item.done).length} 项待办',
                      style: TextStyle(fontSize: 11, color: widget.theme.text3),
                    ),
                  ],
                ),
              ),
              if (widget.arrangeable)
                IconButton(
                  tooltip: _editing ? '完成布局调整' : '调整今日布局',
                  onPressed: () => _setEditing(!_editing),
                  icon: Icon(
                    _editing ? Icons.check : Icons.dashboard_customize_outlined,
                    color: _editing ? widget.theme.accent : widget.theme.text2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    double availableWidth,
    int index,
    YsTodayBuildContext data,
  ) {
    final config = _widgets[index];
    final columns = availableWidth >= 760 ? 3 : 2;
    final unit = (availableWidth - (columns - 1) * 10) / columns;
    final span = math.min(config.size.columns, columns);
    final width = span * unit + (span - 1) * 10;
    final height = config.size.rows * 138.0 + (config.size.rows - 1) * 10;
    final body = widget.customBuilders[config.id]?.call(context, data) ??
        _builtInWidget(config.id, data);
    final weatherKind = widget.weather?.current?.kind;
    final weatherTint = weatherKind == null
        ? widget.theme.surface1
        : Color.lerp(
            widget.theme.surface1,
            _weatherSurfaceTint(weatherKind),
            0.08,
          )!;
    final tile = Semantics(
      label: '今日组件 ${_widgetTitle(config.id)}',
      button: true,
      hint: widget.arrangeable ? '长按进入布局调整' : null,
      child: GestureDetector(
        onLongPress: widget.arrangeable ? () => _setEditing(true) : null,
        onTap: () => widget.onWidgetTap?.call(config.id),
        child: AnimatedContainer(
          key: ValueKey(config.id),
          width: width,
          height: height,
          duration: widget.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: weatherTint.withValues(alpha: 0.94),
            border: Border.all(
              color: _editing ? widget.theme.accent : widget.theme.border,
              width: _editing ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: IgnorePointer(ignoring: _editing, child: body),
                  ),
                ),
                if (_editing)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: widget.theme.accent,
                        ),
                      ),
                    ),
                  ),
                if (_editing)
                  for (final corner in YsTodayResizeCorner.values)
                    _TodayResizeHandle(
                      key: ValueKey('${config.id}-${corner.name}'),
                      corner: corner,
                      size: config.size,
                      theme: widget.theme,
                      onPreview: (size) => _previewSize(index, size),
                      onCommit: (size) => _commitSize(index, size, corner),
                      onCancel: (size) => _previewSize(index, size),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!_editing) return tile;
    final draggable = LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 120),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: math.min(width, 260),
          height: math.min(height, 190),
          child: Opacity(opacity: 0.9, child: tile),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: tile),
      child: tile,
    );
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => _move(details.data, index),
      builder: (context, candidates, rejected) => AnimatedScale(
        scale: candidates.isEmpty ? 1 : 0.97,
        duration: widget.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 140),
        child: draggable,
      ),
    );
  }

  Widget _builtInWidget(String id, YsTodayBuildContext data) {
    return switch (id) {
      YsTodayWidgetIds.nextCourse => _nextCourse(data),
      YsTodayWidgetIds.timeline => _timeline(data),
      YsTodayWidgetIds.readiness => _readiness(data),
      YsTodayWidgetIds.plans => _plans(data),
      YsTodayWidgetIds.courseTasks => _courseTasks(data),
      YsTodayWidgetIds.weekGlance => _weekGlance(data),
      YsTodayWidgetIds.weather => _weather(data),
      _ => _emptyCustom(id),
    };
  }

  Widget _nextCourse(YsTodayBuildContext data) {
    final next = _findNextCourse(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.play_circle_outline, '下一节'),
        const Spacer(),
        Text(
          next?.course.name ?? _emptyFor('next-course', '今天课程已结束'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: data.size == YsTodayWidgetSize.compact ? 15 : 20,
            height: 1.12,
            fontWeight: FontWeight.w800,
            color: widget.theme.text1,
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 5),
          Text(
            '第 ${next.course.startSection}-${next.course.endSection} 节'
            '${next.course.location == null ? '' : ' · ${next.course.location}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: widget.theme.text3),
          ),
        ],
      ],
    );
  }

  Widget _timeline(YsTodayBuildContext data) {
    final limit = data.size.rows > 1 ? 6 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.view_timeline_outlined, '今日时间线'),
        const SizedBox(height: 9),
        if (data.todayCourses.isEmpty)
          _emptyText(_emptyFor('today-timeline', '今天没有课程'))
        else
          for (final course in data.todayCourses.take(limit))
            Expanded(
              child: InkWell(
                onTap: () => widget.onCourseTap?.call(course),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      color: widget.theme.accent,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        course.course.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.text1,
                        ),
                      ),
                    ),
                    Text(
                      '${course.course.startSection}-${course.course.endSection}节',
                      style: TextStyle(fontSize: 10, color: widget.theme.text3),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _readiness(YsTodayBuildContext data) {
    final materials = data.todayCourses
        .expand((course) => course.course.carryItems)
        .fold(<String, YsCourseMaterial>{}, (items, material) {
          items.putIfAbsent(material.name.trim().toLowerCase(), () => material);
          return items;
        })
        .values
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.backpack_outlined, '上课准备'),
        const SizedBox(height: 12),
        if (materials.isEmpty)
          _emptyText(_emptyFor('readiness', '今天没有额外物品'))
        else
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final material in materials)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      material.kind == YsCourseMaterialKind.book
                          ? Icons.menu_book_outlined
                          : Icons.check_circle_outline,
                      size: 15,
                    ),
                    label: Text(
                      material.quantity > 1
                          ? '${material.name} x${material.quantity}'
                          : material.name,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _plans(YsTodayBuildContext data) {
    final limit = data.size.rows > 1 ? 6 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.task_alt_outlined, '今日计划'),
        const SizedBox(height: 9),
        if (data.plans.isEmpty)
          _emptyText(_emptyFor('plans', '还没有安排计划'))
        else
          for (final plan in data.plans.take(limit))
            Expanded(
              child: Row(
                children: [
                  Icon(
                    plan.done ? Icons.check_circle : Icons.circle_outlined,
                    size: 17,
                    color: plan.done ? widget.theme.accent : widget.theme.text3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        decoration:
                            plan.done ? TextDecoration.lineThrough : null,
                        color:
                            plan.done ? widget.theme.text3 : widget.theme.text1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _courseTasks(YsTodayBuildContext data) {
    final tasks = [
      for (final course in data.todayCourses)
        for (final task in course.course.tasks) (course: course, task: task),
    ];
    final limit = data.size.rows > 1 ? 6 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.task_alt_outlined, '课程任务'),
        const SizedBox(height: 9),
        if (tasks.isEmpty)
          _emptyText(_emptyFor('course-tasks', '今天没有课程任务'))
        else
          for (final item in tasks.take(limit))
            Expanded(
              child: Row(
                children: [
                  Icon(
                    item.task.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: item.task.done
                        ? widget.theme.accent
                        : widget.theme.text3,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        decoration:
                            item.task.done ? TextDecoration.lineThrough : null,
                        color: item.task.done
                            ? widget.theme.text3
                            : widget.theme.text1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.course.course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: widget.theme.text3),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _weekGlance(YsTodayBuildContext data) {
    final active =
        data.weekModel.courses.where((course) => course.active).length;
    final days = data.weekModel.courses
        .where((course) => course.active)
        .map((course) => course.weekday)
        .toSet()
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.calendar_view_week_outlined, '本周一览'),
        const Spacer(),
        Row(
          children: [
            _metric('$active', '节次块'),
            const SizedBox(width: 24),
            _metric('$days', '上课日'),
            const SizedBox(width: 24),
            _metric('第 ${data.week}', '当前周'),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _weather(YsTodayBuildContext data) {
    final current = data.weather?.current;
    final daily = data.weather?.weatherForDate(formatDateKey(data.now));
    final kind = current?.kind ?? daily?.kind ?? YsWeatherKind.neutral;
    final temperature = current?.temperatureC;
    if (current == null && daily == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(Icons.location_on_outlined, '今日天气'),
          const Spacer(),
          _emptyText(_emptyFor('weather', '暂无天气信息')),
          const Spacer(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.location_on_outlined, '今日天气'),
        const Spacer(),
        Row(
          children: [
            YsWeatherGlyph(kind: kind, size: 31, color: widget.theme.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temperature == null ? '--°' : '${temperature.round()}°',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: widget.theme.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current?.label ?? daily?.label ?? ysWeatherLabel(kind),
                    style: TextStyle(fontSize: 11, color: widget.theme.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyCustom(String id) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(Icons.extension_outlined, id),
          const Spacer(),
          _emptyText(_emptyFor(id, '请通过 customBuilders 提供内容')),
          const Spacer(),
        ],
      );

  Widget _eyebrow(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 17, color: widget.theme.text3),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: widget.theme.text3,
              ),
            ),
          ),
        ],
      );

  Widget _metric(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: widget.theme.text1,
            ),
          ),
          Text(label,
              style: TextStyle(fontSize: 10, color: widget.theme.text3)),
        ],
      );

  Widget _emptyText(String text) => Text(
        text,
        style: TextStyle(fontSize: 12, color: widget.theme.text3),
      );

  String _emptyFor(String id, String fallback) =>
      widget.emptyTexts[id] ?? widget.emptyText ?? fallback;

  YsDisplayCourse? _findNextCourse(YsTodayBuildContext data) {
    for (final course in data.todayCourses) {
      final section = course.course.endSection;
      if (section > widget.courseTimes.length) return course;
      final parts = widget.courseTimes[section - 1].end.split(':');
      final end = DateTime(
        data.now.year,
        data.now.month,
        data.now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (end.isAfter(data.now)) return course;
    }
    return null;
  }

  String _widgetTitle(String id) => switch (id) {
        YsTodayWidgetIds.nextCourse => '下一节',
        YsTodayWidgetIds.timeline => '今日时间线',
        YsTodayWidgetIds.readiness => '上课准备',
        YsTodayWidgetIds.plans => '今日计划',
        YsTodayWidgetIds.courseTasks => '课程任务',
        YsTodayWidgetIds.weekGlance => '本周一览',
        YsTodayWidgetIds.weather => '今日天气',
        _ => id,
      };

  void _setEditing(bool value) {
    if (_editing == value) return;
    setState(() => _editing = value);
    widget.onLayoutEditing?.call(value);
  }

  void _move(int from, int to) {
    if (from == to || from < 0 || from >= _widgets.length) return;
    final movingId = _widgets[from].id;
    setState(() {
      final item = _widgets.removeAt(from);
      _widgets.insert(to.clamp(0, _widgets.length), item);
    });
    widget.onWidgetMove?.call(movingId, from, to);
    _notifyWidgets();
  }

  void _previewSize(int index, YsTodayWidgetSize size) {
    if (_widgets[index].size == size) return;
    setState(() => _widgets[index] = _widgets[index].copyWith(size: size));
  }

  void _commitSize(
    int index,
    YsTodayWidgetSize size,
    YsTodayResizeCorner corner,
  ) {
    _previewSize(index, size);
    widget.onWidgetResize?.call(_widgets[index].id, size, corner);
    _notifyWidgets();
  }

  void _notifyWidgets() {
    widget.onWidgetsChanged?.call(List.unmodifiable(_widgets));
  }
}

class _TodayResizeHandle extends StatefulWidget {
  const _TodayResizeHandle({
    required this.corner,
    required this.size,
    required this.theme,
    required this.onPreview,
    required this.onCommit,
    required this.onCancel,
    super.key,
  });

  final YsTodayResizeCorner corner;
  final YsTodayWidgetSize size;
  final YsScheduleTheme theme;
  final ValueChanged<YsTodayWidgetSize> onPreview;
  final ValueChanged<YsTodayWidgetSize> onCommit;
  final ValueChanged<YsTodayWidgetSize> onCancel;

  @override
  State<_TodayResizeHandle> createState() => _TodayResizeHandleState();
}

class _TodayResizeHandleState extends State<_TodayResizeHandle> {
  Offset _delta = Offset.zero;
  late YsTodayWidgetSize _origin = widget.size;
  late YsTodayWidgetSize _current = widget.size;

  @override
  Widget build(BuildContext context) {
    final top = widget.corner == YsTodayResizeCorner.topLeft ||
        widget.corner == YsTodayResizeCorner.topRight;
    final left = widget.corner == YsTodayResizeCorner.topLeft ||
        widget.corner == YsTodayResizeCorner.bottomLeft;
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Semantics(
        label: '从${_cornerLabel(widget.corner)}调整组件尺寸',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            _delta = Offset.zero;
            _origin = widget.size;
            _current = widget.size;
          },
          onPanUpdate: (details) {
            _delta += details.delta;
            final horizontal = _delta.dx * (left ? -1 : 1);
            final vertical = _delta.dy * (top ? -1 : 1);
            final columns = horizontal > 28
                ? 2
                : horizontal < -28
                    ? 1
                    : _origin.columns;
            final rows = vertical > 28
                ? 2
                : vertical < -28
                    ? 1
                    : _origin.rows;
            final next = _sizeForDimensions(columns, rows);
            if (next == _current) return;
            _current = next;
            widget.onPreview(next);
          },
          onPanEnd: (_) => widget.onCommit(_current),
          onPanCancel: () => widget.onCancel(_origin),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Transform.rotate(
              angle: switch (widget.corner) {
                YsTodayResizeCorner.topLeft => 0,
                YsTodayResizeCorner.topRight => math.pi / 2,
                YsTodayResizeCorner.bottomRight => math.pi,
                YsTodayResizeCorner.bottomLeft => math.pi * 1.5,
              },
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                size: 18,
                color: widget.theme.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

YsTodayWidgetSize _sizeForDimensions(int columns, int rows) {
  if (columns == 1 && rows == 2) return YsTodayWidgetSize.oneByTwo;
  if (columns == 2 && rows == 1) return YsTodayWidgetSize.twoByOne;
  if (columns == 2 && rows == 2) return YsTodayWidgetSize.twoByTwo;
  return YsTodayWidgetSize.oneByOne;
}

String _cornerLabel(YsTodayResizeCorner corner) => switch (corner) {
      YsTodayResizeCorner.topLeft => '左上角',
      YsTodayResizeCorner.topRight => '右上角',
      YsTodayResizeCorner.bottomLeft => '左下角',
      YsTodayResizeCorner.bottomRight => '右下角',
    };

Color _weatherSurfaceTint(YsWeatherKind kind) => switch (kind) {
      YsWeatherKind.clear => const Color(0xFFFFD477),
      YsWeatherKind.rain ||
      YsWeatherKind.drizzle ||
      YsWeatherKind.storm =>
        const Color(0xFF83B7D8),
      YsWeatherKind.snow => const Color(0xFFDCECF4),
      _ => const Color(0xFFAAB8C5),
    };
