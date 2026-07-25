import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

class WeatherScene extends StatefulWidget {
  const WeatherScene({
    required this.child,
    required this.kind,
    required this.reduceMotion,
    this.intensity = 1,
    super.key,
  });

  final Widget child;
  final WeatherKind kind;
  final bool reduceMotion;
  final double intensity;

  @override
  State<WeatherScene> createState() => _WeatherSceneState();
}

class _WeatherSceneState extends State<WeatherScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant WeatherScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) _syncMotion();
  }

  void _syncMotion() {
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
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
    final palette = context.palette;
    final colors = _sceneColors(widget.kind, palette);
    return AnimatedContainer(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
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
              builder: (context, _) => CustomPaint(
                painter: _WeatherScenePainter(
                  kind: widget.kind,
                  progress: _controller.value,
                  palette: palette,
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
                  palette.canvas.withValues(alpha: 0.18),
                  palette.canvas.withValues(alpha: 0.76),
                  palette.canvas.withValues(alpha: 0.96),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

List<Color> _sceneColors(WeatherKind kind, AppPalette palette) {
  final dark = palette.canvas.computeLuminance() < 0.2;
  return switch (kind) {
    WeatherKind.sunny =>
      dark
          ? const [Color(0xFF172A27), Color(0xFF252119), Color(0xFF101513)]
          : const [Color(0xFFDDEFE8), Color(0xFFFFF0CC), Color(0xFFF2F5F4)],
    WeatherKind.cloudy =>
      dark
          ? const [Color(0xFF1B292C), Color(0xFF17221F), Color(0xFF101513)]
          : const [Color(0xFFDCE8EA), Color(0xFFE7EEEB), Color(0xFFF2F5F4)],
    WeatherKind.rain || WeatherKind.drizzle =>
      dark
          ? const [Color(0xFF15242A), Color(0xFF172020), Color(0xFF101513)]
          : const [Color(0xFFD7E5EA), Color(0xFFE1E9E7), Color(0xFFF2F5F4)],
    WeatherKind.storm =>
      dark
          ? const [Color(0xFF1A202A), Color(0xFF131B1B), Color(0xFF101513)]
          : const [Color(0xFFD5DDE7), Color(0xFFE3E8E6), Color(0xFFF2F5F4)],
    WeatherKind.snow =>
      dark
          ? const [Color(0xFF233033), Color(0xFF18211F), Color(0xFF101513)]
          : const [Color(0xFFE6F0F2), Color(0xFFF0F3F1), Color(0xFFF2F5F4)],
    _ =>
      dark
          ? const [Color(0xFF17211F), Color(0xFF101513)]
          : const [Color(0xFFE5ECE9), Color(0xFFF2F5F4)],
  };
}

class _WeatherScenePainter extends CustomPainter {
  const _WeatherScenePainter({
    required this.kind,
    required this.progress,
    required this.palette,
    required this.intensity,
  });

  final WeatherKind kind;
  final double progress;
  final AppPalette palette;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == WeatherKind.sunny) _paintSun(canvas, size);
    if ({
      WeatherKind.cloudy,
      WeatherKind.overcast,
      WeatherKind.rain,
      WeatherKind.drizzle,
      WeatherKind.storm,
      WeatherKind.snow,
    }.contains(kind)) {
      _paintClouds(canvas, size);
    }
    if ({
      WeatherKind.rain,
      WeatherKind.drizzle,
      WeatherKind.storm,
    }.contains(kind)) {
      _paintRain(canvas, size, kind == WeatherKind.drizzle ? 14 : 28);
    }
    if (kind == WeatherKind.snow) _paintSnow(canvas, size);
    if (kind == WeatherKind.fog) _paintFog(canvas, size);
    if (kind == WeatherKind.storm) _paintLightning(canvas, size);
  }

  void _paintSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.11);
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.04;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD777).withValues(alpha: 0.34 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 112 * pulse));
    canvas.drawCircle(center, 112 * pulse, glow);
    canvas.drawCircle(
      center,
      28 * pulse,
      Paint()..color = const Color(0xFFFFD36A).withValues(alpha: 0.72),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final shift = (progress * size.width * 0.16) % (size.width * 0.16);
    final paint = Paint()
      ..color = palette.surface.withValues(alpha: 0.16 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var index = 0; index < 3; index++) {
      final x = -40 + index * size.width * 0.42 + shift;
      final y = 42.0 + index * 34;
      canvas.drawOval(Rect.fromLTWH(x, y, 150, 42), paint);
      canvas.drawCircle(Offset(x + 48, y + 4), 30, paint);
      canvas.drawCircle(Offset(x + 92, y + 2), 38, paint);
    }
  }

  void _paintRain(Canvas canvas, Size size, int count) {
    final paint = Paint()
      ..color = const Color(0xFF8ABDE0).withValues(alpha: 0.25 * intensity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < count; index++) {
      final seed = (index * 47) % 101 / 101;
      final x = (seed * size.width + progress * 58) % size.width;
      final y = ((index * 83.0 + progress * size.height * 1.4) % size.height);
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 11), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42 * intensity);
    for (var index = 0; index < 22; index++) {
      final x =
          ((index * 61.0 + math.sin(progress * 6 + index) * 18) % size.width);
      final y = (index * 79.0 + progress * size.height) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5 + index % 3, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.surface.withValues(alpha: 0.16 * intensity)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index++) {
      final y = 56.0 + index * 54;
      final shift = math.sin(progress * math.pi * 2 + index) * 22;
      canvas.drawLine(
        Offset(18 + shift, y),
        Offset(size.width - 28 + shift, y),
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    final flash = math.max(0.0, math.sin(progress * math.pi * 8) - 0.94) * 2.8;
    if (flash <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDDE5FF).withValues(alpha: flash * 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherScenePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.kind != kind;
  }
}
