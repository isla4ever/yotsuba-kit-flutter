# Architecture

## 设计目标

- 离线优先：核心课表和今日视图不依赖网络。
- 移动优先：Android/iOS 使用相同领域模型，并允许桌面端扩展布局。
- 数据源可替换：开源仓库只提供 mock，实现方可以接入 JSON、ICS 或学校插件。
- 视觉可核对：Flutter 展示组件与原 Vue 模块保持一一对应，方便逐屏回归。
- 领域逻辑可测试：周次、单双周和倒计时不依赖具体 Widget。

## 数据流

```text
Mock / Import Adapter -> ScheduleController -> Feature Providers -> Widgets
                              |                       |
                              |                       +-> Today aggregation
                              +-> SharedPreferences   +-> Schedule / planning UI
```

`MockScheduleRepository` 负责构造演示数据；`ScheduleLocalRepository` 负责版本化 JSON 持久化；`ScheduleController` 是课程、日计划、课程计划和携带物品的唯一写入口。今日和课表页面只订阅 Provider，不直接保存数据。

## 模块边界

- `domain/models`：课程、日待办、课程计划和课表数据。
- `core/utils`：日期、教学周和课程过滤算法。
- `features/schedule/application`：课表与计划状态、空闲时间安排和持久化写入。
- `features/schedule/presentation/planning`：课程计划表单、完成确认和历史记录入口。
- `features/schedule/presentation/widgets`：课表头、星期栏、12 节次网格、课程卡片和数据迁移。
- `features/today`：今日聚合、核心摘要、课程时间轴、任务和携带准备。
- `features/weather`：定位状态机、16 天缓存、天气图标和原创 CustomPainter 场景。
- `features/onboarding`：只在首次使用出现、可重播的聚焦引导。
- `features/settings`：主题、动画、课表密度与数据重置。

## 完成记录

课程作业完成前由展示层二次确认，确认后调用 `ScheduleController.setCoursePlanCompleted`。领域模型保留 `completed`、`completedAt`、`createdAt` 和延期次数；恢复任务时只清除完成状态与时间，不删除计划。完整状态会进入本地 JSON、课表码和数据分享，可直接作为后续学期总结的数据基础。

## 动效边界

- 周切换由 `PageView` 负责手势和页面生命周期，课程卡不参与布局插值。
- 页面落定后由单个 `AnimationController` 驱动课程卡的分批透明度和 4px 位移，不为每张卡创建控制器。
- 天气场景独立在 `RepaintBoundary` 中绘制，并尊重“减少动态效果”。

## 展示层映射

```text
TodayDashboard.vue             -> TodayScreen
TodayCommandSummary.vue        -> TodayCommandSummary
TodayCourseTimeline.vue        -> TodayCourseTimeline
TodayReadinessBoard.vue        -> TodayReadinessBoard
ScheduleHeader.vue             -> ScheduleHeader
WeekdayHeader.vue              -> WeekTimetable header
ScheduleGrid.vue               -> WeekTimetable grid
ScheduleCourseCard.vue         -> WeekTimetable course card
ScheduleActionDock.vue         -> ScheduleActionDock
CourseDetailContent.vue        -> CourseDetailSheet
```

颜色、圆角、边框和浅深色语义集中在 `AppPalette`，页面组件不重新定义另一套视觉系统。

## 数据源扩展

后续可以将 `MockScheduleRepository` 抽象为接口：

```dart
abstract interface class ScheduleRepository {
  Future<ScheduleData> load();
}
```

任何网络实现都应先转换为领域模型，再交给 Controller；Widget 不应知道接口地址或鉴权方式。
