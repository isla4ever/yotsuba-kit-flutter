# Yotsuba Schedule Kit Flutter 演示

这个应用只使用 `yotsuba_schedule_kit` 的公开 API，展示完整课表和 Today：七种换周动效、天气场景、弹层位置、课程详情密度、浅深主题、课程配色、教材 / 携带物 / 任务、卡片效果，以及长按整卡拖动和四角缩放。

```bash
flutter run -d chrome
```

底部导航只保留「课表」和「今日」。长期默认值放在悬浮设置入口中；模块内高频设置仍位于周 Header、课程详情 Header 和 Today 布局编辑入口。

Web 演示内置了约 325 KB 的 Noto Sans SC 字体子集，保证中文标签在不同环境中稳定渲染。字体子集继续遵循 `assets/fonts/OFL-NotoSansSC.txt` 中的 SIL Open Font License。

相关项目：

- Web 主体组件库：[yotsuba-kit](https://github.com/isla4ever/yotsuba-kit)
- Vue / React / 原生 Web 演示：[yotsuba-kit-playground](https://github.com/isla4ever/yotsuba-kit-playground)
- Flutter 仓库：[yotsuba-kit-flutter](https://github.com/isla4ever/yotsuba-kit-flutter)

「今日」默认同时展示 `1x1 / 1x2 / 2x1 / 2x2` 四种布局；大尺寸「本周一览」包含七日课程图表，可直接进入排版并观察选中、缩放和内容层级过渡。
