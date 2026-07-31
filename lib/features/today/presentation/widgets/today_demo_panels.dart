import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_panel.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

class TodayWeatherPanel extends StatelessWidget {
  const TodayWeatherPanel({
    required this.size,
    required this.weather,
    required this.date,
    required this.reduceMotion,
    required this.onTap,
    super.key,
  });

  final TodayTileSize size;
  final WeatherState weather;
  final DateTime date;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final snapshot = weather.snapshot;
    final daily = snapshot?.weatherForDate(
      DateFormat('yyyy-MM-dd').format(date),
    );
    final code = daily?.weatherCode ?? snapshot?.currentWeatherCode;
    final presentation = code == null ? null : weatherPresentation(code);
    final kind = presentation?.kind ?? WeatherKind.neutral;
    return TodayPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (presentation != null)
                Opacity(
                  opacity: 0.66,
                  child: WeatherCardLayer(
                    kind: kind,
                    reduceMotion: reduceMotion,
                    intensity: 0.72,
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(size.columns == 1 ? 10 : 14),
                child: snapshot == null
                    ? _WeatherEmpty(status: weather.status)
                    : _WeatherContent(
                        size: size,
                        snapshot: snapshot,
                        daily: daily,
                        kind: kind,
                        label: presentation!.label,
                        reduceMotion: reduceMotion,
                        campusFallback: weather.campusFallback,
                        demoMode: weather.demoMode,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.size,
    required this.snapshot,
    required this.daily,
    required this.kind,
    required this.label,
    required this.reduceMotion,
    required this.campusFallback,
    required this.demoMode,
  });

  final TodayTileSize size;
  final WeatherSnapshot snapshot;
  final DailyWeather? daily;
  final WeatherKind kind;
  final String label;
  final bool reduceMotion;
  final bool campusFallback;
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final compact = size == TodayTileSize.oneByOne;
    final tall = size == TodayTileSize.oneByTwo;
    final wide = size == TodayTileSize.twoByOne;
    final temperature = daily == null
        ? '${snapshot.currentTemperature.round()}°'
        : '${daily!.temperatureMax.round()}°';
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelEyebrow(icon: Icons.location_on_outlined, label: '天气'),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              WeatherGlyph(
                kind: kind,
                size: 34,
                animate: !reduceMotion,
                color: _weatherGlyphColor(kind),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  temperature,
                  style: TextStyle(
                    height: 1,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: palette.textSoft),
          ),
        ],
      );
    }
    if (tall) {
      final low = daily?.temperatureMin.round();
      final precipitation = daily?.precipitationProbability;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelEyebrow(icon: Icons.location_on_outlined, label: '天气'),
          const SizedBox(height: 16),
          Center(
            child: WeatherGlyph(
              kind: kind,
              size: 58,
              animate: !reduceMotion,
              color: _weatherGlyphColor(kind),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              temperature,
              style: TextStyle(
                height: 1,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: palette.textSoft),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.5),
              border: Border.all(color: palette.border.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              children: [
                _TallWeatherMetric(
                  label: '低温',
                  value: low == null ? '--' : '$low°',
                ),
                const SizedBox(height: 7),
                _TallWeatherMetric(
                  label: '降水',
                  value: precipitation == null ? '--' : '$precipitation%',
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (wide) {
      return Row(
        children: [
          WeatherGlyph(
            kind: kind,
            size: 50,
            animate: !reduceMotion,
            color: _weatherGlyphColor(kind),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temperature,
                  style: TextStyle(
                    height: 1,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${demoMode ? '分时演示' : (campusFallback ? '校园天气' : '当前位置')} · $label',
                  style: TextStyle(fontSize: 10, color: palette.textSoft),
                ),
              ],
            ),
          ),
          _WeatherMetric(
            label: '低温',
            value: daily == null ? '--' : '${daily!.temperatureMin.round()}°',
          ),
          const SizedBox(width: 12),
          _WeatherMetric(
            label: '降水',
            value: daily?.precipitationProbability == null
                ? '--'
                : '${daily!.precipitationProbability}%',
          ),
        ],
      );
    }
    if (size == TodayTileSize.twoByTwo) {
      final dateKey = daily?.dateKey;
      final hourly = snapshot.hourly
          .where(
            (item) =>
                dateKey == null ||
                DateFormat('yyyy-MM-dd').format(item.time) == dateKey,
          )
          .take(6)
          .toList();
      final temperatures = hourly.map((item) => item.temperature).toList();
      final minTemperature = temperatures.isEmpty
          ? 0.0
          : temperatures.reduce(math.min);
      final maxTemperature = temperatures.isEmpty
          ? 1.0
          : temperatures.reduce(math.max);
      final spread = math.max(1.0, maxTemperature - minTemperature);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '今日天气',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.textSoft,
                ),
              ),
              const Spacer(),
              Text(
                daily == null
                    ? label
                    : '${daily!.temperatureMin.round()}~${daily!.temperatureMax.round()}°',
                style: TextStyle(fontSize: 9, color: palette.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 122,
                  child: Row(
                    children: [
                      WeatherGlyph(
                        kind: kind,
                        size: 47,
                        animate: !reduceMotion,
                        color: _weatherGlyphColor(kind),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${snapshot.currentTemperature.round()}°',
                              style: TextStyle(
                                height: 1,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: palette.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '逐时变化',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: palette.textSoft,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${hourly.length} 个时段',
                            style: TextStyle(
                              fontSize: 8,
                              color: palette.textFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in hourly)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(item.time),
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: palette.textFaint,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                            heightFactor:
                                                0.36 +
                                                ((item.temperature -
                                                            minTemperature) /
                                                        spread) *
                                                    0.64,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC89855),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(3),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      WeatherGlyph(
                                        kind: weatherPresentation(
                                          item.weatherCode,
                                        ).kind,
                                        size: 13,
                                        animate: false,
                                        color: _weatherGlyphColor(
                                          weatherPresentation(
                                            item.weatherCode,
                                          ).kind,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.temperature.round()}°',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: palette.textSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final forecast = snapshot.daily.take(
      size == TodayTileSize.twoByTwo ? 4 : 3,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PanelEyebrow(
              icon: Icons.location_on_outlined,
              label: demoMode ? '分时天气演示' : (campusFallback ? '校园天气' : '当前位置'),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: palette.textSoft),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            WeatherGlyph(
              kind: kind,
              size: size == TodayTileSize.twoByTwo ? 66 : 48,
              animate: !reduceMotion,
              color: _weatherGlyphColor(kind),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temperature,
                    style: TextStyle(
                      height: 1,
                      fontSize: size == TodayTileSize.twoByTwo ? 36 : 29,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    daily == null
                        ? label
                        : '${daily!.temperatureMin.round()}° / ${daily!.temperatureMax.round()}°',
                    style: TextStyle(fontSize: 11, color: palette.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        for (final item in forecast)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Text(
                  item.dateKey.substring(5).replaceFirst('-', '/'),
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
                const Spacer(),
                WeatherGlyph(
                  kind: weatherPresentation(item.weatherCode).kind,
                  size: 14,
                  animate: false,
                  color: _weatherGlyphColor(
                    weatherPresentation(item.weatherCode).kind,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.temperatureMin.round()}°  ${item.temperatureMax.round()}°',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: palette.textSoft,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeatherEmpty extends StatelessWidget {
  const _WeatherEmpty({required this.status});

  final WeatherStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          status == WeatherStatus.loading
              ? Icons.location_searching_rounded
              : Icons.add_location_alt_outlined,
          size: 30,
          color: palette.todayAccent,
        ),
        const SizedBox(height: 8),
        Text(
          status == WeatherStatus.loading ? '正在获取天气' : '点击获取当前位置天气',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: palette.textSoft,
          ),
        ),
      ],
    );
  }
}

class TodayReadinessPanel extends StatelessWidget {
  const TodayReadinessPanel({
    required this.size,
    required this.viewModel,
    super.key,
  });

  final TodayTileSize size;
  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final materialNames = viewModel.courses
        .expand((item) => item.course.materials)
        .toList();
    final materials = materialNames.length;
    final tasks = viewModel.dayTasks.where((item) => !item.completed).length;
    final plans = viewModel.coursePlans.where((item) => !item.completed).length;
    final compact = size == TodayTileSize.oneByOne;
    if (size == TodayTileSize.twoByOne) {
      return TodayPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 72,
              child: _PanelEyebrow(
                icon: Icons.fact_check_outlined,
                label: '出发准备',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReadinessWideMetric(
                label: '课程',
                value: viewModel.remainingCourses,
              ),
            ),
            Expanded(
              child: _ReadinessWideMetric(label: '物品', value: materials),
            ),
            Expanded(
              child: _ReadinessWideMetric(label: '待办', value: tasks + plans),
            ),
          ],
        ),
      );
    }
    return TodayPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelEyebrow(
            icon: compact ? Icons.backpack_outlined : Icons.fact_check_outlined,
            label: compact ? '记得带' : '出发准备',
          ),
          const Spacer(),
          if (compact) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$materials',
                  style: TextStyle(
                    height: 1,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '件物品',
                    style: TextStyle(fontSize: 9, color: palette.textSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              materialNames.isEmpty
                  ? '今天无需额外携带'
                  : materialNames.take(2).join('、'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: palette.textSoft),
            ),
          ] else ...[
            _ReadinessMetric(
              icon: Icons.school_outlined,
              label: '课程',
              value: viewModel.remainingCourses,
            ),
            const SizedBox(height: 8),
            _ReadinessMetric(
              icon: Icons.backpack_outlined,
              label: '物品',
              value: materials,
            ),
            const SizedBox(height: 8),
            _ReadinessMetric(
              icon: Icons.task_alt_outlined,
              label: '待办',
              value: tasks + plans,
            ),
          ],
        ],
      ),
    );
  }
}

