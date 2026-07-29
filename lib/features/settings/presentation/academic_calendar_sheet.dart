import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/data/calendar/china_holiday_repository.dart';
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

Future<void> showAcademicCalendarSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: appModalAnimationStyle,
    builder: (context) => const _AcademicCalendarSheet(),
  );
}

class _AcademicCalendarSheet extends ConsumerStatefulWidget {
  const _AcademicCalendarSheet();

  @override
  ConsumerState<_AcademicCalendarSheet> createState() =>
      _AcademicCalendarSheetState();
}

class _AcademicCalendarSheetState
    extends ConsumerState<_AcademicCalendarSheet> {
  var _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleControllerProvider);
    final palette = context.palette;
    final end = schedule.termStart.add(
      Duration(days: schedule.totalWeeks * 7 - 1),
    );
    final visibleOverrides = schedule.dayOverrides.where((item) {
      final date = item.date;
      return !date.isBefore(schedule.termStart) && !date.isAfter(end);
    }).toList();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '学期日历',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '开学日期、节假日与补班统一影响课表和今日',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _TermCard(
                    start: schedule.termStart,
                    weeks: schedule.totalWeeks,
                    onEdit: () => _editTerm(schedule),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '日期调整',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _refreshing
                            ? null
                            : () => _refreshHolidays(schedule),
                        icon: _refreshing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 17),
                        label: const Text('刷新节假日'),
                      ),
                      IconButton(
                        tooltip: '添加日期调整',
                        onPressed: () => _editOverride(),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  Text(
                    '在线数据来自国务院公告整理项目；学校临时调课可手工覆盖。补班需指定按星期几上课。',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: palette.textFaint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (visibleOverrides.isEmpty)
                    _EmptyCalendar(onAdd: () => _editOverride())
                  else
                    ...visibleOverrides.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OverrideTile(
                          value: item,
                          onEdit: () => _editOverride(initial: item),
                          onDelete: () => ref
                              .read(scheduleControllerProvider.notifier)
                              .deleteDayOverride(item.dateKey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTerm(ScheduleState schedule) async {
    var start = schedule.termStart;
    var weeks = schedule.totalWeeks;
    final result = await showDialog<(DateTime, int)>(
      context: context,
      animationStyle: appModalAnimationStyle,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('学期范围'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开学周一'),
                subtitle: Text(DateFormat('yyyy年M月d日').format(start)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime(start.year - 2),
                    lastDate: DateTime(start.year + 2),
                  );
                  if (picked != null) {
                    setDialogState(() => start = picked);
                  }
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: weeks,
                decoration: const InputDecoration(labelText: '教学周数'),
                items: [
                  for (var value = 12; value <= 24; value++)
                    DropdownMenuItem(value: value, child: Text('$value 周')),
                ],
                onChanged: (value) =>
                    setDialogState(() => weeks = value ?? weeks),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (start, weeks)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      ref
          .read(scheduleControllerProvider.notifier)
          .updateAcademicTerm(result.$1, result.$2);
    }
  }

  Future<void> _refreshHolidays(ScheduleState schedule) async {
    setState(() => _refreshing = true);
    final end = schedule.termStart.add(
      Duration(days: schedule.totalWeeks * 7 - 1),
    );
    try {
      final values = await const ChinaHolidayRepository().fetchYears({
        schedule.termStart.year,
        end.year,
      });
      ref
          .read(scheduleControllerProvider.notifier)
          .replaceRemoteDayOverrides(values);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已更新 ${values.length} 条节假日与补班记录')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('节假日刷新失败，已保留现有配置')));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _editOverride({AcademicDayOverride? initial}) async {
    var date = initial?.date ?? DateTime.now();
    var kind = initial?.kind ?? AcademicDayKind.holiday;
    var sourceWeekday = initial?.sourceWeekday ?? 1;
    final name = TextEditingController(text: initial?.name ?? '校历调整');
    final result = await showDialog<AcademicDayOverride>(
      context: context,
      animationStyle: appModalAnimationStyle,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initial == null ? '添加日期调整' : '编辑日期调整'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('日期'),
                  subtitle: Text(DateFormat('yyyy年M月d日').format(date)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(date.year - 2),
                      lastDate: DateTime(date.year + 2),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                ),
                SegmentedButton<AcademicDayKind>(
                  segments: const [
                    ButtonSegment(
                      value: AcademicDayKind.holiday,
                      label: Text('停课/放假'),
                      icon: Icon(Icons.beach_access_outlined),
                    ),
                    ButtonSegment(
                      value: AcademicDayKind.makeUp,
                      label: Text('补班'),
                      icon: Icon(Icons.event_repeat_outlined),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (value) =>
                      setDialogState(() => kind = value.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                if (kind == AcademicDayKind.makeUp)
                  DropdownButtonFormField<int>(
                    initialValue: sourceWeekday,
                    decoration: const InputDecoration(labelText: '按哪天课程上课'),
                    items: [
                      for (var day = 1; day <= 7; day++)
                        DropdownMenuItem(
                          value: day,
                          child: Text('星期${_dayName(day)}'),
                        ),
                    ],
                    onChanged: (value) => setDialogState(
                      () => sourceWeekday = value ?? sourceWeekday,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                AcademicDayOverride(
                  dateKey: DateFormat('yyyy-MM-dd').format(date),
                  kind: kind,
                  name: name.text.trim().isEmpty ? '校历调整' : name.text.trim(),
                  sourceWeekday: kind == AcademicDayKind.makeUp
                      ? sourceWeekday
                      : null,
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (result != null) {
      ref.read(scheduleControllerProvider.notifier).upsertDayOverride(result);
    }
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.start,
    required this.weeks,
    required this.onEdit,
  });

  final DateTime start;
  final int weeks;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final end = start.add(Duration(days: weeks * 7 - 1));
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_outlined, color: palette.scheduleAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前学期',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${DateFormat('yyyy.M.d').format(start)} - ${DateFormat('yyyy.M.d').format(end)} · $weeks 周',
                    style: TextStyle(fontSize: 11, color: palette.textSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: palette.textFaint),
          ],
        ),
      ),
    );
  }
}

class _OverrideTile extends StatelessWidget {
  const _OverrideTile({
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  final AcademicDayOverride value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final makeUp = value.kind == AcademicDayKind.makeUp;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: makeUp
                  ? palette.warning.withValues(alpha: 0.14)
                  : palette.todayAccentSoft,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              makeUp ? Icons.event_repeat_outlined : Icons.celebration_outlined,
              size: 20,
              color: makeUp ? palette.warning : palette.todayAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('M月d日 E', 'zh_CN').format(value.date)} · ${value.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  makeUp
                      ? value.sourceWeekday == null
                            ? '补班 · 请指定对应课程日'
                            : '补班 · 按星期${_dayName(value.sourceWeekday!)}上课'
                      : '停课/放假',
                  style: TextStyle(fontSize: 10, color: palette.textFaint),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '编辑',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptyCalendar extends StatelessWidget {
  const _EmptyCalendar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onAdd,
    icon: const Icon(Icons.add_rounded),
    label: const Text('添加本学期日期调整'),
    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
  );
}

String _dayName(int day) => const ['一', '二', '三', '四', '五', '六', '日'][day - 1];
