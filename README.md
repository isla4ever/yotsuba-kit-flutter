# Yotsuba Schedule

一个面向 Android、iOS、Web 和桌面端的离线优先 Flutter 课表。展示层按原 Vue 项目的“今日指挥台”和“课表”逐组件转译，保留相同的信息层级、紧凑密度、浅深色令牌与交互入口；开源版使用可替换的 mock repository，不依赖学校教务系统、账号或私有后端。

## 当前功能

- 今日指挥台：下一节课、倒计时、剩余课程与课时进度
- 今日课程时间轴、可增改完成的日待办、课程计划与携带物品
- 周课表：12 节次、午休分隔、单双周、非本周课程、重叠角标和紧凑模式
- 本地课程：新增、编辑、删除、周次/单双周设置，不上传任何数据
- 课程计划：截止到某次课程或指定时间、优先级、预计时长、子任务、延期和自动安排空闲时间
- 完成确认与历史：课程作业确认后才归档，保留完成时间并支持恢复，为后续学期总结提供数据
- 携带提醒：为每门课记录教材、资料和必备物品
- 课表编辑模式、课程详情、首次聚焦引导与设置中重播
- 原生跟手换周、分批波浪淡入、页面切换过渡和减少动态效果
- 定位天气、16 天预报缓存、天气图标和原创动态天气背景
- JSON 导入/分享、课表码、ICS 日历导出和离线持久化
- Android、iOS、Web、macOS、Windows、Linux 工程配置

## 技术选择

- [Flutter](https://github.com/flutter/flutter)：跨平台 UI 与运行时
- [Riverpod](https://github.com/rrousselGit/riverpod)：状态与依赖注入
- [go_router](https://github.com/flutter/packages/tree/main/packages/go_router)：声明式三栏导航
- [shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences)：版本化本地课表、计划与设置存储
- [geolocator](https://github.com/Baseflow/flutter-geolocator)：跨平台定位权限与低精度位置
- [Open-Meteo](https://open-meteo.com/)：无需密钥的天气预报数据源
- Noto Sans SC：随应用打包的开源中文字体，许可证见 `assets/fonts/OFL-NotoSansSC.txt`

课表网格、重叠课程、天气场景、跟手分页和响应式布局均由项目内代码实现，没有引入商业日历或动画 SDK。天气背景只参考了 Flutter 社区的 Canvas 分层思路，图形和动效均为本项目原创实现。

## 开始运行

```bash
flutter pub get
flutter run
```

常用验证命令：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

## 目录结构

```text
lib/
  app/                  路由和应用入口
  core/                 原版设计令牌、主题、设置与课表算法
  data/local/           版本化本地持久化
  data/mock/            可替换的示例数据源
  data/weather/         天气服务适配器
  domain/models/        与 UI 无关的领域模型
  features/today/       今日标题、核心摘要、时间轴与准备看板
  features/schedule/    课表、日计划、课程计划、数据迁移与详情弹窗
  features/weather/     定位状态、天气缓存、图标与背景场景
  features/onboarding/  首次聚焦式操作引导
  features/settings/    通用设置与离线数据管理
```

更详细的边界见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 数据源适配

开源仓库不会包含任何教务系统爬虫、Cookie、服务器地址或学校账号。接入新数据源时，实现与 `MockScheduleRepository` 相同的返回模型，并在 Provider 中替换 repository 即可。

## Roadmap

- 原生长按拖选节次与冲突解决
- Android/iOS 本地通知和桌面小组件
- ICS 双向订阅与系统日历写入适配器
- 学期总结：课程投入、按时完成率和延期趋势
- CSV 与高校教务数据源插件协议

## License

项目代码使用 [MIT License](LICENSE)。第三方依赖仍遵循各自许可证。
