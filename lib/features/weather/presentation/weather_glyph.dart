import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

IconData weatherIconFor(WeatherKind kind) => switch (kind) {
  WeatherKind.sunny => Icons.wb_sunny_outlined,
  WeatherKind.cloudy => Icons.cloud_queue_rounded,
  WeatherKind.overcast => Icons.cloud_outlined,
  WeatherKind.fog => Icons.foggy,
  WeatherKind.drizzle => Icons.grain_rounded,
  WeatherKind.rain => Icons.water_drop_outlined,
  WeatherKind.heavyRain => Icons.water_rounded,
  WeatherKind.storm => Icons.thunderstorm_outlined,
  WeatherKind.snow => Icons.ac_unit_rounded,
  WeatherKind.neutral => Icons.cloud_outlined,
};

class WeatherGlyph extends StatefulWidget {
  const WeatherGlyph({
    required this.kind,
    this.size = 22,
    this.animate = true,
    this.color,
    super.key,
  });

  final WeatherKind kind;
  final double size;
  final bool animate;
  final Color? color;

  @override
  State<WeatherGlyph> createState() => _WeatherGlyphState();
}

class _WeatherGlyphState extends State<WeatherGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WeatherGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
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
    final palette = context.palette;
    final color = widget.color ?? palette.scheduleAccent;
    return Semantics(
      image: true,
      label: widget.kind.name,
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

  final WeatherKind kind;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    if (kind == WeatherKind.sunny) {
      _sun(canvas, size, unit, full: true);
      return;
    }
    if (kind == WeatherKind.cloudy) _sun(canvas, size, unit);
    if (kind == WeatherKind.fog) {
      _cloud(canvas, size, unit, opacity: 0.58);
      _fog(canvas, unit);
      return;
    }
    _cloud(
      canvas,
      size,
      unit,
      opacity: kind == WeatherKind.overcast ? 0.94 : 0.84,
    );
    switch (kind) {
      case WeatherKind.drizzle:
        _rain(canvas, size, unit, count: 2, cycles: 1, opacity: 0.58);
      case WeatherKind.rain:
        _rain(canvas, size, unit, count: 3, cycles: 3, opacity: 0.76);
      case WeatherKind.heavyRain:
        _rain(canvas, size, unit, count: 5, cycles: 5, opacity: 0.96);
      case WeatherKind.storm:
        _rain(canvas, size, unit, count: 4, cycles: 4, opacity: 0.82);
        _lightning(canvas, size);
      case WeatherKind.snow:
        _snow(canvas, size, unit);
      case WeatherKind.sunny ||
          WeatherKind.cloudy ||
          WeatherKind.overcast ||
          WeatherKind.fog ||
          WeatherKind.neutral:
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
          math.cos(angle) * radius * 1.55,
          math.sin(angle) * radius * 1.55,
        ),
        Offset(
          math.cos(angle) * radius * 2.05,
          math.sin(angle) * radius * 2.05,
        ),
        paint,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius * (1 + math.sin(progress * math.pi * 2) * 0.06),
      paint,
    );
  }

  void _cloud(
    Canvas canvas,
    Size size,
    double unit, {
    required double opacity,
  }) {
    final drift = math.sin(progress * math.pi * 2) * unit * 0.035;
    final paint = Paint()..color = color.withValues(alpha: opacity);
    final base = Rect.fromLTWH(
      size.width * 0.14 + drift,
      size.height * 0.43,
      size.width * 0.72,
      size.height * 0.3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(unit * 0.16)),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.38 + drift, size.height * 0.42),
      unit * 0.2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.61 + drift, size.height * 0.37),
      unit * 0.26,
      paint,
    );
  }

  void _rain(
    Canvas canvas,
    Size size,
    double unit, {
    required int count,
    required int cycles,
    required double opacity,
  }) {
    final paint = Paint()
      ..strokeWidth = math.max(1, unit * 0.055)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < count; index++) {
      final phase = (progress * cycles + index / count) % 1;
      final edgeOpacity = phase < 0.18
          ? phase / 0.18
          : phase > 0.82
          ? (1 - phase) / 0.18
          : 1.0;
      paint.color = color.withValues(alpha: opacity * edgeOpacity);
      final x = size.width * (0.22 + index * (0.58 / math.max(1, count - 1)));
      final y = size.height * (0.64 + phase * 0.26);
      canvas.drawLine(
        Offset(x + unit * 0.035, y - unit * 0.07),
        Offset(x - unit * 0.035, y + unit * 0.07),
        paint,
      );
    }
  }

  void _snow(Canvas canvas, Size size, double unit) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.94)
      ..strokeWidth = math.max(1, unit * 0.045)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final float = math.sin(progress * math.pi * 2) * unit * 0.025;
    _drawSnowflake(
      canvas,
      Offset(size.width * 0.6, size.height * 0.79 + float),
      unit * 0.13,
      paint,
      progress * math.pi / 3,
    );
    _drawSnowflake(
      canvas,
      Offset(size.width * 0.3, size.height * 0.75 - float),
      unit * 0.075,
      paint..color = color.withValues(alpha: 0.7),
      -progress * math.pi / 4,
    );
  }

  void _drawSnowflake(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    for (var axis = 0; axis < 3; axis++) {
      final angle = axis * math.pi / 3;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(direction * -radius, direction * radius, paint);
      for (final sign in [-1.0, 1.0]) {
        final tip = direction * radius * sign;
        final backAngle = angle + (sign > 0 ? math.pi : 0);
        for (final branch in [-0.55, 0.55]) {
          canvas.drawLine(
            tip,
            tip +
                Offset(
                      math.cos(backAngle + branch),
                      math.sin(backAngle + branch),
                    ) *
                    radius *
                    0.34,
            paint,
          );
        }
      }
    }
    canvas.restore();
  }

  void _fog(Canvas canvas, double unit) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..strokeWidth = math.max(1, unit * 0.065)
      ..strokeCap = StrokeCap.round;
    final drift = math.sin(progress * math.pi * 2) * unit * 0.06;
    canvas.drawLine(
      Offset(unit * 0.16 + drift, unit * 0.72),
      Offset(unit * 0.84 + drift, unit * 0.72),
      paint,
    );
    canvas.drawLine(
      Offset(unit * 0.25 - drift, unit * 0.86),
      Offset(unit * 0.77 - drift, unit * 0.86),
      paint,
    );
  }

  void _lightning(Canvas canvas, Size size) {
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
