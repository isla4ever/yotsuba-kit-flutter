import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_panel.dart';

class TodayCourseTimeline extends StatelessWidget {
  const TodayCourseTimeline({
    required this.size,
    required this.courses,
    required this.onOpenSchedule,
    super.key,
  });

  final TodayTileSize size;
  final List<TodayCourse> courses;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final pending = courses
        .where((item) => item.status != TodayCourseStatus.finished)
        .toList();
    final ordered = pending.isNotEmpty ? pending : courses.reversed.toList();
    final visibleCount = switch (size) {
      TodayTileSize.oneByOne => 1,
      TodayTileSize.twoByOne => 2,
      TodayTileSize.oneByTwo => 4,
      TodayTileSize.twoByTwo => 4,
    };
    final visible = ordered.take(visibleCount).toList();
    final compact = size == TodayTileSize.oneByOne;
    final horizontal = size == TodayTileSize.twoByOne;

    return TodayPanel(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineHeading(
            compact: compact,
            courseCount: courses.length,
            onOpenSchedule: onOpenSchedule,
          ),
          SizedBox(height: compact ? 7 : 10),
          Expanded(
            child: visible.isEmpty
                ? _EmptyTimeline(compact: compact, onTap: onOpenSchedule)
                : horizontal
                ? Row(
                    children: [
                      for (var index = 0; index < visible.length; index++) ...[
                        Expanded(
                          child: _TimelineCard(
                            item: visible[index],
                            compact: true,
                            onTap: onOpenSchedule,
                          ),
                        ),
                        if (index != visible.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) => _TimelineCard(
                      item: visible[index],
                      compact: compact,
                      showRoom: !compact,
                      onTap: onOpenSchedule,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineHeading extends StatelessWidget {
  const _TimelineHeading({
    required this.compact,
    required this.courseCount,
    required this.onOpenSchedule,
  });

  final bool compact;
  final int courseCount;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (compact) {
      return Row(
        children: [
          Icon(Icons.route_rounded, size: 16, color: palette.todayAccent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '今日行程',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
          Text(
            '$courseCount门',
            style: TextStyle(fontSize: 9, color: palette.textFaint),
          ),
        ],
      );
    }
    return TodaySectionHeading(
      eyebrow: '今日行程',
      title: '课程时间轴',
      trailing: IconButton(
        tooltip: '查看完整课表',
        onPressed: onOpenSchedule,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_forward_rounded,
          size: 18,
          color: palette.todayAccent,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.item,
    required this.compact,
    required this.onTap,
    this.showRoom = false,
  });

  final TodayCourse item;
  final bool compact;
  final bool showRoom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ongoing = item.status == TodayCourseStatus.ongoing;
    final finished = item.status == TodayCourseStatus.finished;
    final status = switch (item.status) {
      TodayCourseStatus.ongoing => '进行中',
      TodayCourseStatus.upcoming => '待上课',
      TodayCourseStatus.finished => '已结束',
    };
    return Opacity(
      opacity: finished ? 0.58 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 72 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 6,
          ),
          decoration: BoxDecoration(
            color: ongoing ? palette.todayAccentSoft : palette.surfaceMuted,
            border: Border.all(
              color: ongoing
                  ? palette.todayAccent.withValues(alpha: 0.2)
                  : palette.border,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: compact ? 42 : 34,
                decoration: BoxDecoration(
                  color: ongoing ? palette.todayAccent : palette.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: compact ? 7 : 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.course.name,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        height: 1.16,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      showRoom
                          ? '${item.timeLabel} · ${item.course.room}'
                          : item.timeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        color: palette.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ongoing ? palette.todayAccentSoft : palette.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      color: ongoing ? palette.todayAccent : palette.textSoft,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: compact ? 22 : 28,
              color: palette.todayAccent,
            ),
            const SizedBox(height: 5),
            Text(
              '今天没有排课',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
