# Project Rules for Kazumi

## CI Compatibility: `mortis.dart` / `dandan_credentials.dart`

### Background
DanDanPlay API 密钥通过 CI 的 `sed` 替换占位符注入。原始文件 `lib/utils/mortis.dart` 在重构中被重命名为 `lib/utils/dandan_credentials.dart`，但 CI workflow 仍引用旧路径导致构建失败。

### File Architecture
```
lib/utils/mortis.dart              ← CI sed 目标（占位符，原始路径）
lib/utils/dandan_credentials.dart  ← 业务代码进口（桥接层，from mortis.dart）
```

- **`mortis.dart`** — 包含占位符 `kvpx7qkqjh` / `rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax`，CI 发布构建时 `release.yaml` 用 `sed` 替换为真实密钥。**此文件名必须保留**以兼容 upstream（Predidit/Kazumi）。
- **`dandan_credentials.dart`** — 通过 `import 'package:kazumi/utils/mortis.dart'` 导入，对外提供 `dandanCredentials` 常量。业务代码统一导入此文件。

### Rules
1. **不要删除 `mortis.dart`**，即使重构改名也要保留原文件并桥接到新文件。
2. **占位符字符串 `kvpx7qkqjh` 和 `rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax` 必须保持在 `mortis.dart` 中**，否则 CI 的 sed 替换会失败。
3. **CI workflow（`.github/workflows/release.yaml`）** 中对 `mortis.dart` 的 sed 路径不要修改，保持与 upstream 一致。
4. 新增需要 DanDanPlay 密钥的代码，导入 `dandan_credentials.dart` 而非 `mortis.dart`。

## Test Files
- 所有测试文件放在 `test/` 目录下
- `test/` 目录已被 `.gitignore` 忽略，不会提交到 GitHub

## Architecture
- 框架：Flutter 3.44.0 / Dart
- 状态管理：MobX（页面级）+ Provider（全局主题）
- 路由：flutter_modular
- 存储：Hive CE（8个Box）
- 网络层：Dio + 自定义 XPath 爬虫引擎
- 项目是 [Predidit/Kazumi](https://github.com/Predidit/Kazumi) 的 fork

## Key Directories
| 目录 | 职责 |
|---|---|
| `lib/pages/` | UI 页面 |
| `lib/modules/` | 数据模型 |
| `lib/services/` | 业务逻辑 |
| `lib/request/` | HTTP 层 |
| `lib/plugins/` | 插件引擎 |
| `lib/repositories/` | 数据访问 |
| `lib/bean/widget/` | 自定义 Widget |

## Commits
- 写明 type：`feat:` / `fix:` / `refactor:` / `docs:` / `test:`
- 关注与 upstream 的合并兼容性
