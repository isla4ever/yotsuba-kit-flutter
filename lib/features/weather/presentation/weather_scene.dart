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
        _paintRain(canvas, size, count: 2, opacity: 0.34);
      case WeatherKind.rain:
        _paintRain(canvas, size, count: 3, opacity: 0.5);
      case WeatherKind.heavyRain:
        _paintRain(canvas, size, count: 4, opacity: 0.68);
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
    final center = Offset(size.width * 1.02, -unit * 0.03);
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.035;
    final radius = unit * 0.78 * pulse;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.68 * intensity),
            const Color(0xFFFFDC84).withValues(alpha: 0.32 * intensity),
            Colors.transparent,
          ],
          stops: const [0, 0.28, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final ray = Paint()
      ..color = const Color(0xFFFFE7A8).withValues(alpha: 0.22 * intensity)
      ..strokeWidth = math.max(1, unit * 0.025)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 4; index++) {
      final angle = math.pi * (0.45 + index * 0.22) + progress * math.pi * 2;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.28,
        center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.7,
        ray,
      );
    }
  }

  void _paintCloud(Canvas canvas, Size size, {required bool dense}) {
    final unit = size.shortestSide;
    final drift = math.sin(progress * math.pi * 2) * unit * 0.045;
    final paint = Paint()
      ..color = (dense ? const Color(0xFF9FB1C2) : Colors.white).withValues(
        alpha: (dense ? 0.28 : 0.42) * intensity,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.1);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.52 + drift,
        -unit * 0.02,
        unit * 0.82,
        unit * 0.36,
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78 + drift, unit * 0.12),
      unit * 0.2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.98 + drift, unit * 0.08),
      unit * 0.25,
      paint,
    );
  }

  void _paintRain(
    Canvas canvas,
    Size size, {
    required int count,
    required double opacity,
  }) {
    _paintCloud(canvas, size, dense: true);
    final unit = size.shortestSide;
    final paint = Paint()
      ..color = const Color(0xFFD7EEFF).withValues(alpha: opacity * intensity)
      ..strokeWidth = math.max(1, unit * 0.025)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < count; index++) {
      final x = size.width * (0.58 + index * 0.12);
      final fall = (progress * 1.8 + index * 0.21) % 1;
      final y = unit * (0.16 + fall * 0.26);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - unit * 0.06, y + unit * (0.24 + index * 0.02)),
        paint,
      );
    }
  }

  void _paintStorm(Canvas canvas, Size size) {
    _paintRain(canvas, size, count: 3, opacity: 0.6);
    final unit = size.shortestSide;
    final path = Path()
      ..moveTo(size.width * 0.84, unit * 0.2)
      ..lineTo(size.width * 0.73, unit * 0.43)
      ..lineTo(size.width * 0.82, unit * 0.41)
      ..lineTo(size.width * 0.7, unit * 0.66);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE4E1FF).withValues(
          alpha: (0.36 + math.sin(progress * math.pi * 2) * 0.12) * intensity,
        )
        ..strokeWidth = math.max(1, unit * 0.035)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintSnow(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    _paintCloud(canvas, size, dense: false);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82 * intensity);
    const points = [
      Offset(0.62, 0.24),
      Offset(0.82, 0.38),
      Offset(0.94, 0.22),
      Offset(0.7, 0.54),
    ];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final float = math.sin(progress * math.pi * 2 + index) * unit * 0.045;
      canvas.drawCircle(
        Offset(size.width * point.dx, unit * point.dy + float),
        unit * (index.isEven ? 0.035 : 0.026),
        paint,
      );
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final color = palette.canvas.computeLuminance() < 0.2
        ? const Color(0xFFB7C3CD)
        : Colors.white;
    final drift = math.sin(progress * math.pi * 2) * unit * 0.08;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.34 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.12);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.48 + drift,
        unit * 0.05,
        unit * 0.92,
        unit * 0.22,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.58 - drift,
        unit * 0.3,
        unit * 0.82,
        unit * 0.18,
      ),
      paint..color = color.withValues(alpha: 0.24 * intensity),
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherCardPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity;
}
