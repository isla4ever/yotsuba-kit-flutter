import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';

class TodayCommandSummary extends StatelessWidget {
  const TodayCommandSummary({required this.viewModel, super.key});

  final TodayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lead = viewModel.lead;
    final state = switch (lead?.status) {
      TodayCourseStatus.ongoing => '进行中',
      TodayCourseStatus.upcoming => '下一节',
      _ => '已完成',
    };
    final nowMinutes = viewModel.now.hour * 60 + viewModel.now.minute;
    final countdown = switch (lead?.status) {
      TodayCourseStatus.ongoing => '${lead!.endMinutes - nowMinutes}分钟后下课',
      TodayCourseStatus.upcoming => '${lead!.startMinutes - nowMinutes}分钟后上课',
      _ when viewModel.courses.isEmpty => '今天没有课程',
      _ => '今日课程已结束',
    };
    final progress = (viewModel.progress * 100).round().clamp(0, 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 21,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: lead?.status == TodayCourseStatus.ongoing
                                ? palette.todayAccentSoft
                                : lead == null
                                ? palette.surfaceMuted
                                : palette.blueSoft,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            state,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: lead?.status == TodayCourseStatus.ongoing
                                  ? palette.todayAccent
                                  : lead == null
                                  ? palette.textSoft
                                  : palette.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lead?.course.name ??
                              (viewModel.courses.isEmpty
                                  ? '今天没有课程'
                                  : '今天的课已全部结束'),
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            height: 1.2,
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead == null
                              ? (viewModel.courses.isEmpty
                                    ? '把时间留给自己的计划'
                                    : '可以开始整理作业和明日物品')
                              : '${lead.timeLabel} · ${lead.course.room}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textSoft,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          countdown,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.todayAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  _ProgressRing(progress: progress, size: compact ? 62 : 72),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: palette.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Metric(
                    label: '剩余课程',
                    value: '${viewModel.remainingCourses}',
                    unit: '门',
                  ),
                  _MetricDivider(color: palette.border),
                  _Metric(
                    label: '还需上课',
                    value: viewModel.remainingMinutes >= 60
                        ? (viewModel.remainingMinutes / 60).toStringAsFixed(1)
                        : '${viewModel.remainingMinutes}',
                    unit: viewModel.remainingMinutes >= 60 ? '小时' : '分钟',
                  ),
                  _MetricDivider(color: palette.border),
                  _Metric(
                    label: '今日总计',
                    value: '${viewModel.courses.length}',
                    unit: '门',
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: palette.textFaint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '体感较舒适，17°-24°',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: palette.textSoft),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.size});

  final int progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: palette.track,
              valueColor: AlwaysStoppedAnimation(palette.todayAccent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$progress%',
                style: TextStyle(
                  height: 1.05,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              Text(
                '课程进度',
                style: TextStyle(fontSize: 8, color: palette.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: palette.textFaint)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: palette.textSoft,
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

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: color);
}
