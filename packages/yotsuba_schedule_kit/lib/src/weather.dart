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

class YsHourlyWeather {
  const YsHourlyWeather({
    required this.time,
    required this.kind,
    this.temperatureC,
    this.label,
  });

  /// Open-Meteo 所在时区的本地时间。
  final DateTime time;
  final YsWeatherKind kind;
  final double? temperatureC;
  final String? label;
}

class YsWeatherSnapshot {
  const YsWeatherSnapshot({
    required this.daily,
    required this.updatedAt,
    this.current,
    this.hourly = const [],
  });

  final YsCurrentWeather? current;
  final List<YsDailyWeather> daily;
  final List<YsHourlyWeather> hourly;
  final DateTime updatedAt;

  YsDailyWeather? weatherForDate(String dateKey) {
    return _weatherIndex.dailyByDate[dateKey];
  }

  /// 优先返回同一天最接近目标时刻的小时天气；没有时回退到日预报。
  YsDailyWeather? weatherForDateTime(DateTime target) {
    final index = _weatherIndex;
    final cacheKey = target.microsecondsSinceEpoch;
    if (index.byTarget.containsKey(cacheKey)) {
      return index.byTarget[cacheKey];
    }

    YsHourlyWeather? nearest;
    var nearestDistance = Duration(days: 365);
    final dateKey = _weatherDateKey(target);
    for (final value in index.hourlyByDate[dateKey] ?? const []) {
      final distance = value.time.difference(target).abs();
      if (distance < nearestDistance) {
        nearest = value;
        nearestDistance = distance;
      }
    }
    if (nearest != null) {
      final result = YsDailyWeather(
        date: dateKey,
        kind: nearest.kind,
        lowC: nearest.temperatureC,
        highC: nearest.temperatureC,
        label: nearest.label,
      );
      index.byTarget[cacheKey] = result;
      return result;
    }
    final result = index.dailyByDate[dateKey];
    index.byTarget[cacheKey] = result;
    return result;
  }
}

final Expando<_YsWeatherIndex> _ysWeatherIndexCache =
    Expando<_YsWeatherIndex>('ys-weather-index');

extension on YsWeatherSnapshot {
  _YsWeatherIndex get _weatherIndex {
    final existing = _ysWeatherIndexCache[this];
    if (existing != null) return existing;
    final created = _YsWeatherIndex(this);
    _ysWeatherIndexCache[this] = created;
    return created;
  }
}

class _YsWeatherIndex {
  _YsWeatherIndex(YsWeatherSnapshot snapshot) {
    for (final value in snapshot.daily) {
      dailyByDate[value.date] = value;
    }
    for (final value in snapshot.hourly) {
      (hourlyByDate[_weatherDateKey(value.time)] ??= []).add(value);
    }
  }

  final Map<String, YsDailyWeather> dailyByDate = {};
  final Map<String, List<YsHourlyWeather>> hourlyByDate = {};
  final Map<int, YsDailyWeather?> byTarget = {};
}

String _weatherDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

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
        _rain(canvas, size, unit, count: 2, cycles: 1, opacity: 0.58);
      case YsWeatherKind.rain:
        _rain(canvas, size, unit, count: 3, cycles: 3, opacity: 0.76);
      case YsWeatherKind.heavyRain:
        _rain(canvas, size, unit, count: 5, cycles: 5, opacity: 0.96);
      case YsWeatherKind.storm:
        _rain(canvas, size, unit, count: 4, cycles: 4, opacity: 0.82);
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
      {required int count, required int cycles, required double opacity}) {
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
      canvas.drawLine(Offset(x + unit * 0.035, y - unit * 0.07),
          Offset(x - unit * 0.035, y + unit * 0.07), paint);
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
      duration: const Duration(seconds: 44),
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
          : const Duration(milliseconds: 900),
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
        center: Offset(
          size.width * (0.18 + drift * 0.04),
          size.height * 0.13,
        ),
        width: size.width * 0.78 * breathe,
        height: size.height * 0.34 * breathe,
      ),
      first,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * (0.88 - drift * 0.05),
          size.height * 0.3,
        ),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      second,
    );
  }

  (Color, Color) _ambientColors() => switch (kind) {
        YsWeatherKind.clear => (
            const Color(0xFFFFD071),
            const Color(0xFFFFF0C8)
          ),
        YsWeatherKind.cloudy => (
            const Color(0xFFE8F0F5),
            const Color(0xFF8FA8BE)
          ),
        YsWeatherKind.overcast => (
            const Color(0xFF889CB0),
            const Color(0xFFC2CDD6)
          ),
        YsWeatherKind.fog => (const Color(0xFFE4EAEE), const Color(0xFFA6B4C0)),
        YsWeatherKind.drizzle => (
            const Color(0xFFA9C9DD),
            const Color(0xFF6F9ABD)
          ),
        YsWeatherKind.rain => (
            const Color(0xFF779FBE),
            const Color(0xFFB4CFDF)
          ),
        YsWeatherKind.heavyRain => (
            const Color(0xFF4A6F91),
            const Color(0xFF8DACC4)
          ),
        YsWeatherKind.storm => (
            const Color(0xFF5B5F94),
            const Color(0xFF9AA5CF)
          ),
        YsWeatherKind.snow => (
            const Color(0xFFEAF6FC),
            const Color(0xFF9CC6DE)
          ),
        YsWeatherKind.neutral => (theme.surface2, theme.surface3),
      };

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.kind != kind ||
      oldDelegate.intensity != intensity;
}

