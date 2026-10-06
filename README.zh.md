# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

基于 Flutter 的 Android SSH 终端 + AI 助手应用。通过 SSH 连接服务器，让 AI Agent 在已连接的主机上执行命令（支持确认模式与审计日志），管理服务器列表，监控集群健康状态。

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 功能特性

| 模块 | 功能 |
| --- | --- |
| **SSH 终端** | 密码 / 私钥认证（[dartssh2](https://pub.dev/packages/dartssh2)）；终端模拟 + 辅助键盘栏（[xterm](https://pub.dev/packages/xterm)）；断线自动重连（指数退避）；多会话全局注册表，离开页面会话不断开；**6 套可选终端配色方案**（Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic） |
| **SFTP 文件浏览** | 目录浏览与逐级导航；文本文件预览；下载到应用本地；新建文件夹 / 重命名 / 删除 |
| **端口转发** | 本地转发（`ssh -L`）与远程转发（`ssh -R`）；活动隧道列表与一键关闭 |
| **AI Agent** | 确认模式 / 全自动双模式执行命令；危险命令拦截；可配置最大执行轮数；单对话内多服务器协同；执行过程时间线可视化；全量命令审计日志 |
| **AI 对话** | **代码块语法高亮**（shell / python / json / yaml / dockerfile / sql）；**多会话管理**（新建 / 切换 / 重命名 / 删除）；**对话历史搜索**（标题 + 消息正文）；对话导出 Markdown；终端上下文附加 |
| **AI 服务商** | 内置 DeepSeek / Qwen / GLM / MiMo / OpenAI（OpenAI 兼容协议）；自定义服务商（名称 + Base URL + 模型列表）；SSE 流式响应；模型选择弹窗（搜索过滤） |
| **服务器管理** | 增删改查，分组与搜索；卡片实时连接状态徽标；集群健康聚合卡片（uptime / load 探测）+ AI 一键诊断 |
| **导入导出** | 命令片段与服务器配置的 JSON 导出 / 导入（服务器凭据永不导出，导入项自动分配新 ID） |
| **通知** | 应用在后台时，SSH 会话断开 / AI 任务完成发送本地通知（可开关） |
| **安全与隐私** | 凭据经 `flutter_secure_storage` 加密存储；生物识别应用锁；隐藏 IP 模式；命令审计日志；错误诊断导出 |
| **效率功能** | AI 对话历史持久化；命令片段（AI 对话 / 终端双入口）；对话导出 Markdown；终端上下文附加到 AI 对话 |
| **本地化与主题** | 多语言界面（英语 / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano）；浅色 / 深色 / 跟随系统主题 |
| **平台** | Android（APK 按 ABI 分包）；iOS（Info.plist 已配置本地网络与 Face ID 用途说明，通知权限由插件请求） |

## 截图

<!-- TODO: 截图待补充，预期存放于 docs/screenshots/ 目录。 -->

## 快速开始

### 从 Releases 安装

1. 前往 [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) 页面。
2. 下载对应架构的 APK 并安装到 Android 设备（现代手机选 `arm64-v8a`，老旧 32 位设备选 `armeabi-v7a`，`x86_64` 仅供模拟器）。
3. 应用内也支持检查更新（基于 GitHub Releases，自动按设备 ABI 选择匹配包）。

### 从源码构建

环境要求：Flutter 3.47+（要求 Dart SDK ^3.13.4）、Java 17+、Android SDK 36。

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

构建 Release APK（按 ABI 分包，与 CI 发布产物一致）：

```bash
flutter build apk --release --split-per-abi
```

产物位于 `build/app/outputs/flutter-apk/`，生成 `app-arm64-v8a-release.apk`、`app-armeabi-v7a-release.apk`、`app-x86_64-release.apk` 三个包。仅本地真机调试时也可直接 `flutter build apk --release`（默认 fat 包约 63 MB，仅适合本机安装）。

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

# 单元与 Widget 测试（全量）
flutter test
```

## CI/CD 发布

推送 `v*` 格式的 tag（如 `v1.4.1`）会触发 [GitHub Actions](.github/workflows/release.yml)：

1. 校验 tag 与 `pubspec.yaml` 中的版本一致（不一致直接失败）；
2. 运行测试门禁（`flutter pub get` / `flutter analyze` / `flutter test`，任一失败即中止发布）；
3. 构建签名的 Release APK（`--split-per-abi`，产物命名 `Shell-Mind-v{version}-{abi}.apk`，含 arm64-v8a / armeabi-v7a / x86_64 三个包）；
4. 从 [CHANGELOG.md](CHANGELOG.md) 提取对应版本的中文变更说明作为 Release Notes，创建 GitHub Release 并上传全部分包 APK 与校验和。

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

本项目基于 [MIT License](LICENSE) 发布。
