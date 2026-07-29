import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/data/calendar/device_calendar_sync_service.dart';
import 'package:yotsuba_schedule/data/calendar/schedule_calendar_exporter.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

Future<void> showDataManagementSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: appModalAnimationStyle,
    builder: (context) => const _DataManagementSheet(),
  );
}

class _DataManagementSheet extends ConsumerStatefulWidget {
  const _DataManagementSheet();

  @override
  ConsumerState<_DataManagementSheet> createState() =>
      _DataManagementSheetState();
}

class _DataManagementSheetState extends ConsumerState<_DataManagementSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '课表数据',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_busy)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: palette.scheduleAccent,
                    ),
                  )
                else
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DataOption(
              icon: Icons.table_view_outlined,
              color: palette.scheduleAccent,
              title: '导入本地备份',
              subtitle: '读取本应用导出的 JSON 完整备份',
              enabled: !_busy,
              onTap: _importFile,
            ),
            const SizedBox(height: 8),
            _DataOption(
              icon: Icons.ios_share_rounded,
              color: const Color(0xFFC26A1B),
              title: '导出本地备份',
              subtitle: '备份课程、计划、待办和携带物品',
              enabled: !_busy,
              onTap: _shareJson,
            ),
            const SizedBox(height: 8),
            _DataOption(
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF237A56),
              title: supportsDirectCalendarSync ? '同步到系统日历' : '导出 ICS 日历',
              subtitle: supportsDirectCalendarSync
                  ? '授权后直接更新整学期课程、计划和截止时间'
                  : '为 Web 或桌面端生成可导入的 ICS 文件',
              enabled: !_busy,
              onTap: supportsDirectCalendarSync
                  ? _syncSystemCalendar
                  : _shareCalendar,
            ),
          ],
        ),
      ),
    );
  }

  ScheduleData get _data => ref.read(scheduleControllerProvider).data;

  Future<void> _importFile() async {
    await _run(() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      final data = ScheduleData.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
      ref.read(scheduleControllerProvider.notifier).replaceScheduleData(data);
      _notify('已导入 ${data.courses.length} 门课程');
    });
  }

  Future<void> _shareJson() async {
    await _run(() async {
      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(_data.toJson());
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Yotsuba Schedule 课表备份',
          text: 'Yotsuba Schedule 课表备份',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(content)),
              mimeType: 'application/json',
              name: 'yotsuba-schedule.json',
            ),
          ],
        ),
      );
    });
  }

  Future<void> _shareCalendar() async {
    await _run(() async {
      final settings = ref.read(appSettingsProvider);
      final entries = ScheduleCalendarBuilder.build(
        _data,
        settings.summerSchedule ? summerCourseTimes : standardCourseTimes,
      );
      final calendar = IcsCalendarSerializer.serialize(entries);
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Yotsuba Schedule 日历',
          text: '课程与计划日历',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(calendar)),
              mimeType: 'text/calendar',
              name: 'yotsuba-schedule.ics',
            ),
          ],
        ),
      );
    });
  }

  Future<void> _syncSystemCalendar() async {
    await _run(() async {
      final settings = ref.read(appSettingsProvider);
      final entries = ScheduleCalendarBuilder.build(
        _data,
        settings.summerSchedule ? summerCourseTimes : standardCourseTimes,
      );
      final rangeStart = DateTime(
        _data.termStart.year,
        _data.termStart.month,
        _data.termStart.day - 1,
      );
      final termEnd = _data.termStart.add(Duration(days: _data.totalWeeks * 7));
      final planDates = entries.expand((entry) => [entry.start, entry.end]);
      final rangeEnd = planDates
          .fold<DateTime>(
            termEnd,
            (latest, value) => value.isAfter(latest) ? value : latest,
          )
          .add(const Duration(days: 1));
      final result = await ref
          .read(deviceCalendarSyncServiceProvider)
          .sync(entries: entries, rangeStart: rangeStart, rangeEnd: rangeEnd);
      _notify('已同步 ${result.created} 个日历事件');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on DeviceCalendarSyncException catch (error) {
      _notifyCalendarError(error);
    } on FormatException {
      _notify('操作失败，请确认备份文件格式正确');
    } on Object {
      _notify('操作失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _notifyCalendarError(DeviceCalendarSyncException error) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: error.failure == DeviceCalendarSyncFailure.denied
            ? SnackBarAction(
                label: '前往设置',
                onPressed: () {
                  ref.read(deviceCalendarSyncServiceProvider).openAppSettings();
                },
              )
            : null,
      ),
    );
  }
}

class _DataOption extends StatelessWidget {
  const _DataOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: palette.textFaint),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
