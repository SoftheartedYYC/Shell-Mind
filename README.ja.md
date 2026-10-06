# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Flutter ベースの Android SSH ターミナル + AI アシスタントアプリです。SSH 経由でサーバーに接続し、接続先ホスト上でコマンドを実行する AI エージェントを動かし（確認モードと監査ログ付き）、サーバー群を管理し、クラスターの健全性を監視します。

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 機能

| モジュール | 機能 |
| --- | --- |
| **SSH ターミナル** | パスワード / 秘密鍵による認証（[dartssh2](https://pub.dev/packages/dartssh2)）、補助キーボードバー付きのターミナルエミュレーション（[xterm](https://pub.dev/packages/xterm)）、指数バックオフによる自動再接続、グローバルなマルチセッションレジストリ — 画面を離れてもセッションは動作し続けます。**6 種類のターミナル配色**（Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic） |
| **SFTP ブラウザー** | 階層ごとに移動できるフォルダー閲覧、テキストファイルのプレビュー、ローカルストレージへのダウンロード、mkdir / rename / delete |
| **ポート転送** | ローカル（`ssh -L`）およびリモート（`ssh -R`）トンネル、ワンタップで閉じられるライブトンネル一覧 |
| **AI エージェント** | 確認モードまたは全自動モードでのコマンド実行、危険なコマンドの遮断、設定可能な最大実行ラウンド数、単一の会話からの複数サーバー連携、視覚的な実行タイムライン、完全なコマンド監査ログ |
| **AI チャット** | **コードブロックの構文ハイライト**（shell / python / json / yaml / dockerfile / sql）、**マルチセッション管理**（新規 / 切り替え / 名前変更 / 削除）、**会話履歴の検索**（タイトル + メッセージ本文）、Markdown エクスポート、ターミナルコンテキストの添付 |
| **AI プロバイダー** | 組み込みの DeepSeek / Qwen / GLM / MiMo / OpenAI（OpenAI 互換）、カスタムプロバイダー（名前 + ベース URL + モデル）、SSE ストリーミング応答、検索フィルター付きモデル選択シート |
| **サーバー管理** | グループ化と検索に対応した CRUD、サーバーカード上のライブ接続ステータスバッジ、ワンクリック AI 診断付きクラスター健全性集計カード（稼働時間 / 負荷プロービング） |
| **インポート / エクスポート** | コマンドスニペットとサーバー設定の JSON エクスポート / インポート（認証情報は一切エクスポートされません。インポートされたエントリーには新しい ID が付与されます） |
| **通知** | アプリがバックグラウンドにある間に SSH セッションが切断された場合や AI タスクが完了した場合のローカル通知（切り替え可能） |
| **セキュリティとプライバシー** | `flutter_secure_storage` による認証情報の暗号化、生体認証によるアプリロック、IP 非表示モード、コマンド監査ログ、エラー診断のエクスポート |
| **生産性** | 永続的な AI チャット履歴、コマンドスニペット（AI チャット / ターミナルの二重入力）、Markdown 会話エクスポート、AI 会話へのターミナルコンテキスト添付 |
| **ローカライズとテーマ** | 多言語インターフェース（English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano）、ライト / ダーク / システム連動テーマ |
| **プラットフォーム** | Android（ABI ごとの分割 APK）、iOS（Info.plist にローカルネットワークと Face ID の使用を記載。通知権限はプラグインが要求します） |

## スクリーンショット

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## はじめに

### リリースからインストール

1. [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) ページにアクセスします。
2. お使いのデバイスの ABI に合った APK をダウンロードしてインストールします（`arm64-v8a` は最新のスマートフォン向け、`armeabi-v7a` はレガシーな 32 ビットデバイス向け、`x86_64` はエミュレーター専用）。
3. アプリ内でもアップデートを確認します（GitHub Releases 経由で、デバイスの ABI に合ったアセットを自動選択します）。

### ソースからビルド

必要条件: Flutter 3.47+（Dart SDK ^3.13.4 が必要）、Java 17+、Android SDK 36。

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

リリース APK をビルドします（ABI ごとの分割、CI のリリース成果物と一致）:

```bash
flutter build apk --release --split-per-abi
```

成果物は `build/app/outputs/flutter-apk/` に `app-arm64-v8a-release.apk`、`app-armeabi-v7a-release.apk`、`app-x86_64-release.apk` として出力されます。ローカルデバイスでのテストのみであれば、通常の `flutter build apk --release` でも動作します（ローカルインストール用の約 63 MB の fat APK）。

> **署名**: 署名付きリリースビルドには 2 つのファイルが必要です（どちらも `.gitignore` で除外され、コミットされることはありません）:
>
> - `android/key.properties` — `android/key.properties.example` からコピーして、実際の認証情報を入力します。
> - `android/app/shellmind-release-key.jks` — リリース用キーストア。
>
> どちらかが欠けている場合、ビルドはデバッグ署名設定にフォールバックします（ローカルデバッグ専用で、配布用ではありません）。公式ビルドは JDK 17 と JDK 25 で検証済みです。

## 開発

```bash
# Static analysis
flutter analyze

# Unit & widget tests (full suite)
flutter test
```

## CI/CD リリース

`v*` タグ（例: `v1.4.1`）をプッシュすると [GitHub Actions](.github/workflows/release.yml) がトリガーされます:

1. タグが `pubspec.yaml` 内のバージョンと一致することを検証します（一致しない場合は失敗します）。
2. テストゲートを実行します（`flutter pub get` / `flutter analyze` / `flutter test`。いずれかが失敗するとリリースを中止します）。
3. 署名付きリリース APK をビルドします（`--split-per-abi`、arm64-v8a / armeabi-v7a / x86_64 向けに `Shell-Mind-v{version}-{abi}.apk` という名前で）。
4. 対応するバージョンの中国語リリースノートを [CHANGELOG.md](CHANGELOG.md) から抽出し、GitHub Release を作成して、すべての ABI 別 APK とチェックサムを自動的にアップロードします。

**Settings → Secrets and variables → Actions** の下に、リポジトリの Secrets を 2 つ設定する必要があります（どちらもファイル内容の Base64 です）:

| Secret | 内容 |
| --- | --- |
| `KEYSTORE_BASE64` | リリース用キーストア `android/app/shellmind-release-key.jks` の Base64 |
| `KEY_PROPERTIES_BASE64` | `android/key.properties` の Base64 |

PowerShell で生成します: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Secrets が欠けている場合、ワークフローは即座に失敗します — デバッグ署名済み APK を公開することは決してありません。

## 技術スタック

| レイヤー | ライブラリ |
| --- | --- |
| フレームワーク | Flutter 3.47+ / Dart ^3.13.4 |
| 状態管理 | flutter_riverpod |
| ルーティング | go_router |
| SSH | dartssh2 |
| ターミナルエミュレーション | xterm |
| AI トランスポート | dio（SSE ストリーミング） |
| ローカルストレージ | hive_ce |
| セキュアストレージ | flutter_secure_storage |
| 生体認証 | local_auth |
| アプリ内アップデート | package_info_plus / open_filex / permission_handler |

## 免責事項

このアプリは AI エージェントに実際のサーバー上でコマンドを実行させます。全自動モードはコマンドごとの確認なしで実行します。危険なコマンドの遮断は安全対策であり、保証ではありません。本番環境や重要なホストでは、無人で自動モードを有効にしないでください。ご自身の責任でご利用ください。

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。
