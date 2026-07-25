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
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant WeatherGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.animate ? _controller.value : 0.0;
        final offset = switch (widget.kind) {
          WeatherKind.rain ||
          WeatherKind.drizzle ||
          WeatherKind.snow => Offset(0, value * 1.5),
          WeatherKind.cloudy || WeatherKind.fog => Offset(value * 1.5, 0),
          _ => Offset.zero,
        };
        final angle = widget.kind == WeatherKind.sunny
            ? value * 0.08 - 0.04
            : 0.0;
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: Icon(
              weatherIconFor(widget.kind),
              size: widget.size,
              color: widget.color ?? palette.scheduleAccent,
            ),
          ),
        );
      },
    );
  }
}
