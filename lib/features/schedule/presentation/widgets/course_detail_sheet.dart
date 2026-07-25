import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';

enum CourseDetailAction { edit, delete, plans, materials }

Future<CourseDetailAction?> showCourseDetailSheet(
  BuildContext context, {
  required Course course,
  required List<CoursePlan> plans,
  DailyWeather? weather,
  String weatherHint = '',
}) {
  return showModalBottomSheet<CourseDetailAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _CourseDetailSheet(
      course: course,
      plans: plans,
      weather: weather,
      weatherHint: weatherHint,
    ),
  );
}

class _CourseDetailSheet extends StatelessWidget {
  const _CourseDetailSheet({
    required this.course,
    required this.plans,
    required this.weather,
    required this.weatherHint,
  });

  final Course course;
  final List<CoursePlan> plans;
  final DailyWeather? weather;
  final String weatherHint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final activePlans = plans.where((plan) => !plan.completed).length;
    final day = const [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ][course.weekday - 1];
    final pattern = switch (course.pattern) {
      WeekPattern.every => '每周',
      WeekPattern.odd => '单周',
      WeekPattern.even => '双周',
    };
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 8, 9),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '课程详情',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textFaint,
                          ),
                        ),
                        Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            ),
            Divider(height: 1, color: palette.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _CourseHero(course: course, weather: weather),
                    const SizedBox(height: 10),
                    _InformationGroup(
                      children: [
                        _FactRow(
                          icon: Icons.schedule_outlined,
                          label: '时间',
                          value:
                              '$day · 第 ${course.startSection}-${course.endSection} 节',
                        ),
                        _FactRow(
                          icon: Icons.location_on_outlined,
                          label: '地点',
                          value: course.room.isEmpty ? '暂未安排' : course.room,
                        ),
                        _FactRow(
                          icon: Icons.person_outline_rounded,
                          label: '教师',
                          value: course.teacher.isEmpty
                              ? '暂未安排'
                              : course.teacher,
                        ),
                        _FactRow(
                          icon: Icons.calendar_month_outlined,
                          label: '教学周',
                          value:
                              '第 ${course.startWeek}-${course.endWeek} 周 · $pattern',
                          last: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InformationGroup(
                      children: [
                        _ActionRow(
                          icon: Icons.menu_book_outlined,
                          label: '上课携带',
                          value: course.materials.isEmpty
                              ? '添加教材或必备物品'
                              : course.materials.join('、'),
                          onTap: () => Navigator.pop(
                            context,
                            CourseDetailAction.materials,
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.task_alt_outlined,
                          label: '课程计划 · $activePlans 项待完成',
                          value: activePlans == 0
                              ? '记录作业、报告或复习任务'
                              : '查看进度、截止时间和子任务',
                          last: true,
                          onTap: () =>
                              Navigator.pop(context, CourseDetailAction.plans),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _WeatherHint(weather: weather, hint: weatherHint),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.outlined(
                          tooltip: '删除课程',
                          onPressed: () =>
                              Navigator.pop(context, CourseDetailAction.delete),
                          style: IconButton.styleFrom(
                            foregroundColor: palette.danger,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.pop(context, CourseDetailAction.edit),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('编辑课程'),
                          ),
                        ),
                      ],
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
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course, this.weather});

  final Course course;
  final DailyWeather? weather;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color(course.colorValue);
    final presentation = weather == null
        ? null
        : weatherPresentation(weather!.weatherCode);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(palette.surface, color, 0.14)!,
            palette.surfaceRaised,
          ],
        ),
        border: Border.all(color: Color.lerp(palette.border, color, 0.3)!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '课程概览',
                  style: TextStyle(fontSize: 10, color: palette.textFaint),
                ),
                const SizedBox(height: 2),
                Text(
                  course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (weather != null && presentation != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WeatherGlyph(kind: presentation.kind, size: 28),
                Text(
                  '${weather!.temperatureMax.round()}°',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  presentation.label,
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InformationGroup extends StatelessWidget {
  const _InformationGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: palette.textFaint),
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: palette.textFaint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.scheduleAccent),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textFaint),
          ],
        ),
      ),
    );
  }
}

class _WeatherHint extends StatelessWidget {
  const _WeatherHint({required this.weather, required this.hint});

  final DailyWeather? weather;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final presentation = weather == null
        ? null
        : weatherPresentation(weather!.weatherCode);
    final rain = weather?.precipitationProbability;
    final message = weather == null
        ? (hint.isEmpty ? '该日期天气暂不可用' : hint)
        : '${presentation!.label}，${weather!.temperatureMin.round()}°-${weather!.temperatureMax.round()}°${rain != null && rain >= 40 ? '，降水概率 $rain%，记得带伞' : '，出发前留意体感变化'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (presentation != null)
            WeatherGlyph(kind: presentation.kind, size: 19)
          else
            Icon(Icons.cloud_off_outlined, size: 18, color: palette.textFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, color: palette.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}
