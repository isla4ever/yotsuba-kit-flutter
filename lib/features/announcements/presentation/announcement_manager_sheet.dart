import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/local_announcement.dart';
import 'package:yotsuba_schedule/features/announcements/application/local_announcement_controller.dart';
import 'package:yotsuba_schedule/features/announcements/presentation/local_announcement_dialog.dart';

Future<void> showAnnouncementManagerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: appModalAnimationStyle,
    builder: (context) => const _AnnouncementManagerSheet(),
  );
}

class _AnnouncementManagerSheet extends ConsumerWidget {
  const _AnnouncementManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localAnnouncementProvider);
    final items = [...state.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本机公告中心',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '用于演示公告弹窗，不会发送到其他设备',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '新建公告',
                    onPressed: () => _edit(context, ref),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _edit(context, ref),
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('创建第一条公告'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _AnnouncementTile(
                          value: item,
                          onPreview: () =>
                              showLocalAnnouncementDialog(context, item),
                          onEdit: () => _edit(context, ref, initial: item),
                          onPublish: () => ref
                              .read(localAnnouncementProvider.notifier)
                              .setPublished(item.id, !item.published),
                          onDelete: () => ref
                              .read(localAnnouncementProvider.notifier)
                              .delete(item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    LocalAnnouncement? initial,
  }) async {
    final title = TextEditingController(text: initial?.title ?? '');
    final content = TextEditingController(text: initial?.content ?? '');
    var publish = initial?.published ?? false;
    final submitted = await showDialog<bool>(
      context: context,
      animationStyle: appModalAnimationStyle,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initial == null ? '新建公告' : '编辑公告'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: initial == null,
                  maxLength: 32,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: content,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    alignLabelWithHint: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: publish,
                  title: const Text('保存后立即发布'),
                  subtitle: const Text('下次启动时弹出，除非用户勾选不再提醒'),
                  onChanged: (value) => setDialogState(() => publish = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true) {
      ref
          .read(localAnnouncementProvider.notifier)
          .save(
            id: initial?.id,
            title: title.text,
            content: content.text,
            publish: publish,
          );
    }
    title.dispose();
    content.dispose();
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.value,
    required this.onPreview,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
  });

  final LocalAnnouncement value;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: value.published
                      ? palette.todayAccentSoft
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value.published ? '已发布' : '草稿',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: value.published
                        ? palette.todayAccent
                        : palette.textSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: palette.textSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.publishedAt == null
                ? '创建于 ${DateFormat('M.d HH:mm').format(value.createdAt)}'
                : '发布于 ${DateFormat('M.d HH:mm').format(value.publishedAt!)}',
            style: TextStyle(fontSize: 9, color: palette.textFaint),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              TextButton(onPressed: onPreview, child: const Text('预览')),
              TextButton(onPressed: onEdit, child: const Text('编辑')),
              TextButton(
                onPressed: onPublish,
                child: Text(value.published ? '取消发布' : '发布'),
              ),
              TextButton(onPressed: onDelete, child: const Text('删除')),
            ],
          ),
        ],
      ),
    );
  }
}
