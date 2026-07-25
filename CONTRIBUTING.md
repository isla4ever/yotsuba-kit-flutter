# Contributing

感谢参与 Yotsuba Schedule。

## 开发约定

1. 功能代码放在对应的 `features/` 内，跨功能代码才进入 `core/`。
2. 数据源通过 repository/Provider 替换，不在 Widget 中直接请求网络。
3. 不提交真实学生信息、学校账号、Cookie、Token 或私有接口地址。
4. 新增算法或交互时补充单元测试或组件测试。
5. 提交前运行格式化、静态分析和完整测试。

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

提交信息建议采用 Conventional Commits，例如 `feat: add calendar export`。
