import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';
import 'package:yotsuba_schedule/features/announcements/application/local_announcement_controller.dart';
import 'package:yotsuba_schedule/features/announcements/presentation/local_announcement_dialog.dart';
import 'package:yotsuba_schedule/features/settings/presentation/settings_screen.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule/features/weather/presentation/weather_scene.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _lastIndex;
  var _direction = 1.0;
  var _announcementShown = false;
  var _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.navigationShell.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startServices();
      }
    });
  }

  Future<void> _startServices() async {
    await ref.read(weatherControllerProvider.notifier).requestAutomatically();
    if (!mounted || _announcementShown) return;
    final announcement = ref.read(localAnnouncementProvider).latestUnmuted;
    if (announcement == null) return;
    _announcementShown = true;
    final muted = await showLocalAnnouncementDialog(context, announcement);
    if (muted && mounted) {
      ref.read(localAnnouncementProvider.notifier).mute(announcement.id);
    }
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.navigationShell.currentIndex;
    if (next != _lastIndex) {
      _direction = next > _lastIndex ? 1 : -1;
      _lastIndex = next;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    if (_settingsOpen) return;
    setState(() => _settingsOpen = true);
    await showDemoSettingsSheet(context, ref);
    if (mounted) setState(() => _settingsOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final weather = ref.watch(weatherControllerProvider);
    final reduceMotion = settings.reduceMotion;
    final sceneKind = weather.snapshot == null
        ? WeatherKind.neutral
        : weatherPresentation(weather.snapshot!.currentWeatherCode).kind;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: reduceMotion
          ? widget.navigationShell
          : FadeTransition(
              opacity: Tween<double>(begin: 0.9, end: 1).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.007 * _direction, 0.003),
                  end: Offset.zero,
                ).animate(animation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.999, end: 1).animate(animation),
                  child: widget.navigationShell,
                ),
              ),
            ),
      bottomNavigationBar: _AppTabBar(
        selectedIndex: _settingsOpen ? 2 : widget.navigationShell.currentIndex,
        showLabels: settings.showDockLabels,
        onSelected: (index) {
          if (index == 2) {
            _openSettings();
            return;
          }
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
    final scene = settings.weatherScene
        ? WeatherScene(
            kind: sceneKind,
            reduceMotion: reduceMotion,
            intensity: 0.82,
            child: scaffold,
          )
        : scaffold;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRect(child: scene),
        ),
      ),
    );
  }
}

class _AppTabBar extends StatelessWidget {
  const _AppTabBar({
    required this.selectedIndex,
    required this.showLabels,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool showLabels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const items = [
      (Icons.calendar_month_outlined, '课表'),
      (Icons.auto_awesome_rounded, '今日'),
      (Icons.tune_rounded, '设置'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.84),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SizedBox(
        height: 58 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _TabItem(
                    icon: items[index].$1,
                    label: items[index].$2,
                    showLabel: showLabels,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 42,
              height: 31,
              decoration: BoxDecoration(
                color: selected ? palette.surfaceMuted : Colors.transparent,
                border: selected ? Border.all(color: palette.border) : null,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: palette.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: selected ? palette.text : palette.textSoft,
                  ),
                  if (selected)
                    Positioned(
                      top: -5,
                      child: Container(
                        width: 18,
                        height: 3,
                        decoration: BoxDecoration(
                          color: palette.text,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  height: 1,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? palette.text : palette.textSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