class TodayWeekGlancePanel extends StatelessWidget {
  const TodayWeekGlancePanel({
    required this.size,
    required this.courses,
    required this.week,
    super.key,
  });

  final TodayTileSize size;
  final List<Course> courses;
  final int week;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final counts = [
      for (var day = 1; day <= 7; day++)
        courses
            .where(
              (course) => course.weekday == day && course.occursInWeek(week),
            )
            .length,
    ];
    final maxCount = math.max(1, counts.reduce(math.max));
    final compact = size == TodayTileSize.oneByOne;
    if (compact) {
      final todayCount = counts[DateTime.monday - 1];
      return TodayPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '概览',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.textFaint,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(value: '$week', label: '当前周'),
                ),
                Expanded(
                  child: _OverviewMetric(value: '$todayCount', label: '今日课程'),
                ),
                Expanded(
                  child: _OverviewMetric(value: '0/$todayCount', label: '已完成'),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      );
    }
    if (size == TodayTileSize.twoByOne) {
      return TodayPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 72,
              child: _PanelEyebrow(
                icon: Icons.date_range_outlined,
                label: '本周一览',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < counts.length; index++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[index]}',
                            style: TextStyle(
                              fontSize: 7,
                              color: palette.textFaint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 5.0 + counts[index] / maxCount * 27,
                            decoration: BoxDecoration(
                              color: index == DateTime.now().weekday - 1
                                  ? palette.todayAccent
                                  : palette.todayAccentSoft,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 7,
                              color: palette.textFaint,
                            ),
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
    return TodayPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelEyebrow(icon: Icons.date_range_outlined, label: '本周一览'),
          const Spacer(),
          SizedBox(
            height: compact ? 66 : (size.rows == 1 ? 94 : 104),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < counts.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!compact)
                            Text(
                              '${counts[index]}',
                              style: TextStyle(
                                fontSize: 8,
                                color: palette.textFaint,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Container(
                            height:
                                9 +
                                counts[index] /
                                    maxCount *
                                    (compact ? 30 : (size.rows == 1 ? 48 : 58)),
                            decoration: BoxDecoration(
                              color: index == DateTime.now().weekday - 1
                                  ? palette.todayAccent
                                  : palette.todayAccentSoft,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 8,
                              color: palette.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            height: 1,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 7, color: palette.textFaint),
        ),
      ],
    );
  }
}

