import 'dart:ui';

import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';

typedef YsSheetBodyBuilder = Widget Function(
  BuildContext context,
  YsSheetPlacement placement,
);

typedef YsSheetHeaderActionsBuilder = List<Widget> Function(
  BuildContext context,
  YsSheetPlacement placement,
);

Future<T?> showYsAdaptiveSheet<T>({
  required BuildContext context,
  required String title,
  required YsSheetKind kind,
  required YsSheetBodyBuilder builder,
  YsScheduleTheme theme = YsScheduleTheme.light,
  YsSheetConfig config = const YsSheetConfig(),
  IconData? icon,
  YsSheetHeaderActionsBuilder? headerActionsBuilder,
  String barrierLabel = '关闭弹窗',
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: !config.contained,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => _YsSheetPage(
      title: title,
      icon: icon,
      initialPlacement: config.placementFor(kind),
      theme: theme,
      glass: config.glass,
      adjustable: config.adjustable,
      builder: builder,
      headerActionsBuilder: headerActionsBuilder,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _YsSheetPage extends StatefulWidget {
  const _YsSheetPage({
    required this.title,
    required this.initialPlacement,
    required this.theme,
    required this.glass,
    required this.adjustable,
    required this.builder,
    this.icon,
    this.headerActionsBuilder,
  });

  final String title;
  final IconData? icon;
  final YsSheetPlacement initialPlacement;
  final YsScheduleTheme theme;
  final bool glass;
  final bool adjustable;
  final YsSheetBodyBuilder builder;
  final YsSheetHeaderActionsBuilder? headerActionsBuilder;

  @override
  State<_YsSheetPage> createState() => _YsSheetPageState();
}

class _YsSheetPageState extends State<_YsSheetPage> {
  late YsSheetPlacement _placement = widget.initialPlacement;

  void _cyclePlacement() {
    setState(() {
      _placement = switch (_placement) {
        YsSheetPlacement.bottom => YsSheetPlacement.center,
        YsSheetPlacement.center => YsSheetPlacement.right,
        YsSheetPlacement.right => YsSheetPlacement.bottom,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final availableHeight = media.size.height - media.padding.vertical - 24;
    final width = switch (_placement) {
      YsSheetPlacement.bottom => media.size.width,
      YsSheetPlacement.center => mathMin(520, media.size.width - 24),
      YsSheetPlacement.right => mathMin(440, media.size.width - 16),
    };
    final height = switch (_placement) {
      YsSheetPlacement.bottom => mathMin(650, availableHeight * 0.78),
      YsSheetPlacement.center => mathMin(620, availableHeight * 0.76),
      YsSheetPlacement.right => availableHeight,
    };
    final alignment = switch (_placement) {
      YsSheetPlacement.bottom => Alignment.bottomCenter,
      YsSheetPlacement.center => Alignment.center,
      YsSheetPlacement.right => Alignment.centerRight,
    };
    final radius = switch (_placement) {
      YsSheetPlacement.bottom =>
        const BorderRadius.vertical(top: Radius.circular(12)),
      YsSheetPlacement.center => BorderRadius.circular(10),
      YsSheetPlacement.right =>
        const BorderRadius.horizontal(left: Radius.circular(10)),
    };

    return SafeArea(
      child: AnimatedAlign(
        alignment: alignment,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          width: width,
          height: height,
          margin:
              EdgeInsets.all(_placement == YsSheetPlacement.bottom ? 0 : 12),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.glass ? 18 : 0,
                  sigmaY: widget.glass ? 18 : 0,
                ),
                child: Material(
                  color: widget.glass
                      ? widget.theme.surface1.withValues(alpha: 0.9)
                      : widget.theme.surface1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.theme.border),
                      borderRadius: radius,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(child: widget.builder(context, _placement)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final actions = widget.headerActionsBuilder?.call(context, _placement) ??
        const <Widget>[];
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: widget.theme.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: widget.theme.text2),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: widget.theme.text1,
                  ),
                ),
              ),
              ...actions,
              if (widget.adjustable)
                IconButton(
                  tooltip: '调整弹窗位置',
                  onPressed: _cyclePlacement,
                  icon: Icon(
                    switch (_placement) {
                      YsSheetPlacement.bottom => Icons.vertical_align_bottom,
                      YsSheetPlacement.center => Icons.filter_center_focus,
                      YsSheetPlacement.right => Icons.vertical_align_center,
                    },
                    size: 19,
                    color: widget.theme.text2,
                  ),
                ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: 20, color: widget.theme.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double mathMin(num a, num b) => (a < b ? a : b).toDouble();
