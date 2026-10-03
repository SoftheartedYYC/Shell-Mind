# ShellMind

[简体中文](#简体中文) | [English](#english)

<a id="简体中文"></a>

基于 Flutter 的 Android SSH 终端 + AI 助手应用。通过 SSH 连接服务器，让 AI Agent 在已连接的主机上执行命令（支持确认模式与审计日志），管理服务器列表，监控集群健康状态。

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-TBD-lightgrey)

---

## 功能特性

| 模块 | 功能 |
| --- | --- |
| **SSH 终端** | 密码 / 私钥认证（[dartssh2](https://pub.dev/packages/dartssh2)）；终端模拟 + 辅助键盘栏（[xterm](https://pub.dev/packages/xterm)）；断线自动重连（指数退避）；多会话全局注册表，离开页面会话不断开 |
| **AI Agent** | 确认模式 / 全自动双模式执行命令；危险命令拦截；可配置最大执行轮数；单对话内多服务器协同；执行过程时间线可视化；全量命令审计日志 |
| **AI 服务商** | 内置 DeepSeek / Qwen / GLM / MiMo / OpenAI（OpenAI 兼容协议）；自定义服务商（名称 + Base URL + 模型列表）；SSE 流式响应；模型选择弹窗（搜索过滤） |
| **服务器管理** | 增删改查，分组与搜索；卡片实时连接状态徽标；集群健康聚合卡片（uptime / load 探测）+ AI 一键诊断 |
| **安全与隐私** | 凭据经 `flutter_secure_storage` 加密存储；生物识别应用锁；隐藏 IP 模式；命令审计日志；错误诊断导出 |
| **效率功能** | AI 对话历史持久化；命令片段（AI 对话 / 终端双入口）；对话导出 Markdown；终端上下文附加到 AI 对话 |
| **本地化与主题** | 英文 / 简体中文界面；浅色 / 深色 / 跟随系统主题 |

## 截图

<!-- TODO: 截图待补充，预期存放于 docs/screenshots/ 目录。 -->

## 快速开始

### 从 Releases 安装

1. 前往 [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) 页面。
2. 下载最新 APK 并安装到 Android 设备。
3. 应用内也支持检查更新（基于 GitHub Releases）。

### 从源码构建

环境要求：Flutter 3.47+（要求 Dart SDK ^3.13.4）、Java 17+、Android SDK 36。

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

构建 Release APK：

```bash
flutter build apk --release
```

> **签名配置**：Release 签名需要两个文件（均已被 `.gitignore` 排除，不会提交仓库）：
>
> - `android/key.properties` —— 从 `android/key.properties.example` 复制并填入真实凭据；
> - `android/app/shellmind-release-key.jks` —— 签名密钥库。
>
> 两者缺失时构建会回退到 debug 签名（仅供本地调试，不可用于发布）。官方构建已在 JDK 17 与 JDK 25 上验证通过。

## 开发

```bash
# 静态分析
flutter analyze

# 单元与 Widget 测试（480 例）
flutter test
```

## CI/CD 发布

推送 `v*` 格式的 tag（如 `v1.4.1`）会触发 [GitHub Actions](.github/workflows/release.yml)：

1. 校验 tag 与 `pubspec.yaml` 中的版本一致（不一致直接失败）；
2. 构建签名的 Release APK（产物命名 `Shell-Mind-v{version}.apk`）；
3. 自动创建 GitHub Release 并上传 APK。

需要在仓库 **Settings → Secrets and variables → Actions** 配置两个 Secrets（均为文件内容的 Base64 编码）：

| Secret | 内容 |
| --- | --- |
| `KEYSTORE_BASE64` | 签名密钥库 `android/app/shellmind-release-key.jks` 的 Base64 |
| `KEY_PROPERTIES_BASE64` | `android/key.properties` 的 Base64 |

PowerShell 生成方式：`[Convert]::ToBase64String([IO.File]::ReadAllBytes('<文件路径>'))`

> Secrets 未配置时工作流会快速失败，不会发布 debug 签名的 APK。

## 技术栈

| 层 | 库 |
| --- | --- |
| 框架 | Flutter 3.47+ / Dart ^3.13.4 |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| SSH | dartssh2 |
| 终端模拟 | xterm |
| AI 传输 | dio（SSE 流式） |
| 本地存储 | hive_ce |
| 安全存储 | flutter_secure_storage |
| 生物识别 | local_auth |
| 应用内更新 | package_info_plus / open_filex / permission_handler |

## 免责声明

本应用允许 AI Agent 在真实服务器上执行命令，全自动模式下无需逐条确认。危险命令拦截仅为辅助手段，不构成安全保证。请勿在生产环境或重要主机上无人监督地启用全自动模式。使用本应用产生的一切后果由使用者自行承担。

## 许可证

License: TBD。

---

<a id="english"></a>

# ShellMind

[简体中文](#简体中文) | [English](#english)

Flutter-based Android SSH terminal + AI assistant app. Connect to your servers over SSH, run an AI agent that executes commands on connected hosts (with confirmation modes and audit logging), manage server fleets, and monitor cluster health.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-TBD-lightgrey)

---

## Features

| Module | Features |
| --- | --- |
| **SSH Terminal** | Password / private-key authentication ([dartssh2](https://pub.dev/packages/dartssh2)); terminal emulation with an auxiliary keyboard bar ([xterm](https://pub.dev/packages/xterm)); auto-reconnect with exponential backoff; global multi-session registry — sessions keep running when you navigate away |
| **AI Agent** | Runs commands in confirmation or fully automatic mode; dangerous-command interception; configurable maximum execution rounds; multi-server coordination from a single conversation; visual execution timeline; full command audit log |
| **AI Providers** | Built-in DeepSeek / Qwen / GLM / MiMo / OpenAI (OpenAI-compatible); custom providers (name + Base URL + models); SSE streaming responses; model picker sheet with search filtering |
| **Server Management** | CRUD with grouping and search; live connection-status badges on server cards; cluster health aggregation cards (uptime / load probing) with one-click AI diagnosis |
| **Security & Privacy** | Credentials encrypted via `flutter_secure_storage`; biometric app lock; hide-IP mode; command audit log; error-diagnosis export |
| **Productivity** | Persistent AI chat history; command snippets (AI chat / terminal dual entry); Markdown conversation export; attach terminal context to AI conversations |
| **Localization & Theming** | English / Simplified Chinese interface; light / dark / follow-system themes |

## Screenshots

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Getting Started

### Install from Releases

1. Go to the [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) page.
2. Download the latest APK and install it on your Android device.
3. The app also checks for updates in-app (via GitHub Releases).

### Build from Source

Requirements: Flutter 3.47+ (requires Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

> **Signing**: a signed release build requires two files (both excluded by `.gitignore` and never committed):
>
> - `android/key.properties` — copy from `android/key.properties.example` and fill in real credentials;
> - `android/app/shellmind-release-key.jks` — the release keystore.
>
> If either is missing, the build falls back to the debug signing config (local debugging only, not for distribution). Official builds have been verified with JDK 17 and JDK 25.

## Development

```bash
# Static analysis
flutter analyze

# Unit & widget tests (480 tests)
flutter test
```

## CI/CD Release

Pushing a `v*` tag (e.g. `v1.4.1`) triggers [GitHub Actions](.github/workflows/release.yml):

1. Verifies the tag matches the version in `pubspec.yaml` (fails otherwise);
2. Builds a signed release APK (`Shell-Mind-v{version}.apk`);
3. Creates a GitHub Release and uploads the APK automatically.

Two repository Secrets must be configured under **Settings → Secrets and variables → Actions** (both are Base64 of file contents):

| Secret | Content |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 of the release keystore `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 of `android/key.properties` |

Generate with PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> If the Secrets are missing, the workflow fails fast — it never publishes a debug-signed APK.

## Tech Stack

| Layer | Library |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| State management | flutter_riverpod |
| Routing | go_router |
| SSH | dartssh2 |
| Terminal emulation | xterm |
| AI transport | dio (SSE streaming) |
| Local storage | hive_ce |
| Secure storage | flutter_secure_storage |
| Biometrics | local_auth |
| In-app update | package_info_plus / open_filex / permission_handler |

## Disclaimer

This app lets an AI agent run commands on real servers, and fully automatic mode executes without per-command confirmation. Dangerous-command interception is a safeguard, not a guarantee. Do not enable automatic mode unattended on production or critical hosts. Use at your own risk.

## License

License: TBD.
