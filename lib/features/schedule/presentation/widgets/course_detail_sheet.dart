import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

enum CourseDetailAction { share, edit, delete, plans, materials }

Future<CourseDetailAction?> showCourseDetailSheet(
  BuildContext context, {
  required Course course,
  required List<CoursePlan> plans,
  DailyWeather? weather,
  YsDetailHero hero = YsDetailHero.weather,
  YsDetailLayout layout = YsDetailLayout.standard,
  bool showActions = true,
  YsSheetPlacement placement = YsSheetPlacement.bottom,
  bool glass = true,
  bool reduceMotion = false,
}) {
  final body = _CourseDetailSheet(
    course: course,
    plans: plans,
    weather: weather,
    hero: hero,
    layout: layout,
    showActions: showActions,
  );
  if (placement == YsSheetPlacement.bottom) {
    return showModalBottomSheet<CourseDetailAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      sheetAnimationStyle: reduceMotion
          ? const AnimationStyle(
              duration: Duration.zero,
              reverseDuration: Duration.zero,
            )
          : appModalAnimationStyle,
      builder: (context) => _BottomDetailFrame(glass: glass, child: body),
    );
  }
  return showGeneralDialog<CourseDetailAction>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: '关闭课程详情',
    barrierColor: Colors.black.withValues(alpha: 0.34),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) =>
        _DetailDialogFrame(placement: placement, glass: glass, child: body),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final begin = placement == YsSheetPlacement.right
          ? const Offset(0.08, 0)
          : const Offset(0, 0.025);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _BottomDetailFrame extends StatelessWidget {
  const _BottomDetailFrame({required this.glass, required this.child});

  final bool glass;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget surface = Material(
      color: palette.surface.withValues(alpha: glass ? 0.9 : 1),
      surfaceTintColor: Colors.transparent,
      child: child,
    );
    if (glass) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: surface,
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: surface,
    );
  }
}

class _DetailDialogFrame extends StatelessWidget {
  const _DetailDialogFrame({
    required this.placement,
    required this.glass,
    required this.child,
  });

  final YsSheetPlacement placement;
  final bool glass;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = MediaQuery.sizeOf(context);
    final right = placement == YsSheetPlacement.right;
    final radius = right
        ? const BorderRadius.horizontal(left: Radius.circular(14))
        : BorderRadius.circular(12);
    Widget surface = Material(
      color: palette.surface.withValues(alpha: glass ? 0.9 : 1),
      surfaceTintColor: Colors.transparent,
      child: child,
    );
    if (glass) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: surface,
      );
    }
    return SafeArea(
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.center,
        child: Padding(
          padding: right
              ? const EdgeInsets.symmetric(vertical: 10)
              : const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: right ? size.width.clamp(0, 390) : 0,
              maxWidth: right ? 390 : 380,
              maxHeight: right ? size.height - 20 : size.height * 0.86,
            ),
            child: ClipRRect(borderRadius: radius, child: surface),
          ),
        ),
      ),
    );
  }
}

class _CourseDetailSheet extends StatelessWidget {
  const _CourseDetailSheet({
    required this.course,
    required this.plans,
    required this.weather,
    required this.hero,
    required this.layout,
    required this.showActions,
  });

