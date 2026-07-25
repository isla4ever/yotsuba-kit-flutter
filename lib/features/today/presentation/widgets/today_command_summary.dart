import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule/features/today/application/today_layout_controller.dart';
import 'package:yotsuba_schedule/features/today/application/today_view_model.dart';

class TodayCommandSummary extends StatelessWidget {
  const TodayCommandSummary({
    required this.size,
    required this.viewModel,
    required this.weatherHint,
    super.key,
  });

  final TodayTileSize size;
  final TodayViewModel viewModel;
  final String weatherHint;

  @override
  Widget build(BuildContext context) {
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
    final title =
        lead?.course.name ??
        (viewModel.courses.isEmpty ? '今天没有课程' : '今天的课已全部结束');
    final detail = lead == null
        ? (viewModel.courses.isEmpty ? '把时间留给自己的计划' : '可以开始整理作业和明日物品')
        : '${lead.timeLabel} · ${lead.course.room}';
    final progress = (viewModel.progress * 100).round().clamp(0, 100);

    if (size.rows == 1) {
      return _CommandCard(
        padding: EdgeInsets.all(size.columns == 1 ? 10 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _LeadBlock(
                state: state,
                status: lead?.status,
                title: title,
                detail: detail,
                countdown: countdown,
                compact: true,
                showDetail: size.columns == 2,
              ),
            ),
            SizedBox(width: size.columns == 1 ? 7 : 14),
            _ProgressRing(
              progress: progress,
              size: size.columns == 1 ? 52 : 62,
            ),
          ],
        ),
      );
    }

    if (size.columns == 1) {
      return _CommandCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StateBadge(state: state, status: lead?.status),
                const Spacer(),
                _ProgressRing(progress: progress, size: 56),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.15,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.palette.textSoft),
            ),
            const SizedBox(height: 7),
            Text(
              countdown,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.palette.todayAccent,
              ),
            ),
            const Spacer(),
            Divider(height: 1, color: context.palette.border),
            const SizedBox(height: 10),
            _Metrics(viewModel: viewModel, compact: true),
            const SizedBox(height: 10),
            _WeatherHint(text: weatherHint),
          ],
        ),
      );
    }

    return _CommandCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeadBlock(
                  state: state,
                  status: lead?.status,
                  title: title,
                  detail: detail,
                  countdown: countdown,
                  compact: false,
                  showDetail: true,
                ),
              ),
              const SizedBox(width: 14),
              _ProgressRing(progress: progress, size: 84),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.palette.border),
          const SizedBox(height: 14),
          _Metrics(viewModel: viewModel),
          const SizedBox(height: 13),
          _WeatherHint(text: weatherHint),
        ],
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

class _LeadBlock extends StatelessWidget {
  const _LeadBlock({
    required this.state,
    required this.status,
    required this.title,
    required this.detail,
    required this.countdown,
    required this.compact,
    required this.showDetail,
  });

  final String state;
  final TodayCourseStatus? status;
  final String title;
  final String detail;
  final String countdown;
  final bool compact;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StateBadge(state: state, status: status, compact: compact),
        SizedBox(height: compact ? 5 : 10),
        Text(
          title,
          maxLines: compact ? 2 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            height: 1.15,
            fontSize: compact ? 16 : 24,
            fontWeight: FontWeight.w800,
            color: context.palette.text,
          ),
        ),
        if (showDetail) ...[
          SizedBox(height: compact ? 3 : 6),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 13,
              color: context.palette.textSoft,
            ),
          ),
        ],
        SizedBox(height: compact ? 5 : 12),
        Text(
          countdown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10 : 14,
            fontWeight: FontWeight.w700,
            color: context.palette.todayAccent,
          ),
        ),
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    required this.state,
    required this.status,
    this.compact = false,
  });

  final String state;
  final TodayCourseStatus? status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ongoing = status == TodayCourseStatus.ongoing;
    return Container(
      height: compact ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ongoing
            ? palette.todayAccentSoft
            : status == null
            ? palette.surfaceMuted
            : palette.blueSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        state,
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
          color: ongoing
              ? palette.todayAccent
              : status == null
              ? palette.textSoft
              : palette.blue,
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.viewModel, this.compact = false});

  final TodayViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(
          label: '剩余课程',
          value: '${viewModel.remainingCourses}',
          unit: '门',
          compact: compact,
        ),
        _MetricDivider(color: context.palette.border),
        _Metric(
          label: '还需上课',
          value: viewModel.remainingMinutes >= 60
              ? (viewModel.remainingMinutes / 60).toStringAsFixed(1)
              : '${viewModel.remainingMinutes}',
          unit: viewModel.remainingMinutes >= 60 ? '小时' : '分钟',
          compact: compact,
        ),
        if (!compact) ...[
          _MetricDivider(color: context.palette.border),
          _Metric(
            label: '今日总计',
            value: '${viewModel.courses.length}',
            unit: '门',
          ),
        ],
      ],
    );
  }
}

class _WeatherHint extends StatelessWidget {
  const _WeatherHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: context.palette.textFaint,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.palette.textSoft),
          ),
        ),
      ],
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
    final compact = size < 64;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: compact ? 5 : 7,
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
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              if (!compact)
                Text(
                  '课程进度',
                  style: TextStyle(fontSize: 9, color: palette.textFaint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              color: palette.textFaint,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: compact ? 8 : 10,
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
      Container(width: 1, height: 42, color: color);
}
