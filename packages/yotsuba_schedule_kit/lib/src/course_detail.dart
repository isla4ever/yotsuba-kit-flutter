import 'package:flutter/material.dart';

import 'config.dart';
import 'engine.dart';
import 'models.dart';
import 'sheet.dart';
import 'theme.dart';
import 'weather.dart';

Future<void> showYsCourseDetail({
  required BuildContext context,
  required YsDisplayCourse course,
  List<YsDisplayCourse> stack = const [],
  List<YsCourseTime> courseTimes = standardCourseTimes,
  DateTime? date,
  YsDailyWeather? weather,
  YsScheduleTheme theme = YsScheduleTheme.light,
  YsCourseDetailConfig detail = const YsCourseDetailConfig(),
  YsSheetConfig sheets = const YsSheetConfig(),
  ValueChanged<YsDisplayCourse>? onShare,
  ValueChanged<YsDisplayCourse>? onEdit,
  ValueChanged<YsDisplayCourse>? onRemove,
  ValueChanged<YsDetailLayout>? onLayoutChanged,
}) async {
  final layout = ValueNotifier(detail.layout);
  final selected = ValueNotifier<YsDisplayCourse?>(
    stack.length > 1 ? null : course,
  );
  await showYsAdaptiveSheet<void>(
    context: context,
    title: '课程详情',
    icon: Icons.menu_book_outlined,
    kind: YsSheetKind.courseDetail,
    theme: theme,
    config: sheets,
    headerActionsBuilder: detail.adjustable
        ? (context, placement) => [
              ValueListenableBuilder<YsDetailLayout>(
                valueListenable: layout,
                builder: (context, value, child) =>
                    PopupMenuButton<YsDetailLayout>(
                  tooltip: '切换详情档位',
                  initialValue: value,
                  onSelected: (next) {
                    layout.value = next;
                    onLayoutChanged?.call(next);
                  },
                  icon: const Icon(Icons.density_medium, size: 19),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: YsDetailLayout.compact,
                      child: Text('精简详情'),
                    ),
                    PopupMenuItem(
                      value: YsDetailLayout.standard,
                      child: Text('适中详情'),
                    ),
                    PopupMenuItem(
                      value: YsDetailLayout.full,
                      child: Text('全面详情'),
                    ),
                  ],
                ),
              ),
            ]
        : null,
    builder: (context, placement) => ValueListenableBuilder<YsDisplayCourse?>(
      valueListenable: selected,
      builder: (context, selectedCourse, child) => AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.045, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: selectedCourse == null
            ? _YsOverlapPicker(
                key: const ValueKey('overlap-picker'),
                courses: stack,
                theme: theme,
                onSelected: (value) => selected.value = value,
              )
            : Column(
                key: ValueKey('course-detail-${selectedCourse.displayId}'),
                children: [
                  if (stack.length > 1)
                    SizedBox(
                      height: 42,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => selected.value = null,
                          icon: const Icon(Icons.arrow_back, size: 17),
                          label: const Text('返回重叠课程'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ValueListenableBuilder<YsDetailLayout>(
                      valueListenable: layout,
                      builder: (context, value, child) => YsCourseDetailPanel(
                        course: selectedCourse,
                        stack: stack,
                        courseTimes: courseTimes,
                        date: date,
                        weather: weather,
                        theme: theme,
                        config: detail.copyWith(layout: value),
                        onShare: onShare,
                        onEdit: onEdit,
                        onRemove: onRemove,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
  layout.dispose();
  selected.dispose();
}

class _YsOverlapPicker extends StatelessWidget {
  const _YsOverlapPicker({
    required this.courses,
    required this.theme,
    required this.onSelected,
    super.key,
  });

  final List<YsDisplayCourse> courses;
  final YsScheduleTheme theme;
  final ValueChanged<YsDisplayCourse> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Text(
          '该时段有 ${courses.length} 门课程，选择一门查看详情',
          style: TextStyle(fontSize: 12, color: theme.text3),
        ),
        const SizedBox(height: 10),
        for (final course in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: theme.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(color: theme.border),
              ),
              child: ListTile(
                onTap: () => onSelected(course),
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(
                  course.course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [course.course.location, course.course.teacher]
                      .whereType<String>()
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ],
    );
  }
}

class YsCourseDetailPanel extends StatelessWidget {
  const YsCourseDetailPanel({
    required this.course,
    this.stack = const [],
    this.courseTimes = standardCourseTimes,
    this.date,
    this.weather,
    this.theme = YsScheduleTheme.light,
    this.config = const YsCourseDetailConfig(),
    this.onShare,
    this.onEdit,
    this.onRemove,
    super.key,
  });

  final YsDisplayCourse course;
  final List<YsDisplayCourse> stack;
  final List<YsCourseTime> courseTimes;
  final DateTime? date;
  final YsDailyWeather? weather;
  final YsScheduleTheme theme;
  final YsCourseDetailConfig config;
  final ValueChanged<YsDisplayCourse>? onShare;
  final ValueChanged<YsDisplayCourse>? onEdit;
  final ValueChanged<YsDisplayCourse>? onRemove;

  @override
  Widget build(BuildContext context) {
    final fields = config.fields?.toSet() ?? _defaultFields(config.layout);
    final color = YsCourseColorResolver(theme).resolve(
      course.course.name,
      explicit: course.course.color,
    );
    return Column(
      children: [
        _hero(color),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              if (fields.contains(YsDetailField.time))
                _row(Icons.schedule_outlined, '时间', _timeText()),
              if (fields.contains(YsDetailField.weeks))
                _row(Icons.date_range_outlined, '周次', _weekText()),
              if (fields.contains(YsDetailField.location))
                _row(
                  Icons.location_on_outlined,
                  '地点',
                  _valueOrEmpty(course.course.location, YsDetailField.location),
                ),
              if (fields.contains(YsDetailField.teacher))
                _row(
                  Icons.person_outline,
                  '教师',
                  _valueOrEmpty(course.course.teacher, YsDetailField.teacher),
                ),
              if (fields.contains(YsDetailField.weather))
                _row(
                  weather == null
                      ? Icons.cloud_outlined
                      : ysWeatherIcon(weather!.kind),
                  '天气',
                  weather == null
                      ? _emptyFor(YsDetailField.weather)
                      : '${weather!.label ?? ysWeatherLabel(weather!.kind)}'
                          '${weather!.lowC == null ? '' : ' ${weather!.lowC!.round()}°'}'
                          '${weather!.highC == null ? '' : ' / ${weather!.highC!.round()}°'}',
                ),
              if (fields.contains(YsDetailField.note))
                _section(
                  '备注',
                  _valueOrEmpty(course.course.note, YsDetailField.note),
                ),
              if (fields.contains(YsDetailField.materials))
                _section(
                  '记得带',
                  course.course.carryItems.isEmpty
                      ? _emptyFor(YsDetailField.materials)
                      : course.course.carryItems.map((item) {
                          final quantity =
                              item.quantity > 1 ? ' x${item.quantity}' : '';
                          return '${item.name}$quantity';
                        }).join(' · '),
                ),
              if (fields.contains(YsDetailField.books))
                _section(
                  '课本',
                  course.course.books.isEmpty
                      ? _emptyFor(YsDetailField.books)
                      : course.course.books.map((book) {
                          final author = book.author?.trim();
                          return author == null || author.isEmpty
                              ? book.title
                              : '${book.title} · $author';
                        }).join('\n'),
                ),
              if (fields.contains(YsDetailField.tasks))
                _section(
                  '课程任务',
                  course.course.tasks.isEmpty
                      ? _emptyFor(YsDetailField.tasks)
                      : course.course.tasks.map((task) {
                          final state = task.done ? '已完成' : '待完成';
                          return '${task.title} · $state';
                        }).join('\n'),
                ),
              if (config.layout == YsDetailLayout.full && stack.length > 1)
                _overlapSection(),
              if (config.actions.isNotEmpty) ...[
                const SizedBox(height: 18),
                _actions(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero(Color color) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Container(
            width: 9,
            height: config.layout == YsDetailLayout.compact ? 44 : 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: config.layout == YsDetailLayout.compact ? 19 : 23,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: theme.text1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    if (date != null) '${date!.month}月${date!.day}日',
                    '星期${const [
                      '一',
                      '二',
                      '三',
                      '四',
                      '五',
                      '六',
                      '日'
                    ][course.weekday - 1]}',
                    if (course.isMakeup) course.makeupName ?? '补班',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: theme.text2),
                ),
              ],
            ),
          ),
          if (weather != null)
            YsWeatherGlyph(
              kind: weather!.kind,
              size: 28,
              color: theme.text2,
            ),
        ],
      ),
    );
    return switch (config.hero) {
      YsDetailHero.courseColor => ColoredBox(
          color: Color.lerp(theme.surface1, color, 0.12)!,
          child: content,
        ),
      YsDetailHero.weather when weather != null => SizedBox(
          height: config.layout == YsDetailLayout.compact ? 84 : 100,
          child: YsWeatherScene(
            kind: weather!.kind,
            theme: theme,
            reduceMotion: true,
            child: content,
          ),
        ),
      _ => ColoredBox(color: theme.surface2, child: content),
    };
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.text3),
          const SizedBox(width: 11),
          SizedBox(
            width: 52,
            child:
                Text(label, style: TextStyle(fontSize: 12, color: theme.text3)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: theme.text1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface2,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.text3,
            ),
          ),
          const SizedBox(height: 5),
          Text(body, style: TextStyle(fontSize: 13, color: theme.text1)),
        ],
      ),
    );
  }

  Widget _overlapSection() => _section(
        '同一时段还有 ${stack.length - 1} 门课',
        stack.map((item) => item.course.name).join(' · '),
      );

  Widget _actions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (config.actions.contains(YsDetailAction.share))
          FilledButton.tonalIcon(
            onPressed: onShare == null ? null : () => onShare!(course),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('分享'),
          ),
        if (config.actions.contains(YsDetailAction.edit))
          FilledButton.tonalIcon(
            onPressed: onEdit == null ? null : () => onEdit!(course),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('编辑'),
          ),
        if (config.actions.contains(YsDetailAction.remove))
          TextButton.icon(
            onPressed: onRemove == null ? null : () => onRemove!(course),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除'),
          ),
      ],
    );
  }

  Set<YsDetailField> _defaultFields(YsDetailLayout layout) => switch (layout) {
        YsDetailLayout.compact => {
            YsDetailField.time,
            YsDetailField.location,
            YsDetailField.weather,
          },
        YsDetailLayout.standard => {
            YsDetailField.time,
            YsDetailField.weeks,
            YsDetailField.location,
            YsDetailField.teacher,
            YsDetailField.weather,
            YsDetailField.materials,
            YsDetailField.books,
            YsDetailField.tasks,
          },
        YsDetailLayout.full => YsDetailField.values.toSet(),
      };

  String _timeText() {
    final start = course.course.startSection;
    final end = course.course.endSection;
    if (start <= courseTimes.length && end <= courseTimes.length) {
      return '第 $start-$end 节 · ${courseTimes[start - 1].start}-${courseTimes[end - 1].end}';
    }
    return '第 $start-$end 节';
  }

  String _weekText() {
    final parity = switch (course.course.parity) {
      YsWeekParity.odd => '（单周）',
      YsWeekParity.even => '（双周）',
      YsWeekParity.every => '',
    };
    return '第 ${course.course.startWeek}-${course.course.endWeek} 周$parity';
  }

  String _emptyFor(YsDetailField field) =>
      config.emptyTexts[field] ?? config.emptyText;

  String _valueOrEmpty(String? value, YsDetailField field) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? _emptyFor(field)
        : normalized;
  }
}
