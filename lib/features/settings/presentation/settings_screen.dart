import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/announcements/presentation/announcement_manager_sheet.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/settings/presentation/academic_calendar_sheet.dart';
import 'package:yotsuba_schedule/features/weather/application/weather_controller.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

Future<void> showDemoSettingsSheet(BuildContext context, WidgetRef ref) {
  final settings = ref.read(appSettingsProvider);
  final baseTheme = Theme.of(context).brightness == Brightness.dark
      ? YsScheduleTheme.dark
      : YsScheduleTheme.light;
  return showYsAdaptiveSheet<void>(
    context: context,
    title: '演示设置',
    kind: YsSheetKind.settings,
    theme: baseTheme.copyWith(
      coursePalette: ysPaletteColors(settings.schedulePalette),
    ),
    config: YsSheetConfig(
      placement: settings.sheetPlacement,
      glass: settings.sheetGlass,
      adjustable: true,
    ),
    builder: (context, placement) => const SettingsScreen(embedded: true),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsController = ref.read(appSettingsProvider.notifier);
    final schedule = ref.watch(scheduleControllerProvider);
    final palette = context.palette;
    final weather = ref.watch(weatherControllerProvider);

    return ColoredBox(
      color: embedded
          ? Colors.transparent
          : palette.canvas.withValues(alpha: 0.72),
      child: SafeArea(
        top: !embedded,
        bottom: false,
        child: ListView(
          key: const PageStorageKey('settings-scroll'),
          padding: embedded
              ? const EdgeInsets.fromLTRB(14, 10, 14, 24)
              : const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            if (!embedded) ...[
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
            ] else ...[
              Row(
                children: [
                  Text(
                    '组件配置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: settingsController.resetDemoConfiguration,
                    icon: const Icon(Icons.restart_alt_rounded, size: 15),
                    label: const Text('恢复默认'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const _SectionLabel(label: '外观'),
            _SettingsCard(
              children: [
                _ThemeRow(
                  value: settings.themeMode,
                  onChanged: settingsController.setThemeMode,
                ),
                _SettingsSelect<YsPalette>(
                  icon: Icons.palette_outlined,
                  title: '课程配色',
                  subtitle: '课表、今日和操作状态使用同一套语义色',
                  value: settings.schedulePalette,
                  values: YsPalette.values,
                  labelFor: _paletteLabel,
                  onChanged: settingsController.setSchedulePalette,
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
                _SettingsSelect<YsScheduleDensity>(
                  icon: Icons.density_medium_outlined,
                  title: '信息密度',
                  subtitle: '精简、标准、丰富三档有独立表头和卡片内容',
                  value: settings.scheduleDensity,
                  values: YsScheduleDensity.values,
                  labelFor: _densityLabel,
                  onChanged: settingsController.setScheduleDensity,
                ),
                _SettingsSelect<CourseCardStyle>(
                  icon: Icons.auto_awesome_outlined,
                  title: '课程卡表现',
                  subtitle: '天气与光效互斥，非本周始终保持失色',
                  value: settings.courseCardStyle,
                  values: CourseCardStyle.values,
                  labelFor: _cardStyleLabel,
                  onChanged: settingsController.setCourseCardStyle,
                ),
                _SettingsSelect<int>(
                  icon: Icons.calendar_view_week_outlined,
                  title: '显示天数',
                  subtitle: '支持工作日、含周六或完整七天',
                  value: settings.visibleDays,
                  values: const [5, 6, 7],
                  labelFor: (value) => '$value 天',
                  onChanged: settingsController.setVisibleDays,
                ),
                _SettingsSwitch(
                  icon: Icons.view_column_outlined,
                  title: '星期栏',
                  subtitle: '关闭后隐藏星期、日期和表头天气',
                  value: settings.showWeekdayBar,
                  onChanged: settingsController.setShowWeekdayBar,
                ),
                _SettingsSwitch(
                  icon: Icons.cloud_outlined,
                  title: '天气场景',
                  subtitle: '在课表、今日和设置后方统一渲染天气氛围',
                  value: settings.weatherScene,
                  onChanged: settingsController.setWeatherScene,
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
            const _SectionLabel(label: '课程详情'),
            _SettingsCard(
              children: [
                _SettingsSelect<YsDetailHero>(
                  icon: Icons.web_asset_outlined,
                  title: '详情样式',
                  subtitle: '标题区域使用课程色、天气融合或极简样式',
                  value: settings.detailHero,
                  values: YsDetailHero.values,
                  labelFor: _detailHeroLabel,
                  onChanged: settingsController.setDetailHero,
                ),
                _SettingsSelect<YsDetailLayout>(
                  icon: Icons.view_stream_outlined,
                  title: '默认布局',
                  subtitle: '控制详情字段的展开程度',
                  value: settings.detailLayout,
                  values: YsDetailLayout.values,
                  labelFor: _detailLayoutLabel,
                  onChanged: settingsController.setDetailLayout,
                ),
                _SettingsSwitch(
                  icon: Icons.touch_app_outlined,
                  title: '详情动作',
                  subtitle: '显示编辑、删除、计划和携带物品操作',
                  value: settings.detailActions,
                  onChanged: settingsController.setDetailActions,
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '弹层'),
            _SettingsCard(
              children: [
                _SettingsSelect<YsSheetPlacement>(
                  icon: Icons.open_in_new_outlined,
                  title: '默认位置',
                  subtitle: '底部、居中和右侧均保留移动端可用尺寸',
                  value: settings.sheetPlacement,
                  values: YsSheetPlacement.values,
                  labelFor: _sheetPlacementLabel,
                  onChanged: settingsController.setSheetPlacement,
                ),
                _SettingsSwitch(
                  icon: Icons.blur_on_outlined,
                  title: '毛玻璃',
                  subtitle: '弹层与遮罩使用半透明模糊质感',
                  value: settings.sheetGlass,
                  onChanged: settingsController.setSheetGlass,
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: '应用外壳'),
            _SettingsCard(
              children: [
                _SettingsSwitch(
                  icon: Icons.web_asset_outlined,
                  title: 'Header',
                  subtitle: '显示课表顶部品牌与周次区域',
                  value: settings.showHeader,
                  onChanged: settingsController.setShowHeader,
                ),
                _SettingsSwitch(
                  icon: Icons.location_on_outlined,
                  title: '天气入口',
                  subtitle: '在 Header 中显示定位天气与当前温度',
                  value: settings.showWeather,
                  onChanged: settingsController.setShowWeather,
                ),
                _SettingsSwitch(
                  icon: Icons.folder_open_outlined,
                  title: 'Header 操作',
                  subtitle: '显示数据管理等模块操作入口',
                  value: settings.showHeaderActions,
                  onChanged: settingsController.setShowHeaderActions,
                ),
                _SettingsSwitch(
                  icon: Icons.label_outline_rounded,
                  title: 'Dock 文字',
                  subtitle: '关闭后仅保留课表、今日、设置图标',
                  value: settings.showDockLabels,
                  onChanged: settingsController.setShowDockLabels,
                  last: true,
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
                      : weather.demoMode
                      ? '当前为分时天气演示，点击获取当前位置预报'
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
              onPressed: settingsController.resetDemoConfiguration,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('恢复演示配置默认值'),
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
            value: value.clamp(44, 78),
            min: 44,
            max: 78,
            divisions: 17,
            label: '${value.round()} px',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsSelect<T> extends StatelessWidget {
  const _SettingsSelect({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.2,
                    fontSize: 9,
                    color: palette.textFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 92, maxWidth: 116),
            padding: const EdgeInsets.only(left: 9, right: 4),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
                iconSize: 18,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
                items: [
                  for (final item in values)
                    DropdownMenuItem(value: item, child: Text(labelFor(item))),
                ],
                onChanged: (next) {
                  if (next != null) onChanged(next);
                },
              ),
            ),
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

String _paletteLabel(YsPalette value) => switch (value) {
  YsPalette.classic => '经典',
  YsPalette.macaron => '马卡龙',
  YsPalette.morandi => '莫兰迪',
  YsPalette.cyber => '赛博',
  YsPalette.forest => '森系',
  YsPalette.sunset => '落日',
};

String _densityLabel(YsScheduleDensity value) => switch (value) {
  YsScheduleDensity.minimal => '精简',
  YsScheduleDensity.normal => '标准',
  YsScheduleDensity.rich => '丰富',
};

String _cardStyleLabel(CourseCardStyle value) => switch (value) {
  CourseCardStyle.weather => '实时天气',
  CourseCardStyle.none => '无',
  CourseCardStyle.shimmer => '微光',
  CourseCardStyle.glow => '辉光',
  CourseCardStyle.aurora => '极光',
  CourseCardStyle.breathe => '呼吸',
};

String _detailHeroLabel(YsDetailHero value) => switch (value) {
  YsDetailHero.courseColor => '课程色',
  YsDetailHero.weather => '天气融合',
  YsDetailHero.plain => '极简',
};

String _detailLayoutLabel(YsDetailLayout value) => switch (value) {
  YsDetailLayout.compact => '精简',
  YsDetailLayout.standard => '适中',
  YsDetailLayout.full => '全面',
};

String _sheetPlacementLabel(YsSheetPlacement value) => switch (value) {
  YsSheetPlacement.bottom => '底部',
  YsSheetPlacement.center => '居中',
  YsSheetPlacement.right => '右侧',
};
