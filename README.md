# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Flutter-based Android SSH terminal + AI assistant app. Connect to your servers over SSH, run an AI agent that executes commands on connected hosts (with confirmation modes and audit logging), manage server fleets, and monitor cluster health.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Features

| Module | Features |
| --- | --- |
| **SSH Terminal** | Password / private-key authentication ([dartssh2](https://pub.dev/packages/dartssh2)); terminal emulation with an auxiliary keyboard bar ([xterm](https://pub.dev/packages/xterm)); auto-reconnect with exponential backoff; global multi-session registry — sessions keep running when you navigate away; **6 selectable terminal color schemes** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **SFTP Browser** | Directory browsing with level-by-level navigation; text-file preview; download to local storage; mkdir / rename / delete |
| **Port Forwarding** | Local (`ssh -L`) and remote (`ssh -R`) tunnels; live tunnel list with one-tap close |
| **AI Agent** | Runs commands in confirmation or fully automatic mode; dangerous-command interception; configurable maximum execution rounds; multi-server coordination from a single conversation; visual execution timeline; full command audit log |
| **AI Chat** | **Code-block syntax highlighting** (shell / python / json / yaml / dockerfile / sql); **multi-session management** (new / switch / rename / delete); **conversation history search** (titles + message bodies); Markdown export; attach terminal context |
| **AI Providers** | Built-in DeepSeek / Qwen / GLM / MiMo / OpenAI (OpenAI-compatible); custom providers (name + Base URL + models); SSE streaming responses; model picker sheet with search filtering |
| **Server Management** | CRUD with grouping and search; live connection-status badges on server cards; cluster health aggregation cards (uptime / load probing) with one-click AI diagnosis |
| **Import & Export** | JSON export/import of command snippets and server configurations (credentials are never exported; imported entries get fresh IDs) |
| **Notifications** | Local alerts when an SSH session drops or an AI task finishes while the app is in the background (toggleable) |
| **Security & Privacy** | Credentials encrypted via `flutter_secure_storage`; biometric app lock; hide-IP mode; command audit log; error-diagnosis export |
| **Productivity** | Persistent AI chat history; command snippets (AI chat / terminal dual entry); Markdown conversation export; attach terminal context to AI conversations |
| **Localization & Theming** | Multi-language interface (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); light / dark / follow-system themes |
| **Platforms** | Android (per-ABI split APKs); iOS (Info.plist documents local-network and Face ID usage; notification permission is requested by the plugin) |

## Screenshots

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Getting Started

### Install from Releases

1. Go to the [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) page.
2. Download the APK matching your device's ABI and install it (`arm64-v8a` for modern phones, `armeabi-v7a` for legacy 32-bit devices, `x86_64` for emulators only).
3. The app also checks for updates in-app (via GitHub Releases, auto-selecting the asset matching the device ABI).

### Build from Source

Requirements: Flutter 3.47+ (requires Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Build release APKs (per-ABI split, matching the CI release artifacts):

```bash
flutter build apk --release --split-per-abi
```

Artifacts land in `build/app/outputs/flutter-apk/` as `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, and `app-x86_64-release.apk`. For local device testing only, plain `flutter build apk --release` also works (a ~63 MB fat APK for local install).

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

# Unit & widget tests (full suite)
flutter test
```

## CI/CD Release

Pushing a `v*` tag (e.g. `v1.4.1`) triggers [GitHub Actions](.github/workflows/release.yml):

1. Verifies the tag matches the version in `pubspec.yaml` (fails otherwise);
2. Runs the test gate (`flutter pub get` / `flutter analyze` / `flutter test`, any failure aborts the release);
3. Builds signed release APKs (`--split-per-abi`, named `Shell-Mind-v{version}-{abi}.apk` for arm64-v8a / armeabi-v7a / x86_64);
4. Extracts the matching version's Chinese release notes from [CHANGELOG.md](CHANGELOG.md), creates a GitHub Release, and uploads all per-ABI APKs and checksums automatically.

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

This project is released under the [MIT License](LICENSE).
