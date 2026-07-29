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
      duration: const Duration(seconds: 44),
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
          : const Duration(milliseconds: 900),
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
          ? const [Color(0xFF172331), Color(0xFF29251D), Color(0xFF101319)]
          : const [Color(0xFFDCE9F5), Color(0xFFFFF0CC), Color(0xFFF3F5F8)],
    WeatherKind.cloudy =>
      dark
          ? const [Color(0xFF1B2631), Color(0xFF181D26), Color(0xFF101319)]
          : const [Color(0xFFDCE8F0), Color(0xFFE8EBF0), Color(0xFFF3F5F8)],
    WeatherKind.overcast =>
      dark
          ? const [Color(0xFF222831), Color(0xFF171B22), Color(0xFF101319)]
          : const [Color(0xFFD0D8E0), Color(0xFFE1E5E9), Color(0xFFF3F5F8)],
    WeatherKind.fog =>
      dark
          ? const [Color(0xFF252B31), Color(0xFF181D23), Color(0xFF101319)]
          : const [Color(0xFFDCE2E5), Color(0xFFE9ECEE), Color(0xFFF3F5F8)],
    WeatherKind.rain || WeatherKind.drizzle =>
      dark
          ? const [Color(0xFF142432), Color(0xFF171C25), Color(0xFF101319)]
          : const [Color(0xFFD7E5EF), Color(0xFFE2E7ED), Color(0xFFF3F5F8)],
    WeatherKind.heavyRain =>
      dark
          ? const [Color(0xFF0E1C2B), Color(0xFF111923), Color(0xFF101319)]
          : const [Color(0xFFC4D5E2), Color(0xFFD8E0E7), Color(0xFFF3F5F8)],
    WeatherKind.storm =>
      dark
          ? const [Color(0xFF1B2030), Color(0xFF141822), Color(0xFF101319)]
          : const [Color(0xFFD5DDEB), Color(0xFFE3E6EC), Color(0xFFF3F5F8)],
    WeatherKind.snow =>
      dark
          ? const [Color(0xFF22303A), Color(0xFF191E27), Color(0xFF101319)]
          : const [Color(0xFFE5EFF5), Color(0xFFF0F2F5), Color(0xFFF3F5F8)],
    WeatherKind.neutral =>
      dark
          ? const [Color(0xFF171D27), Color(0xFF101319)]
          : const [Color(0xFFE7EBF1), Color(0xFFF3F5F8)],
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
    final colors = _ambientColors();
    final drift = math.sin(progress * math.pi * 2);
    final breathe = 1 + math.cos(progress * math.pi * 2) * 0.035;
    final short = size.shortestSide;
    final first = Paint()
      ..color = colors.$1.withValues(alpha: 0.24 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, short * 0.12);
    final second = Paint()
      ..color = colors.$2.withValues(alpha: 0.2 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, short * 0.15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * (0.18 + drift * 0.04), size.height * 0.13),
        width: size.width * 0.78 * breathe,
        height: size.height * 0.34 * breathe,
      ),
      first,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * (0.88 - drift * 0.05), size.height * 0.3),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      second,
    );
  }

  (Color, Color) _ambientColors() => switch (kind) {
    WeatherKind.sunny => (const Color(0xFFFFD071), const Color(0xFFFFF0C8)),
    WeatherKind.cloudy => (const Color(0xFFE8F0F5), const Color(0xFF8FA8BE)),
    WeatherKind.overcast => (const Color(0xFF889CB0), const Color(0xFFC2CDD6)),
    WeatherKind.fog => (const Color(0xFFE4EAEE), const Color(0xFFA6B4C0)),
    WeatherKind.drizzle => (const Color(0xFFA9C9DD), const Color(0xFF6F9ABD)),
    WeatherKind.rain => (const Color(0xFF779FBE), const Color(0xFFB4CFDF)),
    WeatherKind.heavyRain => (const Color(0xFF4A6F91), const Color(0xFF8DACC4)),
    WeatherKind.storm => (const Color(0xFF5B5F94), const Color(0xFF9AA5CF)),
    WeatherKind.snow => (const Color(0xFFEAF6FC), const Color(0xFF9CC6DE)),
    WeatherKind.neutral => (palette.surface, palette.surfaceRaised),
  };

  @override
  bool shouldRepaint(covariant _WeatherScenePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.kind != kind;
  }
}

