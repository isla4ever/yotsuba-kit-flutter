import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum YsWeatherKind {
  clear,
  cloudy,
  overcast,
  fog,
  drizzle,
  rain,
  storm,
  snow,
  neutral,
}

class YsCurrentWeather {
  const YsCurrentWeather({
    required this.kind,
    this.temperatureC,
    this.label,
  });

  final YsWeatherKind kind;
  final double? temperatureC;
  final String? label;
}

class YsDailyWeather {
  const YsDailyWeather({
    required this.date,
    required this.kind,
    this.highC,
    this.lowC,
    this.label,
  });

  /// YYYY-MM-DD。
  final String date;
  final YsWeatherKind kind;
  final double? highC;
  final double? lowC;
  final String? label;
}

class YsWeatherSnapshot {
  const YsWeatherSnapshot({
    required this.daily,
    required this.updatedAt,
    this.current,
  });

  final YsCurrentWeather? current;
  final List<YsDailyWeather> daily;
  final DateTime updatedAt;

  YsDailyWeather? weatherForDate(String dateKey) {
    for (final value in daily) {
      if (value.date == dateKey) return value;
    }
    return null;
  }
}

/// 宿主负责定位、网络和权限；组件库只消费天气快照。
abstract interface class YsWeatherProvider {
  Future<YsWeatherSnapshot> getSnapshot();

  Stream<YsWeatherSnapshot>? get snapshots => null;
}

IconData ysWeatherIcon(YsWeatherKind kind) => switch (kind) {
      YsWeatherKind.clear => Icons.wb_sunny_outlined,
      YsWeatherKind.cloudy => Icons.cloud_queue_rounded,
      YsWeatherKind.overcast => Icons.cloud_outlined,
      YsWeatherKind.fog => Icons.foggy,
      YsWeatherKind.drizzle => Icons.grain_rounded,
      YsWeatherKind.rain => Icons.water_drop_outlined,
      YsWeatherKind.storm => Icons.thunderstorm_outlined,
      YsWeatherKind.snow => Icons.ac_unit_rounded,
      YsWeatherKind.neutral => Icons.cloud_outlined,
    };

String ysWeatherLabel(YsWeatherKind kind) => switch (kind) {
      YsWeatherKind.clear => '晴',
      YsWeatherKind.cloudy => '多云',
      YsWeatherKind.overcast => '阴',
      YsWeatherKind.fog => '雾',
      YsWeatherKind.drizzle => '小雨',
      YsWeatherKind.rain => '雨',
      YsWeatherKind.storm => '雷雨',
      YsWeatherKind.snow => '雪',
      YsWeatherKind.neutral => '天气',
    };

class YsWeatherGlyph extends StatefulWidget {
  const YsWeatherGlyph({
    required this.kind,
    this.size = 22,
    this.animate = true,
    this.color,
    super.key,
  });

  final YsWeatherKind kind;
  final double size;
  final bool animate;
  final Color? color;

  @override
  State<YsWeatherGlyph> createState() => _YsWeatherGlyphState();
}

class _YsWeatherGlyphState extends State<YsWeatherGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant YsWeatherGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.animate ? _controller.value : 0.0;
        final offset = switch (widget.kind) {
          YsWeatherKind.rain ||
          YsWeatherKind.drizzle ||
          YsWeatherKind.snow =>
            Offset(0, value * 1.4),
          YsWeatherKind.cloudy || YsWeatherKind.fog => Offset(value * 1.4, 0),
          _ => Offset.zero,
        };
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: widget.kind == YsWeatherKind.clear ? value * 0.08 - 0.04 : 0,
            child: Icon(
              ysWeatherIcon(widget.kind),
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class YsWeatherScene extends StatefulWidget {
  const YsWeatherScene({
    required this.child,
    required this.kind,
    this.theme = YsScheduleTheme.light,
    this.reduceMotion = false,
    this.intensity = 1,
    super.key,
  });

  final Widget child;
  final YsWeatherKind kind;
  final YsScheduleTheme theme;
  final bool reduceMotion;
  final double intensity;

  @override
  State<YsWeatherScene> createState() => _YsWeatherSceneState();
}

class _YsWeatherSceneState extends State<YsWeatherScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant YsWeatherScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) _sync();
  }

  void _sync() {
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = 0.35;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _sceneColors(widget.kind, widget.theme);
    return AnimatedContainer(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _WeatherPainter(
                  kind: widget.kind,
                  progress: _controller.value,
                  theme: widget.theme,
                  intensity: widget.intensity,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.theme.canvas.withValues(alpha: 0.08),
                  widget.theme.canvas.withValues(alpha: 0.76),
                  widget.theme.canvas.withValues(alpha: 0.96),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

List<Color> _sceneColors(YsWeatherKind kind, YsScheduleTheme theme) {
  final dark = theme.canvas.computeLuminance() < 0.2;
  return switch (kind) {
    YsWeatherKind.clear => dark
        ? const [Color(0xFF172331), Color(0xFF29251D), Color(0xFF101319)]
        : const [Color(0xFFDCE9F5), Color(0xFFFFF0CC), Color(0xFFF3F5F8)],
    YsWeatherKind.rain || YsWeatherKind.drizzle || YsWeatherKind.storm => dark
        ? const [Color(0xFF142432), Color(0xFF171C25), Color(0xFF101319)]
        : const [Color(0xFFD7E5EF), Color(0xFFE2E7ED), Color(0xFFF3F5F8)],
    YsWeatherKind.snow => dark
        ? const [Color(0xFF22303A), Color(0xFF191E27), Color(0xFF101319)]
        : const [Color(0xFFE5EFF5), Color(0xFFF0F2F5), Color(0xFFF3F5F8)],
    _ => dark
        ? const [Color(0xFF1B2631), Color(0xFF181D26), Color(0xFF101319)]
        : const [Color(0xFFDCE8F0), Color(0xFFE8EBF0), Color(0xFFF3F5F8)],
  };
}

class _WeatherPainter extends CustomPainter {
  const _WeatherPainter({
    required this.kind,
    required this.progress,
    required this.theme,
    required this.intensity,
  });

  final YsWeatherKind kind;
  final double progress;
  final YsScheduleTheme theme;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == YsWeatherKind.clear) {
      final center = Offset(size.width * 0.82, size.height * 0.1);
      final pulse = 1 + math.sin(progress * math.pi * 2) * 0.04;
      final glow = Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFD777).withValues(alpha: 0.34 * intensity),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: center, radius: 110 * pulse));
      canvas.drawCircle(center, 110 * pulse, glow);
    }
    if ({YsWeatherKind.rain, YsWeatherKind.drizzle, YsWeatherKind.storm}
        .contains(kind)) {
      final paint = Paint()
        ..color = const Color(0xFF8ABDE0).withValues(alpha: 0.25 * intensity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 24; index++) {
        final x = ((index * 47.0 + progress * 58) % size.width);
        final y = ((index * 83.0 + progress * size.height * 1.4) % size.height);
        canvas.drawLine(Offset(x, y), Offset(x - 4, y + 11), paint);
      }
    }
    if (kind == YsWeatherKind.snow) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.42 * intensity);
      for (var index = 0; index < 20; index++) {
        final x =
            (index * 61.0 + math.sin(progress * 6 + index) * 18) % size.width;
        final y = (index * 79.0 + progress * size.height) % size.height;
        canvas.drawCircle(Offset(x, y), 1.5 + index % 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.kind != kind ||
      oldDelegate.intensity != intensity;
}