class TodayStudyLoadPanel extends StatelessWidget {
  const TodayStudyLoadPanel({required this.size, super.key});

  final TodayTileSize size;

  static const _minutes = [72, 96, 54, 118, 84, 42, 66];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final compact = size == TodayTileSize.oneByOne;
    final narrow = size.columns == 1;
    final showBarValues = size == TodayTileSize.twoByTwo;
    final maxMinutes = _minutes.reduce(math.max);
    return TodayPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _PanelEyebrow(
                  icon: Icons.bar_chart_rounded,
                  label: '学习投入',
                ),
              ),
              if (!narrow)
                Text(
                  '较上周 +12%',
                  style: TextStyle(fontSize: 9, color: palette.success),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            compact ? '126' : '8.9 小时',
            style: TextStyle(
              height: 1,
              fontSize: compact ? 28 : 20,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          if (compact)
            Text(
              '今日分钟',
              style: TextStyle(fontSize: 9, color: palette.textFaint),
            ),
          const Spacer(),
          if (!compact)
            SizedBox(
              height: size.rows == 2 ? 98 : 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < _minutes.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: narrow ? 1 : 3,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (showBarValues)
                              Text(
                                '${_minutes[index]}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: palette.textFaint,
                                ),
                              ),
                            SizedBox(height: size.rows == 2 ? 3 : 1),
                            Container(
                              height:
                                  (size.rows == 2 ? 8 : 5) +
                                  _minutes[index] /
                                      maxMinutes *
                                      (size.rows == 2 ? 58 : 14),
                              decoration: BoxDecoration(
                                color: palette.todayAccent,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                            SizedBox(height: size.rows == 2 ? 3 : 1),
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 8,
                                color: palette.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelEyebrow extends StatelessWidget {
  const _PanelEyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: palette.todayAccent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: palette.textSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  const _WeatherMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: palette.textFaint)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

class _TallWeatherMetric extends StatelessWidget {
  const _TallWeatherMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: palette.textFaint)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

class _ReadinessMetric extends StatelessWidget {
  const _ReadinessMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 15, color: palette.todayAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: palette.textSoft),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

class _ReadinessWideMetric extends StatelessWidget {
  const _ReadinessWideMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: TextStyle(
            height: 1,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 9, color: palette.textSoft)),
      ],
    );
  }
}

Color _weatherGlyphColor(WeatherKind kind) => switch (kind) {
  WeatherKind.sunny => const Color(0xFFF1A93A),
  WeatherKind.cloudy => const Color(0xFF7E98B0),
  WeatherKind.overcast => const Color(0xFF708398),
  WeatherKind.fog => const Color(0xFF98A6B2),
  WeatherKind.drizzle => const Color(0xFF5F9EDD),
  WeatherKind.rain => const Color(0xFF4385C9),
  WeatherKind.heavyRain => const Color(0xFF2E70B7),
  WeatherKind.storm => const Color(0xFF6B7190),
  WeatherKind.snow => const Color(0xFF62AED7),
  WeatherKind.neutral => const Color(0xFF8793A0),
};
