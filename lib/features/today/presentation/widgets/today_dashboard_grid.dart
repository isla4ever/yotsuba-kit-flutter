import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';

class TodayDashboardGrid extends StatelessWidget {
  const TodayDashboardGrid({
    required this.layout,
    required this.children,
    required this.editing,
    required this.reduceMotion,
    required this.onRequestEdit,
    required this.onMove,
    required this.onResize,
    required this.onHide,
    super.key,
  });

  final List<TodayTileConfig> layout;
  final Map<TodayTileId, Widget> children;
  final bool editing;
  final bool reduceMotion;
  final VoidCallback onRequestEdit;
  final void Function(TodayTileId moving, TodayTileId target) onMove;
  final void Function(TodayTileId id, OffsetDelta delta) onResize;
  final ValueChanged<TodayTileId> onHide;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final visible = layout.where((item) => item.visible).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 330;
        final columnWidth = twoColumns
            ? (constraints.maxWidth - _gap) / 2
            : constraints.maxWidth;
        return AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final tile in visible)
                _DashboardTile(
                  key: ValueKey(tile.id),
                  config: tile,
                  width: !twoColumns || tile.size.columns == 2
                      ? constraints.maxWidth
                      : columnWidth,
                  height: switch (tile.size.rows) {
                    1 => 176,
                    2 => 296,
                    _ => 604,
                  },
                  editing: editing,
                  reduceMotion: reduceMotion,
                  onRequestEdit: onRequestEdit,
                  onMove: onMove,
                  onResize: onResize,
                  onHide: onHide,
                  child: children[tile.id] ?? const SizedBox.shrink(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTile extends StatefulWidget {
  const _DashboardTile({
    required this.config,
    required this.width,
    required this.height,
    required this.editing,
    required this.reduceMotion,
    required this.onRequestEdit,
    required this.onMove,
    required this.onResize,
    required this.onHide,
    required this.child,
    super.key,
  });

  final TodayTileConfig config;
  final double width;
  final double height;
  final bool editing;
  final bool reduceMotion;
  final VoidCallback onRequestEdit;
  final void Function(TodayTileId moving, TodayTileId target) onMove;
  final void Function(TodayTileId id, OffsetDelta delta) onResize;
  final ValueChanged<TodayTileId> onHide;
  final Widget child;

  @override
  State<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<_DashboardTile> {
  Offset _resizeDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tile = AnimatedContainer(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(ignoring: widget.editing, child: widget.child),
          if (widget.editing)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.scheduleAccentSoft.withValues(alpha: 0.12),
                  border: Border.all(
                    color: palette.scheduleAccent.withValues(alpha: 0.72),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (widget.editing) ...[
            Positioned(
              top: 8,
              left: 8,
              child: _EditBadge(
                icon: Icons.drag_indicator_rounded,
                label: '拖动排序',
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: _RoundEditButton(
                tooltip: '隐藏${_tileName(widget.config.id)}',
                icon: Icons.visibility_off_outlined,
                onTap: () => widget.onHide(widget.config.id),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: _EditBadge(
                icon: Icons.aspect_ratio_rounded,
                label: widget.config.size.label,
              ),
            ),
            Positioned(
              right: 7,
              bottom: 7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => _resizeDelta = Offset.zero,
                onPanUpdate: (details) => _resizeDelta += details.delta,
                onPanEnd: (_) {
                  widget.onResize(
                    widget.config.id,
                    OffsetDelta(_resizeDelta.dx, _resizeDelta.dy),
                  );
                  _resizeDelta = Offset.zero;
                },
                child: Tooltip(
                  message: '拖动调整组件尺寸',
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.borderStrong),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(color: palette.shadow, blurRadius: 8),
                      ],
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 17,
                      color: palette.scheduleAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final target = DragTarget<TodayTileId>(
      onWillAcceptWithDetails: (details) => details.data != widget.config.id,
      onAcceptWithDetails: (details) =>
          widget.onMove(details.data, widget.config.id),
      builder: (context, candidates, _) => AnimatedScale(
        scale: candidates.isEmpty ? 1 : 0.975,
        duration: const Duration(milliseconds: 140),
        child: tile,
      ),
    );

    if (!widget.editing) {
      return GestureDetector(onLongPress: widget.onRequestEdit, child: target);
    }
    return LongPressDraggable<TodayTileId>(
      data: widget.config.id,
      delay: const Duration(milliseconds: 110),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Opacity(opacity: 0.9, child: widget.child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: target),
      child: target,
    );
  }
}

class _RoundEditButton extends StatelessWidget {
  const _RoundEditButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: palette.surface,
        foregroundColor: palette.textSoft,
        side: BorderSide(color: palette.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      icon: Icon(icon, size: 16),
    );
  }
}

class _EditBadge extends StatelessWidget {
  const _EditBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.borderStrong),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: palette.scheduleAccent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: palette.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tileName(TodayTileId id) => switch (id) {
  TodayTileId.command => '课程概览',
  TodayTileId.timeline => '课程时间轴',
  TodayTileId.tasks => '当天待办',
  TodayTileId.courseWork => '课程作业',
  TodayTileId.materials => '携带物品',
};
