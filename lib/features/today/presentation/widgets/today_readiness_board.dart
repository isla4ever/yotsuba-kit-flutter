import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_panel.dart';

class TodayReadinessBoard extends StatelessWidget {
  const TodayReadinessBoard({
    required this.dayTasks,
    required this.coursePlans,
    required this.courses,
    required this.todayCourses,
    required this.wide,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onTogglePlan,
    required this.onOpenPlan,
    required this.onOpenMaterials,
    required this.onOpenSchedule,
    super.key,
  });

  final List<DayTask> dayTasks;
  final List<CoursePlan> coursePlans;
  final List<Course> courses;
  final List<TodayCourse> todayCourses;
  final bool wide;
  final VoidCallback onAddTask;
  final ValueChanged<String> onToggleTask;
  final ValueChanged<CoursePlan> onTogglePlan;
  final ValueChanged<CoursePlan> onOpenPlan;
  final ValueChanged<Course> onOpenMaterials;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final materials = <(Course, List<String>)>[
      for (final item in todayCourses)
        if (item.course.materials.isNotEmpty)
          (item.course, item.course.materials),
    ];
    final taskPanel = TodayTaskPanel(
      tasks: dayTasks,
      onAdd: onAddTask,
      onToggle: onToggleTask,
    );
    final workPanel = TodayCourseWorkPanel(
      plans: coursePlans,
      courses: courses,
      onToggle: onTogglePlan,
      onOpen: onOpenPlan,
    );
    final materialPanel = TodayMaterialsPanel(
      materials: materials,
      onOpenCourse: onOpenMaterials,
      onEmptyTap: onOpenSchedule,
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: taskPanel),
          const SizedBox(width: 10),
          Expanded(child: workPanel),
          const SizedBox(width: 10),
          Expanded(child: materialPanel),
        ],
      );
    }

    return Column(
      children: [
        taskPanel,
        const SizedBox(height: 12),
        workPanel,
        const SizedBox(height: 12),
        materialPanel,
      ],
    );
  }
}

class TodayTaskPanel extends StatelessWidget {
  const TodayTaskPanel({
    required this.tasks,
    required this.onAdd,
    required this.onToggle,
    this.compact = false,
    super.key,
  });

  final List<DayTask> tasks;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TodayPanel(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          TodaySectionHeading(
            eyebrow: '当天待办',
            title: '还要做什么',
            trailing: IconButton(
              tooltip: '添加当天待办',
              onPressed: onAdd,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(Icons.add_rounded, size: 21),
            ),
          ),
          if (tasks.isEmpty)
            _PanelEmpty(
              icon: Icons.task_alt_rounded,
              label: '今天还没有待办',
              onTap: onAdd,
              compact: compact,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  for (final task in tasks.take(compact ? 1 : 3))
                    _TaskRow(task: task, onTap: () => onToggle(task.id)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onTap});

  final DayTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: task.completed
                    ? palette.todayAccent
                    : Colors.transparent,
                border: Border.all(
                  color: task.completed ? palette.todayAccent : palette.border,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: task.completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: task.completed ? palette.textFaint : palette.text,
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayCourseWorkPanel extends StatelessWidget {
  const TodayCourseWorkPanel({
    required this.plans,
    required this.courses,
    required this.onToggle,
    required this.onOpen,
    this.compact = false,
    super.key,
  });

  final List<CoursePlan> plans;
  final List<Course> courses;
  final ValueChanged<CoursePlan> onToggle;
  final ValueChanged<CoursePlan> onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pending = plans
        .where((plan) => !plan.completed)
        .take(compact ? 1 : 3)
        .toList();
    return TodayPanel(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          const TodaySectionHeading(eyebrow: '课程作业', title: '临近截止'),
          if (pending.isEmpty)
            const _PanelEmpty(
              icon: Icons.library_books_outlined,
              label: '暂无待完成作业',
              compact: true,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  for (final plan in pending)
                    _WorkRow(
                      plan: plan,
                      courseName:
                          courses
                              .where((course) => course.id == plan.courseId)
                              .map((course) => course.name)
                              .firstOrNull ??
                          '课程计划',
                      onToggle: () => onToggle(plan),
                      onOpen: () => onOpen(plan),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.plan,
    required this.courseName,
    required this.onToggle,
    required this.onOpen,
  });

  final CoursePlan plan;
  final String courseName;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onOpen,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    plan.dueAt == null
                        ? '$courseName · 未设置截止时间'
                        : '$courseName · ${DateFormat('M月d日').format(plan.dueAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: palette.todayAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayMaterialsPanel extends StatelessWidget {
  const TodayMaterialsPanel({
    required this.materials,
    required this.onOpenCourse,
    required this.onEmptyTap,
    this.compact = false,
    super.key,
  });

  final List<(Course, List<String>)> materials;
  final ValueChanged<Course> onOpenCourse;
  final VoidCallback onEmptyTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final itemCount = materials.fold<int>(
      0,
      (total, group) => total + group.$2.length,
    );
    return TodayPanel(
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: Column(
        children: [
          TodaySectionHeading(
            eyebrow: '出发检查',
            title: '今天要带什么',
            trailing: materials.isEmpty
                ? Icon(
                    Icons.menu_book_outlined,
                    size: 21,
                    color: palette.scheduleAccent,
                  )
                : _MaterialCountBadge(count: itemCount),
          ),
          if (materials.isEmpty)
            _PanelEmpty(
              icon: Icons.bookmark_add_outlined,
              label: '还没有设置携带资料',
              onTap: onEmptyTap,
              compact: compact,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 300;
                  final width = twoColumns
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: [
                      for (final group in materials.take(
                        twoColumns ? (compact ? 2 : 4) : (compact ? 1 : 2),
                      ))
                        SizedBox(
                          width: width,
                          child: _MaterialCourseRow(
                            course: group.$1,
                            names: group.$2,
                            onTap: () => onOpenCourse(group.$1),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MaterialCourseRow extends StatelessWidget {
  const _MaterialCourseRow({
    required this.course,
    required this.names,
    required this.onTap,
  });

  final Course course;
  final List<String> names;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.scheduleAccentSoft, palette.surfaceMuted],
          ),
          border: Border.all(color: palette.border.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.72),
                border: Border.all(
                  color: palette.scheduleAccent.withValues(alpha: 0.14),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 17,
                color: palette.scheduleAccent,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textSoft,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final name in names.take(2))
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface.withValues(alpha: 0.76),
                              border: Border.all(color: palette.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ),
                      if (names.length > 2)
                        Text(
                          '+${names.length - 2}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: palette.scheduleAccent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: palette.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCountBadge extends StatelessWidget {
  const _MaterialCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.scheduleAccentSoft,
        border: Border.all(
          color: palette.scheduleAccent.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.scheduleAccent,
            ),
          ),
          const SizedBox(width: 3),
          Text('件', style: TextStyle(fontSize: 9, color: palette.textSoft)),
        ],
      ),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: compact ? 72 : 88),
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 21 : 24, color: palette.todayAccent),
              SizedBox(height: compact ? 4 : 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.textSoft),
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
