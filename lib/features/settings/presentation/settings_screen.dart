import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/announcements/presentation/announcement_manager_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/settings/presentation/academic_calendar_sheet.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsController = ref.read(appSettingsProvider.notifier);
    final schedule = ref.watch(scheduleControllerProvider);
    final palette = context.palette;
    final weather = ref.watch(weatherControllerProvider);

    return ColoredBox(
      color: palette.canvas.withValues(alpha: 0.72),
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey('settings-scroll'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            Text(
              '设置',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '让课表适应你的设备和使用习惯',
              style: TextStyle(fontSize: 13, color: palette.textSoft),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(label: '外观'),
            _SettingsCard(
              children: [
                _ThemeRow(
                  value: settings.themeMode,
                  onChanged: settingsController.setThemeMode,
                ),
                _SettingsSwitch(
                  icon: Icons.animation_outlined,
                  title: '减少动态效果',
                  subtitle: '关闭周切换和主题过渡动画',
                  value: settings.reduceMotion,
                  onChanged: settingsController.setReduceMotion,
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '课表显示'),
            _SettingsCard(
              children: [
                _SettingsSwitch(
                  icon: Icons.weekend_outlined,
                  title: '显示周末',
                  subtitle: '关闭后只显示周一至周五',
                  value: settings.showWeekend,
                  onChanged: settingsController.setShowWeekend,
                ),
                _SettingsSwitch(
                  icon: Icons.wb_sunny_outlined,
                  title: '夏季作息',
                  subtitle: '下午课程统一延后 30 分钟',
                  value: settings.summerSchedule,
                  onChanged: settingsController.setSummerSchedule,
                ),
                _ScheduleHeightRow(
                  value: settings.scheduleRowHeight,
                  onChanged: settingsController.setScheduleRowHeight,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '操作'),
            _SettingsCard(
              children: [
                _InfoRow(
                  icon: Icons.date_range_outlined,
                  title: '学期、节假日与补班',
                  subtitle: '配置开学日期、总周数并刷新中国法定节假日',
                  onTap: () => showAcademicCalendarSheet(context),
                ),
                _InfoRow(
                  icon: Icons.campaign_outlined,
                  title: '本机公告中心',
                  subtitle: '创建、预览和发布启动公告弹窗',
                  onTap: () => showAnnouncementManagerSheet(context),
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: '定位天气',
                  subtitle: weather.snapshot == null
                      ? (weather.message.isEmpty
                            ? '授权后联动课表背景和课程提醒'
                            : weather.message)
                      : '已缓存当前位置天气，点击重新获取',
                  last: true,
                  onTap: () => ref
                      .read(weatherControllerProvider.notifier)
                      .requestLocation(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '本地数据'),
            _SettingsCard(
              children: [
                _DataRow(label: '课程', value: '${schedule.courses.length} 门'),
                _DataRow(label: '日待办', value: '${schedule.dayTasks.length} 项'),
                _DataRow(
                  label: '课程计划',
                  value: '${schedule.coursePlans.length} 项',
                ),
                _DataRow(
                  label: '已完成计划',
                  value:
                      '${schedule.coursePlans.where((plan) => plan.completed).length} 项',
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context, ref),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('恢复示例数据'),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '关于'),
            _SettingsCard(
              children: [
                _InfoRow(
                  icon: Icons.flutter_dash_rounded,
                  title: 'Yotsuba Schedule',
                  subtitle: 'Flutter 跨平台开源课表 · v1.0.0',
                  onTap: null,
                ),
                _InfoRow(
                  icon: Icons.description_outlined,
                  title: '开源许可证',
                  subtitle: '查看 Flutter 与依赖组件许可证',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Yotsuba Schedule',
                    applicationVersion: '1.0.0',
                  ),
                ),
                _InfoRow(
                  icon: Icons.cloud_outlined,
                  title: '天气数据',
                  subtitle: '预报数据由 Open-Meteo 提供',
                  last: true,
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: appModalAnimationStyle,
      builder: (context) => AlertDialog(
        title: const Text('恢复示例数据？'),
        content: const Text('本地新增的待办和课程将被重置为开源演示数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(scheduleControllerProvider.notifier).resetMockData();
    }
  }
}

class _ScheduleHeightRow extends StatelessWidget {
  const _ScheduleHeightRow({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.height_rounded, size: 19, color: palette.textSoft),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '节次高度',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('按设备与阅读习惯调整课表纵向空间', style: TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              Text(
                '${value.round()} px',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.scheduleAccent,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(54, 78),
            min: 54,
            max: 78,
            divisions: 12,
            label: '${value.round()} px',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.palette.textFaint,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '主题模式',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final item in const [
                (ThemeMode.system, Icons.brightness_auto_outlined, '系统'),
                (ThemeMode.light, Icons.light_mode_outlined, '浅色'),
                (ThemeMode.dark, Icons.dark_mode_outlined, '深色'),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item.$1 == ThemeMode.dark ? 0 : 6,
                    ),
                    child: InkWell(
                      onTap: () => onChanged(item.$1),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: value == item.$1
                              ? palette.scheduleAccentSoft
                              : palette.surfaceRaised,
                          border: Border.all(
                            color: value == item.$1
                                ? palette.scheduleAccent
                                : palette.border,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.$2,
                              size: 16,
                              color: value == item.$1
                                  ? palette.scheduleAccent
                                  : palette.textSoft,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: palette.textSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.scheduleAccent,
            inactiveThumbColor: palette.surface,
            inactiveTrackColor: palette.borderStrong,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.scheduleAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textFaint,
              ),
          ],
        ),
      ),
    );
  }
}
