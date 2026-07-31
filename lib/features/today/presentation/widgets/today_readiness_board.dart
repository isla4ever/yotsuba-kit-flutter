import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
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
      size: TodayTileSize.twoByTwo,
      tasks: dayTasks,
      onAdd: onAddTask,
      onToggle: onToggleTask,
    );
    final workPanel = TodayCourseWorkPanel(
      size: TodayTileSize.twoByTwo,
      plans: coursePlans,
      courses: courses,
      onToggle: onTogglePlan,
      onOpen: onOpenPlan,
    );
    final materialPanel = TodayMaterialsPanel(
      size: TodayTileSize.twoByTwo,
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
    required this.size,
    required this.tasks,
    required this.onAdd,
    required this.onToggle,
    super.key,
  });

  final TodayTileSize size;
  final List<DayTask> tasks;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final compact = size == TodayTileSize.oneByOne;
    final itemLimit = switch (size) {
      TodayTileSize.oneByOne => 1,
      TodayTileSize.twoByOne => 2,
      TodayTileSize.oneByTwo => 4,
      TodayTileSize.twoByTwo => 3,
    };
    final visible = tasks.take(itemLimit).toList();
    if (compact) {
      final completed = tasks.where((task) => task.completed).length;
      final pending = tasks.length - completed;
      return TodayPanel(
        padding: const EdgeInsets.all(10),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日计划 · 剩 $pending 项',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: context.palette.textFaint,
                ),
              ),
              const Spacer(),
              Text(
                '$completed/${tasks.length}',
                style: TextStyle(
                  height: 1,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '已完成',
                style: TextStyle(fontSize: 9, color: context.palette.textSoft),
              ),
            ],
          ),
        ),
      );
    }
    return TodayPanel(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        children: [
          _DashboardPanelHeading(
            icon: Icons.task_alt_rounded,
            eyebrow: '当天待办',
            title: '还要做什么',
            compact: compact,
            trailing: IconButton(
              tooltip: '添加当天待办',
              onPressed: onAdd,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: compact ? 26 : 34,
                height: compact ? 26 : 34,
              ),
              icon: Icon(Icons.add_rounded, size: compact ? 18 : 21),
            ),
          ),
          SizedBox(height: compact ? 6 : 9),
          if (size == TodayTileSize.twoByTwo) ...[
            _TaskStats(tasks: tasks),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: visible.isEmpty
                ? _PanelEmpty(
                    icon: Icons.task_alt_rounded,
                    label: '今天还没有待办',
                    onTap: onAdd,
                    compact: compact,
                  )
                : size == TodayTileSize.twoByOne
                ? Row(
                    children: [
                      for (var index = 0; index < visible.length; index++) ...[
                        Expanded(
                          child: _TaskSummary(
                            task: visible[index],
                            onTap: () => onToggle(visible[index].id),
                          ),
                        ),
                        if (index != visible.length - 1)
                          const SizedBox(width: 7),
                      ],
                    ],
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 3),
                    itemBuilder: (context, index) => _TaskRow(
                      task: visible[index],
                      compact: compact,
                      onTap: () => onToggle(visible[index].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskStats extends StatelessWidget {
  const _TaskStats({required this.tasks});

  final List<DayTask> tasks;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final completed = tasks.where((task) => task.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.blueSoft.withValues(alpha: 0.66),
        border: Border.all(color: palette.blue.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: palette.track,
                  valueColor: AlwaysStoppedAnimation(palette.blue),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatMetric(label: '已完成', value: '$completed'),
          _StatDivider(color: palette.border),
          _StatMetric(label: '待处理', value: '${tasks.length - completed}'),
          _StatDivider(color: palette.border),
          _StatMetric(label: '今日总计', value: '${tasks.length}'),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.compact,
    required this.onTap,
  });

  final DayTask task;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: compact ? 62 : 42,
        child: Row(
          children: [
            _CheckMark(completed: task.completed, compact: compact),
            SizedBox(width: compact ? 7 : 9),
            Expanded(
              child: Text(
                task.title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1.2,
                  fontSize: compact ? 11 : 13,
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

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.task, required this.onTap});

  final DayTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _CheckMark(completed: task.completed, compact: true),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1.15,
                  fontSize: 11,
                  color: task.completed ? palette.textFaint : palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.completed, required this.compact});

  final bool completed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final extent = compact ? 19.0 : 22.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: extent,
      height: extent,
      decoration: BoxDecoration(
        color: completed ? palette.todayAccent : Colors.transparent,
        border: Border.all(
          color: completed ? palette.todayAccent : palette.border,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: completed
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class TodayCourseWorkPanel extends StatelessWidget {
  const TodayCourseWorkPanel({
    required this.size,
    required this.plans,
    required this.courses,
    required this.onToggle,
    required this.onOpen,
    super.key,
  });

  final TodayTileSize size;
  final List<CoursePlan> plans;
  final List<Course> courses;
  final ValueChanged<CoursePlan> onToggle;
  final ValueChanged<CoursePlan> onOpen;

  @override
  Widget build(BuildContext context) {
    final compact = size == TodayTileSize.oneByOne;
    final itemLimit = switch (size) {
      TodayTileSize.oneByOne => 1,
      TodayTileSize.twoByOne => 2,
      TodayTileSize.oneByTwo => 3,
      TodayTileSize.twoByTwo => 3,
    };
    final pending = plans
        .where((plan) => !plan.completed)
        .take(itemLimit)
        .toList();
    if (compact) {
      return TodayPanel(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '课程任务 · 剩 ${pending.length} 项',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.palette.textFaint,
              ),
            ),
            const Spacer(),
            Text(
              '${pending.length}',
              style: TextStyle(
                height: 1,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: context.palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pending.isEmpty ? '暂无待完成任务' : pending.first.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: context.palette.textSoft),
            ),
          ],
        ),
      );
    }
    return TodayPanel(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        children: [
          _DashboardPanelHeading(
            icon: Icons.library_books_outlined,
            eyebrow: '课程作业',
            title: '临近截止',
            compact: compact,
            trailing: pending.isEmpty
                ? null
                : _CountBadge(count: pending.length, unit: '项'),
          ),
          SizedBox(height: compact ? 6 : 9),
          if (size == TodayTileSize.twoByTwo) ...[
            _WorkStats(plans: pending),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: pending.isEmpty
                ? const _PanelEmpty(
                    icon: Icons.library_books_outlined,
                    label: '暂无待完成作业',
                    compact: true,
                  )
                : size == TodayTileSize.twoByOne
                ? Row(
                    children: [
                      for (var index = 0; index < pending.length; index++) ...[
                        Expanded(
                          child: _WorkRow(
                            plan: pending[index],
                            courseName: _courseName(pending[index]),
                            compact: true,
                            onToggle: () => onToggle(pending[index]),
                            onOpen: () => onOpen(pending[index]),
                          ),
                        ),
                        if (index != pending.length - 1)
                          const SizedBox(width: 7),
                      ],
                    ],
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: pending.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) => _WorkRow(
                      plan: pending[index],
                      courseName: _courseName(pending[index]),
                      compact: compact,
                      onToggle: () => onToggle(pending[index]),
                      onOpen: () => onOpen(pending[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _courseName(CoursePlan plan) =>
      courses
          .where((course) => course.id == plan.courseId)
          .map((course) => course.name)
          .firstOrNull ??
      '课程计划';
}

class _WorkStats extends StatelessWidget {
  const _WorkStats({required this.plans});

  final List<CoursePlan> plans;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final urgent = plans
        .where((plan) => plan.priority == PlanPriority.urgent)
        .length;
    final high = plans
        .where((plan) => plan.priority == PlanPriority.high)
        .length;
    final regular = plans.length - urgent - high;
    final minutes = plans.fold<int>(
      0,
      (total, plan) => total + plan.estimatedMinutes,
    );
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (urgent > 0)
                    Expanded(
                      flex: urgent,
                      child: ColoredBox(color: palette.danger),
                    ),
                  if (high > 0)
                    Expanded(
                      flex: high,
                      child: ColoredBox(color: palette.warning),
                    ),
                  Expanded(
                    flex: regular == 0 ? 1 : regular,
                    child: ColoredBox(color: palette.blue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: palette.danger, label: '紧急 $urgent'),
              const SizedBox(width: 10),
              _LegendDot(color: palette.warning, label: '高优 $high'),
              const Spacer(),
              Text(
                '预计 $minutes 分钟',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: palette.textSoft,
                ),
              ),
            ],
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
    required this.compact,
    required this.onToggle,
    required this.onOpen,
  });

  final CoursePlan plan;
  final String courseName;
  final bool compact;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 66 : 50),
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
        decoration: BoxDecoration(
          color: compact ? palette.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1.15,
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan.dueAt == null
                        ? '$courseName · 未设截止'
                        : '$courseName · ${DateFormat('M月d日').format(plan.dueAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: palette.textFaint),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: compact ? 27 : 30,
                height: compact ? 27 : 30,
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 17,
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
    required this.size,
    required this.materials,
    required this.onOpenCourse,
    required this.onEmptyTap,
    super.key,
  });

  final TodayTileSize size;
  final List<(Course, List<String>)> materials;
  final ValueChanged<Course> onOpenCourse;
  final VoidCallback onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final compact = size == TodayTileSize.oneByOne;
    final itemCount = materials.fold<int>(
      0,
      (total, group) => total + group.$2.length,
    );
    final groupLimit = switch (size) {
      TodayTileSize.oneByOne => 1,
      TodayTileSize.twoByOne => 2,
      TodayTileSize.oneByTwo => 3,
      TodayTileSize.twoByTwo => 4,
    };
    final visible = materials.take(groupLimit).toList();
    final horizontal = size == TodayTileSize.twoByOne;
    final grid = size == TodayTileSize.twoByTwo;

    return TodayPanel(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        children: [
          _DashboardPanelHeading(
            icon: Icons.backpack_outlined,
            eyebrow: '出发检查',
            title: '今天要带什么',
            compact: compact,
            trailing: materials.isEmpty
                ? null
                : _CountBadge(count: itemCount, unit: '件'),
          ),
          SizedBox(height: compact ? 6 : 9),
          if (size == TodayTileSize.twoByTwo) ...[
            _MaterialStats(
              courseCount: materials.length,
              materialCount: itemCount,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: visible.isEmpty
                ? _PanelEmpty(
                    icon: Icons.bookmark_add_outlined,
                    label: '还没有设置携带资料',
                    onTap: onEmptyTap,
                    compact: compact,
                  )
                : horizontal
                ? Row(
                    children: [
                      for (var index = 0; index < visible.length; index++) ...[
                        Expanded(
                          child: _MaterialCourseCard(
                            course: visible[index].$1,
                            names: visible[index].$2,
                            compact: true,
                            dense: true,
                            onTap: () => onOpenCourse(visible[index].$1),
                          ),
                        ),
                        if (index != visible.length - 1)
                          const SizedBox(width: 7),
                      ],
                    ],
                  )
                : grid
                ? GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.25,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => _MaterialCourseCard(
                      course: visible[index].$1,
                      names: visible[index].$2,
                      compact: false,
                      onTap: () => onOpenCourse(visible[index].$1),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) => _MaterialCourseCard(
                      course: visible[index].$1,
                      names: visible[index].$2,
                      compact: compact,
                      onTap: () => onOpenCourse(visible[index].$1),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MaterialStats extends StatelessWidget {
  const _MaterialStats({
    required this.courseCount,
    required this.materialCount,
  });

  final int courseCount;
  final int materialCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.scheduleAccentSoft.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            size: 18,
            color: palette.scheduleAccent,
          ),
          const SizedBox(width: 7),
          _StatMetric(label: '课程', value: '$courseCount'),
          _StatDivider(color: palette.border),
          _StatMetric(label: '物品', value: '$materialCount'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              materialCount == 0 ? '为下一节课补充携带提醒' : '按课程收好，出门前逐项确认',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                height: 1.2,
                fontSize: 9,
                color: palette.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: palette.textFaint)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: color);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 8, color: context.palette.textSoft),
        ),
      ],
    );
  }
}

class _MaterialCourseCard extends StatelessWidget {
  const _MaterialCourseCard({
    required this.course,
    required this.names,
    required this.compact,
    this.dense = false,
    required this.onTap,
  });

  final Course course;
  final List<String> names;
  final bool compact;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        constraints: BoxConstraints(minHeight: dense ? 0 : (compact ? 64 : 60)),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: dense ? 4 : 7,
        ),
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
            if (!compact) ...[
              Container(
                width: 28,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: palette.scheduleAccent,
                ),
              ),
              const SizedBox(width: 8),
            ],
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
                      fontSize: dense ? 9 : (compact ? 10 : 11),
                      fontWeight: FontWeight.w700,
                      color: palette.textSoft,
                    ),
                  ),
                  SizedBox(height: dense ? 1 : 5),
                  Text(
                    names.take(dense ? 1 : (compact ? 2 : 3)).join(' · '),
                    maxLines: dense ? 1 : (compact ? 2 : 1),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1.15,
                      fontSize: dense ? 9 : (compact ? 10 : 11),
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanelHeading extends StatelessWidget {
  const _DashboardPanelHeading({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.compact,
    this.trailing,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (!compact) {
      return TodaySectionHeading(
        eyebrow: eyebrow,
        title: title,
        trailing: trailing,
      );
    }
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.todayAccent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.unit});

  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.scheduleAccentSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$count$unit',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: palette.scheduleAccent,
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(compact ? 7 : 10),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 20 : 24, color: palette.todayAccent),
            SizedBox(height: compact ? 4 : 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.15,
                fontSize: compact ? 10 : 12,
                color: palette.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
