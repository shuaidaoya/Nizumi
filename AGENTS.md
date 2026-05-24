# Project Rules for Kazumi

## CI Workflow Rules（最重要）

### 规则总则：CI workflow 文件与源代码同等重要

CI workflow（`.github/workflows/release.yaml`）中存在对源代码文件的**硬引用**。这些引用不会被编译器检查，**本地测试通过不代表 CI 构建通过**。每次代码变更必须考虑对 CI 的影响。

### 规则 1：CI 引用的文件不可删除或重命名

`release.yaml` 中存在如下类型的硬引用：
- `sed -i "..." lib/utils/mortis.dart` — 对特定文件的路径引用
- `cp build/app/outputs/.../app-arm64-v8a-release.apk Kazumi_android_${tag}.apk` — 对构建产物路径的引用

**任何被 CI 引用的文件（路径、文件名）变更时，必须同步更新 workflow**。操作前先 grep：
```bash
grep -r "文件名" .github/workflows/
```

### 规则 2：CI 中的 GitHub Actions 变量引用必须健壮

**不要使用** bash 字符串操作提取 tag 名：
```yaml
# 脆弱：只在 tag push 时生效，workflow_dispatch 时会残留 refs/heads/ 前缀
echo "tag=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
```

**始终使用** `github.ref_name`：
```yaml
# 健壮：任何触发方式下都返回干净的短名
echo "tag=${{ github.ref_name }}" >> $GITHUB_ENV
```

| 触发方式 | `GITHUB_REF` | `github.ref_name` |
|---|---|---|
| tag push `v1.0.0` | `refs/tags/v1.0.0` | `v1.0.0` |
| workflow_dispatch (main) | `refs/heads/main` | `main` |

### 规则 3：`flutter test` 不能替代 CI 验证

`release.yaml` 中还有 `flutter test` 和 `flutter analyze` 两个可本地验证的 job。但以下 CI 专用步骤本地无法测试：
- `sed` 密钥注入（依赖 GitHub Secrets）
- `flutter build apk/ios/linux/macos/windows`（依赖平台环境）
- 文件打包 / 重命名（依赖 tag 变量）

**本地测试通过 ≠ CI 构建通过**。提交前必须检查 CI 引用的文件路径是否存在、变量引用是否正确。

---

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
