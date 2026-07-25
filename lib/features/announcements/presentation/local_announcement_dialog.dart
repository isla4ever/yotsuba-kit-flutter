import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/local_announcement.dart';

Future<bool> showLocalAnnouncementDialog(
  BuildContext context,
  LocalAnnouncement value,
) async {
  var mute = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final palette = context.palette;
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value.title),
                    if (value.publishedAt != null)
                      Text(
                        DateFormat('yyyy.M.d HH:mm').format(value.publishedAt!),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: palette.textFaint,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context, mute),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.48,
              minWidth: 300,
            ),
            child: SingleChildScrollView(
              child: Text(
                value.content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),
          ),
          actions: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: mute,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('不再提醒这条公告'),
              onChanged: (value) => setDialogState(() => mute = value ?? false),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, mute),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    ),
  );
  return result == true;
}