  final Course course;
  final List<CoursePlan> plans;
  final DailyWeather? weather;
  final YsDetailHero hero;
  final YsDetailLayout layout;
  final bool showActions;

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
                    _CourseHero(
                      course: course,
                      weather: weather,
                      hero: hero,
                      layout: layout,
                    ),
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
                        if (layout != YsDetailLayout.compact)
                          _FactRow(
                            icon: Icons.person_outline_rounded,
                            label: '教师',
                            value: course.teacher.isEmpty
                                ? '暂未安排'
                                : course.teacher,
                          ),
                        if (layout != YsDetailLayout.compact)
                          _FactRow(
                            icon: Icons.calendar_month_outlined,
                            label: '教学周',
                            value:
                                '第 ${course.startWeek}-${course.endWeek} 周 · $pattern',
                            last: true,
                          ),
                      ],
                    ),
                    if (layout != YsDetailLayout.compact)
                      const SizedBox(height: 10),
                    if (layout != YsDetailLayout.compact)
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
                            onTap: () => Navigator.pop(
                              context,
                              CourseDetailAction.plans,
                            ),
                          ),
                        ],
                      ),
                    if (showActions) const SizedBox(height: 12),
                    if (showActions)
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: '分享课程',
                            onPressed: () => Navigator.pop(
                              context,
                              CourseDetailAction.share,
                            ),
                            icon: const Icon(Icons.ios_share_rounded),
                          ),
                          const SizedBox(width: 9),
                          IconButton.outlined(
                            tooltip: '删除课程',
                            onPressed: () => Navigator.pop(
                              context,
                              CourseDetailAction.delete,
                            ),
                            style: IconButton.styleFrom(
                              foregroundColor: palette.danger,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(
                                context,
                                CourseDetailAction.edit,
                              ),
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
  const _CourseHero({
    required this.course,
    required this.hero,
    required this.layout,
    this.weather,
  });

  final Course course;
  final YsDetailHero hero;
  final YsDetailLayout layout;
  final DailyWeather? weather;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color(course.colorValue);
    final presentation = weather == null
        ? null
        : weatherPresentation(weather!.weatherCode);
    final temperatureText = weather == null
        ? null
        : weather!.temperatureMin == weather!.temperatureMax
        ? '${weather!.temperatureMax.round()}°'
        : '${weather!.temperatureMin.round()}~${weather!.temperatureMax.round()}°';
    final weatherKind = presentation?.kind;
    final full = layout == YsDetailLayout.full;
    final compact = layout == YsDetailLayout.compact;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 72 : (full ? 108 : 88)),
      padding: EdgeInsets.all(full ? 16 : (compact ? 11 : 13)),
      decoration: BoxDecoration(
        color: hero == YsDetailHero.plain ? palette.surface : null,
        gradient: hero == YsDetailHero.plain
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    palette.surface,
                    hero == YsDetailHero.weather && weatherKind != null
                        ? _weatherHeroTint(weatherKind)
                        : color,
                    hero == YsDetailHero.weather ? 0.2 : 0.14,
                  )!,
                  palette.surfaceRaised,
                ],
              ),
        border: Border.all(color: Color.lerp(palette.border, color, 0.3)!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          if (hero == YsDetailHero.weather && weatherKind != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.36,
                child: WeatherCardLayer(
                  kind: weatherKind,
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: 5,
                height: compact ? 42 : (full ? 58 : 48),
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
                      style: TextStyle(
                        fontSize: compact ? 17 : (full ? 21 : 19),
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (full &&
                        (course.teacher.isNotEmpty ||
                            course.room.isNotEmpty)) ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          course.teacher,
                          course.room,
                        ].where((item) => item.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: palette.textSoft),
                      ),
                    ],
                  ],
                ),
              ),
              if (hero == YsDetailHero.weather &&
                  weather != null &&
                  presentation != null)
                Semantics(
                  label: '${presentation.label}，$temperatureText',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WeatherGlyph(
                        kind: presentation.kind,
                        size: 31,
                        animate: !MediaQuery.disableAnimationsOf(context),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            temperatureText!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            presentation.label,
                            style: TextStyle(
                              fontSize: 9,
                              color: palette.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

Color _weatherHeroTint(WeatherKind kind) => switch (kind) {
  WeatherKind.sunny => const Color(0xFFE89A36),
  WeatherKind.cloudy => const Color(0xFF829EB6),
  WeatherKind.overcast => const Color(0xFF718399),
  WeatherKind.fog => const Color(0xFF9AA7B1),
  WeatherKind.drizzle => const Color(0xFF69A1D5),
  WeatherKind.rain => const Color(0xFF4D85BB),
  WeatherKind.heavyRain => const Color(0xFF376B9D),
  WeatherKind.storm => const Color(0xFF626E90),
  WeatherKind.snow => const Color(0xFF7FB6D3),
  WeatherKind.neutral => const Color(0xFF8793A0),
};

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
