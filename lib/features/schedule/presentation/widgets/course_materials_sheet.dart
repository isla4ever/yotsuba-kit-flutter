import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/theme/app_motion.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

Future<void> showCourseMaterialsSheet(
  BuildContext context, {
  required Course course,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: appModalAnimationStyle,
    builder: (context) => _CourseMaterialsSheet(course: course),
  );
}

class _CourseMaterialsSheet extends ConsumerStatefulWidget {
  const _CourseMaterialsSheet({required this.course});

  final Course course;

  @override
  ConsumerState<_CourseMaterialsSheet> createState() =>
      _CourseMaterialsSheetState();
}

class _CourseMaterialsSheetState extends ConsumerState<_CourseMaterialsSheet> {
  late final List<String> _materials;
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _materials = [...widget.course.materials];
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          2,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textFaint,
                        ),
                      ),
                      Text(
                        '上课携带',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.scheduleAccentSoft,
                border: Border.all(
                  color: palette.scheduleAccent.withValues(alpha: 0.22),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: palette.scheduleAccent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '只记录真正需要带到课堂的物品\n最多 8 项，每项不超过 20 个字',
                      style: TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composer,
                    autofocus: _materials.isEmpty,
                    maxLength: 20,
                    enabled: _materials.length < 8,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '例如：高等数学教材',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '添加携带物品',
                  onPressed: _materials.length < 8 ? _add : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_materials.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '未设置时，课程详情不会显示携带提示',
                  style: TextStyle(fontSize: 12, color: palette.textFaint),
                ),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (var index = 0; index < _materials.length; index++)
                    InputChip(
                      avatar: Icon(
                        Icons.book_outlined,
                        size: 16,
                        color: palette.scheduleAccent,
                      ),
                      label: Text(_materials[index]),
                      onDeleted: () =>
                          setState(() => _materials.removeAt(index)),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('保存携带物品'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add() {
    final value = _composer.text.trim();
    if (value.isEmpty || _materials.length >= 8) return;
    if (!_materials.contains(value)) setState(() => _materials.add(value));
    _composer.clear();
  }

  void _save() {
    ref
        .read(scheduleControllerProvider.notifier)
        .updateCourseMaterials(widget.course.id, _materials);
    Navigator.pop(context);
  }
}
