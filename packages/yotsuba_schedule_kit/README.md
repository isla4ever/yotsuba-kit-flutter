# yotsuba_schedule_kit Flutter 课表组件库

面向 Flutter 的可复用课表与「今日」组件库。它与
[`@iyotsuba/schedule-vue`](https://www.npmjs.com/package/@iyotsuba/schedule-vue)、
[`@iyotsuba/schedule-react`](https://www.npmjs.com/package/@iyotsuba/schedule-react)
和 Web Components 版本共享能力边界，同时保留 Flutter 原生的 Material
交互、自适应弹层和长按布局体验。

这个目录是**依赖包本体**；[`example/`](example/) 是只通过公开 API 构建的完整演示应用。

源码仓库：[yotsuba-kit-flutter](https://github.com/isla4ever/yotsuba-kit-flutter)；Web 主体组件库：[yotsuba-kit](https://github.com/isla4ever/yotsuba-kit)；Vue / React / 原生 Web 演示：[yotsuba-kit-playground](https://github.com/isla4ever/yotsuba-kit-playground)。

## 安装

```bash
flutter pub add yotsuba_schedule_kit
```

要求 Flutter 3.27 或更高版本。组件库本身只依赖 Flutter SDK，不绑定状态管理、网络、定位或日历插件。

## 能力

- 中国高校学期语义：单双周、起止周、假日、调休补班、重叠课程和非本周状态
- 七种换周模式：`wave`、`slide`、`fade`、`cube`、`drop`、`zoom`、`none`
- 旧周保留到离场动画结束，骨架常驻，不出现空白帧或瞬间闪退
- 三档周 Header、三档课表信息密度、六套配色；课程卡默认实时天气，微光 / 辉光 / 极光 / 呼吸与天气层自动互斥
- 精简 / 适中 / 全面课程详情，课程色 / 天气 / 极简三种 Hero
- 天气快照与 Provider 协议、逐日表头图标/最高温、课程卡色调、详情联动和默认动态场景
- 每类弹窗独立默认位置，支持底部、居中、右侧，并可在弹窗 Header 内临时切换
- 课程模型支持 `books` / `materialDetails` / `tasks`，并兼容旧版字符串 `materials`
- `YsToday` 内置七种模块，长按进入布局编辑，整卡拖动排序；选中单卡后显示贴边四角缩放控点，并支持自定义 Builder
- 浅色 / 深色主题令牌、自定义背景、自定义 Today 模块和宿主动作回调
- `MediaQuery.disableAnimations`、显式 `reduceMotion`、语义标签和键盘可达的 Material 控件

## 快速开始

高层 `YsSchedule` 已组合周 Header、周选择器、课表、天气和内置课程详情：

```dart
class SchedulePageState extends State<SchedulePage> {
  int week = 1;

  @override
  Widget build(BuildContext context) {
    return YsSchedule(
      week: week,
      totalWeeks: 20,
      termStart: DateTime(2026, 9, 7),
      courses: const [
        YsCourse(
          id: 'math',
          name: '高等数学',
          teacher: '张老师',
          location: '教一 201',
          weekday: 1,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 20,
          books: [
            YsCourseBook(title: '高等数学（第八版）', required: true),
          ],
          materialDetails: [
            YsCourseMaterial(name: '计算器', kind: YsCourseMaterialKind.device),
          ],
          tasks: [
            YsCourseTask(id: 'math-3', title: '完成第三章课后题'),
          ],
          note: '第八周随堂测验',
        ),
      ],
      onWeekChanged: (value) => setState(() => week = value),
      transition: YsTransition.wave,
      headerStyle: YsHeaderStyle.standard,
      density: YsScheduleDensity.normal,
      cardEffect: YsCardEffect.none,
      weatherCardBackground: true,
      detail: const YsCourseDetailConfig(
        layout: YsDetailLayout.standard,
        hero: YsDetailHero.weather,
      ),
      sheets: const YsSheetConfig(
        placements: {
          YsSheetKind.weekPicker: YsSheetPlacement.center,
          YsSheetKind.courseDetail: YsSheetPlacement.bottom,
        },
      ),
    );
  }
}
```

宿主可把导出、分享和日历同步放在 Header 右侧；组件库只发起动作，不擅自执行副作用：

```dart
headerActions: [
  YsHeaderAction(
    icon: Icons.file_download_outlined,
    label: '导出 ICS',
    onPressed: exportIcs,
  ),
  YsHeaderAction(
    icon: Icons.share_outlined,
    label: '分享课表',
    onPressed: shareSchedule,
  ),
  YsHeaderAction(
    icon: Icons.sync_alt,
    label: '同步系统日历',
    onPressed: syncCalendar,
  ),
],
```

## 今日模块

`YsToday` 与课表复用同一份课程、计划和天气数据。长按任意模块进入布局调整，尺寸变化通过受控回调返回宿主：

```dart
YsToday(
  courses: courses,
  termStart: termStart,
  dayPlans: plans,
  weather: weather,
  widgets: widgets,
  onWidgetsChanged: (value) => setState(() => widgets = value),
  onCourseTap: openCourse,
)
```

内置 id：

```dart
YsTodayWidgetIds.nextCourse
YsTodayWidgetIds.timeline
YsTodayWidgetIds.readiness
YsTodayWidgetIds.plans
YsTodayWidgetIds.courseTasks
YsTodayWidgetIds.weekGlance
YsTodayWidgetIds.weather
```

自定义模块通过 `customBuilders` 注入，不需要 fork 组件库。空数据可用 `emptyText` 统一设置，或用 `emptyTexts` 按模块覆盖。

`YsTodayBuildContext.size` 会随四角缩放实时变化。自定义模块应按 `columns / rows` 披露不同层级，小卡保留关键数字，大卡可以加入图表：

```dart
customBuilders: {
  'study-load': (context, data) => StudyLoadCard(
    columns: data.size.columns,
    rows: data.size.rows,
    showChart: data.size.columns == 2 && data.size.rows == 2,
  ),
},
```

组件在尺寸变化时对卡片宽高和内容执行协调过渡；`reduceMotion` 或系统减少动态效果开启时会禁用该动画。

## 天气接入

组件库不直接请求定位，也不固定天气供应商。宿主负责权限、定位、缓存和网络，然后传入 `YsWeatherSnapshot`；也可以实现 Provider：

```dart
class AppWeatherProvider implements YsWeatherProvider {
  @override
  Future<YsWeatherSnapshot> getSnapshot() async {
    final position = await locationService.currentPosition();
    return weatherApi.load(position.latitude, position.longitude);
  }

  @override
  Stream<YsWeatherSnapshot>? get snapshots => weatherApi.updates;
}

YsSchedule(
  weatherProvider: AppWeatherProvider(),
  weatherScene: true,
  // ...
)
```

这种边界让应用自行选择 `geolocator`、系统定位或学校提供的位置，不会因为引入课表组件就被迫申请权限。

## 全局默认与局部调整

设置页适合保存长期默认值；局部模块保留即时控制：

| 能力 | 全局默认 | 模块内即时控制 |
| --- | --- | --- |
| 周 Header 档位 | `headerStyle` | Header 右侧档位按钮 |
| 课程详情档位 | `YsCourseDetailConfig.layout` | 详情 Header 密度菜单 |
| 弹窗位置 | `YsSheetConfig.placements` | 每个弹窗 Header 位置按钮 |
| Today 布局 | `widgets` | 长按卡片后整卡拖动 / 四角缩放 |

宿主可通过 `adjustable: false`、`headerAdjustable: false` 或 `arrangeable: false` 隐藏相应入口。

## 低层课表

只需要网格时可直接使用 `YsWeekTimetable`。它保留受控 `week`、滑动请求、重叠组回调和全部动画能力，不会自动打开周选择器或课程详情。

纯算法函数 `buildWeekModel`、`buildDisplayCourses`、`buildOverlapGroups`、`dateFor`、`weekOf` 也可独立使用。

## 跨框架对应

| Flutter | Vue / React / Elements |
| --- | --- |
| `YsSchedule` | `<YsSchedule>` / `<ys-schedule>` |
| `YsWeekTimetable` | Vue 课表网格内部实现 |
| `YsToday` | `<YsToday>` / `<ys-today>` |
| `YsTransition` | `BuiltinTransitionName` |
| `YsCourseDetailConfig` | `detail` |
| `YsSheetConfig` | `sheets` |
| `YsWeatherSnapshot` | `WeatherSnapshot` |

Web 版本文档与在线演示见 [Yotsuba Kit](https://isla4ever.github.io/yotsuba-kit/)。

## 示例与验证

```bash
cd example
flutter run -d chrome
```

发布前验证：

```bash
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
cd example
flutter build web --release
cd ..
dart pub publish --dry-run
```

## License

[MIT](LICENSE)