/// 课程卡内部的局部微动态天气材质。宿主应在显式卡片光效启用时隐藏此层。
class YsWeatherCardLayer extends StatefulWidget {
  const YsWeatherCardLayer({
    required this.kind,
    this.theme = YsScheduleTheme.light,
    this.reduceMotion = false,
    this.intensity = 0.66,
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
    duration: const Duration(seconds: 18),
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
      _controller
        ..stop()
        ..value = 0.35;
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _WeatherCardPainter(
            kind: widget.kind,
            theme: widget.theme,
            intensity: widget.intensity,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _WeatherCardPainter extends CustomPainter {
  const _WeatherCardPainter({
    required this.kind,
    required this.theme,
    required this.intensity,
    required this.progress,
  });

  final YsWeatherKind kind;
  final YsScheduleTheme theme;
  final double intensity;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case YsWeatherKind.clear:
        _paintSun(canvas, size);
      case YsWeatherKind.cloudy:
        _paintCloud(canvas, size, dense: false);
      case YsWeatherKind.overcast:
        _paintCloud(canvas, size, dense: true);
      case YsWeatherKind.drizzle:
        _paintRain(canvas, size, count: 3, opacity: 0.48);
      case YsWeatherKind.rain:
        _paintRain(canvas, size, count: 5, opacity: 0.62);
      case YsWeatherKind.heavyRain:
        _paintRain(canvas, size, count: 7, opacity: 0.78);
      case YsWeatherKind.storm:
        _paintStorm(canvas, size);
      case YsWeatherKind.snow:
        _paintSnow(canvas, size);
      case YsWeatherKind.fog:
        _paintFog(canvas, size);
      case YsWeatherKind.neutral:
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
        ).createShader(
          Rect.fromCircle(center: center, radius: unit * 0.145),
        ),
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

  void _paintRain(Canvas canvas, Size size,
      {required int count, required double opacity}) {
    final heavy =
        kind == YsWeatherKind.heavyRain || kind == YsWeatherKind.storm;
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
        YsWeatherKind.drizzle => 7.0,
        YsWeatherKind.rain => 11.0,
        YsWeatherKind.heavyRain => 15.0,
        YsWeatherKind.storm => 13.0,
        _ => 10.0,
      };
      final visibleDrops = math.min(starts.length, count);
      for (var index = 0; index < visibleDrops; index++) {
        final phase = (progress * cycles + index * 0.23) % 1;
        final alpha = math.sin(phase * math.pi) * opacity * intensity;
        final start = starts[index] + Offset(0, phase * 15);
        final end = start + const Offset(-0.9, 8.2);
        iconCanvas.drawLine(
          start,
          end,
          Paint()
            ..color = const Color(0xFFE1F5FF).withValues(alpha: alpha)
            ..strokeWidth = heavy
                ? 1.85
                : kind == YsWeatherKind.drizzle
                    ? 1.15
                    : 1.55
            ..strokeCap = StrokeCap.round,
        );
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
      final pulse = 0.26 +
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
            ).createShader(
              Rect.fromCircle(center: haloCenter, radius: 16),
            ),
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
          ..color = (dense ? const Color(0xFF9CB0C0) : Colors.white)
              .withValues(alpha: (dense ? 0.34 : 0.32) * intensity),
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
      oldDelegate.theme != theme ||
      oldDelegate.intensity != intensity ||
      oldDelegate.progress != progress;
}
