import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';

class ScheduleActionDock extends StatelessWidget {
  const ScheduleActionDock({
    required this.editing,
    required this.menuOpen,
    required this.onToggleMenu,
    required this.onToggleEdit,
    required this.onOpenSettings,
    required this.onReplayGuide,
    required this.onAdd,
    this.toolsGuideKey,
    this.addGuideKey,
    super.key,
  });

  final bool editing;
  final bool menuOpen;
  final VoidCallback onToggleMenu;
  final VoidCallback onToggleEdit;
  final VoidCallback onOpenSettings;
  final VoidCallback onReplayGuide;
  final VoidCallback onAdd;
  final GlobalKey? toolsGuideKey;
  final GlobalKey? addGuideKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: menuOpen
              ? Container(
                  key: const ValueKey('menu'),
                  width: 142,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: editing
                            ? Icons.visibility_off_outlined
                            : Icons.edit_outlined,
                        label: editing ? '退出编辑' : '编辑课表',
                        active: editing,
                        onTap: onToggleEdit,
                      ),
                      _MenuItem(
                        icon: Icons.school_outlined,
                        label: '操作引导',
                        onTap: onReplayGuide,
                      ),
                      _MenuItem(
                        icon: Icons.tune_rounded,
                        label: '应用设置',
                        onTap: onOpenSettings,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        KeyedSubtree(
          key: toolsGuideKey,
          child: _DockButton(
            label: '课表工具',
            icon: Icons.handyman_outlined,
            active: editing || menuOpen,
            color: palette.surfaceRaised,
            foreground: palette.textSoft,
            onTap: onToggleMenu,
          ),
        ),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: addGuideKey,
          child: _DockButton(
            label: '新增课程',
            icon: Icons.add_rounded,
            color: palette.scheduleAccent,
            foreground: Colors.white,
            onTap: onAdd,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active ? palette.scheduleAccentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? palette.scheduleAccent : palette.textSoft,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: active ? palette.scheduleAccentSoft : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: active ? palette.scheduleAccent : palette.border,
          ),
        ),
        elevation: 0,
        shadowColor: palette.shadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: active ? palette.scheduleAccent : foreground,
            ),
          ),
        ),
      ),
    );
  }
}
