import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

class ScheduleToolbar extends StatelessWidget {
  const ScheduleToolbar({
    required this.layout,
    required this.transition,
    required this.headerStyle,
    required this.editing,
    required this.onLayoutChanged,
    required this.onTransitionChanged,
    required this.onCycleHeader,
    required this.onGuide,
    required this.onToggleEdit,
    super.key,
  });

  final ScheduleLayoutMode layout;
  final YsTransition transition;
  final YsHeaderStyle headerStyle;
  final bool editing;
  final ValueChanged<ScheduleLayoutMode> onLayoutChanged;
  final ValueChanged<YsTransition> onTransitionChanged;
  final VoidCallback onCycleHeader;
  final VoidCallback onGuide;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = MediaQuery.sizeOf(context).width <= 360;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.86),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          _SegmentedLayout(
            value: layout,
            compact: narrow,
            onChanged: onLayoutChanged,
          ),
          const Spacer(),
          PopupMenuButton<YsTransition>(
            tooltip: '换周动画：${_transitionLabel(transition)}',
            initialValue: transition,
            onSelected: onTransitionChanged,
            itemBuilder: (context) => [
              for (final value in YsTransition.values)
                PopupMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      if (value == transition)
                        Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: palette.scheduleAccent,
                        )
                      else
                        const SizedBox(width: 17),
                      const SizedBox(width: 8),
                      Text(_transitionLabel(value)),
                    ],
                  ),
                ),
            ],
            child: _ToolbarButton(
              icon: Icons.animation_rounded,
              label: narrow ? null : _transitionLabel(transition),
              semanticLabel: '换周动画：${_transitionLabel(transition)}',
            ),
          ),
          const SizedBox(width: 5),
          Semantics(
            button: true,
            label: '顶部栏：${_headerLabel(headerStyle)}',
            child: InkWell(
              onTap: onCycleHeader,
              borderRadius: BorderRadius.circular(7),
              child: _ToolbarButton(
                icon: Icons.view_day_outlined,
                label: narrow ? null : _headerLabel(headerStyle),
                semanticLabel: '顶部栏：${_headerLabel(headerStyle)}',
              ),
            ),
          ),
          const SizedBox(width: 5),
          _IconAction(
            icon: Icons.help_outline_rounded,
            tooltip: '查看课表引导',
            onTap: onGuide,
          ),
          const SizedBox(width: 5),
          _IconAction(
            icon: editing ? Icons.check_rounded : Icons.edit_outlined,
            tooltip: editing ? '完成编辑' : '编辑课表',
            active: editing,
            onTap: onToggleEdit,
          ),
        ],
      ),
    );
  }
}

class _SegmentedLayout extends StatelessWidget {
  const _SegmentedLayout({
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final ScheduleLayoutMode value;
  final bool compact;
  final ValueChanged<ScheduleLayoutMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item(
            context,
            value: ScheduleLayoutMode.grid,
            icon: Icons.grid_view_rounded,
            label: '周视图',
          ),
          _item(
            context,
            value: ScheduleLayoutMode.agenda,
            icon: Icons.view_agenda_outlined,
            label: '列表',
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required ScheduleLayoutMode value,
    required IconData icon,
    required String label,
  }) {
    final selected = this.value == value;
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 9),
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? palette.scheduleAccent : palette.textFaint,
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? palette.scheduleAccent : palette.textSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
  });

  final IconData icon;
  final String? label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: semanticLabel,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 8),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: palette.textSoft),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: palette.textSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? palette.scheduleAccent : palette.surfaceMuted,
              border: Border.all(
                color: active ? palette.scheduleAccent : palette.border,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : palette.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}

String _transitionLabel(YsTransition value) => switch (value) {
  YsTransition.wave => '波浪',
  YsTransition.slide => '滑动',
  YsTransition.fade => '淡入',
  YsTransition.cube => '立方体',
  YsTransition.drop => '落下',
  YsTransition.zoom => '缩放',
  YsTransition.none => '无动画',
};

String _headerLabel(YsHeaderStyle value) => switch (value) {
  YsHeaderStyle.compact => '紧凑',
  YsHeaderStyle.standard => '标准',
  YsHeaderStyle.expanded => '展开',
  YsHeaderStyle.none => '隐藏',
};
