import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

Future<void> showDataManagementSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
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
              title: '导入课表文件',
              subtitle: '读取本应用导出的 JSON 课表文件',
              enabled: !_busy,
              onTap: _importFile,
            ),
            const SizedBox(height: 8),
            _DataOption(
              icon: Icons.qr_code_rounded,
              color: const Color(0xFF0F8A72),
              title: '课表码导入',
              subtitle: '粘贴分享码，在本机恢复一份课表快照',
              enabled: !_busy,
              onTap: _importCode,
            ),
            const SizedBox(height: 8),
            _DataOption(
              icon: Icons.share_outlined,
              color: const Color(0xFFC26A1B),
              title: '分享与备份',
              subtitle: '分享 JSON 文件或复制只读课表码',
              enabled: !_busy,
              onTap: _showShareOptions,
            ),
            const SizedBox(height: 8),
            _DataOption(
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF237A56),
              title: '导出系统日历',
              subtitle: '生成包含课程和计划截止时间的 ICS 文件',
              enabled: !_busy,
              onTap: _shareCalendar,
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

  Future<void> _importCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('粘贴课表码'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(hintText: '粘贴以 YS1. 开头的课表码'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty) {
      return;
    }
    await _run(() async {
      final value = code.trim();
      if (!value.startsWith('YS1.')) {
        throw const FormatException('invalid code');
      }
      final normalized = base64Url.normalize(value.substring(4));
      final data = ScheduleData.fromJson(
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>,
      );
      ref.read(scheduleControllerProvider.notifier).replaceScheduleData(data);
      _notify('课表码导入成功');
    });
  }

  Future<void> _showShareOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('分享与备份', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.file_present_outlined),
                title: const Text('分享 JSON 文件'),
                subtitle: const Text('完整备份课程、计划和携带物品'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_rounded),
                title: const Text('复制课表码'),
                subtitle: const Text('生成离线快照码，不上传任何数据'),
                onTap: () => Navigator.pop(context, 'code'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'file') await _shareJson();
    if (action == 'code') await _copyCode();
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

  Future<void> _copyCode() async {
    await _run(() async {
      final encoded = base64Url.encode(utf8.encode(jsonEncode(_data.toJson())));
      await Clipboard.setData(ClipboardData(text: 'YS1.$encoded'));
      _notify('课表码已复制到剪贴板');
    });
  }

  Future<void> _shareCalendar() async {
    await _run(() async {
      final calendar = _buildCalendar(_data);
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

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      _notify('操作失败，请确认文件或课表码格式正确');
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
}

String _buildCalendar(ScheduleData data) {
  final buffer = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('CALSCALE:GREGORIAN')
    ..writeln('PRODID:-//Yotsuba Schedule//CN');
  for (final course in data.courses) {
    for (var week = course.startWeek; week <= course.endWeek; week++) {
      if (!course.occursInWeek(week)) continue;
      final date = ScheduleEngine.dateForWeekday(
        data.termStart,
        week,
        course.weekday,
      );
      final start = _atTime(date, courseTimes[course.startSection - 1].start);
      final end = _atTime(date, courseTimes[course.endSection - 1].end);
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${course.id}-$week@yotsuba-schedule')
        ..writeln('DTSTAMP:${_icalDate(DateTime.now())}')
        ..writeln('DTSTART:${_icalDate(start)}')
        ..writeln('DTEND:${_icalDate(end)}')
        ..writeln('SUMMARY:${_escapeIcal(course.name)}')
        ..writeln('LOCATION:${_escapeIcal(course.room)}')
        ..writeln(
          'DESCRIPTION:${_escapeIcal('${course.teacher} · 第${course.startSection}-${course.endSection}节')}',
        )
        ..writeln('END:VEVENT');
    }
  }
  for (final plan in data.coursePlans.where(
    (item) => item.calendarSyncEnabled,
  )) {
    final start =
        plan.scheduledStart ??
        plan.dueAt?.subtract(const Duration(minutes: 30));
    final end = plan.scheduledEnd ?? plan.dueAt;
    if (start == null || end == null) continue;
    final courseName = data.courses
        .where((course) => course.id == plan.courseId)
        .map((course) => course.name)
        .firstOrNull;
    buffer
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${plan.id}@yotsuba-schedule')
      ..writeln('DTSTAMP:${_icalDate(DateTime.now())}')
      ..writeln('DTSTART:${_icalDate(start)}')
      ..writeln('DTEND:${_icalDate(end)}')
      ..writeln('SUMMARY:${_escapeIcal(plan.title)}')
      ..writeln(
        'DESCRIPTION:${_escapeIcal('${courseName ?? '课程计划'} · ${plan.notes}')}',
      )
      ..writeln('END:VEVENT');
  }
  buffer.writeln('END:VCALENDAR');
  return buffer.toString();
}

DateTime _atTime(DateTime date, String value) {
  final parts = value.split(':').map(int.parse).toList();
  return DateTime(date.year, date.month, date.day, parts[0], parts[1]);
}

String _icalDate(DateTime value) =>
    "${DateFormat("yyyyMMdd'T'HHmmss").format(value.toUtc())}Z";

String _escapeIcal(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
