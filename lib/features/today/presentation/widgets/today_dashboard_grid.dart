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
    this.tourKeys = const {},
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
  final Map<TodayTileId, GlobalKey> tourKeys;

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
  List<TodayTileId>? _dragBaseOrder;
  final _dropLayerKey = GlobalKey();

  @override
  void didUpdateWidget(covariant TodayDashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing && !widget.editing) {
      _previewOrder = null;
      _previewSizes.clear();
      _draggingId = null;
      _dropIndex = null;
      _dragBaseOrder = null;
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
        final referencePlacements = _dragReferencePlacements(columnCount);
        final occupiedRows = [...placements, ...referencePlacements].fold<int>(
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
                  child: _buildTile(placement, columnWidth),
                ),
              if (_draggingId != null)
                _buildDropLayer(
                  placements: referencePlacements,
                  columnWidth: columnWidth,
                  columnCount: columnCount,
                  totalHeight: totalHeight,
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

  Widget _buildTile(_DashboardPlacement placement, double columnWidth) {
    final config = placement.config;
    return KeyedSubtree(
      key: widget.tourKeys[config.id],
      child: _DashboardTile(
        config: config,
        editing: widget.editing,
        reduceMotion: widget.reduceMotion,
        horizontalResizeThreshold: math.min(columnWidth * 0.24, 36),
        verticalResizeThreshold: 32,
        dropHighlighted: false,
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
      ),
    );
  }

  Widget _buildDropLayer({
    required List<_DashboardPlacement> placements,
    required double columnWidth,
    required int columnCount,
    required double totalHeight,
  }) {
    final indicatorTop = _dropIndicatorTop(_dropIndex, placements, totalHeight);
    return Positioned.fill(
      child: DragTarget<TodayTileId>(
        key: _dropLayerKey,
        onWillAcceptWithDetails: (_) => true,
        onMove: (details) => _previewFromGlobalOffset(
          details.data,
          details.offset,
          placements,
          columnWidth,
          columnCount,
        ),
        onAcceptWithDetails: (details) => _commitDrag(details.data),
        builder: (context, candidates, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: candidates.isNotEmpty
                      ? context.palette.scheduleAccentSoft.withValues(
                          alpha: 0.05,
                        )
                      : Colors.transparent,
                ),
              ),
              AnimatedPositioned(
                duration: widget.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                top: indicatorTop,
                left: 8,
                right: 8,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.scheduleAccent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: context.palette.scheduleAccent.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _previewFromGlobalOffset(
    TodayTileId moving,
    Offset globalOffset,
    List<_DashboardPlacement> placements,
    double columnWidth,
    int columnCount,
  ) {
    final renderObject = _dropLayerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final point = renderObject.globalToLocal(globalOffset);
    final targetIndex = _indexForPoint(
      point,
      placements,
      columnWidth,
      columnCount,
    );
    _previewAt(moving, targetIndex);
  }

  double _dropIndicatorTop(
    int? index,
    List<_DashboardPlacement> placements,
    double totalHeight,
  ) {
    if (placements.isEmpty || index == null || index <= 0) return 2;
    if (index >= placements.length) {
      final last = placements.last;
      final bottom =
          (last.row + last.config.size.rows) * _rowHeight +
          (last.row + last.config.size.rows - 1) * _gap;
      return math.min(totalHeight - 4, bottom + _gap / 2 - 2);
    }
    return math.max(2, placements[index].row * (_rowHeight + _gap) - _gap / 2);
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

  List<_DashboardPlacement> _dragReferencePlacements(int columnCount) {
    final moving = _draggingId;
    final order = _dragBaseOrder;
    if (moving == null || order == null) return const [];
    final byId = {
      for (final item in widget.layout.where((item) => item.visible))
        item.id: item,
    };
    final tiles = order
        .where((id) => id != moving)
        .map((id) => byId[id])
        .whereType<TodayTileConfig>()
        .toList();
    return _placeTiles(tiles, columnCount);
  }

  int _indexForPoint(
    Offset point,
    List<_DashboardPlacement> placements,
    double columnWidth,
    int columnCount,
  ) {
    final targets = <({int index, _DashboardPlacement placement, Rect rect})>[];
    for (var index = 0; index < placements.length; index++) {
      final placement = placements[index];
      final columns = math.min(placement.config.size.columns, columnCount);
      final left = placement.column * (columnWidth + _gap);
      final top = placement.row * (_rowHeight + _gap);
      final width = columns * columnWidth + (columns - 1) * _gap;
      final height =
          placement.config.size.rows * _rowHeight +
          (placement.config.size.rows - 1) * _gap;
      targets.add((
        index: index,
        placement: placement,
        rect: Rect.fromLTWH(left, top, width, height),
      ));
    }

    for (final target in targets) {
      if (!target.rect.contains(point)) continue;
      final columns = math.min(
        target.placement.config.size.columns,
        columnCount,
      );
      if (columns == columnCount || target.placement.config.size.rows > 1) {
        return point.dy <= target.rect.center.dy
            ? target.index
            : target.index + 1;
      }
      return point.dx <= target.rect.center.dx
          ? target.index
          : target.index + 1;
    }

    final spatialTargets = [...targets]
      ..sort((a, b) {
        final vertical = a.rect.top.compareTo(b.rect.top);
        return vertical != 0 ? vertical : a.rect.left.compareTo(b.rect.left);
      });
    for (final target in spatialTargets) {
      if (point.dy < target.rect.top ||
          (point.dy <= target.rect.bottom && point.dx < target.rect.left)) {
        return target.index;
      }
    }
    return placements.length;
  }

  void _beginDrag(TodayTileId id) {
    setState(() {
      _draggingId = id;
      _previewOrder = widget.layout
          .where((item) => item.visible)
          .map((item) => item.id)
          .toList();
      _dragBaseOrder = List.of(_previewOrder!);
      _dropIndex = _previewOrder!.indexOf(id);
    });
  }

  void _previewAt(TodayTileId moving, int targetIndex) {
    final remaining = [...?_dragBaseOrder]..remove(moving);
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
      _dragBaseOrder = null;
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
    required this.horizontalResizeThreshold,
    required this.verticalResizeThreshold,
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
  final double horizontalResizeThreshold;
  final double verticalResizeThreshold;
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
            _HeightResizeHandle(
              onStart: () => _startResize(_ResizeCorner.southeast),
              onUpdate: (delta) =>
                  _updateResize(_ResizeCorner.southeast, Offset(0, delta)),
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
    final columns = horizontal > widget.horizontalResizeThreshold
        ? 2
        : horizontal < -widget.horizontalResizeThreshold
        ? 1
        : _resizeOrigin.columns;
    final rows = vertical > widget.verticalResizeThreshold
        ? 2
        : vertical < -widget.verticalResizeThreshold
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

class _HeightResizeHandle extends StatelessWidget {
  const _HeightResizeHandle({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned(
      right: 48,
      bottom: -5,
      left: 48,
      height: 32,
      child: Semantics(
        label: '上下拖动调整组件高度',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => onStart(),
          onVerticalDragUpdate: (details) => onUpdate(details.delta.dy),
          onVerticalDragEnd: (_) => onEnd(),
          onVerticalDragCancel: onCancel,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 46,
              height: 6,
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(
                  color: palette.scheduleAccent.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
