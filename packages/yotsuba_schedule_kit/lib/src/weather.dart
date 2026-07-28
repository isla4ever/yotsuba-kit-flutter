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
  heavyRain,
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
      YsWeatherKind.heavyRain => Icons.water_rounded,
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
      YsWeatherKind.heavyRain => '大雨',
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
      _controller.repeat();
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
    final color = widget.color ?? IconTheme.of(context).color ?? Colors.white;
    return Semantics(
      image: true,
      label: ysWeatherLabel(widget.kind),
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _WeatherGlyphPainter(
                kind: widget.kind,
                progress: widget.animate ? _controller.value : 0,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherGlyphPainter extends CustomPainter {
  const _WeatherGlyphPainter({
    required this.kind,
    required this.progress,
    required this.color,
  });

  final YsWeatherKind kind;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    if (kind == YsWeatherKind.clear) {
      _sun(canvas, size, unit, full: true);
      return;
    }
    if (kind == YsWeatherKind.cloudy) _sun(canvas, size, unit);
    if (kind == YsWeatherKind.fog) {
      _cloud(canvas, size, unit, opacity: 0.58);
      _fog(canvas, size, unit);
      return;
    }
    _cloud(
      canvas,
      size,
      unit,
      opacity: kind == YsWeatherKind.overcast ? 0.94 : 0.84,
    );
    switch (kind) {
      case YsWeatherKind.drizzle:
        _rain(canvas, size, unit, count: 2, speed: 1.4, opacity: 0.58);
      case YsWeatherKind.rain:
        _rain(canvas, size, unit, count: 3, speed: 2.4, opacity: 0.76);
      case YsWeatherKind.heavyRain:
        _rain(canvas, size, unit, count: 5, speed: 4.2, opacity: 0.96);
      case YsWeatherKind.storm:
        _rain(canvas, size, unit, count: 4, speed: 3.4, opacity: 0.82);
        _lightning(canvas, size, unit);
      case YsWeatherKind.snow:
        _snow(canvas, size, unit);
      case YsWeatherKind.clear ||
            YsWeatherKind.cloudy ||
            YsWeatherKind.overcast ||
            YsWeatherKind.fog ||
            YsWeatherKind.neutral:
        break;
    }
  }

  void _sun(Canvas canvas, Size size, double unit, {bool full = false}) {
    final center = full
        ? Offset(size.width * 0.5, size.height * 0.5)
        : Offset(size.width * 0.33, size.height * 0.32);
    final radius = unit * (full ? 0.22 : 0.15);
    final paint = Paint()
      ..color = color.withValues(alpha: full ? 0.94 : 0.76)
      ..strokeWidth = math.max(1, unit * 0.055)
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      canvas.drawLine(
        Offset(
            math.cos(angle) * radius * 1.55, math.sin(angle) * radius * 1.55),
        Offset(
            math.cos(angle) * radius * 2.05, math.sin(angle) * radius * 2.05),
        paint,
      );
    }
    canvas.restore();
    canvas.drawCircle(
        center, radius * (1 + math.sin(progress * math.pi * 2) * 0.06), paint);
  }

  void _cloud(Canvas canvas, Size size, double unit,
      {required double opacity}) {
    final drift = math.sin(progress * math.pi * 2) * unit * 0.035;
    final paint = Paint()..color = color.withValues(alpha: opacity);
    final base = Rect.fromLTWH(
      size.width * 0.14 + drift,
      size.height * 0.43,
      size.width * 0.72,
      size.height * 0.3,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(base, Radius.circular(unit * 0.16)), paint);
    canvas.drawCircle(Offset(size.width * 0.38 + drift, size.height * 0.42),
        unit * 0.2, paint);
    canvas.drawCircle(Offset(size.width * 0.61 + drift, size.height * 0.37),
        unit * 0.26, paint);
  }

  void _rain(Canvas canvas, Size size, double unit,
      {required int count, required double speed, required double opacity}) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = math.max(1, unit * 0.055)
      ..strokeCap = StrokeCap.round;
    final travel = (progress * speed) % 1;
    for (var index = 0; index < count; index++) {
      final x = size.width * (0.22 + index * (0.58 / math.max(1, count - 1)));
      final y = size.height * (0.68 + ((travel + index * 0.27) % 1) * 0.18);
      canvas.drawLine(Offset(x + unit * 0.035, y - unit * 0.07),
          Offset(x - unit * 0.035, y + unit * 0.07), paint);
    }
  }

  void _snow(Canvas canvas, Size size, double unit) {
    final paint = Paint()..color = color.withValues(alpha: 0.9);
    for (var index = 0; index < 4; index++) {
      final x = size.width * (0.22 + index * 0.18) +
          math.sin(progress * math.pi * 2 + index) * unit * 0.035;
      final y = size.height * (0.7 + ((progress + index * 0.23) % 1) * 0.16);
      canvas.drawCircle(Offset(x, y), unit * 0.035, paint);
    }
  }

  void _fog(Canvas canvas, Size size, double unit) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..strokeWidth = math.max(1, unit * 0.065)
      ..strokeCap = StrokeCap.round;
    final drift = math.sin(progress * math.pi * 2) * unit * 0.06;
    canvas.drawLine(Offset(unit * 0.16 + drift, unit * 0.72),
        Offset(unit * 0.84 + drift, unit * 0.72), paint);
    canvas.drawLine(Offset(unit * 0.25 - drift, unit * 0.86),
        Offset(unit * 0.77 - drift, unit * 0.86), paint);
  }

  void _lightning(Canvas canvas, Size size, double unit) {
    final flash = math.sin(progress * math.pi * 8) > 0.78 ? 1.0 : 0.48;
    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.61)
      ..lineTo(size.width * 0.44, size.height * 0.8)
      ..lineTo(size.width * 0.55, size.height * 0.78)
      ..lineTo(size.width * 0.47, size.height * 0.97)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.58, size.height * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: flash));
  }

  @override
  bool shouldRepaint(covariant _WeatherGlyphPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.kind != kind ||
      oldDelegate.color != color;
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
    YsWeatherKind.cloudy => dark
        ? const [Color(0xFF1B2631), Color(0xFF181D26), Color(0xFF101319)]
        : const [Color(0xFFDCE8F0), Color(0xFFE8EBF0), Color(0xFFF3F5F8)],
    YsWeatherKind.overcast => dark
        ? const [Color(0xFF222831), Color(0xFF171B22), Color(0xFF101319)]
        : const [Color(0xFFD0D8E0), Color(0xFFE1E5E9), Color(0xFFF3F5F8)],
    YsWeatherKind.rain || YsWeatherKind.drizzle => dark
        ? const [Color(0xFF142432), Color(0xFF171C25), Color(0xFF101319)]
        : const [Color(0xFFD7E5EF), Color(0xFFE2E7ED), Color(0xFFF3F5F8)],
    YsWeatherKind.heavyRain => dark
        ? const [Color(0xFF0E1C2B), Color(0xFF111923), Color(0xFF101319)]
        : const [Color(0xFFC4D5E2), Color(0xFFD8E0E7), Color(0xFFF3F5F8)],
    YsWeatherKind.storm => dark
        ? const [Color(0xFF1B2030), Color(0xFF141822), Color(0xFF101319)]
        : const [Color(0xFFD5DDEB), Color(0xFFE3E6EC), Color(0xFFF3F5F8)],
    YsWeatherKind.snow => dark
        ? const [Color(0xFF22303A), Color(0xFF191E27), Color(0xFF101319)]
        : const [Color(0xFFE5EFF5), Color(0xFFF0F2F5), Color(0xFFF3F5F8)],
    YsWeatherKind.fog => dark
        ? const [Color(0xFF252B31), Color(0xFF181D23), Color(0xFF101319)]
        : const [Color(0xFFDCE2E5), Color(0xFFE9ECEE), Color(0xFFF3F5F8)],
    YsWeatherKind.neutral => dark
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
    if (kind == YsWeatherKind.clear) _paintSun(canvas, size);
    if ({
      YsWeatherKind.cloudy,
      YsWeatherKind.overcast,
      YsWeatherKind.rain,
      YsWeatherKind.heavyRain,
      YsWeatherKind.drizzle,
      YsWeatherKind.storm,
      YsWeatherKind.snow,
    }.contains(kind)) {
      _paintClouds(canvas, size);
    }
    if ({
      YsWeatherKind.rain,
      YsWeatherKind.heavyRain,
      YsWeatherKind.drizzle,
      YsWeatherKind.storm,
    }.contains(kind)) {
      final (count, speed, opacity) = switch (kind) {
        YsWeatherKind.drizzle => (14, 0.7, 0.18),
        YsWeatherKind.rain => (28, 1.4, 0.26),
        YsWeatherKind.heavyRain => (48, 2.25, 0.42),
        YsWeatherKind.storm => (38, 1.9, 0.34),
        _ => (24, 1.0, 0.24),
      };
      _paintRain(canvas, size, count: count, speed: speed, opacity: opacity);
    }
    if (kind == YsWeatherKind.snow) _paintSnow(canvas, size);
    if (kind == YsWeatherKind.fog) _paintFog(canvas, size);
    if (kind == YsWeatherKind.storm) _paintLightning(canvas, size);
  }

  void _paintSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.1);
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.04;
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFD777).withValues(alpha: 0.34 * intensity),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: 110 * pulse));
    canvas.drawCircle(center, 110 * pulse, glow);
    canvas.drawCircle(
      center,
      26 * pulse,
      Paint()
        ..color = const Color(0xFFFFD36A).withValues(alpha: 0.68 * intensity),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final shift =
        (progress * size.width * 0.18) % math.max(1, size.width * 0.18);
    final paint = Paint()
      ..color = theme.surface1.withValues(alpha: 0.18 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (var index = 0; index < 3; index++) {
      final x = -50 + index * size.width * 0.44 + shift;
      final y = 28.0 + index * math.min(34, size.height * 0.12);
      canvas.drawOval(
          Rect.fromLTWH(x, y, math.min(150, size.width * 0.62),
              math.min(42, size.height * 0.22)),
          paint);
      canvas.drawCircle(
          Offset(x + 42, y + 4), math.min(28, size.shortestSide * 0.16), paint);
      canvas.drawCircle(
          Offset(x + 86, y + 2), math.min(36, size.shortestSide * 0.2), paint);
    }
  }

  void _paintRain(Canvas canvas, Size size,
      {required int count, required double speed, required double opacity}) {
    final paint = Paint()
      ..color = const Color(0xFF8ABDE0).withValues(alpha: opacity * intensity)
      ..strokeWidth = kind == YsWeatherKind.heavyRain ? 1.7 : 1.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < count; index++) {
      final seed = (index * 47) % 101 / 101;
      final x =
          (seed * size.width + progress * 58 * speed) % math.max(1, size.width);
      final y = (index * 83.0 + progress * size.height * speed) %
          math.max(1, size.height);
      final length = kind == YsWeatherKind.drizzle
          ? 7.0
          : kind == YsWeatherKind.heavyRain
              ? 16.0
              : 11.0;
      canvas.drawLine(
          Offset(x, y), Offset(x - length * 0.36, y + length), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.46 * intensity);
    for (var index = 0; index < 22; index++) {
      final x = (index * 61.0 + math.sin(progress * 6 + index) * 18) %
          math.max(1, size.width);
      final y =
          (index * 79.0 + progress * size.height) % math.max(1, size.height);
      canvas.drawCircle(Offset(x, y), 1.2 + index % 3, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.surface1.withValues(alpha: 0.18 * intensity)
      ..strokeWidth = math.min(18, math.max(5, size.height * 0.12))
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index++) {
      final y = size.height * (0.12 + index * 0.18);
      final shift =
          math.sin(progress * math.pi * 2 + index) * size.width * 0.08;
      canvas.drawLine(Offset(size.width * 0.04 + shift, y),
          Offset(size.width * 0.92 + shift, y), paint);
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    final flash = math.max(0.0, math.sin(progress * math.pi * 8) - 0.94) * 2.8;
    if (flash <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color =
            const Color(0xFFDDE5FF).withValues(alpha: flash * 0.2 * intensity),
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.kind != kind ||
      oldDelegate.intensity != intensity;
}

/// 课程卡内部的天气动画层。宿主应在显式卡片光效启用时隐藏此层。
class YsWeatherCardLayer extends StatefulWidget {
  const YsWeatherCardLayer({
    required this.kind,
    this.theme = YsScheduleTheme.light,
    this.reduceMotion = false,
    this.intensity = 0.72,
    super.key,
  });

  final YsWeatherKind kind;
  final YsScheduleTheme theme;
  final bool reduceMotion;
  final double intensity;

  @override
  State<YsWeatherCardLayer> createState() => _YsWeatherCardLayerState();
}

class _YsWeatherCardLayerState extends State<YsWeatherCardLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant YsWeatherCardLayer oldWidget) {
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _sceneColors(widget.kind, widget.theme)
                  .take(2)
                  .map((color) =>
                      color.withValues(alpha: 0.34 * widget.intensity))
                  .toList(),
            ),
          ),
          child: CustomPaint(
            painter: _WeatherPainter(
              kind: widget.kind,
              progress: _controller.value,
              theme: widget.theme,
              intensity: widget.intensity,
            ),
          ),
        ),
      ),
    );
  }
}
