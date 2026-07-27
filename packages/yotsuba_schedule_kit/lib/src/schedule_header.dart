import 'package:flutter/material.dart';

import 'config.dart';
import 'engine.dart';
import 'theme.dart';
import 'weather.dart';

class YsHeaderAction {
  const YsHeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class YsScheduleHeader extends StatelessWidget {
  const YsScheduleHeader({
    required this.week,
    required this.totalWeeks,
    required this.style,
    this.title = '本学期课表',
    this.termStart,
    this.theme = YsScheduleTheme.light,
    this.weather,
    this.actions = const [],
    this.adjustable = true,
    this.onPrevious,
    this.onNext,
    this.onWeekTap,
    this.onWeatherTap,
    this.onStyleChanged,
    super.key,
  });

  final int week;
  final int totalWeeks;
  final String title;
  final DateTime? termStart;
  final YsHeaderStyle style;
  final YsScheduleTheme theme;
  final YsWeatherSnapshot? weather;
  final List<YsHeaderAction> actions;
  final bool adjustable;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onWeekTap;
  final VoidCallback? onWeatherTap;
  final ValueChanged<YsHeaderStyle>? onStyleChanged;

  double get preferredHeight => switch (style) {
        YsHeaderStyle.compact => 54,
        YsHeaderStyle.standard => 72,
        YsHeaderStyle.expanded => 98,
        YsHeaderStyle.none => 0,
      };

  @override
  Widget build(BuildContext context) {
    if (style == YsHeaderStyle.none) return const SizedBox.shrink();
    return SizedBox(
      height: preferredHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surface1.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: theme.border)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final compact =
              style == YsHeaderStyle.compact || constraints.maxWidth < 620;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 16,
              vertical: compact ? 6 : 10,
            ),
            child: compact ? _compactContent(context) : _wideContent(context),
          );
        }),
      ),
    );
  }

  Widget _compactContent(BuildContext context) {
    return Row(
      children: [
        _iconButton('上一周', Icons.chevron_left, onPrevious),
        Expanded(child: _weekButton(compact: true)),
        _iconButton('下一周', Icons.chevron_right, onNext),
        if (weather != null || onWeatherTap != null) _weatherButton(),
        if (actions.isNotEmpty) _actionMenu(),
        if (adjustable) _styleButton(),
      ],
    );
  }

  Widget _wideContent(BuildContext context) {
    final range = _dateRange();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: style == YsHeaderStyle.expanded ? 19 : 15,
                  fontWeight: FontWeight.w800,
                  color: theme.text1,
                ),
              ),
              if (style == YsHeaderStyle.expanded && range != null) ...[
                const SizedBox(height: 3),
                Text(
                  range,
                  style: TextStyle(fontSize: 11, color: theme.text3),
                ),
              ],
            ],
          ),
        ),
        _iconButton('上一周', Icons.chevron_left, onPrevious),
        _weekButton(compact: false),
        _iconButton('下一周', Icons.chevron_right, onNext),
        const SizedBox(width: 4),
        if (weather != null || onWeatherTap != null) _weatherButton(),
        for (final action in actions)
          _iconButton(action.label, action.icon, action.onPressed),
        if (adjustable) _styleButton(),
      ],
    );
  }

  Widget _weekButton({required bool compact}) {
    return Semantics(
      button: true,
      label: '选择周次，当前第 $week 周',
      child: InkWell(
        onTap: onWeekTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '第 $week 周',
                style: TextStyle(
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: theme.text1,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down, size: 17, color: theme.text3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherButton() {
    final current = weather?.current;
    return Tooltip(
      message: current == null
          ? '获取天气'
          : '${current.label ?? ysWeatherLabel(current.kind)} '
              '${current.temperatureC?.round() ?? ''}°',
      child: IconButton(
        onPressed: onWeatherTap,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            YsWeatherGlyph(
              kind: current?.kind ?? YsWeatherKind.neutral,
              size: 19,
              animate: current != null,
              color: theme.text2,
            ),
            if (current?.temperatureC != null) ...[
              const SizedBox(width: 2),
              Text(
                '${current!.temperatureC!.round()}°',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.text2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionMenu() {
    return PopupMenuButton<int>(
      tooltip: '更多操作',
      icon: Icon(Icons.more_horiz, color: theme.text2),
      onSelected: (index) => actions[index].onPressed(),
      itemBuilder: (context) => [
        for (var index = 0; index < actions.length; index++)
          PopupMenuItem(
            value: index,
            child: Row(children: [
              Icon(actions[index].icon, size: 18),
              const SizedBox(width: 10),
              Text(actions[index].label),
            ]),
          ),
      ],
    );
  }

  Widget _styleButton() {
    final next = switch (style) {
      YsHeaderStyle.compact => YsHeaderStyle.standard,
      YsHeaderStyle.standard => YsHeaderStyle.expanded,
      YsHeaderStyle.expanded || YsHeaderStyle.none => YsHeaderStyle.compact,
    };
    return _iconButton(
      '切换 Header 样式',
      Icons.view_agenda_outlined,
      () => onStyleChanged?.call(next),
    );
  }

  Widget _iconButton(String tooltip, IconData icon, VoidCallback? callback) {
    return IconButton(
      tooltip: tooltip,
      onPressed: callback,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: theme.text2),
    );
  }

  String? _dateRange() {
    if (termStart == null) return null;
    final start = dateFor(termStart!, week, 1);
    final end = dateFor(termStart!, week, 7);
    return '${start.month} 月 ${start.day} 日 - ${end.month} 月 ${end.day} 日 · 共 $totalWeeks 周';
  }
}
