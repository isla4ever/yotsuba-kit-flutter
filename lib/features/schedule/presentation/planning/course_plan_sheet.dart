import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_completion_dialog.dart';
import 'package:yotsuba_schedule/features/schedule/presentation/planning/course_plan_form.dart';

Future<void> showCoursePlanSheet(
  BuildContext context, {
  required Course course,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _CoursePlanSheet(courseId: course.id),
  );
}

class _CoursePlanSheet extends ConsumerStatefulWidget {
  const _CoursePlanSheet({required this.courseId});

  final String courseId;

  @override
  ConsumerState<_CoursePlanSheet> createState() => _CoursePlanSheetState();
}

class _CoursePlanSheetState extends ConsumerState<_CoursePlanSheet> {
  CoursePlan? _editing;
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final course = schedule.courses
        .where((item) => item.id == widget.courseId)
        .firstOrNull;
    if (course == null) return const SizedBox.shrink();
    final plans =
        schedule.coursePlans
            .where((plan) => plan.courseId == course.id)
            .toList()
          ..sort((a, b) {
            if (a.completed != b.completed) return a.completed ? 1 : -1;
            final dueA = a.dueAt ?? DateTime(9999);
            final dueB = b.dueAt ?? DateTime(9999);
            return dueA.compareTo(dueB);
          });
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _showForm
              ? CoursePlanForm(
                  key: ValueKey(_editing?.id ?? 'new-plan'),
                  course: course,
                  initial: _editing,
                  termStart: schedule.termStart,
                  totalWeeks: schedule.totalWeeks,
                  courseTimes: settings.summerSchedule
                      ? summerCourseTimes
                      : standardCourseTimes,
                  dayOverrides: schedule.dayOverrides,
                  onCancel: () => setState(() {
                    _showForm = false;
                    _editing = null;
                  }),
                  onSave: (plan) {
                    ref
                        .read(scheduleControllerProvider.notifier)
                        .saveCoursePlan(plan);
                    setState(() {
                      _showForm = false;
                      _editing = null;
                    });
                  },
                )
              : _PlanList(
                  key: const ValueKey('plan-list'),
                  course: course,
                  plans: plans,
                  onClose: () => Navigator.pop(context),
                  onCreate: () => setState(() {
                    _editing = null;
                    _showForm = true;
                  }),
                  onEdit: (plan) => setState(() {
                    _editing = plan;
                    _showForm = true;
                  }),
                ),
        ),
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({
    required this.course,
    required this.plans,
    required this.onClose,
    required this.onCreate,
    required this.onEdit,
    super.key,
  });

  final Course course;
  final List<CoursePlan> plans;
  final VoidCallback onClose;
  final VoidCallback onCreate;
  final ValueChanged<CoursePlan> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final active = plans.where((plan) => !plan.completed).toList();
    final completed = plans.where((plan) => plan.completed).toList();
    final controller = ref.read(scheduleControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(fontSize: 11, color: palette.textFaint),
                    ),
                    Text('课程计划', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '待完成',
                      style: TextStyle(fontSize: 10, color: palette.textFaint),
                    ),
                    Text(
                      '${active.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: active.isEmpty
                      ? null
                      : () => _arrangeAll(context, controller, active),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                  label: const Text('安排空闲时间'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: plans.isEmpty
                ? _EmptyPlans(onCreate: onCreate)
                : ListView(
                    children: [
                      for (final plan in active) ...[
                        _PlanTile(plan: plan, onEdit: () => onEdit(plan)),
                        const SizedBox(height: 7),
                      ],
                      if (completed.isNotEmpty)
                        ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          title: Text('已完成 ${completed.length} 项'),
                          children: [
                            for (final plan in completed)
                              _CompletedPlanTile(plan: plan),
                          ],
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建课程计划'),
            ),
          ),
        ],
      ),
    );
  }

  void _arrangeAll(
    BuildContext context,
    ScheduleController controller,
    List<CoursePlan> plans,
  ) {
    var arranged = 0;
    for (final plan in plans.where((item) => item.scheduledStart == null)) {
      if (controller.autoScheduleCoursePlan(plan.id) != null) arranged++;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(arranged > 0 ? '已为 $arranged 项计划找到空闲时间' : '暂时没有合适的空闲时间'),
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan, required this.onEdit});

  final CoursePlan plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final controller = ref.read(scheduleControllerProvider.notifier);
    final completedSubtasks = plan.subtasks
        .where((item) => item.completed)
        .length;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: _priorityColor(context, plan.priority)),
            Checkbox(
              value: false,
              onChanged: (_) async {
                if (await confirmCoursePlanCompletion(context, plan)) {
                  controller.setCoursePlanCompleted(plan.id, true);
                }
              },
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _PriorityBadge(priority: plan.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.dueAt == null
                            ? '未设置截止时间'
                            : '截止 ${DateFormat('M月d日 HH:mm').format(plan.dueAt!)}',
                        style: TextStyle(fontSize: 11, color: palette.textSoft),
                      ),
                      if (plan.subtasks.isNotEmpty)
                        Text(
                          '子任务 $completedSubtasks/${plan.subtasks.length} · 预计 ${plan.estimatedMinutes} 分钟',
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.textFaint,
                          ),
                        ),
                      if (plan.scheduledStart != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '已安排 ${DateFormat('M月d日 HH:mm').format(plan.scheduledStart!)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: palette.scheduleAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '计划操作',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'postpone') controller.postponeCoursePlan(plan.id);
                if (value == 'arrange') {
                  final start = controller.autoScheduleCoursePlan(plan.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        start == null
                            ? '暂时没有合适的空闲时间'
                            : '已安排到 ${DateFormat('M月d日 HH:mm').format(start)}',
                      ),
                    ),
                  );
                }
                if (value == 'delete') controller.deleteCoursePlan(plan.id);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'postpone', child: Text('延期一天')),
                PopupMenuItem(value: 'arrange', child: Text('安排空闲时间')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPlanTile extends ConsumerWidget {
  const _CompletedPlanTile({required this.plan});

  final CoursePlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final controller = ref.read(scheduleControllerProvider.notifier);
    return ListTile(
      dense: true,
      leading: Checkbox(
        value: true,
        onChanged: (_) => controller.setCoursePlanCompleted(plan.id, false),
      ),
      title: Text(
        plan.title,
        style: TextStyle(
          color: palette.textFaint,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      trailing: IconButton(
        tooltip: '删除',
        onPressed: () => controller.deleteCoursePlan(plan.id),
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_add, size: 38, color: palette.textFaint),
          const SizedBox(height: 8),
          const Text(
            '这门课还没有课程计划',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            '课堂作业、报告和复习任务都可以放在这里',
            style: TextStyle(fontSize: 11, color: palette.textFaint),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onCreate, child: const Text('创建第一项')),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final PlanPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(context, priority);
    final label = switch (priority) {
      PlanPriority.low => '低',
      PlanPriority.medium => '普通',
      PlanPriority.high => '高',
      PlanPriority.urgent => '紧急',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

Color _priorityColor(BuildContext context, PlanPriority priority) {
  final palette = context.palette;
  return switch (priority) {
    PlanPriority.low => palette.success,
    PlanPriority.medium => palette.scheduleAccent,
    PlanPriority.high => palette.warning,
    PlanPriority.urgent => palette.danger,
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
