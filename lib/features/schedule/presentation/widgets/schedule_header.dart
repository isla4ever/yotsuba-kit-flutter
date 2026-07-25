import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_glyph.dart';

class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({
    required this.week,
    required this.dateRange,
    required this.weather,
    required this.reduceMotion,
    required this.onSelectWeek,
    required this.onWeather,
    required this.onManage,
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
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.88),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: KeyedSubtree(
              key: weekGuideKey,
              child: InkWell(
                onTap: onSelectWeek,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本周课表 · $dateRange',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textSoft,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '第 $week 周',
                          style: TextStyle(
                            height: 1,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 23,
                          color: palette.textSoft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                                fontSize: 11,
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
          const SizedBox(width: 10),
          KeyedSubtree(
            key: dataGuideKey,
            child: _HeaderButton(
              label: '打开本地数据管理',
              onTap: onManage,
              child: Icon(
                Icons.folder_open_outlined,
                size: 20,
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
          constraints: const BoxConstraints(minWidth: 48),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
