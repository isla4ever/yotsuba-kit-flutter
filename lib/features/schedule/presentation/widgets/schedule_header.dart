import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({
    required this.week,
    required this.dateRange,
    required this.weather,
    required this.reduceMotion,
    required this.onSelectWeek,
    required this.onWeather,
    required this.onManage,
    this.style = YsHeaderStyle.standard,
    this.showWeather = true,
    this.showActions = true,
    this.weekGuideKey,
    this.weatherGuideKey,
    this.dataGuideKey,
    super.key,
  });

  final int week;
  final String dateRange;
  final WeatherState weather;
  final bool reduceMotion;
  final VoidCallback onSelectWeek;
  final VoidCallback onWeather;
  final VoidCallback onManage;
  final YsHeaderStyle style;
  final bool showWeather;
  final bool showActions;
  final GlobalKey? weekGuideKey;
  final GlobalKey? weatherGuideKey;
  final GlobalKey? dataGuideKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final snapshot = weather.snapshot;
    final presentation = snapshot == null
        ? null
        : weatherPresentation(snapshot.currentWeatherCode);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: KeyedSubtree(
              key: weekGuideKey,
              child: InkWell(
                onTap: onSelectWeek,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.scheduleAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yotsuba 课表',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '第 $week 周 · 2026 秋季学期',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: palette.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showWeather)
            KeyedSubtree(
              key: weatherGuideKey,
              child: _HeaderButton(
                label: snapshot == null
                    ? '获取当前位置天气'
                    : '${presentation!.label} ${snapshot.currentTemperature.round()}度',
                onTap: onWeather,
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  child: weather.status == WeatherStatus.loading
                      ? SizedBox(
                          key: const ValueKey('weather-loading'),
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: palette.scheduleAccent,
                          ),
                        )
                      : Row(
                          key: ValueKey(presentation?.kind),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WeatherGlyph(
                              kind: presentation?.kind ?? WeatherKind.neutral,
                              size: 18,
                              animate: !reduceMotion && snapshot != null,
                              color: palette.textSoft,
                            ),
                            if (snapshot != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${snapshot.currentTemperature.round()}°',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          if (showWeather && showActions) const SizedBox(width: 7),
          if (showActions)
            KeyedSubtree(
              key: dataGuideKey,
              child: _HeaderButton(
                label: '日历与数据',
                onTap: onManage,
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 19,
                  color: palette.textSoft,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: palette.surfaceRaised.withValues(alpha: 0.9),
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
