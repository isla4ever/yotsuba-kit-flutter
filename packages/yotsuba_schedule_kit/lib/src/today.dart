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
  String? _selectedWidgetId;

  @override
  void didUpdateWidget(covariant YsToday oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameWidgets(oldWidget.widgets, widget.widgets)) {
      _widgets = List.of(widget.widgets);
      if (!_widgets.any(
        (item) => item.enabled && item.id == _selectedWidgetId,
      )) {
        _selectedWidgetId = null;
      }
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
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(40),
                    minimumSize: const Size.square(40),
                    maximumSize: const Size.square(40),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color:
                          _editing ? widget.theme.accent : widget.theme.border,
                    ),
                    backgroundColor: _editing
                        ? widget.theme.accent.withValues(alpha: 0.1)
                        : widget.theme.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    _editing ? Icons.check : Icons.edit_outlined,
                    size: 20,
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
    final selected = _editing && _selectedWidgetId == config.id;
    final columns = availableWidth >= 760 ? 3 : 2;
    final unit = (availableWidth - (columns - 1) * 10) / columns;
    final span = math.min(config.size.columns, columns);
    final width = span * unit + (span - 1) * 10;
    final height = config.size.rows * 138.0 + (config.size.rows - 1) * 10;
    final body = widget.customBuilders[config.id]?.call(context, data) ??
        _builtInWidget(config.id, data);
    final animatedBody = AnimatedSwitcher(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('${config.id}-${config.size.name}'),
        child: body,
      ),
    );
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
      selected: selected,
      hint: _editing
          ? (selected ? '已选择，长按拖动或从四角调整尺寸' : '点按选择，长按拖动重排')
          : (widget.arrangeable ? '长按进入布局调整' : null),
      child: GestureDetector(
        onLongPress: widget.arrangeable
            ? () => _setEditing(true, selectedWidgetId: config.id)
            : null,
        onTap: () {
          if (_editing) {
            _selectWidget(config.id);
            return;
          }
          widget.onWidgetTap?.call(config.id);
        },
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
              color: selected ? widget.theme.accent : widget.theme.border,
              width: selected ? 1.5 : 1,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: IgnorePointer(
                      ignoring: _editing,
                      child: animatedBody,
                    ),
                  ),
                ),
              ),
              if (selected)
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
    );
    if (!_editing) return tile;
    final draggable = LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 120),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => _selectWidget(config.id),
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

  bool _isCompact(YsTodayBuildContext data) =>
      data.size.columns == 1 && data.size.rows == 1;

  bool _isTall(YsTodayBuildContext data) =>
      data.size.columns == 1 && data.size.rows == 2;

  bool _isWide(YsTodayBuildContext data) =>
      data.size.columns == 2 && data.size.rows == 1;

  int _itemLimit(YsTodayBuildContext data) {
    if (_isCompact(data)) return 1;
    if (_isWide(data)) return 2;
    if (_isTall(data)) return 4;
    return 6;
  }

  Widget _nextCourse(YsTodayBuildContext data) {
    final next = _findNextCourse(data);
    if (_isCompact(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-next-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.play_circle_outline, '下一节'),
            const Spacer(),
            Text(
              next?.course.name ?? _emptyFor('next-course', '今日已结束'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: widget.theme.text1,
              ),
            ),
            if (next != null)
              Text(
                '${next.course.startSection}-${next.course.endSection} 节',
                style: TextStyle(fontSize: 10, color: widget.theme.text3),
              ),
          ],
        ),
      );
    }
    if (_isWide(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-next-wide'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.play_circle_outline, '下一节'),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        next?.course.name ??
                            _emptyFor('next-course', '今天课程已结束'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: widget.theme.text1,
                        ),
                      ),
                      if (next != null)
                        Text(
                          '${next.course.startSection}-${next.course.endSection} 节'
                          '${next.course.location == null ? '' : ' · ${next.course.location}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.theme.text3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (next != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.theme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '${next.course.startSection} 节开始',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    final preview = data.todayCourses.take(_isTall(data) ? 3 : 4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(
          Icons.play_circle_outline,
          _isTall(data) ? '后续课程' : '今日接下来',
        ),
        const SizedBox(height: 12),
        Text(
          next?.course.name ?? _emptyFor('next-course', '今天课程已结束'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 21,
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
        const SizedBox(height: 8),
        Divider(height: 1, color: widget.theme.border),
        const SizedBox(height: 4),
        for (final course in preview)
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${course.course.startSection}节',
                    style: TextStyle(fontSize: 9, color: widget.theme.text3),
                  ),
                ),
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.theme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course.course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.text1,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _timeline(YsTodayBuildContext data) {
    if (_isCompact(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-timeline-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.view_timeline_outlined, '今日课程'),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.todayCourses.length}',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: widget.theme.text1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    '节课程',
                    style: TextStyle(fontSize: 10, color: widget.theme.text3),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      );
    }
    final limit = _itemLimit(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.view_timeline_outlined, '今日时间线'),
        const SizedBox(height: 9),
        if (data.todayCourses.isEmpty)
          _emptyText(_emptyFor('today-timeline', '今天没有课程'))
        else if (_isWide(data))
          Expanded(
            child: Row(
              children: [
                for (var index = 0;
                    index < math.min(limit, data.todayCourses.length);
                    index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.theme.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: widget.theme.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.todayCourses[index].course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.theme.text1,
                                ),
                              ),
                            ),
                            Text(
                              '${data.todayCourses[index].course.startSection}节',
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.theme.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
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
    if (_isCompact(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-readiness-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.backpack_outlined, '上课准备'),
            const Spacer(),
            Text(
              '${materials.length}',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w800,
                color: widget.theme.text1,
              ),
            ),
            Text(
              materials.isEmpty ? '无需额外物品' : materials.first.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: widget.theme.text3),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.backpack_outlined, '上课准备'),
        const SizedBox(height: 12),
        if (materials.isEmpty)
          _emptyText(_emptyFor('readiness', '今天没有额外物品'))
        else
          Expanded(
            child: _isTall(data)
                ? Column(
                    children: [
                      for (final material in materials.take(_itemLimit(data)))
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                material.kind == YsCourseMaterialKind.book
                                    ? Icons.menu_book_outlined
                                    : Icons.check_circle_outline,
                                size: 16,
                                color: widget.theme.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  material.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.theme.text1,
                                  ),
                                ),
                              ),
                              if (material.quantity > 1)
                                Text(
                                  'x${material.quantity}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: widget.theme.text3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  )
                : Wrap(
                    spacing: 7,
                    runSpacing: _isWide(data) ? 5 : 9,
                    children: [
                      for (final material in materials.take(_itemLimit(data)))
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
    final limit = _itemLimit(data);
    final completed = data.plans.where((plan) => plan.done).length;
    if (_isCompact(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-plans-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.task_alt_outlined, '今日计划'),
            const Spacer(),
            Text(
              '$completed/${data.plans.length}',
              style: TextStyle(
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
                color: widget.theme.text1,
              ),
            ),
            Text(
              '已完成',
              style: TextStyle(fontSize: 10, color: widget.theme.text3),
            ),
          ],
        ),
      );
    }
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
    final limit = _itemLimit(data);
    if (_isCompact(data)) {
      final pending = tasks.where((item) => !item.task.done).toList();
      return KeyedSubtree(
        key: const ValueKey('today-course-tasks-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(Icons.task_alt_outlined, '课程任务'),
            const Spacer(),
            Text(
              '${pending.length}',
              style: TextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w800,
                color: widget.theme.text1,
              ),
            ),
            Text(
              pending.isEmpty ? '全部完成' : pending.first.task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: widget.theme.text3),
            ),
          ],
        ),
      );
    }
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
    final counts = List<int>.generate(
      7,
      (index) => data.weekModel.courses
          .where((course) => course.active && course.weekday == index + 1)
          .length,
    );
    final active = counts.fold<int>(0, (total, count) => total + count);
    final days = counts.where((count) => count > 0).length;
    final compact = data.size.columns == 1 && data.size.rows == 1;
    final tall = data.size.columns == 1 && data.size.rows == 2;
    final wide = data.size.columns == 2 && data.size.rows == 1;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(Icons.calendar_view_week_outlined, '本周一览'),
          const Spacer(),
          Row(
            children: [
              _metric('$active', '课程块'),
              const SizedBox(width: 18),
              _metric('第 ${data.week}', '当前周'),
            ],
          ),
          const Spacer(),
        ],
      );
    }

    if (tall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(Icons.calendar_view_week_outlined, '本周节奏'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _metric('$active', '课程块'),
              _metric('$days', '上课日'),
              _metric('第 ${data.week}', '当前周'),
            ],
          ),
          const Spacer(),
          _weekBars(counts, height: 92, showValues: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(Icons.calendar_view_week_outlined, '本周一览'),
        SizedBox(height: wide ? 7 : 12),
        Row(
          children: [
            _metric('$active', '节次块'),
            const SizedBox(width: 24),
            _metric('$days', '上课日'),
            const SizedBox(width: 24),
            _metric('第 ${data.week}', '当前周'),
          ],
        ),
        SizedBox(height: wide ? 7 : 16),
        _weekBars(
          counts,
          height: wide ? 34 : 112,
          showValues: !wide,
        ),
        if (!wide) ...[
          const SizedBox(height: 10),
          Text(
            '本周共 $active 个课程块 · $days 个上课日',
            style: TextStyle(fontSize: 10, color: widget.theme.text2),
          ),
        ],
      ],
    );
  }

  Widget _weekBars(
    List<int> counts, {
    required double height,
    required bool showValues,
  }) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final maxCount = math.max(1, counts.reduce(math.max));
    return Semantics(
      key: const ValueKey('week-glance-chart'),
      label: '本周课程分布',
      image: true,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < counts.length; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      if (showValues)
                        Text(
                          '${counts[index]}',
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.theme.text2,
                          ),
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: counts[index] == 0
                                ? 0.06
                                : math
                                    .max(0.14, counts[index] / maxCount)
                                    .toDouble(),
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  widget.theme.accent,
                                  widget.theme.warning,
                                  0.22,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.theme.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
    final hours = _todayWeatherHours(data);
    final label = current?.label ?? daily?.label ?? ysWeatherLabel(kind);
    final range = daily?.highC == null
        ? null
        : '${daily?.lowC?.round() ?? '--'}~${daily!.highC!.round()}°';

    if (_isCompact(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-weather-compact'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _eyebrow(Icons.location_on_outlined, '今日天气')),
                if (range != null)
                  Text(
                    range,
                    style: TextStyle(fontSize: 9, color: widget.theme.text3),
                  ),
              ],
            ),
            const Spacer(),
            _weatherCurrent(kind, temperature, label),
            const Spacer(),
          ],
        ),
      );
    }

    if (_isWide(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-weather-wide'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _eyebrow(Icons.location_on_outlined, '今日天气')),
                if (range != null)
                  Text(
                    range,
                    style: TextStyle(fontSize: 9, color: widget.theme.text3),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 128,
                    child: _weatherCurrent(kind, temperature, label),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: hours.isEmpty
                        ? _emptyText('暂无逐时预报')
                        : _weatherBars(hours.take(4).toList()),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isTall(data)) {
      return KeyedSubtree(
        key: const ValueKey('today-weather-tall'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _eyebrow(Icons.location_on_outlined, '今日天气')),
                if (range != null)
                  Text(
                    range,
                    style: TextStyle(fontSize: 9, color: widget.theme.text3),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _weatherCurrent(kind, temperature, label, glyphSize: 36),
            const SizedBox(height: 10),
            Divider(height: 1, color: widget.theme.border),
            const SizedBox(height: 4),
            if (hours.isEmpty)
              Expanded(child: Center(child: _emptyText('暂无逐时预报')))
            else
              for (final hour in hours.take(4))
                Expanded(child: _weatherHourRow(hour)),
          ],
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('today-weather-large'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _eyebrow(Icons.location_on_outlined, '今日天气')),
              if (range != null)
                Text(
                  range,
                  style: TextStyle(fontSize: 10, color: widget.theme.text3),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 132,
                  child: _weatherCurrent(
                    kind,
                    temperature,
                    label,
                    glyphSize: 48,
                    temperatureSize: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '逐时变化',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.theme.text2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${math.min(hours.length, 6)} 个时段',
                            style: TextStyle(
                              fontSize: 9,
                              color: widget.theme.text3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: hours.isEmpty
                            ? _emptyText('暂无逐时预报')
                            : _weatherBars(hours.take(6).toList(),
                                showGlyph: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<YsHourlyWeather> _todayWeatherHours(YsTodayBuildContext data) {
    final values = data.weather?.hourly
            .where((value) =>
                value.time.year == data.now.year &&
                value.time.month == data.now.month &&
                value.time.day == data.now.day)
            .toList() ??
        <YsHourlyWeather>[];
    values.sort((first, second) => first.time.compareTo(second.time));
    return values;
  }

  Widget _weatherCurrent(
    YsWeatherKind kind,
    double? temperature,
    String label, {
    double glyphSize = 31,
    double temperatureSize = 24,
  }) =>
      Row(
        children: [
          YsWeatherGlyph(
            kind: kind,
            size: glyphSize,
            color: widget.theme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temperature == null ? '--°' : '${temperature.round()}°',
                  style: TextStyle(
                    fontSize: temperatureSize,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: widget.theme.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: widget.theme.text3),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _weatherHourRow(YsHourlyWeather hour) => Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              _hourLabel(hour.time),
              style: TextStyle(fontSize: 9, color: widget.theme.text3),
            ),
          ),
          YsWeatherGlyph(
            kind: hour.kind,
            size: 18,
            color: widget.theme.accent,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              hour.label ?? ysWeatherLabel(hour.kind),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: widget.theme.text2),
            ),
          ),
          Text(
            hour.temperatureC == null ? '--' : '${hour.temperatureC!.round()}°',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.theme.text1,
            ),
          ),
        ],
      );

  Widget _weatherBars(
    List<YsHourlyWeather> hours, {
    bool showGlyph = false,
  }) {
    final temperatures =
        hours.map((hour) => hour.temperatureC).whereType<double>().toList();
    final low = temperatures.isEmpty ? 0.0 : temperatures.reduce(math.min);
    final high = temperatures.isEmpty ? 0.0 : temperatures.reduce(math.max);
    return Semantics(
      key: const ValueKey('today-weather-hourly-chart'),
      label: '今日逐时天气与温度',
      image: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < hours.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _hourLabel(hours[index].time),
                    style: TextStyle(fontSize: 8, color: widget.theme.text3),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: _temperatureFactor(
                          hours[index].temperatureC,
                          low,
                          high,
                        ),
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.theme.accent.withValues(alpha: 0.68),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showGlyph) ...[
                    const SizedBox(height: 3),
                    YsWeatherGlyph(
                      kind: hours[index].kind,
                      size: 15,
                      color: widget.theme.accent,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    hours[index].temperatureC == null
                        ? '--'
                        : '${hours[index].temperatureC!.round()}°',
                    style: TextStyle(fontSize: 8, color: widget.theme.text2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _temperatureFactor(double? value, double low, double high) {
    if (value == null) return 0.32;
    if (high == low) return 0.58;
    return 0.28 + (value - low) / (high - low) * 0.52;
  }

  String _hourLabel(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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

  void _setEditing(bool value, {String? selectedWidgetId}) {
    final editingChanged = _editing != value;
    final nextSelected = value ? selectedWidgetId : null;
    if (!editingChanged && _selectedWidgetId == nextSelected) return;
    setState(() {
      _editing = value;
      _selectedWidgetId = nextSelected;
    });
    if (editingChanged) {
      widget.onLayoutEditing?.call(value);
    }
  }

  void _selectWidget(String id) {
    if (!_editing || _selectedWidgetId == id) return;
    setState(() => _selectedWidgetId = id);
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
    final alignment = Alignment(left ? -1 : 1, top ? -1 : 1);
    final markerOffset = Offset(left ? -5 : 5, top ? -5 : 5);
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
            child: Align(
              alignment: alignment,
              child: Transform.translate(
                offset: markerOffset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.theme.surface1,
                    border: Border.all(
                      color: Color.lerp(
                        widget.theme.border,
                        widget.theme.accent,
                        0.82,
                      )!,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const SizedBox.square(dimension: 10),
                ),
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
