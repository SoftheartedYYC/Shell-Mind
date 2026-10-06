// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'サーバー';

  @override
  String get navAiChat => 'AI チャット';

  @override
  String get navSettings => '設定';

  @override
  String get pageNotFound => 'ページが見つかりません';

  @override
  String get backToServers => 'サーバーに戻る';

  @override
  String get serversTitle => 'サーバー';

  @override
  String serversHostCount(int count) {
    return '$count 台のホスト';
  }

  @override
  String get serversSearch => 'サーバーを検索…';

  @override
  String get serversAdd => 'サーバーを追加';

  @override
  String get serversEmpty => 'サーバーがまだありません';

  @override
  String get serversEmptyHint => '最初の SSH サーバーを追加して開始しましょう。';

  @override
  String get serversDeleteConfirmTitle => 'サーバーを削除';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return '\"$name\" を削除しますか？\n\n$identity:$port と保存された認証情報は完全に削除されます。';
  }

  @override
  String serversDeleted(String identity) {
    return '$identity を削除しました';
  }

  @override
  String serversDeleteFailed(String message) {
    return '削除に失敗しました: $message';
  }

  @override
  String get serversLoading => 'サーバーを読み込み中';

  @override
  String get serversUngrouped => '未分類';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => '最近';

  @override
  String get serversQuickStart => 'クイックスタート';

  @override
  String get serversQuickStep1Title => 'ホストを追加';

  @override
  String get serversQuickStep1Desc => 'パスワードまたは鍵認証で SSH エンドポイントを登録します。';

  @override
  String get serversQuickStep2Title => '接続をテスト';

  @override
  String get serversQuickStep2Desc => '登録前にポートを確認します。入力ミスをすばやく検出できます。';

  @override
  String get serversQuickStep3Title => '接続';

  @override
  String get serversQuickStep3Desc => 'ターミナルセッションを開きます — 完全な PTY、配色、vim に対応。';

  @override
  String serversNoMatch(String query) {
    return '一致なし: \"$query\"';
  }

  @override
  String get serversClearFilter => 'フィルターをクリア';

  @override
  String get serversReadError => 'サーバー一覧を読み込めませんでした。';

  @override
  String get serverEditTitle => 'サーバーを追加';

  @override
  String get serverEditTitleEdit => 'サーバーを編集';

  @override
  String get serverNotFound => 'サーバーが見つかりません';

  @override
  String get serverValidationNameRequired => '名前が必要です';

  @override
  String get serverValidationHostRequired => 'ホストが必要です';

  @override
  String get serverValidationNoSpaces => 'スペースは使用できません';

  @override
  String get serverValidationRequired => '必須';

  @override
  String get serverValidationNumeric => '数値';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'ユーザー名が必要です';

  @override
  String get serverValidationPasswordRequired => 'パスワードが必要です';

  @override
  String get serverValidationPrivateKeyRequired => '秘密鍵が必要です';

  @override
  String serverAdded(String identity, int port) {
    return 'サーバーを追加しました: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return '保存しました: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return '保存に失敗しました: $message';
  }

  @override
  String get serverTestEnterHost => '最初にホストアドレスを入力してください';

  @override
  String serverTestProbing(String host, int port) {
    return '$host:$port を確認しています…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — 到達可能';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — タイムアウト';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — 拒否 / 到達不可';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — 確認に失敗しました';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port SSH ハンドシェイクに失敗しました';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port 認証に失敗しました - ユーザー名と認証情報を確認してください';
  }

  @override
  String get serverLoading => '読み込み中';

  @override
  String get serverSaveChanges => '変更を保存';

  @override
  String get serverSectionIdentity => '識別情報';

  @override
  String get serverSectionConnection => '接続';

  @override
  String get serverSectionAuthentication => '認証';

  @override
  String get serverFieldLabel => 'ラベル';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'グループ (任意)';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => 'ホスト';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'ポート';

  @override
  String get serverFieldUsername => 'ユーザー名';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'パスワード';

  @override
  String get serverFieldPasswordStored => '保存済み — 変更しない場合は空のまま';

  @override
  String get serverFieldPrivateKey => '秘密鍵 (PEM)';

  @override
  String get serverFieldPassphrase => '鍵のパスフレーズ (任意)';

  @override
  String get serverAuthPassword => 'パスワード';

  @override
  String get serverAuthPrivateKey => '秘密鍵';

  @override
  String get serverTestIdle => '\"テスト\" をタップして接続を確認';

  @override
  String get serverSecurityNote =>
      '認証情報は端末のキーストアで暗号化されます。Hive メタデータストアには保存されず、この端末の外に出ることもありません。';

  @override
  String get serverTesting => 'テスト中…';

  @override
  String get serverTest => 'テスト';

  @override
  String get serverSaving => '保存中…';

  @override
  String serverCopiedAddress(String address) {
    return '$address をコピーしました';
  }

  @override
  String get serverActions => 'サーバー操作';

  @override
  String get serverActionConnect => '接続';

  @override
  String get serverActionEdit => '編集';

  @override
  String get serverActionEditDetails => '詳細を編集';

  @override
  String get serverActionCopySsh => 'SSH コマンドをコピー';

  @override
  String get serverActionDelete => '削除';

  @override
  String get serverActionDeleteServer => 'サーバーを削除';

  @override
  String get serverOnline => 'オンライン';

  @override
  String get serverNeverConnected => '未接続';

  @override
  String get serverJustNow => 'たった今';

  @override
  String serverMinutesAgo(int minutes) {
    return '$minutes 分前';
  }

  @override
  String serverHoursAgo(int hours) {
    return '$hours 時間前';
  }

  @override
  String serverDaysAgo(int days) {
    return '$days 日前';
  }

  @override
  String get terminalHostNotFound => 'ホストが見つかりません';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'ID \"$id\" に一致する保存済みサーバーがありません。削除された可能性があります。';
  }

  @override
  String get terminalBackToServers => 'サーバーに戻る';

  @override
  String get terminalConnectionFailed => '接続に失敗しました。';

  @override
  String get terminalSessionClosed => 'セッションが終了しました';

  @override
  String terminalSessionClosedMessage(String name) {
    return '$name への接続が切断されました。';
  }

  @override
  String get terminalReconnect => '再接続';

  @override
  String get terminalAuthenticating => '認証中';

  @override
  String get terminalConnecting => '接続中';

  @override
  String get terminalResolvingHost => 'ホストを解決しています…';

  @override
  String get terminalTooltipDisconnectBack => '切断して戻る';

  @override
  String get terminalTooltipSmallerText => '文字を小さく';

  @override
  String get terminalTooltipLargerText => '文字を大きく';

  @override
  String get terminalTooltipDisconnect => '切断';

  @override
  String get terminalRetryAvailable => '再試行可能';

  @override
  String get terminalStatusConnected => '接続済み';

  @override
  String get terminalStatusOffline => 'オフライン';

  @override
  String get terminalStatusError => 'エラー';

  @override
  String get aiChatTitle => 'AI アシスタント';

  @override
  String get aiChatStatusSetup => 'セットアップ';

  @override
  String get aiChatStatusStreaming => 'ストリーミング';

  @override
  String get aiChatStatusReady => '準備完了';

  @override
  String get aiChatClearConversation => '会話をクリア';

  @override
  String get aiChatSuggestion1 => 'ls -la の出力の意味を説明して';

  @override
  String get aiChatSuggestion2 => 'どのプロセスがポートを使用しているか調べる方法は？';

  @override
  String get aiChatSuggestion3 => 'ログを tail してエラーを grep する方法を教えて';

  @override
  String get aiChatSuggestion4 => 'CSV の列を合計する awk ワンライナーを書いて';

  @override
  String get aiChatTryAsking => '質問してみる';

  @override
  String get aiChatIntroTitle => 'あなたのターミナルの相棒';

  @override
  String get aiChatIntroBody =>
      'コマンド、エラー、またはログ出力の一部を貼り付けてください。ShellMind が何が起きたかを説明し、次の手を提案し、コマンドを書いてくれます。';

  @override
  String get aiChatNoKeyTitle => 'API キーが設定されていません';

  @override
  String aiChatNoKeyMessage(String provider) {
    return '$provider の API キーを追加してアシスタントを起動してください。キーはこの端末に暗号化されて保存され、モデルを呼び出す以外に端末の外に出ることはありません。';
  }

  @override
  String get aiChatOpenSettings => 'AI 設定を開く';

  @override
  String get aiChatCheckingCredentials => '認証情報を確認中';

  @override
  String get aiChatInputHint => '何でも質問してください…';

  @override
  String get aiChatInputDisabled => '開始するには API キーを設定してください';

  @override
  String get aiChatError => 'エラー';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'コピーしました';

  @override
  String get aiChatCopy => 'コピー';

  @override
  String get aiChatThinking => '考え中…';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSearchTooltip => '設定を検索';

  @override
  String get settingsStable => '安定版';

  @override
  String get settingsSectionAppearance => '外観と言語';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システム';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'AI プロバイダー';

  @override
  String get settingsSectionAiAgent => 'AI エージェント';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'サーバー';

  @override
  String get settingsSectionAboutUpdate => 'このアプリとアップデート';

  @override
  String get settingsSectionStoragePrivacy => 'ストレージとプライバシー';

  @override
  String get settingsSectionResources => 'リソース';

  @override
  String get settingsTileSecrets => '機密情報';

  @override
  String get settingsTileEncrypted => '暗号化';

  @override
  String get settingsTileLocalCache => 'ローカルキャッシュ';

  @override
  String get settingsTileClearData => 'すべてのデータを消去';

  @override
  String get settingsTileLicenses => 'オープンソースライセンス';

  @override
  String get settingsTileReportIssue => '問題を報告';

  @override
  String get settingsFooter => 'モダンなワークフローのための SSH + AI アシスタント';

  @override
  String get settingsSecretsDialogTitle => '機密情報と暗号化';

  @override
  String get settingsSecretsDialogBody =>
      '認証情報 (サーバーのパスワード、秘密鍵、AI API キー) は、プラットフォームのキーストア (Android Keystore / iOS Keychain) を使用して常に暗号化されて保存されます。この保護は設計上のものであり、無効にすることはできません。認証情報を変更するには、サーバー編集ページまたは AI 設定で編集または削除してください。';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => '閉じる';

  @override
  String get settingsCacheDialogTitle => 'ローカルキャッシュ';

  @override
  String get settingsCacheHiveData => 'アプリデータ';

  @override
  String get settingsCacheDownloads => 'ダウンロード済みアップデート';

  @override
  String get settingsCacheTotal => '合計';

  @override
  String get settingsCacheDialogHint =>
      'ダウンロードキャッシュをクリアすると、ダウンロード済みのアップデートパッケージ (APK) が削除されます。サーバー、キー、チャット履歴は保持されます。';

  @override
  String get settingsCacheClearDownloads => 'ダウンロードキャッシュをクリア';

  @override
  String settingsCacheCleared(String freed) {
    return '$freed を解放しました';
  }

  @override
  String get settingsClearDataTitle => 'すべてのデータを消去しますか？';

  @override
  String get settingsClearDataMessage =>
      'この端末上のすべてのサーバー、保存済み認証情報、AI キー、チャット履歴、設定が完全に削除されます。この操作は取り消せません。';

  @override
  String get settingsClearDataConfirm => 'すべて消去';

  @override
  String get settingsDataCleared => 'すべてのデータを消去しました';

  @override
  String settingsClearDataFailed(String message) {
    return 'データを消去できませんでした: $message';
  }

  @override
  String get settingsIssueLinkCopied => '問題のリンクをクリップボードにコピーしました。';

  @override
  String get settingsAboutGithub => 'GitHub リポジトリ';

  @override
  String get settingsHideIp => 'IP アドレスを隠す';

  @override
  String get settingsHideIpDesc => 'サーバー一覧と AI ページで IP アドレスをマスクします';

  @override
  String get serverMaskedAddress => 'アドレスは非表示';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return '$provider API キー';
  }

  @override
  String get aiSettingsKeySet => '設定済み';

  @override
  String get aiSettingsKeyNotConfigured => '未設定';

  @override
  String get aiSettingsGetApiKey => 'API キーを取得';

  @override
  String get aiSettingsTemperature => '温度';

  @override
  String get aiSettingsRemoveKey => 'キーを削除';

  @override
  String aiSettingsKeySaved(String provider) {
    return '$provider API キーを安全に保存しました。';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return '$provider キーを削除しますか？';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      '新しいキーを追加するまで、このプロバイダーのアシスタントは動作しなくなります。';

  @override
  String get aiSettingsRemoveKeyConfirm => '削除';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return '$provider キーを取得';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'ブラウザーでプロバイダーのコンソールを開いて API キーを作成し、ここに貼り付けてください。';

  @override
  String get aiSettingsClose => '閉じる';

  @override
  String get aiSettingsLinkCopied => 'リンクをクリップボードにコピーしました。';

  @override
  String get aiSettingsCopyLink => 'リンクをコピー';

  @override
  String get aiSettingsKeyConfigured => 'キー設定済み';

  @override
  String get aiSettingsNotConfigured => '未設定';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return '$provider キーを更新';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return '$provider キーを追加';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'この端末に暗号化されて保存されます。AI プロバイダーを呼び出すためにのみ使用されます。';

  @override
  String get aiSettingsApiKeyHint => 'API キー…';

  @override
  String get aiSettingsSave => '保存';

  @override
  String get modelDescFastAffordable => '高速で低コスト';

  @override
  String get modelDescMostCapable => '最高性能';

  @override
  String get modelDescLegacyFast => '従来の高速';

  @override
  String get modelDescGeneralConversation => '一般的な会話';

  @override
  String get modelDescAdvancedReasoning => '高度な推論';

  @override
  String get modelDescFastResponse => '高速応答';

  @override
  String get modelDescBalanced => 'バランス';

  @override
  String get modelDescFreeFast => '無料で高速';

  @override
  String get modelDescEnhanced => '強化版';

  @override
  String get modelDescStandard => '標準';

  @override
  String get modelDescLightweight => '軽量';

  @override
  String get modelDescRlEnhanced => 'RL 強化';

  @override
  String get aiModelsTitle => 'モデル';

  @override
  String get aiModelsRefresh => 'モデル一覧を更新';

  @override
  String get aiModelsAddCustom => 'カスタムモデルを追加';

  @override
  String get aiModelsAddCustomHint => 'モデル ID (例: deepseek-chat)';

  @override
  String get aiModelsAdd => '追加';

  @override
  String get aiModelsCustomBadge => 'カスタム';

  @override
  String get aiModelsFetchFailed => 'モデルを取得できませんでした — 内蔵の一覧を表示しています。';

  @override
  String get aiModelsRemoveCustom => 'カスタムモデルを削除';

  @override
  String get aiModelsEmpty => 'モデルがありません';

  @override
  String get aiModelsInvalidId => 'モデル ID を入力してください。';

  @override
  String get aiModelsDuplicate => 'このモデルは既に一覧にあります。';

  @override
  String get aiModelsPickerTitle => 'モデルを選択';

  @override
  String get aiModelsSearchHint => 'モデルを検索';

  @override
  String get aiModelsSearchEmpty => '検索に一致するモデルはありません。';

  @override
  String get aiProvidersAddTile => 'カスタムプロバイダーを追加';

  @override
  String get aiProvidersAddTitle => 'カスタムプロバイダーを追加';

  @override
  String get aiProvidersFieldName => '名前';

  @override
  String get aiProvidersFieldNameHint => '例: SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'ベース URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'デフォルトモデル (任意)';

  @override
  String get aiProvidersFieldModelHint => 'モデル ID (例: deepseek-chat)';

  @override
  String get aiProvidersAddConfirm => '追加';

  @override
  String get aiProvidersInvalidInput => '名前とベース URL を入力してください。';

  @override
  String get aiProvidersInvalidUrl =>
      'ベース URL は http:// または https:// で始まる必要があります';

  @override
  String get aiProvidersDuplicateName => 'この名前のプロバイダーは既に存在します。';

  @override
  String get aiProvidersAdded => 'カスタムプロバイダーを追加しました。';

  @override
  String get aiProvidersAddFailed => 'プロバイダーを追加できませんでした — 入力を確認してください。';

  @override
  String get aiProvidersDeleteTile => 'カスタムプロバイダーを削除';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return '$provider を削除しますか？';
  }

  @override
  String get aiProvidersDeleteMessage =>
      '保存された API キー、記憶されたモデル、カスタムモデルも削除されます。内蔵プロバイダーは削除できません。';

  @override
  String get aiProvidersDeleteConfirm => '削除';

  @override
  String get aiProvidersPickerTitle => 'プロバイダーを選択';

  @override
  String get updateVersion => 'バージョン';

  @override
  String get updateSoftwareUpdate => 'ソフトウェアアップデート';

  @override
  String get updateChecking => '確認中';

  @override
  String get updateUpToDate => '最新';

  @override
  String get updateCheckAgain => 'もう一度確認';

  @override
  String get updateReady => '準備完了';

  @override
  String get updateNew => '新規';

  @override
  String get updateCheck => '確認';

  @override
  String get updateAwaitingResponse => '応答待ち';

  @override
  String get updateAlreadyLatest => '既に最新のビルドです';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version は GitHub で公開されている最新リリースです。';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return '実行中 v$current — リモートの最新は v$latest です。';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return '$timeAgo に確認済み';
  }

  @override
  String get updateAvailable => 'アップデートがあります';

  @override
  String get updatePre => 'プレ';

  @override
  String get updateDownloadInstall => 'ダウンロードとインストール';

  @override
  String get updateLater => '後で';

  @override
  String get updateApkHint =>
      'APK のインストールは Android でのみサポートされています。ここではファイルをダウンロードできます。';

  @override
  String updateDownloading(String tag) {
    return '$tag をダウンロード中';
  }

  @override
  String get updateSize => 'サイズ';

  @override
  String get updateRate => '速度';

  @override
  String get updateEta => '残り時間';

  @override
  String get updateElapsed => '経過時間';

  @override
  String get updateCancel => 'キャンセル';

  @override
  String get updateKeepForeground => 'アプリを前面に維持';

  @override
  String get updateDownloadComplete => 'ダウンロード完了';

  @override
  String get updateInstallHint =>
      'Android が確認を求めます。インストーラーの実行中は ShellMind が終了しますが、サーバーと履歴は保持されます。';

  @override
  String get updateLaunching => '起動中...';

  @override
  String get updateInstallNow => '今すぐインストール';

  @override
  String get updateDelete => '削除';

  @override
  String updateInstallTitle(String tag) {
    return '$tag をインストールしますか？';
  }

  @override
  String get updateInstallMessage =>
      'システムのパッケージインストーラーが開きます。インストール中は ShellMind が終了し、新しいバージョンで再度開きます。';

  @override
  String get updateNotNow => '今はしない';

  @override
  String get updateInstall => 'インストール';

  @override
  String get updateCheckFailed => 'アップデート確認に失敗しました。';

  @override
  String get updateErrorTitleNoReleases => 'リリースなし';

  @override
  String get updateErrorTitleGeneric => 'アップデート確認に失敗しました';

  @override
  String get updateErrNoReleases => 'ShellMind のリリースはまだ公開されていません。';

  @override
  String get updateErrRateLimit =>
      'GitHub の API レート制限に達しました。しばらくしてから再試行してください。';

  @override
  String get updateErrTimeout => 'GitHub へのリクエストがタイムアウトしました。接続を確認して再試行してください。';

  @override
  String get updateErrNetwork => 'GitHub に接続できませんでした。ネットワーク接続を確認してください。';

  @override
  String get updateErrAuth => 'GitHub がアップデートリクエストを拒否しました。';

  @override
  String get updateErrPermission => 'アップデートリクエストが拒否されました。';

  @override
  String get updateErrStorage => 'アップデートを完了するためのストレージ容量が不足しています。';

  @override
  String get updateErrDigestMismatch =>
      'ダウンロードしたアップデートが SHA-256 整合性チェックに失敗したため削除されました。ダウンロードを再試行してください。';

  @override
  String get updateErrDigestMissing =>
      'アップデートパッケージに公開された整合性ダイジェストがないため、アップデートは拒否されました。後でもう一度お試しください。';

  @override
  String get updateRetry => '再試行';

  @override
  String get updateDismiss => '閉じる';

  @override
  String updateReleaseNotes(String tag) {
    return 'リリース $tag';
  }

  @override
  String get updateNotesLabel => 'ノート';

  @override
  String get updateNewVersionAvailable => '新しいバージョンがあります';

  @override
  String get updateRemindLater => '後で通知';

  @override
  String get updateCancelDownload => 'ダウンロードをキャンセル';

  @override
  String updateInstallTag(String tag) {
    return '$tag をインストール';
  }

  @override
  String get updateInstallLaterFromSettings => '後で設定からインストール';

  @override
  String get updateCouldNotComplete => 'アップデートを完了できませんでした。';

  @override
  String get updateClose => '閉じる';

  @override
  String get updatePromptInstallHint =>
      'インストーラーの実行中は Android が ShellMind を終了します。サーバー、キー、チャット履歴は保持されます。';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonLoading => '読み込み中...';

  @override
  String get commonNoData => 'データがありません';

  @override
  String get commonNothingToShow => 'ここにはまだ表示するものがありません。';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'コマンドの自動実行';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      '解析されたコマンドを毎回確認せずに AI エージェントが実行することを許可';

  @override
  String get settingsAiAutoConnectTitle => 'AI サーバー自動接続';

  @override
  String get settingsAiAutoConnectSubtitle =>
      '設定済みだがオフラインのサーバーに AI アシスタントが自動接続してコマンドを実行することを許可します (保存済みの認証情報が使用されます)';

  @override
  String get settingsAiMaxAutoLoopsTitle => '自動ループの最大反復回数';

  @override
  String get settingsAiMaxAutoLoopsSub => '応答ごとの自動コマンド実行回数の上限';

  @override
  String get settingsAiMaxAutoLoopsTileDesc => 'AI がタスクごとに実行できるコマンドラウンドの上限';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'これは AI タスクごとの実行ラウンドの上限です。SSH 再接続の試行回数ではありません (それは SSH の下にあります)。';

  @override
  String get terminalAskAi => 'AI に質問';

  @override
  String get terminalAskAiSubtitle => '選択したテキストを AI アシスタントに送信';

  @override
  String get terminalTooltipAskAi => 'AI に質問';

  @override
  String get aiChatNoConnection => 'まずサーバーターミナルに接続してください';

  @override
  String get aiChatAnalyzePrompt =>
      '上記のコマンド出力を分析し、結果の意味を説明し、必要に応じてフォローアップの提案をしてください。';

  @override
  String get aiExecuteButton => 'サーバーで実行';

  @override
  String get aiExecuteTitle => 'コマンド実行の確認';

  @override
  String get aiExecuteConfirmButton => '実行';

  @override
  String get aiExecuteConfirmAnyway => 'それでも実行';

  @override
  String get aiExecuteDangerWarning => '⚠ 危険なコマンド';

  @override
  String get aiExecuteDangerText => 'このコマンドは破壊的であり、データ損失やシステム障害を引き起こす可能性があります。';

  @override
  String get aiExecuteCommandLabel => '実行するコマンド:';

  @override
  String get aiExecuteTargetServer => '対象サーバー:';

  @override
  String get aiExecuteSelectServer => '対象サーバーを選択';

  @override
  String get aiExecuteNoServer => 'まずサーバーに接続してください';

  @override
  String get aiExecuteAtLeastOne => '少なくとも 1 つのサーバーを選択してください';

  @override
  String get aiExecuteSelectHint => 'このコマンドを実行するサーバーを選択してください';

  @override
  String aiExecuteRunCount(int count) {
    return '実行 ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'すべて選択';

  @override
  String get aiExecuteClearSelection => 'クリア';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return 'オンライン $hours 時間 $minutes 分';
  }

  @override
  String get aiExecuteSuccess => 'コマンドを正常に実行しました';

  @override
  String get aiExecuteFailed => 'コマンドの実行に失敗しました';

  @override
  String get aiServerManageTitle => 'サーバー';

  @override
  String get aiServerManageSubtitle => 'AI アシスタントが操作するサーバーを接続';

  @override
  String aiServerOnlineCount(int count) {
    return '$count 台オンライン';
  }

  @override
  String get aiServerDone => '完了';

  @override
  String get aiServerConnecting => '接続中…';

  @override
  String get aiServerOffline => 'オフライン';

  @override
  String get aiServerNoCredential =>
      '保存済みの認証情報がありません — 最初にサーバーページでパスワードまたはキーを保存してください';

  @override
  String get aiServerConnectFailed => '接続に失敗しました';

  @override
  String get aiToolResultCommand => 'コマンド';

  @override
  String get aiToolResultOutput => 'コマンド出力';

  @override
  String aiToolResultExitCode(int code) {
    return '終了コード: $code';
  }

  @override
  String get aiToolResultElapsed => '経過時間';

  @override
  String get aiToolResultAnalyzeButton => 'AI に出力を分析させる';

  @override
  String aiToolResultCollapsedShow(int total) {
    return 'さらに $total 行';
  }

  @override
  String get aiToolResultExpandedHide => '出力を隠す';

  @override
  String get aiToolResultStderrLabel => 'エラー出力:';

  @override
  String get aiContextToggleAttach => 'ターミナルコンテキストを添付';

  @override
  String get aiContextToggleDetach => 'ターミナルコンテキスト添付済み';

  @override
  String get aiContextBadge => 'コンテキスト';

  @override
  String aiContextLines(int lines) {
    return 'ターミナルから $lines 行';
  }

  @override
  String get aiAgentStop => '自動モードを停止';

  @override
  String get aiAgentExecuting => '実行中…';

  @override
  String get aiAgentDefaultServer => 'サーバー';

  @override
  String get aiTimelineTitle => '実行タイムライン';

  @override
  String get aiTimelineOpen => '実行タイムライン';

  @override
  String get aiTimelineEmpty => 'まだコマンドは実行されていません';

  @override
  String get aiTimelineEmptyHint => 'チャットまたは自動モードでコマンドを実行すると、一連の流れがここに表示されます。';

  @override
  String aiTimelineStatRounds(int count) {
    return '$count ラウンド';
  }

  @override
  String aiTimelineStatCommands(int count) {
    return '$count コマンド';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    return '$count 件成功';
  }

  @override
  String aiTimelineStatFailed(int count) {
    return '$count 件失敗';
  }

  @override
  String aiTimelineStarted(String time) {
    return '開始 $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return '終了 $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return '終了コード: $code';
  }

  @override
  String get aiTimelineNoExitCode => '終了コードなし';

  @override
  String get aiTimelineOutput => '出力';

  @override
  String get aiTimelineOutputEmpty => '出力なし';

  @override
  String get aiTimelineErrorOutput => 'エラー出力';

  @override
  String get aiTimelineRunning => '実行中…';

  @override
  String get aiTimelineClose => '閉じる';

  @override
  String get sshReconnectToggle => '切断時に自動再接続';

  @override
  String get sshReconnectToggleDesc => '指数バックオフで切断された SSH セッションを再試行します';

  @override
  String get sshReconnectMaxAttempts => '再接続の最大試行回数';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      '切断後の自動再接続の最大試行回数 — 0 は成功するまで再試行することを意味します';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => '無制限';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return '再接続中 (試行 $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return '再接続中 (試行 $attempt / $max)';
  }

  @override
  String get sshReconnectGaveUp => '自動再接続を断念しました';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return '$max 回試行しても $name に到達できませんでした。';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return '$name に到達できませんでした。';
  }

  @override
  String get sshReconnectRetryNow => '今すぐ再試行';

  @override
  String get sshReconnectStopAuto => '停止';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return '$name に再接続しました';
  }

  @override
  String get snippetsTitle => 'コマンドスニペット';

  @override
  String get snippetsSubtitle => 'すぐに再利用できるようコマンドを保存';

  @override
  String get snippetsAddTooltip => 'スニペットを追加';

  @override
  String get snippetsAddTitle => '新しいスニペット';

  @override
  String get snippetsSave => '保存';

  @override
  String get snippetsCommandLabel => 'コマンド';

  @override
  String get snippetsCommandHint => '例: docker ps -a';

  @override
  String get snippetsNameLabel => '名前 (任意)';

  @override
  String get snippetsNameHint => '例: すべてのコンテナを一覧表示';

  @override
  String get snippetsCommandRequired => 'コマンドテキストが必要です';

  @override
  String get snippetsDeleteTooltip => 'スニペットを削除';

  @override
  String get snippetsEmptyTitle => 'スニペットがまだありません';

  @override
  String get snippetsEmptyMessage => 'よく使うコマンドを保存して、ワンタップで挿入または実行できます。';

  @override
  String get snippetsLoadFailed => 'スニペットを読み込めませんでした';

  @override
  String get healthTitle => 'フリートのヘルス';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total オンライン';
  }

  @override
  String get healthProbing => '確認中…';

  @override
  String get healthProbeTooltip => 'ヘルスチェックを実行';

  @override
  String healthProbedAt(String time) {
    return '$time に確認';
  }

  @override
  String get healthMoodAllOnline => 'すべてのシステム正常';

  @override
  String get healthMoodDegraded => '一部のサーバーに到達できません';

  @override
  String get healthMoodAllOffline => 'すべてのサーバーに到達できません';

  @override
  String healthOfflineServers(String names) {
    return 'オフライン: $names';
  }

  @override
  String get healthNoData => '更新をタップしてすべてのサーバーを確認';

  @override
  String healthUptime(String brief) {
    return '稼働 $brief';
  }

  @override
  String healthLoad(String value) {
    return '負荷 $value';
  }

  @override
  String get healthDiagIntro => 'こちらが私のフリートのヘルスレポートです:';

  @override
  String healthDiagStats(int online, int total) {
    return '$total 台中 $online 台のサーバーがオンラインです。';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name: オフライン';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name: オンライン ($details)';
  }

  @override
  String get healthDiagOutro =>
      'ヘルスデータを分析し、異常な点 (高負荷、最近の再起動) があれば指摘し、次に確認すべきことを提案してください。';

  @override
  String get healthDiagnose => 'AI 診断';

  @override
  String get healthStaleNote => '最後の確認以降に一部のサーバーがオフラインになりました。';

  @override
  String get auditTitle => 'コマンド監査ログ';

  @override
  String get auditTileDesc => 'AI エージェントが実行したコマンド';

  @override
  String get auditEmptyTitle => '監査エントリはまだありません';

  @override
  String get auditEmptyMessage => 'AI エージェントが実行したコマンドがここに記録されます。';

  @override
  String get auditFilteredEmpty => '現在のフィルターに一致するエントリはありません';

  @override
  String get auditFilterAllServers => 'すべてのサーバー';

  @override
  String get auditFilterAllModes => 'すべてのモード';

  @override
  String get auditFilterAllResults => 'すべての結果';

  @override
  String get auditFilterConfirmed => '確認済み';

  @override
  String get auditFilterAuto => '自動';

  @override
  String get auditFilterSuccess => '成功';

  @override
  String get auditFilterFailed => '失敗';

  @override
  String get auditModeConfirmed => '確認済み';

  @override
  String get auditModeAuto => '自動';

  @override
  String get auditStatusSuccess => '成功';

  @override
  String get auditStatusFailed => '失敗';

  @override
  String get auditDangerousBadge => '危険';

  @override
  String auditExitCode(int code) {
    return '終了コード $code';
  }

  @override
  String get auditOutputSummary => '出力の概要';

  @override
  String get auditNoOutput => '出力なし';

  @override
  String get auditClearTooltip => '監査ログをクリア';

  @override
  String get auditClearConfirmTitle => '監査ログをクリア';

  @override
  String auditClearConfirmMessage(int count) {
    return '$count 件の監査エントリがすべて完全に削除されます。';
  }

  @override
  String get auditClearAction => 'クリア';

  @override
  String get auditCleared => '監査ログをクリアしました';

  @override
  String auditEntriesCount(int count) {
    return '$count 件のエントリ';
  }

  @override
  String get serverActionDisconnect => '切断';

  @override
  String get exportChatAction => 'Markdown としてエクスポート';

  @override
  String get exportChatEmpty => 'まだエクスポートするものはありません';

  @override
  String exportChatSuccess(String path) {
    return '会話を $path にエクスポートしました';
  }

  @override
  String exportChatFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get diagTitle => '診断';

  @override
  String get diagTileDesc => 'アプリのエラーと診断エクスポート';

  @override
  String get diagEmptyTitle => 'エラーは記録されていません';

  @override
  String get diagEmptyMessage => '未処理の例外がここに記録され、問題報告に役立ちます。';

  @override
  String diagEntriesCount(int count) {
    return '$count 件のエラー';
  }

  @override
  String get diagSourceFlutter => 'UI エラー';

  @override
  String get diagSourcePlatform => 'ランタイムエラー';

  @override
  String get diagSourceZone => '非同期タスク';

  @override
  String get diagStackTrace => 'スタックトレース';

  @override
  String get diagNoStackTrace => 'スタックトレースなし';

  @override
  String get diagExportAction => '診断レポートをエクスポート';

  @override
  String get diagExportEmpty => '報告するものはありません — 基本情報をエクスポートします';

  @override
  String diagExportSuccess(String path) {
    return '診断レポートを $path にエクスポートしました';
  }

  @override
  String diagExportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get diagPrivacyNote => '診断コンテンツは編集済みです — パスワード、秘密鍵、API キーは含まれません。';

  @override
  String get diagClearTooltip => 'エラー記録をクリア';

  @override
  String get diagClearConfirmTitle => 'エラー記録をクリア';

  @override
  String diagClearConfirmMessage(int count) {
    return '$count 件のエラー記録がすべて完全に削除されます。';
  }

  @override
  String get diagClearAction => 'クリア';

  @override
  String get diagCleared => 'エラー記録をクリアしました';

  @override
  String get diagAppInfoTitle => 'アプリ情報';

  @override
  String get diagAppInfoVersion => 'バージョン';

  @override
  String get diagAppInfoPlatform => 'プラットフォーム';

  @override
  String get diagAppInfoLocale => '言語';

  @override
  String get diagAppInfoStorage => 'ローカルデータサイズ';

  @override
  String get authLockToggleTitle => '生体認証ロック';

  @override
  String get authLockToggleDesc => 'アプリを開くときに指紋または顔認証を要求';

  @override
  String get authLockEnableFailed => '認証に失敗しました — ロックはオフのままです';

  @override
  String get authLockUnavailableDesc => 'この端末には生体認証が登録されていません';

  @override
  String get authLockScreenTitle => 'ShellMind はロックされています';

  @override
  String get authLockScreenSubtitle => '続行するには認証してください';

  @override
  String get authLockUnlockAction => 'ロック解除';

  @override
  String get authLockUnlockFailed => '認証に失敗しました — もう一度お試しください';

  @override
  String get terminalTabPickerTitle => 'ターミナルを切り替え';

  @override
  String get terminalTabPickerSubtitle =>
      'ターミナルタブとして開くサーバーを選択してください — オンラインのサーバーは即座に参加し、オフラインのサーバーは先に接続します';

  @override
  String get terminalTabPickerEmpty => 'まだサーバーが設定されていません';

  @override
  String get terminalTabNewTooltip => '新しいターミナルタブ';

  @override
  String get terminalTabCloseTooltip => 'タブを閉じる';

  @override
  String get hostKeyConfirmTitle => 'このホストを信頼しますか？';

  @override
  String get hostKeyConfirmMessage =>
      'これはこのサーバーへの最初の接続です。信頼する前にフィンガープリントを確認してください。これにより中間者攻撃から保護されます。';

  @override
  String get hostKeyEndpointLabel => 'サーバー';

  @override
  String get hostKeyFingerprintLabel => 'SHA-256 フィンガープリント';

  @override
  String get hostKeySecurityNote =>
      'サーバー運営者から帯域外で取得した値とフィンガープリントを比較してください。誤ったフィンガープリントを信頼すると認証情報が漏えいします。';

  @override
  String get hostKeyTrustAndConnect => '信頼して接続';

  @override
  String get hostKeyReject => '拒否';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return '$seconds 秒後に自動拒否します — 信頼は確認した場合にのみ記録されます。';
  }

  @override
  String get hostKeyMismatchTitle => 'ホストキーが変更されました';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return '$host:$port が提示したキーは、以前信頼したキーと異なります。接続はブロックされました。これは中間者攻撃か、サーバーが再インストールされた可能性があります。新しいキーを確認した場合は、サーバー編集ページでホスト信頼をリセットして再接続してください。';
  }

  @override
  String get hostKeyRejectedMessage =>
      '接続をキャンセルしました — ホストキーは信頼されませんでした。もう一度接続してフィンガープリントを確認できます。';

  @override
  String get serverResetTrustAction => 'ホスト信頼をリセット';

  @override
  String get serverResetTrustDesc => 'このサーバーの保存済みフィンガープリントを忘れ、次回の接続で再確認を求めます。';

  @override
  String get serverResetTrustConfirmTitle => 'ホスト信頼をリセットしますか？';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return '$identity:$port の保存済みフィンガープリントが削除されます。次回の接続でホストキーの確認が再び求められます。';
  }

  @override
  String get serverResetTrustConfirmAction => 'リセット';

  @override
  String get serverResetTrustDone =>
      'ホスト信頼をリセットしました — 再接続してフィンガープリントを再度確認してください。';

  @override
  String get agentErrorNoTargetServer => '対象サーバーがありません';

  @override
  String get agentErrorExecFailed => 'コマンドの実行に失敗しました';

  @override
  String get agentErrorConnectFailed => 'サーバーへの自動接続に失敗しました';

  @override
  String get agentErrorConnectAuthRequired =>
      'このサーバーの保存済み認証情報がありません — 自動接続はできません';

  @override
  String agentErrorDangerSkipped(String command) {
    return '危険なコマンドをスキップしました: $command';
  }

  @override
  String get agentErrorUnexpected => '予期しないエラー';

  @override
  String get exportDocChatTitle => 'Shell-Mind チャットエクスポート';

  @override
  String exportDocExportedAt(String time) {
    return 'エクスポート日時: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'メッセージ: $count';
  }

  @override
  String get exportDocUserSection => 'ユーザー';

  @override
  String get exportDocAssistantSection => 'アシスタント';

  @override
  String get exportDocToolSection => 'ツール実行';

  @override
  String get exportDocNoContent => '_(コンテンツなし)_';

  @override
  String get exportDocUnknownServer => '不明なサーバー';

  @override
  String exportDocExitCode(int code) {
    return '終了コード $code';
  }

  @override
  String get exportDocCommand => 'コマンド';

  @override
  String get exportDocOutput => '出力';

  @override
  String get exportDocErrorOutput => 'エラー出力';

  @override
  String get exportDocDiagTitle => 'Shell-Mind 診断レポート';

  @override
  String exportDocDiagCrashCount(int count) {
    return '記録されたエラー: $count';
  }

  @override
  String get exportDocDiagCrashesSection => '記録されたエラー';

  @override
  String get exportDocDiagNone => '(なし)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'エラー概要: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'アプリバージョン: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'プラットフォーム: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return '言語: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'ローカルデータ使用量: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'AI コマンド監査 (最新 $limit 件の概要)';
  }

  @override
  String get exportDocDiagSuccess => '成功';

  @override
  String get exportDocDiagFailed => '失敗';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return '終了コード $code';
  }

  @override
  String get settingsTerminalScheme => 'ターミナル配色';

  @override
  String get settingsTerminalSchemeDesc => 'SSH ターミナルの ANSI カラーパレットを選択します。';

  @override
  String get settingsSectionDataTransfer => 'インポートとエクスポート';

  @override
  String get transferSnippetsTitle => 'コマンドスニペット';

  @override
  String get transferServersTitle => 'サーバー設定';

  @override
  String get transferExport => 'エクスポート';

  @override
  String get transferImport => 'インポート';

  @override
  String get transferExportImport => 'エクスポート / インポート';

  @override
  String get transferExportTitle => 'エクスポート';

  @override
  String get transferCopyJson => 'JSON をコピー';

  @override
  String get transferCopied => 'クリップボードにコピーしました';

  @override
  String get transferImportHint => 'エクスポートした JSON をここに貼り付けてください…';

  @override
  String get transferSnippetsEmpty => 'エクスポートするコマンドスニペットはありません。';

  @override
  String get transferServersEmpty => 'エクスポートするサーバーはありません。';

  @override
  String get transferImportNothing => 'インポートに有効な項目が見つかりませんでした。';

  @override
  String transferSnippetsImported(int count) {
    return '$count 件のコマンドスニペットをインポートしました';
  }

  @override
  String transferServersImported(int count) {
    return '$count 件のサーバーをインポートしました';
  }

  @override
  String transferImportFailed(String message) {
    return 'インポートに失敗しました: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'エクスポートに失敗しました: $message';
  }

  @override
  String get sessionsTitle => '会話';

  @override
  String get sessionsNew => '新しい会話';

  @override
  String get sessionsSearch => '会話を検索…';

  @override
  String get sessionsEmpty => '会話がまだありません';

  @override
  String sessionsNoMatch(String query) {
    return '一致なし: \"$query\"';
  }

  @override
  String get sessionsRename => '名前を変更';

  @override
  String get sessionsRenameHint => '会話タイトル';

  @override
  String get sessionsDelete => '削除';

  @override
  String sessionsDeleteConfirm(String title) {
    return '\"$title\" を削除しますか？ この操作は取り消せません。';
  }

  @override
  String sessionsMessageCount(int count) {
    return '$count 件のメッセージ';
  }

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsNotificationsTitle => 'バックグラウンド通知';

  @override
  String get settingsNotificationsDesc =>
      'アプリがバックグラウンドにあるときに SSH セッションの切断や AI タスクの完了を通知します。';

  @override
  String get sftpTitle => 'ファイル';

  @override
  String get sftpNotConnected => 'このサーバーに接続されていません。';

  @override
  String get sftpLoading => 'ファイルを読み込み中…';

  @override
  String get sftpEmpty => 'このフォルダーは空です。';

  @override
  String get sftpDownload => 'ダウンロード';

  @override
  String sftpDownloaded(String path, int size) {
    return '$path をダウンロードしました ($size バイト)';
  }

  @override
  String get sftpDownloadFailed => 'ダウンロードに失敗しました';

  @override
  String get sftpPreviewError => 'プレビューに失敗しました';

  @override
  String get sftpNewFolderName => '新しいフォルダー';

  @override
  String get sftpRefresh => '更新';

  @override
  String get sftpDelete => '削除';

  @override
  String sftpDeleteConfirm(String name) {
    return '\"$name\" を削除しますか？';
  }

  @override
  String get sftpRename => '名前を変更';

  @override
  String get sftpTooltip => 'ファイルを閲覧 (SFTP)';

  @override
  String get terminalMoreTooltip => 'その他';

  @override
  String get tunnelsTitle => 'ポート転送';

  @override
  String get tunnelsEmpty => 'アクティブなトンネルはありません。';

  @override
  String get tunnelsAddLocal => 'ローカル転送';

  @override
  String get tunnelsAddRemote => 'リモート転送';

  @override
  String get tunnelsLocalPort => 'ローカルポート';

  @override
  String get tunnelsRemoteHost => 'リモートホスト';

  @override
  String get tunnelsRemotePort => 'リモートポート';

  @override
  String get tunnelsAdd => '追加';

  @override
  String get tunnelsClose => '閉じる';

  @override
  String get tunnelsTooltip => 'ポート転送 (SSH トンネル)';

  @override
  String get tunnelsError => 'トンネルに失敗しました';

  @override
  String get tunnelsInvalidPort => 'ポートは 1 〜 65535 の範囲で指定してください。';

  @override
  String get settingsLanguageTitle => '言語';
}
