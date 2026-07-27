# Yotsuba Kit Flutter

Yotsuba 课表的 Flutter 开源实现。仓库同时包含一个完整离线课表应用、一个可发布到 pub.dev 的组件依赖，以及只使用依赖公开 API 的演示项目。

它与 Vue、React 和 Web Components 版本使用同一能力模型，但界面遵循 Flutter 原生交互：Material 控件、自适应底部 / 居中 / 右侧弹层、系统减少动态效果，以及长按进入 Today 布局编辑。

## Yotsuba 项目关系

| 项目 | 定位 |
| --- | --- |
| **[yotsuba-kit](https://github.com/isla4ever/yotsuba-kit)** | Web 主体组件库、NPM 包和文档官网 |
| **[yotsuba-kit-playground](https://github.com/isla4ever/yotsuba-kit-playground)** | Vue / React / 原生 Web 演示与依赖消费验证 |
| **[yotsuba-kit-flutter](https://github.com/isla4ever/yotsuba-kit-flutter)** | 当前仓库：Flutter 组件包、完整应用和 Flutter 演示 |

文档官网：[isla4ever.github.io/yotsuba-kit](https://isla4ever.github.io/yotsuba-kit/)；Flutter 包：[pub.dev/packages/yotsuba_schedule_kit](https://pub.dev/packages/yotsuba_schedule_kit)。

## 仓库组成

| 目录 | 定位 |
| --- | --- |
| `lib/` | 完整 Flutter 应用：离线数据、课程编辑、计划、天气、导入导出和系统能力 |
| `packages/yotsuba_schedule_kit/` | 可复用依赖包 `yotsuba_schedule_kit`，不绑定 Riverpod、定位或网络 |
| `packages/yotsuba_schedule_kit/example/` | package 演示：课表 / 今日 / 设置，所有功能只调用公开 API |

依赖包文档见 [`packages/yotsuba_schedule_kit/README.md`](packages/yotsuba_schedule_kit/README.md)。

## 组件能力

- 单双周、起止周、节次、假日、调休补班、重叠课和非本周状态
- wave / slide / fade / cube / drop / zoom / none 七种换周模式
- 旧周完整淡出、骨架常驻，避免切页闪空
- 精简 / 标准 / 展开周 Header，精简 / 适中 / 全面课程详情
- 课程卡与逐日天气联动，默认动态天气背景、星期图标/温度和可注入天气 Provider
- 每类弹窗分别配置底部、居中或右侧，弹窗 Header 可即时调整
- 六套课程配色、五种卡片特效、三档信息密度、浅深色主题和自定义背景
- 结构化教材、携带物和课程任务，同时保留旧版 `materials: List<String>`
- Today 七种内置模块，长按后整卡拖动换位，选中单卡后显示贴边四角缩放控点，并支持自定义 Builder
- `1x1 / 1x2 / 2x1 / 2x2` 分别展示摘要、纵向清单、紧凑趋势和完整图表，缩放时同步过渡内容层级
- 导出、分享、日历同步等副作用由宿主通过 Header 动作与详情回调接管

## 跨框架实现

- Web Core / Vue / React / Elements：[`isla4ever/yotsuba-kit`](https://github.com/isla4ever/yotsuba-kit)
- React 绑定：`@iyotsuba/schedule-react`
- Vue 绑定：`@iyotsuba/schedule-vue`
- Web Components：`@iyotsuba/schedule-elements`
- Web 演示：[`isla4ever/yotsuba-kit-playground`](https://github.com/isla4ever/yotsuba-kit-playground)
- Flutter 依赖：`yotsuba_schedule_kit`

Flutter 的 `YsSchedule` / `YsToday`、Web 的 `<YsSchedule>` / `<YsToday>` 和原生 Elements 使用相同的课程、天气、详情、弹窗和布局概念。平台相关能力仍由各自宿主接入，不把网络权限或系统副作用塞进 UI 组件。

## 运行完整应用

```bash
flutter pub get
flutter run
```

完整应用使用 Riverpod、go_router、shared_preferences、geolocator、Open-Meteo、文件分享与系统日历插件；所有课程与计划数据默认离线保存，开源仓库不包含教务账号、Cookie 或私有后端。

## 运行依赖演示

```bash
cd packages/yotsuba_schedule_kit/example
flutter pub get
flutter run -d chrome
```

演示底部只保留「课表 / 今日」。长期默认值位于设置 Dock；周 Header、课程详情、弹窗位置和 Today 布局仍可在各自模块内即时调整。

## 安装依赖

```bash
flutter pub add yotsuba_schedule_kit
```

最小接入：

```dart
YsSchedule(
  week: week,
  courses: courses,
  termStart: termStart,
  onWeekChanged: (value) => setState(() => week = value),
)
```

## 完整应用功能

- 今日下一节、课程时间线、日待办、课程计划和携带物品
- 课本、结构化资料与课程任务在详情和 Today 中共享展示
- 本地课程新增、编辑、删除、单双周和冲突展示
- 课程计划截止时间、优先级、子任务、延期、完成确认与历史恢复
- 定位天气、预报缓存、天气图标和动态天气场景
- JSON 导入 / 分享、课表码、ICS 导出和系统日历同步
- Android、iOS、Web、macOS、Windows、Linux 工程配置

## 验证

完整应用：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test
flutter test
flutter build web
```

依赖包：

```bash
cd packages/yotsuba_schedule_kit
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
dart pub publish --dry-run
```

## License

[MIT](LICENSE)
