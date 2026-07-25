import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';

class SpotlightStep {
  const SpotlightStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final String title;
  final String body;
}

class SpotlightTour extends StatefulWidget {
  const SpotlightTour({
    required this.steps,
    required this.onFinish,
    required this.reduceMotion,
    super.key,
  });

  final List<SpotlightStep> steps;
  final VoidCallback onFinish;
  final bool reduceMotion;

  @override
  State<SpotlightTour> createState() => _SpotlightTourState();
}

class _SpotlightTourState extends State<SpotlightTour> {
  final _overlayKey = GlobalKey();
  var _index = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant SpotlightTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted || widget.steps.isEmpty) {
      return;
    }
    final target = widget.steps[_index].target.currentContext
        ?.findRenderObject();
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (target is! RenderBox || overlay is! RenderBox || !target.hasSize) {
      return;
    }
    final global = target.localToGlobal(Offset.zero);
    final origin = overlay.localToGlobal(Offset.zero);
    final relative = Offset(global.dx - origin.dx, global.dy - origin.dy);
    final rect = relative & target.size;
    setState(() => _targetRect = rect.inflate(7));
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final duration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 360);
    return Positioned.fill(
      child: Material(
        key: _overlayKey,
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rect =
                _targetRect ??
                Rect.fromLTWH(18, 18, constraints.maxWidth - 36, 70);
            final cardWidth = (constraints.maxWidth - 28).clamp(260.0, 380.0);
            final putBelow = rect.bottom + 178 < constraints.maxHeight;
            final top = putBelow
                ? rect.bottom + 14
                : (rect.top - 164).clamp(12.0, constraints.maxHeight - 174);
            final left = (rect.center.dx - cardWidth / 2).clamp(
              14.0,
              constraints.maxWidth - cardWidth - 14,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _next,
                    child: TweenAnimationBuilder<Rect?>(
                      tween: RectTween(end: rect),
                      duration: duration,
                      curve: Curves.easeInOutCubicEmphasized,
                      builder: (context, value, _) => CustomPaint(
                        painter: _SpotlightPainter(rect: value ?? rect),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: top,
                  width: cardWidth,
                  child: _TourCard(
                    step: step,
                    index: _index,
                    total: widget.steps.length,
                    onBack: _index == 0 ? null : _back,
                    onNext: _next,
                    onClose: widget.onFinish,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinish();
      return;
    }
    setState(() {
      _index++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _back() {
    setState(() {
      _index--;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final spotlight = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(11)));
    canvas.drawPath(
      spotlight,
      Paint()..color = const Color(0xFF0B1110).withValues(alpha: 0.74),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8BB9FF),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect;
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onClose,
    this.onBack,
  });

  final SpotlightStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.borderStrong),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.035, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(index),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${index + 1} / $total',
                      style: TextStyle(fontSize: 10, color: palette.textFaint),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onClose,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: palette.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: palette.textSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onBack != null)
                TextButton(onPressed: onBack, child: const Text('上一步')),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                child: Text(index == total - 1 ? '开始使用' : '下一步'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
