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
    final taskPanel = _TaskPanel(
      tasks: dayTasks,
      onAdd: onAddTask,
      onToggle: onToggleTask,
    );
    final workPanel = _CourseWorkPanel(
      plans: coursePlans,
      courses: courses,
      onToggle: onTogglePlan,
      onOpen: onOpenPlan,
    );
    final materialPanel = _MaterialsPanel(
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: taskPanel),
              const SizedBox(width: 10),
              Expanded(child: workPanel),
            ],
          ),
        ),
        const SizedBox(height: 10),
        materialPanel,
      ],
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.tasks,
    required this.onAdd,
    required this.onToggle,
  });

  final List<DayTask> tasks;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return TodayPanel(
      child: Column(
        children: [
          TodaySectionHeading(
            eyebrow: '当天待办',
            title: '还要做什么',
            trailing: IconButton(
              tooltip: '添加当天待办',
              onPressed: onAdd,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              icon: const Icon(Icons.add_rounded, size: 17),
            ),
          ),
          if (tasks.isEmpty)
            _PanelEmpty(
              icon: Icons.task_alt_rounded,
              label: '今天还没有待办',
              onTap: onAdd,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                children: [
                  for (final task in tasks.take(3))
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
        height: 32,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
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
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
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

class _CourseWorkPanel extends StatelessWidget {
  const _CourseWorkPanel({
    required this.plans,
    required this.courses,
    required this.onToggle,
    required this.onOpen,
  });

  final List<CoursePlan> plans;
  final List<Course> courses;
  final ValueChanged<CoursePlan> onToggle;
  final ValueChanged<CoursePlan> onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = plans.where((plan) => !plan.completed).take(3).toList();
    return TodayPanel(
      child: Column(
        children: [
          const TodaySectionHeading(eyebrow: '课程作业', title: '临近截止'),
          if (pending.isEmpty)
            const _PanelEmpty(
              icon: Icons.library_books_outlined,
              label: '暂无待完成作业',
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 7),
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
        height: 40,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    plan.dueAt == null
                        ? '$courseName · 未设置截止时间'
                        : '$courseName · ${DateFormat('M月d日').format(plan.dueAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 8, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
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

class _MaterialsPanel extends StatelessWidget {
  const _MaterialsPanel({
    required this.materials,
    required this.onOpenCourse,
    required this.onEmptyTap,
  });

  final List<(Course, List<String>)> materials;
  final ValueChanged<Course> onOpenCourse;
  final VoidCallback onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TodayPanel(
      child: Column(
        children: [
          TodaySectionHeading(
            eyebrow: '出发检查',
            title: '今天要带什么',
            trailing: Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: palette.todayAccent,
            ),
          ),
          if (materials.isEmpty)
            _PanelEmpty(
              icon: Icons.bookmark_add_outlined,
              label: '还没有设置携带资料',
              onTap: onEmptyTap,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final group in materials.take(4))
                    SizedBox(
                      width: 158,
                      child: InkWell(
                        onTap: () => onOpenCourse(group.$1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.$1.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: palette.textFaint,
                                ),
                              ),
                              Text(
                                group.$2.join('、'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: palette.todayAccent),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: palette.textSoft),
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
