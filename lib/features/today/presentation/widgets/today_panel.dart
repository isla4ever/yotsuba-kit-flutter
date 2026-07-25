import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';

class TodayPanel extends StatelessWidget {
  const TodayPanel({
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.constraints,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TodaySectionHeading extends StatelessWidget {
  const TodaySectionHeading({
    required this.eyebrow,
    required this.title,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  height: 1.15,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: palette.textFaint,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: TextStyle(
                  height: 1.25,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
