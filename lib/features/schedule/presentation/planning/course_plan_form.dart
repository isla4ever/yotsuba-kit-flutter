import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';

class CoursePlanForm extends StatefulWidget {
  const CoursePlanForm({
    required this.course,
    required this.termStart,
    required this.totalWeeks,
    required this.onCancel,
    required this.onSave,
    this.initial,
    super.key,
  });

  final Course course;
  final CoursePlan? initial;
  final DateTime termStart;
  final int totalWeeks;
  final VoidCallback onCancel;
  final ValueChanged<CoursePlan> onSave;

  @override
  State<CoursePlanForm> createState() => _CoursePlanFormState();
}

class _CoursePlanFormState extends State<CoursePlanForm> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  final _subtaskDraft = TextEditingController();
  late PlanPriority _priority;
  late int _estimatedMinutes;
  late bool _sessionDeadline;
  int? _sessionWeek;
  DateTime? _dueAt;
  late List<int> _reminderOffsets;
  late bool _calendarSyncEnabled;
  late int _postponeCount;
  late List<CoursePlanSubtask> _subtasks;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _notes = TextEditingController(text: initial?.notes ?? '');
    _priority = initial?.priority ?? PlanPriority.medium;
    _estimatedMinutes = initial?.estimatedMinutes ?? 60;
    _sessionDeadline = initial == null || initial.dueSessionWeek != null;
    _sessionWeek = initial?.dueSessionWeek;
    _dueAt = initial?.dueAt;
    _reminderOffsets = [...?initial?.reminderOffsets];
    if (_reminderOffsets.isEmpty) _reminderOffsets = [1440, 60];
    _calendarSyncEnabled = initial?.calendarSyncEnabled ?? true;
    _postponeCount = initial?.postponeCount ?? 0;
    _subtasks = [...?initial?.subtasks];
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _subtaskDraft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sessions = _futureSessions();
    _sessionWeek ??= sessions.firstOrNull?.$1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        2,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '返回',
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.name,
                      style: TextStyle(fontSize: 11, color: palette.textFaint),
                    ),
                    Text(
                      widget.initial == null ? '新建课程计划' : '编辑课程计划',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _title,
                  autofocus: widget.initial == null,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: '计划名称',
                    hintText: '例如：完成第三章习题',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '说明',
                    hintText: '提交方式、要求或注意事项',
                  ),
                ),
                const SizedBox(height: 12),
                Text('优先级', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 7),
                SegmentedButton<PlanPriority>(
                  segments: const [
                    ButtonSegment(value: PlanPriority.low, label: Text('低')),
                    ButtonSegment(
                      value: PlanPriority.medium,
                      label: Text('普通'),
                    ),
                    ButtonSegment(value: PlanPriority.high, label: Text('高')),
                    ButtonSegment(
                      value: PlanPriority.urgent,
                      label: Text('紧急'),
                    ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (value) =>
                      setState(() => _priority = value.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '预计时长',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '$_estimatedMinutes 分钟',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.scheduleAccent,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _estimatedMinutes.toDouble(),
                  min: 15,
                  max: 240,
                  divisions: 15,
                  label: '$_estimatedMinutes 分钟',
                  onChanged: (value) =>
                      setState(() => _estimatedMinutes = value.round()),
                ),
                const SizedBox(height: 6),
                Text('截止时间', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 7),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.school_outlined, size: 17),
                      label: Text('某次上课'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.event_outlined, size: 17),
                      label: Text('指定时间'),
                    ),
                  ],
                  selected: {_sessionDeadline},
                  onSelectionChanged: (value) =>
                      setState(() => _sessionDeadline = value.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 9),
                if (_sessionDeadline)
                  DropdownButtonFormField<int>(
                    initialValue:
                        sessions.any((item) => item.$1 == _sessionWeek)
                        ? _sessionWeek
                        : null,
                    decoration: const InputDecoration(labelText: '选择要提交的课程'),
                    items: [
                      for (final session in sessions)
                        DropdownMenuItem(
                          value: session.$1,
                          child: Text(
                            '第 ${session.$1} 周 · ${DateFormat('M月d日').format(session.$2)} · 第${widget.course.startSection}-${widget.course.endSection}节',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _sessionWeek = value),
                  )
                else
                  InkWell(
                    onTap: _pickDueAt,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '截止日期与时间'),
                      child: Text(
                        _dueAt == null
                            ? '点击选择'
                            : DateFormat('yyyy年M月d日 HH:mm').format(_dueAt!),
                      ),
                    ),
                  ),
                if (widget.initial != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _postpone,
                      icon: const Icon(Icons.update_rounded, size: 17),
                      label: Text(
                        _postponeCount == 0
                            ? '延期一天'
                            : '延期一天 · 已延期 $_postponeCount 次',
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '子任务',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${_subtasks.length}/20',
                      style: TextStyle(fontSize: 10, color: palette.textFaint),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskDraft,
                        maxLength: 60,
                        onSubmitted: (_) => _addSubtask(),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '拆成更容易完成的小步骤',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: '添加子任务',
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                if (_subtasks.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  for (final subtask in _subtasks)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        value: subtask.completed,
                        title: Text(
                          subtask.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: IconButton(
                          tooltip: '删除子任务',
                          onPressed: () =>
                              setState(() => _subtasks.remove(subtask)),
                          icon: const Icon(Icons.close_rounded, size: 17),
                        ),
                        onChanged: (value) => setState(() {
                          final index = _subtasks.indexOf(subtask);
                          _subtasks[index] = subtask.copyWith(
                            completed: value ?? false,
                          );
                        }),
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                Text('提醒', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final option in const [
                      (1440, '提前一天'),
                      (60, '提前一小时'),
                      (0, '截止时'),
                    ])
                      FilterChip(
                        label: Text(option.$2),
                        selected: _reminderOffsets.contains(option.$1),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _reminderOffsets.add(option.$1);
                          } else {
                            _reminderOffsets.remove(option.$1);
                          }
                        }),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('同步到系统日历', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('导出或订阅日历时包含这项计划'),
                  value: _calendarSyncEnabled,
                  onChanged: (value) =>
                      setState(() => _calendarSyncEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('保存计划'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<(int, DateTime)> _futureSessions() {
    final result = <(int, DateTime)>[];
    final now = DateTime.now().subtract(const Duration(minutes: 1));
    for (
      var week = widget.course.startWeek;
      week <= widget.course.endWeek;
      week++
    ) {
      if (!widget.course.occursInWeek(week)) continue;
      final date = ScheduleEngine.dateForWeekday(
        widget.termStart,
        week,
        widget.course.weekday,
      );
      final parts = courseTimes[widget.course.startSection - 1].start
          .split(':')
          .map(int.parse)
          .toList();
      final due = DateTime(date.year, date.month, date.day, parts[0], parts[1]);
      if (due.isAfter(now)) result.add((week, due));
    }
    return result.take(28).toList();
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(
      () => _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _addSubtask() {
    final value = _subtaskDraft.text.trim();
    if (value.isEmpty || _subtasks.length >= 20) return;
    setState(() {
      _subtasks.add(
        CoursePlanSubtask(
          id: 'subtask-${DateTime.now().microsecondsSinceEpoch}',
          title: value,
          position: _subtasks.length,
        ),
      );
      _subtaskDraft.clear();
    });
  }

  void _postpone() {
    setState(() {
      _sessionDeadline = false;
      _sessionWeek = null;
      _dueAt = (_dueAt ?? widget.initial?.dueAt ?? DateTime.now()).add(
        const Duration(days: 1),
      );
      _postponeCount++;
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final sessions = _futureSessions();
    final selectedSession = _sessionDeadline
        ? sessions.where((item) => item.$1 == _sessionWeek).firstOrNull
        : null;
    final dueAt = selectedSession?.$2 ?? (_sessionDeadline ? null : _dueAt);
    final initial = widget.initial;
    widget.onSave(
      CoursePlan(
        id: initial?.id ?? 'plan-${DateTime.now().microsecondsSinceEpoch}',
        courseId: widget.course.id,
        title: title,
        notes: _notes.text.trim(),
        priority: _priority,
        estimatedMinutes: _estimatedMinutes,
        completed: initial?.completed ?? false,
        dueAt: dueAt,
        dueSessionWeek: selectedSession?.$1,
        dueSessionWeekday: selectedSession == null
            ? null
            : widget.course.weekday,
        dueSessionStartSection: selectedSession == null
            ? null
            : widget.course.startSection,
        dueSessionEndSection: selectedSession == null
            ? null
            : widget.course.endSection,
        scheduledStart: initial?.scheduledStart,
        scheduledEnd: initial?.scheduledEnd,
        reminderOffsets: _reminderOffsets.toSet().toList()
          ..sort((a, b) => b.compareTo(a)),
        calendarSyncEnabled: _calendarSyncEnabled,
        postponeCount: _postponeCount,
        subtasks: [
          for (var index = 0; index < _subtasks.length; index++)
            _subtasks[index].copyWith(position: index),
        ],
        createdAt: initial?.createdAt,
        completedAt: initial?.completedAt,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
