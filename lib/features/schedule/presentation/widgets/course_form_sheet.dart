import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';

Future<Course?> showCourseFormSheet(
  BuildContext context, {
  required int currentWeek,
  required int totalWeeks,
  Course? initial,
  int? initialWeekday,
  int? initialStartSection,
  int? initialEndSection,
}) {
  return showModalBottomSheet<Course>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _CourseForm(
      currentWeek: currentWeek,
      totalWeeks: totalWeeks,
      initial: initial,
      initialWeekday: initialWeekday,
      initialStartSection: initialStartSection,
      initialEndSection: initialEndSection,
    ),
  );
}

class _CourseForm extends StatefulWidget {
  const _CourseForm({
    required this.currentWeek,
    required this.totalWeeks,
    this.initial,
    this.initialWeekday,
    this.initialStartSection,
    this.initialEndSection,
  });

  final int currentWeek;
  final int totalWeeks;
  final Course? initial;
  final int? initialWeekday;
  final int? initialStartSection;
  final int? initialEndSection;

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  late final TextEditingController _name;
  late final TextEditingController _teacher;
  late final TextEditingController _room;
  late int _weekday;
  late int _startSection;
  late int _endSection;
  late int _startWeek;
  late int _endWeek;
  late WeekPattern _pattern;
  late int _colorValue;

  static const _colors = [
    0xFF2C8B7F,
    0xFF5874B8,
    0xFFE56B4A,
    0xFF9C6DB0,
    0xFFCA8A2C,
    0xFF30779A,
    0xFF71853E,
    0xFFB45C72,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _teacher = TextEditingController(text: initial?.teacher ?? '');
    _room = TextEditingController(text: initial?.room ?? '');
    _weekday = initial?.weekday ?? widget.initialWeekday ?? 1;
    _startSection = initial?.startSection ?? widget.initialStartSection ?? 1;
    _endSection =
        initial?.endSection ?? widget.initialEndSection ?? _startSection;
    _startWeek = initial?.startWeek ?? widget.currentWeek;
    _endWeek = initial?.endWeek ?? widget.totalWeeks;
    _pattern = initial?.pattern ?? WeekPattern.every;
    _colorValue = initial?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本地课程',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textFaint,
                          ),
                        ),
                        Text(
                          widget.initial == null ? '新增课程' : '编辑课程',
                          style: Theme.of(context).textTheme.titleLarge,
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
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: widget.initial == null,
                      maxLength: 24,
                      decoration: const InputDecoration(labelText: '课程名称'),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _teacher,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              labelText: '教师',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: TextField(
                            controller: _room,
                            maxLength: 24,
                            decoration: const InputDecoration(
                              labelText: '教室',
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<int>(
                      initialValue: _weekday,
                      decoration: const InputDecoration(labelText: '星期'),
                      items: [
                        for (var day = 1; day <= 7; day++)
                          DropdownMenuItem(
                            value: day,
                            child: Text('星期${_dayName(day)}'),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _weekday = value ?? 1),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _startSection,
                            decoration: const InputDecoration(
                              labelText: '开始节次',
                            ),
                            items: [
                              for (
                                var section = 1;
                                section <= courseTimes.length;
                                section++
                              )
                                DropdownMenuItem(
                                  value: section,
                                  child: Text('第 $section 节'),
                                ),
                            ],
                            onChanged: (value) => setState(() {
                              _startSection = value ?? 1;
                              if (_endSection < _startSection) {
                                _endSection = _startSection;
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(_endSection),
                            initialValue: _endSection,
                            decoration: const InputDecoration(
                              labelText: '结束节次',
                            ),
                            items: [
                              for (
                                var section = _startSection;
                                section <= courseTimes.length;
                                section++
                              )
                                DropdownMenuItem(
                                  value: section,
                                  child: Text('第 $section 节'),
                                ),
                            ],
                            onChanged: (value) => setState(
                              () => _endSection = value ?? _startSection,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _startWeek,
                            decoration: const InputDecoration(labelText: '开始周'),
                            items: [
                              for (
                                var week = 1;
                                week <= widget.totalWeeks;
                                week++
                              )
                                DropdownMenuItem(
                                  value: week,
                                  child: Text('第 $week 周'),
                                ),
                            ],
                            onChanged: (value) => setState(() {
                              _startWeek = value ?? 1;
                              if (_endWeek < _startWeek) _endWeek = _startWeek;
                            }),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(_endWeek),
                            initialValue: _endWeek,
                            decoration: const InputDecoration(labelText: '结束周'),
                            items: [
                              for (
                                var week = _startWeek;
                                week <= widget.totalWeeks;
                                week++
                              )
                                DropdownMenuItem(
                                  value: week,
                                  child: Text('第 $week 周'),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _endWeek = value ?? _startWeek),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SegmentedButton<WeekPattern>(
                      segments: const [
                        ButtonSegment(
                          value: WeekPattern.every,
                          label: Text('每周'),
                        ),
                        ButtonSegment(
                          value: WeekPattern.odd,
                          label: Text('单周'),
                        ),
                        ButtonSegment(
                          value: WeekPattern.even,
                          label: Text('双周'),
                        ),
                      ],
                      selected: {_pattern},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _pattern = value.first),
                    ),
                    const SizedBox(height: 14),
                    Text('课程颜色', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final value in _colors)
                          InkWell(
                            onTap: () => setState(() => _colorValue = value),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(value),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _colorValue == value
                                      ? palette.text
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: _colorValue == value
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                    widget.initial == null
                        ? Icons.add_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(widget.initial == null ? '添加到课表' : '保存课程'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final initial = widget.initial;
    Navigator.pop(
      context,
      Course(
        id: initial?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        teacher: _teacher.text.trim(),
        room: _room.text.trim(),
        weekday: _weekday,
        startSection: _startSection,
        endSection: _endSection,
        startWeek: _startWeek,
        endWeek: _endWeek,
        pattern: _pattern,
        colorValue: _colorValue,
        isCustom: initial?.isCustom ?? true,
        materials: initial?.materials ?? const [],
      ),
    );
  }
}

String _dayName(int day) => const ['一', '二', '三', '四', '五', '六', '日'][day - 1];
