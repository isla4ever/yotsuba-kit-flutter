import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';

typedef TodayTileBuilder = Widget Function(TodayTileSize size);

class TodayDashboardGrid extends StatefulWidget {
  const TodayDashboardGrid({
    required this.layout,
    required this.children,
    required this.editing,
    required this.reduceMotion,
    required this.onRequestEdit,
    required this.onReorder,
    required this.onResize,
    required this.onHide,
    super.key,
  });

  final List<TodayTileConfig> layout;
  final Map<TodayTileId, TodayTileBuilder> children;
  final bool editing;
  final bool reduceMotion;
  final VoidCallback onRequestEdit;
  final void Function(TodayTileId moving, int visibleIndex) onReorder;
  final void Function(TodayTileId id, TodayTileSize size) onResize;
  final ValueChanged<TodayTileId> onHide;

  @override
  State<TodayDashboardGrid> createState() => _TodayDashboardGridState();
}

class _TodayDashboardGridState extends State<TodayDashboardGrid> {
  static const _gap = 12.0;
  static const _rowHeight = 152.0;

  List<TodayTileId>? _previewOrder;
  final Map<TodayTileId, TodayTileSize> _previewSizes = {};
  TodayTileId? _draggingId;
  int? _dropIndex;

  @override
  void didUpdateWidget(covariant TodayDashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing && !widget.editing) {
      _previewOrder = null;
      _previewSizes.clear();
      _draggingId = null;
      _dropIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 280;
        final columnCount = twoColumns ? 2 : 1;
        final columnWidth = twoColumns
            ? (constraints.maxWidth - _gap) / 2
            : constraints.maxWidth;
        final visible = _visibleConfigs();
        final placements = _placeTiles(visible, columnCount);
        final occupiedRows = placements.fold<int>(
          0,
          (maximum, item) =>
              math.max(maximum, item.row + item.config.size.rows),
        );
        final displayRows = occupiedRows + (_draggingId == null ? 0 : 1);
        final totalHeight = displayRows == 0
            ? 0.0
            : displayRows * _rowHeight + (displayRows - 1) * _gap;

        final content = SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_draggingId != null)
                for (var row = 0; row < displayRows; row++)
                  for (var column = 0; column < columnCount; column++)
                    _buildDropCell(
                      row: row,
                      column: column,
                      columnWidth: columnWidth,
                      placements: placements,
                      columnCount: columnCount,
                    ),
              for (final placement in placements)
                AnimatedPositioned(
                  key: ValueKey(placement.config.id),
                  duration: widget.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: placement.column * (columnWidth + _gap),
                  top: placement.row * (_rowHeight + _gap),
                  width: (!twoColumns || placement.config.size.columns == 2)
                      ? constraints.maxWidth
                      : columnWidth,
                  height:
                      placement.config.size.rows * _rowHeight +
                      (placement.config.size.rows - 1) * _gap,
                  child: _buildTile(placement),
                ),
            ],
          ),
        );

        if (widget.reduceMotion) return content;
        return AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: content,
        );
      },
    );
  }

  Widget _buildTile(_DashboardPlacement placement) {
    final config = placement.config;
    return DragTarget<TodayTileId>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        if (details.data != config.id) {
          _previewBefore(details.data, config.id);
        }
      },
      onAcceptWithDetails: (details) => _commitDrag(details.data),
      builder: (context, candidates, _) {
        return _DashboardTile(
          config: config,
          editing: widget.editing,
          reduceMotion: widget.reduceMotion,
          dropHighlighted: candidates.isNotEmpty,
          onRequestEdit: widget.onRequestEdit,
          onDragStarted: () => _beginDrag(config.id),
          onDragEnded: _finishDrag,
          onResizePreview: (size) => _previewResize(config.id, size),
          onResizeCommit: (size) => _commitResize(config.id, size),
          onResizeCancel: () => _cancelResize(config.id),
          onHide: () => widget.onHide(config.id),
          child:
              widget.children[config.id]?.call(config.size) ??
              const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildDropCell({
    required int row,
    required int column,
    required double columnWidth,
    required List<_DashboardPlacement> placements,
    required int columnCount,
  }) {
    final targetIndex = _indexForSlot(row, column, placements, columnCount);
    return Positioned(
      left: column * (columnWidth + _gap),
      top: row * (_rowHeight + _gap),
      width: columnWidth,
      height: _rowHeight,
      child: DragTarget<TodayTileId>(
        onWillAcceptWithDetails: (_) => true,
        onMove: (details) => _previewAt(details.data, targetIndex),
        onAcceptWithDetails: (details) => _commitDrag(details.data),
        builder: (context, candidates, _) {
          final highlighted =
              candidates.isNotEmpty || _dropIndex == targetIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: highlighted
                  ? context.palette.scheduleAccentSoft.withValues(alpha: 0.48)
                  : Colors.transparent,
              border: Border.all(
                color: highlighted
                    ? context.palette.scheduleAccent.withValues(alpha: 0.62)
                    : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  List<TodayTileConfig> _visibleConfigs() {
    final visible = widget.layout.where((item) => item.visible).toList();
    final byId = {for (final item in visible) item.id: item};
    final order = _previewOrder ?? visible.map((item) => item.id).toList();
    return [
      for (final id in order)
        if (byId[id] case final config?)
          config.copyWith(size: _previewSizes[id] ?? config.size),
    ];
  }

  List<_DashboardPlacement> _placeTiles(
    List<TodayTileConfig> tiles,
    int columnCount,
  ) {
    final occupied = <List<bool>>[];
    final placements = <_DashboardPlacement>[];
    for (final tile in tiles) {
      final width = math.min(tile.size.columns, columnCount);
      final height = math.min(tile.size.rows, 2);
      var row = 0;
      var placed = false;
      while (!placed) {
        while (occupied.length < row + height) {
          occupied.add(List.filled(columnCount, false));
        }
        for (var column = 0; column <= columnCount - width; column++) {
          var available = true;
          for (var y = row; y < row + height && available; y++) {
            for (var x = column; x < column + width; x++) {
              if (occupied[y][x]) {
                available = false;
                break;
              }
            }
          }
          if (!available) continue;
          for (var y = row; y < row + height; y++) {
            for (var x = column; x < column + width; x++) {
              occupied[y][x] = true;
            }
          }
          placements.add(
            _DashboardPlacement(config: tile, column: column, row: row),
          );
          placed = true;
          break;
        }
        if (!placed) row++;
      }
    }
    return placements;
  }

  int _indexForSlot(
    int row,
    int column,
    List<_DashboardPlacement> placements,
    int columnCount,
  ) {
    final moving = _draggingId;
    final remaining = (_previewOrder ?? const <TodayTileId>[])
        .where((id) => id != moving)
        .toList();
    final slot = row * columnCount + column;
    for (final placement in placements) {
      if (placement.config.id == moving) continue;
      final placementSlot = placement.row * columnCount + placement.column;
      if (placementSlot >= slot) {
        final index = remaining.indexOf(placement.config.id);
        if (index >= 0) return index;
      }
    }
    return remaining.length;
  }

  void _beginDrag(TodayTileId id) {
    setState(() {
      _draggingId = id;
      _previewOrder = widget.layout
          .where((item) => item.visible)
          .map((item) => item.id)
          .toList();
      _dropIndex = _previewOrder!.indexOf(id);
    });
  }

  void _previewBefore(TodayTileId moving, TodayTileId target) {
    final remaining = [...?_previewOrder]..remove(moving);
    final targetIndex = remaining.indexOf(target);
    if (targetIndex < 0) return;
    _setPreview(moving, targetIndex, remaining);
  }

  void _previewAt(TodayTileId moving, int targetIndex) {
    final remaining = [...?_previewOrder]..remove(moving);
    _setPreview(moving, targetIndex, remaining);
  }

  void _setPreview(
    TodayTileId moving,
    int targetIndex,
    List<TodayTileId> remaining,
  ) {
    final index = targetIndex.clamp(0, remaining.length);
    final next = [...remaining]..insert(index, moving);
    if (_previewOrder != null && _sameOrder(_previewOrder!, next)) return;
    setState(() {
      _previewOrder = next;
      _dropIndex = index;
    });
  }

  void _commitDrag(TodayTileId moving) {
    final index = _previewOrder?.indexOf(moving) ?? 0;
    widget.onReorder(moving, math.max(0, index));
    _clearDragPreview();
  }

  void _finishDrag(bool accepted) {
    if (!accepted) _clearDragPreview();
  }

  void _clearDragPreview() {
    if (!mounted) return;
    setState(() {
      _draggingId = null;
      _previewOrder = null;
      _dropIndex = null;
    });
  }

  void _previewResize(TodayTileId id, TodayTileSize size) {
    if (_previewSizes[id] == size) return;
    setState(() => _previewSizes[id] = size);
  }

  void _commitResize(TodayTileId id, TodayTileSize size) {
    widget.onResize(id, size);
    setState(() => _previewSizes.remove(id));
  }

  void _cancelResize(TodayTileId id) {
    if (_previewSizes.remove(id) != null) setState(() {});
  }

  bool _sameOrder(List<TodayTileId> a, List<TodayTileId> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class _DashboardPlacement {
  const _DashboardPlacement({
    required this.config,
    required this.column,
    required this.row,
  });

  final TodayTileConfig config;
  final int column;
  final int row;
}

enum _ResizeCorner { northwest, northeast, southwest, southeast }

class _DashboardTile extends StatefulWidget {
  const _DashboardTile({
    required this.config,
    required this.editing,
    required this.reduceMotion,
    required this.dropHighlighted,
    required this.onRequestEdit,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onResizePreview,
    required this.onResizeCommit,
    required this.onResizeCancel,
    required this.onHide,
    required this.child,
  });

  final TodayTileConfig config;
  final bool editing;
  final bool reduceMotion;
  final bool dropHighlighted;
  final VoidCallback onRequestEdit;
  final VoidCallback onDragStarted;
  final ValueChanged<bool> onDragEnded;
  final ValueChanged<TodayTileSize> onResizePreview;
  final ValueChanged<TodayTileSize> onResizeCommit;
  final VoidCallback onResizeCancel;
  final VoidCallback onHide;
  final Widget child;

  @override
  State<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<_DashboardTile> {
  Offset _resizeDelta = Offset.zero;
  TodayTileSize _resizeOrigin = TodayTileSize.oneByOne;
  TodayTileSize _resizeCurrent = TodayTileSize.oneByOne;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tile = AnimatedContainer(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          AnimatedScale(
            scale: widget.dropHighlighted ? 0.975 : 1,
            duration: const Duration(milliseconds: 140),
            child: IgnorePointer(ignoring: widget.editing, child: widget.child),
          ),
          if (widget.editing)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.scheduleAccentSoft.withValues(alpha: 0.14),
                  border: Border.all(
                    color: widget.dropHighlighted
                        ? palette.scheduleAccent
                        : palette.scheduleAccent.withValues(alpha: 0.72),
                    width: widget.dropHighlighted ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (widget.editing) ...[
            const Positioned(
              top: 8,
              left: 30,
              child: _EditBadge(
                icon: Icons.drag_indicator_rounded,
                label: '长按拖放',
              ),
            ),
            Positioned(
              top: 7,
              right: 30,
              child: _RoundEditButton(
                tooltip: '隐藏${_tileName(widget.config.id)}',
                icon: Icons.visibility_off_outlined,
                onTap: widget.onHide,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: _EditBadge(
                  icon: Icons.aspect_ratio_rounded,
                  label: widget.config.size.label,
                ),
              ),
            ),
            for (final corner in _ResizeCorner.values)
              _ResizeHandle(
                corner: corner,
                label:
                    '从${_cornerName(corner)}缩放${_tileName(widget.config.id)}',
                onStart: () => _startResize(corner),
                onUpdate: (delta) => _updateResize(corner, delta),
                onEnd: _endResize,
                onCancel: widget.onResizeCancel,
              ),
          ],
        ],
      ),
    );

    if (!widget.editing) {
      return GestureDetector(onLongPress: widget.onRequestEdit, child: tile);
    }
    return LongPressDraggable<TodayTileId>(
      data: widget.config.id,
      delay: const Duration(milliseconds: 120),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: widget.onDragStarted,
      onDragEnd: (details) => widget.onDragEnded(details.wasAccepted),
      feedback: _WidgetDragFeedback(
        name: _tileName(widget.config.id),
        size: widget.config.size,
        child: widget.child,
      ),
      childWhenDragging: _DropPlaceholder(name: _tileName(widget.config.id)),
      child: tile,
    );
  }

  void _startResize(_ResizeCorner corner) {
    _resizeDelta = Offset.zero;
    _resizeOrigin = widget.config.size;
    _resizeCurrent = widget.config.size;
    widget.onResizePreview(_resizeCurrent);
  }

  void _updateResize(_ResizeCorner corner, Offset delta) {
    _resizeDelta += delta;
    final horizontal =
        _resizeDelta.dx *
        switch (corner) {
          _ResizeCorner.northeast || _ResizeCorner.southeast => 1,
          _ => -1,
        };
    final vertical =
        _resizeDelta.dy *
        switch (corner) {
          _ResizeCorner.southwest || _ResizeCorner.southeast => 1,
          _ => -1,
        };
    final columns = horizontal > 24
        ? 2
        : horizontal < -24
        ? 1
        : _resizeOrigin.columns;
    final rows = vertical > 24
        ? 2
        : vertical < -24
        ? 1
        : _resizeOrigin.rows;
    final next = TodayTileSize.values.firstWhere(
      (size) => size.columns == columns && size.rows == rows,
    );
    if (next == _resizeCurrent) return;
    _resizeCurrent = next;
    widget.onResizePreview(next);
  }

  void _endResize() => widget.onResizeCommit(_resizeCurrent);
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.corner,
    required this.label,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final _ResizeCorner corner;
  final String label;
  final VoidCallback onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final top = {
      _ResizeCorner.northwest,
      _ResizeCorner.northeast,
    }.contains(corner);
    final left = {
      _ResizeCorner.northwest,
      _ResizeCorner.southwest,
    }.contains(corner);
    return Positioned(
      top: top ? -2 : null,
      bottom: top ? null : -2,
      left: left ? -2 : null,
      right: left ? null : -2,
      child: Semantics(
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onStart(),
          onPanUpdate: (details) => onUpdate(details.delta),
          onPanEnd: (_) => onEnd(),
          onPanCancel: onCancel,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Transform.rotate(
              angle: switch (corner) {
                _ResizeCorner.northwest => 0,
                _ResizeCorner.northeast => math.pi / 2,
                _ResizeCorner.southeast => math.pi,
                _ResizeCorner.southwest => math.pi * 1.5,
              },
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                size: 19,
                color: context.palette.scheduleAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WidgetDragFeedback extends StatelessWidget {
  const _WidgetDragFeedback({
    required this.name,
    required this.size,
    required this.child,
  });

  final String name;
  final TodayTileSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.columns == 2 ? 220 : 156,
        height: size.rows == 2 ? 164 : 124,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x300F172A),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: 0.9, child: child),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  color: const Color(0xD9111827),
                  child: Text(
                    '移动 $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.scheduleAccentSoft.withValues(alpha: 0.62),
        border: Border.all(
          color: palette.scheduleAccent.withValues(alpha: 0.68),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vertical_align_center_rounded,
              color: palette.scheduleAccent,
            ),
            const SizedBox(height: 4),
            Text(
              '$name放置位置',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.scheduleAccent,
              ),
            ),
          ],
        ),
      ),
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

String _cornerName(_ResizeCorner corner) => switch (corner) {
  _ResizeCorner.northwest => '左上角',
  _ResizeCorner.northeast => '右上角',
  _ResizeCorner.southwest => '左下角',
  _ResizeCorner.southeast => '右下角',
};
