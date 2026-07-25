import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';

Future<void> showDayPlannerSheet(
  BuildContext context, {
  required DateTime date,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _DayPlannerSheet(date: date),
  );
}

class _DayPlannerSheet extends ConsumerStatefulWidget {
  const _DayPlannerSheet({required this.date});

  final DateTime date;

  @override
  ConsumerState<_DayPlannerSheet> createState() => _DayPlannerSheetState();
}

class _DayPlannerSheetState extends ConsumerState<_DayPlannerSheet> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = MediaQuery.of(context);
    final sheetHeight = (media.size.height * 0.82).clamp(420.0, 680.0);
    final dateKey = ScheduleEngine.dateKey(widget.date);
    final tasks = ref
        .watch(scheduleControllerProvider)
        .dayTasks
        .where((task) => task.dateKey == dateKey)
        .toList();
    final weather = ref
        .watch(weatherControllerProvider)
        .weatherForDate(dateKey);
    final done = tasks.where((task) => task.completed).length;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 2, 16, media.viewInsets.bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'M月d日 · EEEE',
                            'zh_CN',
                          ).format(widget.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textFaint,
                          ),
                        ),
                        Text(
                          '当天计划',
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
              const SizedBox(height: 10),
              _DaySummary(tasks: tasks, done: done, weather: weather),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      autofocus: tasks.isEmpty,
                      maxLength: 80,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '添加今天要完成的事',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '添加计划',
                    onPressed: _add,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: palette.scheduleAccent,
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: tasks.isEmpty
                    ? _EmptyDay(date: widget.date)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 7),
                        itemBuilder: (context, index) =>
                            _TaskTile(task: tasks[index], onEdit: _editTask),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _add() {
    final value = _composer.text.trim();
    if (value.isEmpty) return;
    ref
        .read(scheduleControllerProvider.notifier)
        .addDayTask(widget.date, value);
    _composer.clear();
  }

  Future<void> _editTask(DayTask task) async {
    final controller = TextEditingController(text: task.title);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑当天计划'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) {
      ref
          .read(scheduleControllerProvider.notifier)
          .updateDayTask(task.id, value);
    }
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.tasks, required this.done, this.weather});

  final List<DayTask> tasks;
  final int done;
  final DailyWeather? weather;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final presentation = weather == null
        ? null
        : weatherPresentation(weather!.weatherCode);
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当天进度',
                  style: TextStyle(fontSize: 11, color: palette.textFaint),
                ),
                Text(
                  '$done / ${tasks.length}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (weather != null && presentation != null)
            Row(
              children: [
                WeatherGlyph(kind: presentation.kind, size: 27),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${weather!.temperatureMin.round()}° / ${weather!.temperatureMax.round()}°',
                      style: TextStyle(fontSize: 11, color: palette.textSoft),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              '天气暂不可用',
              style: TextStyle(fontSize: 11, color: palette.textFaint),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.onEdit});

  final DayTask task;
  final ValueChanged<DayTask> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final controller = ref.read(scheduleControllerProvider.notifier);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
      decoration: BoxDecoration(
        color: task.completed ? palette.surfaceMuted : palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: (_) => controller.toggleDayTask(task.id),
          ),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 14,
                color: task.completed ? palette.textFaint : palette.text,
                decoration: task.completed ? TextDecoration.lineThrough : null,
              ),
              child: Text(task.title),
            ),
          ),
          IconButton(
            tooltip: '编辑',
            onPressed: () => onEdit(task),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: () => controller.deleteDayTask(task.id),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: palette.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded, size: 34, color: palette.textFaint),
            const SizedBox(height: 7),
            const Text(
              '这一天还没有计划',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '从一件能完成的小事开始',
              style: TextStyle(fontSize: 11, color: palette.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
