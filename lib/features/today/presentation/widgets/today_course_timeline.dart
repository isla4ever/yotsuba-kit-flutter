import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';
import 'package:yotsuba_schedule/features/today/presentation/widgets/today_panel.dart';

class TodayCourseTimeline extends StatelessWidget {
  const TodayCourseTimeline({
    required this.courses,
    required this.onOpenSchedule,
    super.key,
  });

  final List<TodayCourse> courses;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pending = courses
        .where((item) => item.status != TodayCourseStatus.finished)
        .toList();
    final visible =
        (pending.isNotEmpty ? pending : courses.reversed.take(2).toList())
            .take(4)
            .toList();

    return TodayPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        children: [
          TodaySectionHeading(
            eyebrow: '今日行程',
            title: '课程时间轴',
            trailing: TextButton(
              onPressed: onOpenSchedule,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                foregroundColor: palette.todayAccent,
                textStyle: const TextStyle(fontSize: 10),
              ),
              child: const Row(
                children: [
                  Text('完整课表'),
                  Icon(Icons.chevron_right_rounded, size: 15),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            _EmptyTimeline(onTap: onOpenSchedule)
          else
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    bottom: 14,
                    left: 74,
                    child: Container(width: 1, color: palette.border),
                  ),
                  Column(
                    children: [
                      for (final item in visible)
                        _TimelineItem(item: item, onTap: onOpenSchedule),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.onTap});

  final TodayCourse item;
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
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  item.timeLabel,
                  style: TextStyle(fontSize: 9, color: palette.textSoft),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: ongoing ? palette.todayAccent : palette.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ongoing ? palette.todayAccentSoft : palette.blue,
                      spreadRadius: ongoing ? 2 : 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      item.course.room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: palette.textFaint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: ongoing
                      ? palette.todayAccentSoft
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 8,
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
  const _EmptyTimeline({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: 48,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: palette.todayAccent,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今天没有排课',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                Text(
                  '点击查看完整课表安排',
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