class WeatherCardLayer extends StatefulWidget {
  const WeatherCardLayer({
    required this.kind,
    required this.reduceMotion,
    this.intensity = 0.66,
    super.key,
  });

  final WeatherKind kind;
  final bool reduceMotion;
  final double intensity;

  @override
  State<WeatherCardLayer> createState() => _WeatherCardLayerState();
}

class _WeatherCardLayerState extends State<WeatherCardLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WeatherCardLayer oldWidget) {
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
    final palette = context.palette;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _WeatherCardPainter(
            kind: widget.kind,
            progress: _controller.value,
            palette: palette,
            intensity: widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _WeatherCardPainter extends CustomPainter {
  const _WeatherCardPainter({
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
    switch (kind) {
      case WeatherKind.sunny:
        _paintSun(canvas, size);
      case WeatherKind.cloudy:
        _paintCloud(canvas, size, dense: false);
      case WeatherKind.overcast:
        _paintCloud(canvas, size, dense: true);
      case WeatherKind.drizzle:
        _paintRain(canvas, size, count: 3, opacity: 0.48);
      case WeatherKind.rain:
        _paintRain(canvas, size, count: 5, opacity: 0.62);
      case WeatherKind.heavyRain:
        _paintRain(canvas, size, count: 7, opacity: 0.78);
      case WeatherKind.storm:
        _paintStorm(canvas, size);
      case WeatherKind.snow:
        _paintSnow(canvas, size);
      case WeatherKind.fog:
        _paintFog(canvas, size);
      case WeatherKind.neutral:
        break;
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final center = Offset(size.width * 0.9, unit * 0.08);
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.045;
    final radius = unit * 0.92 * pulse;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF7D8).withValues(alpha: 0.94 * intensity),
            const Color(0xFFFF5E4A).withValues(alpha: 0.68 * intensity),
            const Color(0xFFFF7558).withValues(alpha: 0.4 * intensity),
            const Color(0xFFFFB14E).withValues(alpha: 0.16 * intensity),
            Colors.transparent,
          ],
          stops: const [0, 0.13, 0.38, 0.68, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      unit * 0.145,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFCEB).withValues(alpha: 0.98 * intensity),
            const Color(0xFFFFC06A).withValues(alpha: 0.72 * intensity),
            const Color(0xFFFF684E).withValues(alpha: 0.2 * intensity),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: unit * 0.145)),
    );
    final ray = Paint()
      ..color = const Color(0xFFFFE7A8).withValues(alpha: 0.3 * intensity)
      ..strokeWidth = math.max(1, unit * 0.025)
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(progress * math.pi * 2) * 0.025;
    for (var index = 0; index < 5; index++) {
      final angle = math.pi * (0.44 + index * 0.14 + sway);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.22,
        center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.78,
        ray,
      );
    }
  }

  void _paintCloud(Canvas canvas, Size size, {required bool dense}) {
    _paintTint(
      canvas,
      size,
      dense ? const Color(0xFF7F97AA) : Colors.white,
      dense ? const Color(0xFF475F75) : const Color(0xFFDCEBF5),
      coreAlpha: dense ? 0.28 : 0.46,
    );
    _paintCloudIcon(canvas, size, dense: dense, showSun: !dense);
  }

  void _paintRain(
    Canvas canvas,
    Size size, {
    required int count,
    required double opacity,
  }) {
    final heavy = kind == WeatherKind.heavyRain || kind == WeatherKind.storm;
    _paintTint(
      canvas,
      size,
      heavy ? const Color(0xFFBDD7E8) : const Color(0xFFDDEFF8),
      heavy ? const Color(0xFF315C7E) : const Color(0xFF5C8EAF),
      coreAlpha: heavy ? 0.38 : 0.32,
    );
    _withIconCanvas(canvas, size, (iconCanvas) {
      final drift = math.sin(progress * math.pi * 2) * 1.25;
      iconCanvas.save();
      iconCanvas.translate(0, drift);
      _drawRainCloud(iconCanvas, heavy: heavy);
      iconCanvas.restore();

      const starts = [
        Offset(21, 47.5),
        Offset(31.5, 51),
        Offset(42.5, 47),
        Offset(53.5, 51),
        Offset(63, 46.5),
        Offset(16, 57),
        Offset(47, 58),
      ];
      final cycles = switch (kind) {
        WeatherKind.drizzle => 7.0,
        WeatherKind.rain => 11.0,
        WeatherKind.heavyRain => 15.0,
        WeatherKind.storm => 13.0,
        _ => 10.0,
      };
      final visibleDrops = math.min(starts.length, count);
      for (var index = 0; index < visibleDrops; index++) {
        final phase = (progress * cycles + index * 0.23) % 1;
        final alpha = math.sin(phase * math.pi) * opacity * intensity;
        final start = starts[index] + Offset(0, phase * 15);
        final end = start + const Offset(-0.9, 8.2);
        final dropPaint = Paint()
          ..color = const Color(0xFFE1F5FF).withValues(alpha: alpha)
          ..strokeWidth = heavy
              ? 1.85
              : kind == WeatherKind.drizzle
              ? 1.15
              : 1.55
          ..strokeCap = StrokeCap.round;
        iconCanvas.drawLine(start, end, dropPaint);
      }
    });
  }

  void _paintStorm(Canvas canvas, Size size) {
    _paintRain(canvas, size, count: 7, opacity: 0.74);
    _withIconCanvas(canvas, size, (iconCanvas) {
      final path = Path()
        ..moveTo(45, 42)
        ..lineTo(36.5, 55.7)
        ..lineTo(42.7, 55.7)
        ..lineTo(39, 66)
        ..lineTo(53.5, 49.7)
        ..lineTo(46.4, 49.7)
        ..lineTo(52, 42)
        ..close();
      final pulse =
          0.26 +
          math.pow(math.max(0, math.sin(progress * math.pi * 2)), 6) * 0.36;
      iconCanvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFEFB8).withValues(alpha: pulse * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    });
  }

  void _paintSnow(Canvas canvas, Size size) {
    _paintTint(
      canvas,
      size,
      const Color(0xFFF7FCFF),
      const Color(0xFF9ECBE2),
      coreAlpha: 0.42,
    );
    _paintCloudIcon(canvas, size, dense: false, showSun: false);
    _withIconCanvas(canvas, size, (iconCanvas) {
      final float = math.sin(progress * math.pi * 2) * 2.2;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * intensity)
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawCardSnowflake(
        iconCanvas,
        Offset(51 + float * 0.25, 51 + float),
        13,
        paint,
        progress * math.pi / 8,
      );
      _drawCardSnowflake(
        iconCanvas,
        Offset(26 - float * 0.2, 53 - float * 0.55),
        6,
        paint..color = Colors.white.withValues(alpha: 0.68 * intensity),
        -progress * math.pi / 6,
      );
    });
  }

  void _drawCardSnowflake(
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

  void _paintFog(Canvas canvas, Size size) {
    _paintTint(
      canvas,
      size,
      const Color(0xFFF9FCFD),
      const Color(0xFFAEBFCB),
      coreAlpha: 0.42,
    );
    _withIconCanvas(canvas, size, (iconCanvas) {
      final glowCenter = const Offset(51, 19);
      iconCanvas.drawCircle(
        glowCenter,
        16,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.24 * intensity),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: glowCenter, radius: 16)),
      );
      final cloud = Path()
        ..moveTo(13, 35)
        ..cubicTo(13.4, 29.2, 18.2, 24.6, 24.1, 24.6)
        ..cubicTo(26, 24.6, 27.8, 25.1, 29.4, 25.9)
        ..cubicTo(32, 20.1, 37.8, 16, 44.5, 16)
        ..cubicTo(53.7, 16, 61.3, 23.2, 61.8, 32.3)
        ..cubicTo(66.3, 33.1, 69.7, 37, 69.7, 41.7)
        ..lineTo(15.1, 41.7)
        ..cubicTo(13.7, 39.8, 13, 37.5, 13, 35)
        ..close();
      iconCanvas.drawPath(
        cloud,
        Paint()
          ..color = const Color(0xFFDCE7ED).withValues(alpha: 0.26 * intensity),
      );

      final drifts = [
        math.sin(progress * math.pi * 2) * 2.8,
        math.sin(progress * math.pi * 2 + math.pi) * 3.2,
        math.sin(progress * math.pi * 2 + math.pi / 2) * 2.5,
      ];
      final paths = [
        Path()
          ..moveTo(9, 43.5)
          ..lineTo(51.5, 43.5)
          ..cubicTo(56.7, 43.5, 59.2, 41.4, 63, 38.5),
        Path()
          ..moveTo(16, 52)
          ..lineTo(61, 52),
        Path()
          ..moveTo(8, 60.5)
          ..lineTo(43.5, 60.5)
          ..cubicTo(49.2, 60.5, 52.2, 58.6, 56, 55.5),
      ];
      for (var index = 0; index < paths.length; index++) {
        iconCanvas.save();
        iconCanvas.translate(drifts[index], 0);
        iconCanvas.drawPath(
          paths[index],
          Paint()
            ..color = (index == 1 ? const Color(0xFFDCE8EE) : Colors.white)
                .withValues(alpha: (index == 1 ? 0.46 : 0.58) * intensity)
            ..strokeWidth = index == 1 ? 5.2 : 4.2
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        iconCanvas.restore();
      }
    });
  }

  void _paintTint(
    Canvas canvas,
    Size size,
    Color core,
    Color wash, {
    required double coreAlpha,
  }) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topRight,
          radius: 0.86,
          colors: [
            core.withValues(alpha: coreAlpha * intensity),
            wash.withValues(alpha: 0.2 * intensity),
            Colors.transparent,
          ],
          stops: const [0, 0.46, 1],
        ).createShader(rect),
    );
  }

  void _withIconCanvas(
    Canvas canvas,
    Size size,
    void Function(Canvas iconCanvas) paint,
  ) {
    final iconSize = math.min(72.0, math.max(54.0, size.width * 1.34));
    canvas.save();
    canvas.translate(size.width - iconSize + 10, -7);
    canvas.scale(iconSize / 72);
    paint(canvas);
    canvas.restore();
  }

  void _paintCloudIcon(
    Canvas canvas,
    Size size, {
    required bool dense,
    required bool showSun,
  }) {
    _withIconCanvas(canvas, size, (iconCanvas) {
      if (showSun) {
        final haloCenter = const Offset(49, 18);
        iconCanvas.drawCircle(
          haloCenter,
          16,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.42 * intensity),
                const Color(0xFFFFE8B6).withValues(alpha: 0.2 * intensity),
                Colors.transparent,
              ],
              stops: const [0, 0.42, 1],
            ).createShader(Rect.fromCircle(center: haloCenter, radius: 16)),
        );
      }
      final drift = math.sin(progress * math.pi * 2) * 1.8;
      final back = Path()
        ..moveTo(17, 35.5)
        ..cubicTo(17.6, 29.4, 22.7, 24.6, 29, 24.6)
        ..cubicTo(31.2, 24.6, 33.3, 25.2, 35.1, 26.3)
        ..cubicTo(37.6, 20.1, 43.6, 15.9, 50.5, 15.9)
        ..cubicTo(59.7, 15.9, 67.2, 23.3, 67.3, 32.5)
        ..cubicTo(70.7, 33.7, 73, 36.9, 73, 40.6)
        ..cubicTo(73, 45.4, 69.1, 49.3, 64.3, 49.3)
        ..lineTo(26.1, 49.3)
        ..cubicTo(19.9, 49.3, 14.9, 44.3, 14.9, 38.1)
        ..cubicTo(14.9, 37.2, 15, 36.3, 15.2, 35.5)
        ..close();
      final front = Path()
        ..moveTo(8.5, 47.4)
        ..cubicTo(8.5, 42.3, 12.6, 38.2, 17.7, 38.2)
        ..cubicTo(18.9, 38.2, 20.1, 38.4, 21.2, 38.9)
        ..cubicTo(23.3, 33.6, 28.5, 29.9, 34.5, 29.9)
        ..cubicTo(41.8, 29.9, 47.9, 35.3, 48.8, 42.3)
        ..cubicTo(50, 41.7, 51.4, 41.4, 52.8, 41.4)
        ..cubicTo(58.1, 41.4, 62.4, 45.7, 62.4, 51)
        ..cubicTo(62.4, 56.3, 58.1, 60.6, 52.8, 60.6)
        ..lineTo(21.7, 60.6)
        ..cubicTo(14.4, 60.6, 8.5, 54.7, 8.5, 47.4)
        ..close();
      iconCanvas.save();
      iconCanvas.translate(drift, -drift * 0.5);
      iconCanvas.drawPath(
        back,
        Paint()
          ..color = (dense ? const Color(0xFF9CB0C0) : Colors.white).withValues(
            alpha: (dense ? 0.34 : 0.32) * intensity,
          ),
      );
      iconCanvas.restore();
      iconCanvas.save();
      iconCanvas.translate(-drift * 0.55, drift * 0.3);
      iconCanvas.drawPath(
        front,
        Paint()
          ..color = (dense ? const Color(0xFFC4D3DE) : const Color(0xFFF0F7FC))
              .withValues(alpha: (dense ? 0.38 : 0.44) * intensity),
      );
      final edge = Path()
        ..moveTo(15.5, 53.4)
        ..cubicTo(25.9, 58.2, 42.6, 58.1, 55.7, 52.7);
      iconCanvas.drawPath(
        edge,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.34 * intensity)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      iconCanvas.restore();
    });
  }

  void _drawRainCloud(Canvas canvas, {required bool heavy}) {
    final cloud = Path()
      ..moveTo(10, 30.5)
      ..cubicTo(10, 24.7, 14.7, 20, 20.5, 20)
      ..cubicTo(22.2, 20, 23.8, 20.4, 25.2, 21.1)
      ..cubicTo(28, 14.6, 34.5, 10, 42.1, 10)
      ..cubicTo(52.3, 10, 60.6, 18.1, 61, 28.2)
      ..cubicTo(65.5, 29.1, 68.9, 33.1, 68.9, 37.9)
      ..cubicTo(68.9, 43.4, 64.4, 47.9, 58.9, 47.9)
      ..lineTo(22.5, 47.9)
      ..cubicTo(15.6, 47.9, 10, 42.3, 10, 35.4)
      ..cubicTo(10, 33.7, 10.3, 32.1, 11, 30.6)
      ..close();
    canvas.drawPath(
      cloud,
      Paint()
        ..color = (heavy ? const Color(0xFF9DB8CD) : const Color(0xFFD3E4EF))
            .withValues(alpha: (heavy ? 0.44 : 0.4) * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    final edge = Path()
      ..moveTo(18, 41)
      ..cubicTo(30.5, 45, 47.5, 44.8, 61.5, 40);
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34 * intensity)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherCardPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity;
}
