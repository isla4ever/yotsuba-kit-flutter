# yotsuba_schedule_kit

课表组件库(Flutter 版):中国高校学期语义 + 招牌波浪覆盖换周动画。
npm 生态孪生版:[`@iyotsuba/schedule-vue`](https://www.npmjs.com/package/@iyotsuba/schedule-vue) · [文档官网](https://isla4ever.github.io/yotsuba-kit/)

## 特性

- **波浪覆盖换周**:骨架常驻、稳定格静止、旧周垫底新卡逐列扫入——任何一帧不出现空网格
- **学期语义引擎**:单双周、调休补班、假日、重叠课连通分组、非本周置灰,纯函数可独立使用
- **主题令牌**:light / dark 内置,课程颜色按名稳定分配,`YsScheduleTheme` 全量可定制
- 受控 `week` + 滑动手势回调,重叠课点击返回整组

## 快速开始

```dart
YsWeekTimetable(
  week: week,
  courses: const [
    YsCourse(
      id: 'math', name: '高等数学', location: '教1-201',
      weekday: 1, startSection: 1, endSection: 2,
      startWeek: 1, endWeek: 20,
    ),
    YsCourse(
      id: 'pe', name: '体育（单周）',
      weekday: 4, startSection: 1, endSection: 2,
      startWeek: 1, endWeek: 16, parity: YsWeekParity.odd,
    ),
  ],
  termStart: DateTime(2026, 9, 7),
  onWeekRequested: (direction) =>
      setState(() => week = (week + direction).clamp(1, 20)),
  onCourseTap: (course, stack) => openDetail(course, stack),
)
```

调休补班:

```dart
YsWeekTimetable(
  // 9/28(周日)补周一的课
  overrides: const [
    YsDayOverride(date: '2026-09-28', kind: YsDayOverrideKind.makeup, sourceWeekday: 1),
  ],
  // ...
)
```

完整示例见 `example/`。
