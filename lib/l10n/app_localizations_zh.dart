// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => '服务器';

  @override
  String get navAiChat => 'AI 助手';

  @override
  String get navSettings => '设置';

  @override
  String get pageNotFound => '页面未找到';

  @override
  String get backToServers => '返回服务器列表';

  @override
  String get serversTitle => '服务器';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台主机',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => '搜索服务器…';

  @override
  String get serversAdd => '添加服务器';

  @override
  String get serversEmpty => '暂无服务器';

  @override
  String get serversEmptyHint => '添加您的第一台 SSH 服务器开始使用。';

  @override
  String get serversDeleteConfirmTitle => '删除服务器';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return '确定要删除「$name」吗？\n\n$identity:$port 及其存储的凭据将被永久移除。';
  }

  @override
  String serversDeleted(String identity) {
    return '已移除 $identity';
  }

  @override
  String serversDeleteFailed(String message) {
    return '删除失败：$message';
  }

  @override
  String get serversLoading => '加载服务器列表';

  @override
  String get serversUngrouped => '未分组';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => '最近';

  @override
  String get serversQuickStart => '快速开始';

  @override
  String get serversQuickStep1Title => '添加主机';

  @override
  String get serversQuickStep1Desc => '注册一个 SSH 端点，支持密码或密钥认证。';

  @override
  String get serversQuickStep2Title => '测试连接';

  @override
  String get serversQuickStep2Desc => '在提交前探测端口 — 快速发现拼写错误。';

  @override
  String get serversQuickStep3Title => '连接';

  @override
  String get serversQuickStep3Desc => '打开终端会话 — 完整 PTY、彩色输出和 vim。';

  @override
  String serversNoMatch(String query) {
    return '无匹配：\"$query\"';
  }

  @override
  String get serversClearFilter => '清除筛选';

  @override
  String get serversReadError => '无法读取服务器列表。';

  @override
  String get serverEditTitle => '添加服务器';

  @override
  String get serverEditTitleEdit => '编辑服务器';

  @override
  String get serverNotFound => '服务器未找到';

  @override
  String get serverValidationNameRequired => '请输入名称';

  @override
  String get serverValidationHostRequired => '请输入主机地址';

  @override
  String get serverValidationNoSpaces => '不允许包含空格';

  @override
  String get serverValidationRequired => '必填';

  @override
  String get serverValidationNumeric => '请输入数字';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => '请输入用户名';

  @override
  String get serverValidationPasswordRequired => '请输入密码';

  @override
  String get serverValidationPrivateKeyRequired => '请输入私钥';

  @override
  String serverAdded(String identity, int port) {
    return '服务器已添加：$identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return '已保存：$identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return '保存失败：$message';
  }

  @override
  String get serverTestEnterHost => '请先输入主机地址';

  @override
  String serverTestProbing(String host, int port) {
    return '正在探测 $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — 可达';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — 超时';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — 拒绝/不可达';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — 探测失败';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port SSH 握手失败';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port 认证失败，请检查用户名与凭据';
  }

  @override
  String get serverLoading => '加载中';

  @override
  String get serverSaveChanges => '保存更改';

  @override
  String get serverSectionIdentity => '标识';

  @override
  String get serverSectionConnection => '连接';

  @override
  String get serverSectionAuthentication => '认证';

  @override
  String get serverFieldLabel => '名称';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => '分组（可选）';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => '主机地址';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => '端口';

  @override
  String get serverFieldUsername => '用户名';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => '密码';

  @override
  String get serverFieldPasswordStored => '已存储 — 留空保持不变';

  @override
  String get serverFieldPrivateKey => '私钥 (PEM)';

  @override
  String get serverFieldPassphrase => '密钥口令（可选）';

  @override
  String get serverAuthPassword => '密码';

  @override
  String get serverAuthPrivateKey => '私钥';

  @override
  String get serverTestIdle => '点击「测试」探测连接';

  @override
  String get serverSecurityNote => '凭据已加密存储在设备密钥库中 — 不会写入 Hive 元数据存储，也不会离开此设备。';

  @override
  String get serverTesting => '测试中…';

  @override
  String get serverTest => '测试';

  @override
  String get serverSaving => '保存中…';

  @override
  String serverCopiedAddress(String address) {
    return '已复制 $address';
  }

  @override
  String get serverActions => '服务器操作';

  @override
  String get serverActionConnect => '连接';

  @override
  String get serverActionEdit => '编辑';

  @override
  String get serverActionEditDetails => '编辑详情';

  @override
  String get serverActionCopySsh => '复制 SSH 命令';

  @override
  String get serverActionDelete => '删除';

  @override
  String get serverActionDeleteServer => '删除服务器';

  @override
  String get serverOnline => '在线';

  @override
  String get serverNeverConnected => '从未连接';

  @override
  String get serverJustNow => '刚刚';

  @override
  String serverMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String serverHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String serverDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get terminalHostNotFound => '主机未找到';

  @override
  String terminalHostNotFoundMessage(String id) {
    return '没有匹配的服务器 ID \"$id\"，它可能已被删除。';
  }

  @override
  String get terminalBackToServers => '返回服务器列表';

  @override
  String get terminalConnectionFailed => '连接失败。';

  @override
  String get terminalSessionClosed => '会话已关闭';

  @override
  String terminalSessionClosedMessage(String name) {
    return '与 $name 的连接已终止。';
  }

  @override
  String get terminalReconnect => '重新连接';

  @override
  String get terminalAuthenticating => '认证中';

  @override
  String get terminalConnecting => '连接中';

  @override
  String get terminalResolvingHost => '正在解析主机…';

  @override
  String get terminalTooltipDisconnectBack => '断开并返回';

  @override
  String get terminalTooltipSmallerText => '缩小字体';

  @override
  String get terminalTooltipLargerText => '放大字体';

  @override
  String get terminalTooltipDisconnect => '断开连接';

  @override
  String get terminalRetryAvailable => '可重试';

  @override
  String get terminalStatusConnected => '已连接';

  @override
  String get terminalStatusOffline => '离线';

  @override
  String get terminalStatusError => '错误';

  @override
  String get aiChatTitle => 'AI 助手';

  @override
  String get aiChatStatusSetup => '待配置';

  @override
  String get aiChatStatusStreaming => '输出中';

  @override
  String get aiChatStatusReady => '就绪';

  @override
  String get aiChatClearConversation => '清空对话';

  @override
  String get aiChatSuggestion1 => '解释 ls -la 输出的含义';

  @override
  String get aiChatSuggestion2 => '如何查找占用端口的进程？';

  @override
  String get aiChatSuggestion3 => '教我 tail 日志并用 grep 过滤错误';

  @override
  String get aiChatSuggestion4 => '写一个 awk 单行命令求和 CSV 列';

  @override
  String get aiChatTryAsking => '试试问我';

  @override
  String get aiChatIntroTitle => '你的终端伴侣';

  @override
  String get aiChatIntroBody =>
      '粘贴一个命令、一段报错或一块日志输出。ShellMind 会解释发生了什么、建议下一步操作，并帮你编写命令。';

  @override
  String get aiChatNoKeyTitle => '未配置 API 密钥';

  @override
  String aiChatNoKeyMessage(String provider) {
    return '添加你的 $provider API 密钥以启用助手。密钥加密存储在本设备上，除调用模型外不会离开设备。';
  }

  @override
  String get aiChatOpenSettings => '打开 AI 设置';

  @override
  String get aiChatCheckingCredentials => '检查凭据中';

  @override
  String get aiChatInputHint => '输入任何问题…';

  @override
  String get aiChatInputDisabled => '请先设置 API 密钥';

  @override
  String get aiChatError => '错误';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => '已复制';

  @override
  String get aiChatCopy => '复制';

  @override
  String get aiChatThinking => '思考中…';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSearchTooltip => '搜索设置';

  @override
  String get settingsStable => '稳定版';

  @override
  String get settingsSectionAppearance => '外观与语言';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'AI 服务商';

  @override
  String get settingsSectionAiAgent => 'AI Agent';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => '服务器';

  @override
  String get settingsSectionAboutUpdate => '关于与更新';

  @override
  String get settingsSectionStoragePrivacy => '存储与隐私';

  @override
  String get settingsSectionResources => '资源';

  @override
  String get settingsTileSecrets => '密钥';

  @override
  String get settingsTileEncrypted => '已加密';

  @override
  String get settingsTileLocalCache => '本地缓存';

  @override
  String get settingsTileClearData => '清除所有数据';

  @override
  String get settingsTileLicenses => '开源许可';

  @override
  String get settingsTileReportIssue => '报告问题';

  @override
  String get settingsFooter => 'SSH + AI 助手，为现代工作流打造';

  @override
  String get settingsSecretsDialogTitle => '密钥与加密';

  @override
  String get settingsSecretsDialogBody =>
      '凭据（服务器密码、私钥和 AI 密钥）始终通过平台密钥库（Android Keystore / iOS Keychain）加密存储。该保护为设计行为，无法关闭。如需更换凭据，请前往服务器编辑页或 AI 设置中修改或删除。';

  @override
  String get settingsDialogOk => '知道了';

  @override
  String get settingsDialogClose => '关闭';

  @override
  String get settingsCacheDialogTitle => '本地缓存';

  @override
  String get settingsCacheHiveData => '应用数据';

  @override
  String get settingsCacheDownloads => '已下载的更新包';

  @override
  String get settingsCacheTotal => '合计';

  @override
  String get settingsCacheDialogHint =>
      '清理下载缓存会删除已下载的更新安装包（APK），你的服务器、密钥和聊天记录将被保留。';

  @override
  String get settingsCacheClearDownloads => '清理下载缓存';

  @override
  String settingsCacheCleared(String freed) {
    return '已释放 $freed';
  }

  @override
  String get settingsClearDataTitle => '清除所有数据？';

  @override
  String get settingsClearDataMessage =>
      '此操作将永久删除本设备上的所有服务器、存储的凭据、AI 密钥、聊天记录和偏好设置，且无法撤销。';

  @override
  String get settingsClearDataConfirm => '全部清除';

  @override
  String get settingsDataCleared => '已清除所有数据';

  @override
  String settingsClearDataFailed(String message) {
    return '无法清除数据：$message';
  }

  @override
  String get settingsIssueLinkCopied => '问题反馈链接已复制到剪贴板。';

  @override
  String get settingsAboutGithub => 'GitHub 仓库';

  @override
  String get settingsHideIp => '隐藏 IP 地址';

  @override
  String get settingsHideIpDesc => '在服务器列表与 AI 页面中以打码形式显示 IP 地址';

  @override
  String get serverMaskedAddress => '地址已隐藏';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return '$provider API 密钥';
  }

  @override
  String get aiSettingsKeySet => '已设置';

  @override
  String get aiSettingsKeyNotConfigured => '未配置';

  @override
  String get aiSettingsGetApiKey => '获取 API 密钥';

  @override
  String get aiSettingsTemperature => '温度';

  @override
  String get aiSettingsRemoveKey => '移除密钥';

  @override
  String aiSettingsKeySaved(String provider) {
    return '$provider API 密钥已安全保存。';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return '移除 $provider 密钥？';
  }

  @override
  String get aiSettingsRemoveKeyMessage => '助手将无法使用该服务商，直到添加新密钥。';

  @override
  String get aiSettingsRemoveKeyConfirm => '移除';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return '获取 $provider 密钥';
  }

  @override
  String get aiSettingsGetKeyMessage => '在浏览器中打开服务商控制台创建 API 密钥，然后粘贴到此处。';

  @override
  String get aiSettingsClose => '关闭';

  @override
  String get aiSettingsLinkCopied => '链接已复制到剪贴板。';

  @override
  String get aiSettingsCopyLink => '复制链接';

  @override
  String get aiSettingsKeyConfigured => '密钥已配置';

  @override
  String get aiSettingsNotConfigured => '未配置';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return '更新 $provider 密钥';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return '添加 $provider 密钥';
  }

  @override
  String get aiSettingsKeyStorageNote => '加密存储在本设备上，仅用于调用 AI 服务商。';

  @override
  String get aiSettingsApiKeyHint => 'API 密钥…';

  @override
  String get aiSettingsSave => '保存';

  @override
  String get modelDescFastAffordable => '快速经济';

  @override
  String get modelDescMostCapable => '最强能力';

  @override
  String get modelDescLegacyFast => '经典快速';

  @override
  String get modelDescGeneralConversation => '通用对话';

  @override
  String get modelDescAdvancedReasoning => '高级推理';

  @override
  String get modelDescFastResponse => '快速响应';

  @override
  String get modelDescBalanced => '均衡';

  @override
  String get modelDescFreeFast => '免费极速';

  @override
  String get modelDescEnhanced => '增强';

  @override
  String get modelDescStandard => '标准';

  @override
  String get modelDescLightweight => '轻量';

  @override
  String get modelDescRlEnhanced => '强化学习增强';

  @override
  String get aiModelsTitle => '模型';

  @override
  String get aiModelsRefresh => '刷新模型列表';

  @override
  String get aiModelsAddCustom => '添加自定义模型';

  @override
  String get aiModelsAddCustomHint => '输入模型 ID，如 deepseek-chat';

  @override
  String get aiModelsAdd => '添加';

  @override
  String get aiModelsCustomBadge => '自定义';

  @override
  String get aiModelsFetchFailed => '模型列表获取失败，已显示内置模型';

  @override
  String get aiModelsRemoveCustom => '移除自定义模型';

  @override
  String get aiModelsEmpty => '暂无模型';

  @override
  String get aiModelsInvalidId => '请输入模型 ID';

  @override
  String get aiModelsDuplicate => '该模型已存在';

  @override
  String get aiModelsPickerTitle => '选择模型';

  @override
  String get aiModelsSearchHint => '搜索模型';

  @override
  String get aiModelsSearchEmpty => '没有匹配的模型';

  @override
  String get aiProvidersAddTile => '添加自定义服务商';

  @override
  String get aiProvidersAddTitle => '添加自定义服务商';

  @override
  String get aiProvidersFieldName => '名称';

  @override
  String get aiProvidersFieldNameHint => '例如：硅基流动';

  @override
  String get aiProvidersFieldBaseUrl => 'Base URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => '默认模型（可选）';

  @override
  String get aiProvidersFieldModelHint => '输入模型 ID，如 deepseek-chat';

  @override
  String get aiProvidersAddConfirm => '添加';

  @override
  String get aiProvidersInvalidInput => '请输入名称和 Base URL';

  @override
  String get aiProvidersInvalidUrl => 'Base URL 必须以 http:// 或 https:// 开头';

  @override
  String get aiProvidersDuplicateName => '已存在同名服务商';

  @override
  String get aiProvidersAdded => '自定义服务商已添加。';

  @override
  String get aiProvidersAddFailed => '添加失败，请检查输入。';

  @override
  String get aiProvidersDeleteTile => '移除自定义服务商';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return '移除 $provider？';
  }

  @override
  String get aiProvidersDeleteMessage =>
      '其存储的 API 密钥、记忆的模型与自定义模型也将一并删除。内置服务商不可删除。';

  @override
  String get aiProvidersDeleteConfirm => '移除';

  @override
  String get aiProvidersPickerTitle => '选择服务商';

  @override
  String get updateVersion => '版本';

  @override
  String get updateSoftwareUpdate => '软件更新';

  @override
  String get updateChecking => '检查中';

  @override
  String get updateUpToDate => '已是最新';

  @override
  String get updateCheckAgain => '重新检查';

  @override
  String get updateReady => '就绪';

  @override
  String get updateNew => '新版';

  @override
  String get updateCheck => '检查';

  @override
  String get updateAwaitingResponse => '等待响应';

  @override
  String get updateAlreadyLatest => '已是最新版本';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version 是 GitHub 上发布的最新版本。';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return '当前 v$current — 远程最新 v$latest。';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return '检查于 $timeAgo';
  }

  @override
  String get updateAvailable => '发现新版本';

  @override
  String get updatePre => '预览版';

  @override
  String get updateDownloadInstall => '下载并安装';

  @override
  String get updateLater => '稍后';

  @override
  String get updateApkHint => 'APK 安装仅在 Android 上支持。文件仍可在此下载。';

  @override
  String updateDownloading(String tag) {
    return '正在下载 $tag';
  }

  @override
  String get updateSize => '大小';

  @override
  String get updateRate => '速率';

  @override
  String get updateEta => '剩余';

  @override
  String get updateElapsed => '已用';

  @override
  String get updateCancel => '取消';

  @override
  String get updateKeepForeground => '请保持应用在前台';

  @override
  String get updateDownloadComplete => '下载完成';

  @override
  String get updateInstallHint =>
      'Android 会要求你确认。安装期间 ShellMind 会关闭；你的服务器和历史记录将被保留。';

  @override
  String get updateLaunching => '启动中...';

  @override
  String get updateInstallNow => '立即安装';

  @override
  String get updateDelete => '删除';

  @override
  String updateInstallTitle(String tag) {
    return '安装 $tag？';
  }

  @override
  String get updateInstallMessage =>
      '系统安装程序将会打开。安装期间 ShellMind 会关闭，完成后自动以新版本重新打开。';

  @override
  String get updateNotNow => '暂不安装';

  @override
  String get updateInstall => '安装';

  @override
  String get updateCheckFailed => '更新检查失败。';

  @override
  String get updateErrorTitleNoReleases => '暂无发布版本';

  @override
  String get updateErrorTitleGeneric => '更新检查失败';

  @override
  String get updateErrNoReleases => 'ShellMind 目前还没有发布任何版本。';

  @override
  String get updateErrRateLimit => '已达到 GitHub API 访问频率限制，请稍后重试。';

  @override
  String get updateErrTimeout => '请求 GitHub 超时，请检查网络后重试。';

  @override
  String get updateErrNetwork => '无法连接 GitHub，请检查网络连接。';

  @override
  String get updateErrAuth => 'GitHub 拒绝了本次更新请求。';

  @override
  String get updateErrPermission => '更新请求被拒绝。';

  @override
  String get updateErrStorage => '存储空间不足，无法完成更新。';

  @override
  String get updateErrDigestMismatch => '下载的更新包未通过 SHA-256 完整性校验，已被删除。请重新下载。';

  @override
  String get updateErrDigestMissing => '更新包缺少发布方完整性摘要（digest），本次更新已拒绝。请稍后重试。';

  @override
  String get updateRetry => '重试';

  @override
  String get updateDismiss => '忽略';

  @override
  String updateReleaseNotes(String tag) {
    return '版本 $tag';
  }

  @override
  String get updateNotesLabel => '日志';

  @override
  String get updateNewVersionAvailable => '发现新版本';

  @override
  String get updateRemindLater => '稍后提醒';

  @override
  String get updateCancelDownload => '取消下载';

  @override
  String updateInstallTag(String tag) {
    return '安装 $tag';
  }

  @override
  String get updateInstallLaterFromSettings => '稍后在设置中安装';

  @override
  String get updateCouldNotComplete => '更新无法完成。';

  @override
  String get updateClose => '关闭';

  @override
  String get updatePromptInstallHint =>
      '安装期间 Android 会关闭 ShellMind。服务器、密钥和聊天历史将被保留。';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRetry => '重试';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonNoData => '暂无数据';

  @override
  String get commonNothingToShow => '这里还没有内容。';

  @override
  String get commonOk => '确定';

  @override
  String get settingsAiAutoExecuteTitle => '自动执行命令';

  @override
  String get settingsAiAutoExecuteSubtitle => '允许 AI 智能体无需逐次确认即可运行解析出的命令';

  @override
  String get settingsAiAutoConnectTitle => 'AI 自动连接服务器';

  @override
  String get settingsAiAutoConnectSubtitle =>
      '允许 AI 助手对未连接的已配置服务器自动发起连接并执行命令（将使用已保存的凭据）';

  @override
  String get settingsAiMaxAutoLoopsTitle => '最大自动循环次数';

  @override
  String get settingsAiMaxAutoLoopsSub => '限制每次响应后的自动命令执行次数上限';

  @override
  String get settingsAiMaxAutoLoopsTileDesc => 'AI 每次任务可自动执行命令的最大轮数';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      '这是 AI 每次任务的执行轮数上限，并非 SSH 断线后的自动重连次数（后者位于 SSH 分区）。';

  @override
  String get terminalAskAi => '询问 AI';

  @override
  String get terminalAskAiSubtitle => '将选中的文本发送给 AI 助手';

  @override
  String get terminalTooltipAskAi => '询问 AI';

  @override
  String get aiChatNoConnection => '请先在服务器页面连接终端';

  @override
  String get aiChatAnalyzePrompt => '请分析上面命令的执行输出，说明结果含义并在必要时给出后续建议。';

  @override
  String get aiExecuteButton => '在服务器执行';

  @override
  String get aiExecuteTitle => '确认执行命令';

  @override
  String get aiExecuteConfirmButton => '确认执行';

  @override
  String get aiExecuteConfirmAnyway => '仍要执行';

  @override
  String get aiExecuteDangerWarning => '⚠ 危险命令警告';

  @override
  String get aiExecuteDangerText => '此命令可能具有破坏性，可能导致数据丢失或系统损坏。';

  @override
  String get aiExecuteCommandLabel => '要执行的命令：';

  @override
  String get aiExecuteTargetServer => '目标服务器：';

  @override
  String get aiExecuteSelectServer => '选择目标服务器';

  @override
  String get aiExecuteNoServer => '请先在服务器页面连接终端';

  @override
  String get aiExecuteAtLeastOne => '请至少选择一个服务器';

  @override
  String get aiExecuteSelectHint => '请选择要执行命令的服务器';

  @override
  String aiExecuteRunCount(int count) {
    return '执行（$count）';
  }

  @override
  String get aiExecuteSelectAll => '全选';

  @override
  String get aiExecuteClearSelection => '清除';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '在线 $hours 小时 $minutes 分钟';
  }

  @override
  String get aiExecuteSuccess => '命令执行成功';

  @override
  String get aiExecuteFailed => '命令执行失败';

  @override
  String get aiServerManageTitle => '服务器';

  @override
  String get aiServerManageSubtitle => '连接服务器供 AI 助手操作';

  @override
  String aiServerOnlineCount(int count) {
    return '$count 台在线';
  }

  @override
  String get aiServerDone => '完成';

  @override
  String get aiServerConnecting => '连接中…';

  @override
  String get aiServerOffline => '离线';

  @override
  String get aiServerNoCredential => '未存储凭据——请先在服务器页面保存密码或密钥';

  @override
  String get aiServerConnectFailed => '连接失败';

  @override
  String get aiToolResultCommand => '命令';

  @override
  String get aiToolResultOutput => '命令输出';

  @override
  String aiToolResultExitCode(int code) {
    return '退出码：$code';
  }

  @override
  String get aiToolResultElapsed => '执行耗时';

  @override
  String get aiToolResultAnalyzeButton => '让 AI 分析输出';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '展开其余 $total 行';
  }

  @override
  String get aiToolResultExpandedHide => '收起输出';

  @override
  String get aiToolResultStderrLabel => '错误输出：';

  @override
  String get aiContextToggleAttach => '附加终端上下文';

  @override
  String get aiContextToggleDetach => '终端上下文已开启';

  @override
  String get aiContextBadge => '上下文';

  @override
  String aiContextLines(int lines) {
    return '来自终端的 $lines 行';
  }

  @override
  String get aiAgentStop => '停止自动模式';

  @override
  String get aiAgentExecuting => '执行中…';

  @override
  String get aiAgentDefaultServer => '服务器';

  @override
  String get aiTimelineTitle => '执行时间线';

  @override
  String get aiTimelineOpen => '执行时间线';

  @override
  String get aiTimelineEmpty => '还没有执行过命令';

  @override
  String get aiTimelineEmptyHint => '通过对话或自动模式执行命令后，完整链路将在此展示。';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 轮',
      one: '1 轮',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条命令',
      one: '1 条命令',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条成功',
      one: '1 条成功',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条失败',
      one: '1 条失败',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return '开始于 $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return '结束于 $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return '退出码：$code';
  }

  @override
  String get aiTimelineNoExitCode => '无退出码';

  @override
  String get aiTimelineOutput => '输出';

  @override
  String get aiTimelineOutputEmpty => '无输出';

  @override
  String get aiTimelineErrorOutput => '错误输出';

  @override
  String get aiTimelineRunning => '执行中…';

  @override
  String get aiTimelineClose => '关闭';

  @override
  String get sshReconnectToggle => 'SSH 断线自动重连';

  @override
  String get sshReconnectToggleDesc => '连接意外断开时按指数退避自动重试';

  @override
  String get sshReconnectMaxAttempts => '最大重试次数';

  @override
  String get sshReconnectMaxAttemptsDesc => 'SSH 断线后自动重连的最大尝试次数，0 表示一直重试直到成功';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => '不限';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return '重连中（第 $attempt 次）';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return '重连中（第 $attempt/$max 次）';
  }

  @override
  String get sshReconnectGaveUp => '自动重连已放弃';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return '重试 $max 次后仍无法连接 $name。';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return '无法连接 $name。';
  }

  @override
  String get sshReconnectRetryNow => '立即重试';

  @override
  String get sshReconnectStopAuto => '停止';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return '已重新连接到 $name';
  }

  @override
  String get snippetsTitle => '命令快捷片段';

  @override
  String get snippetsSubtitle => '保存常用命令，随时快速复用';

  @override
  String get snippetsAddTooltip => '添加片段';

  @override
  String get snippetsAddTitle => '新建片段';

  @override
  String get snippetsSave => '保存';

  @override
  String get snippetsCommandLabel => '命令';

  @override
  String get snippetsCommandHint => '例如 docker ps -a';

  @override
  String get snippetsNameLabel => '名称（可选）';

  @override
  String get snippetsNameHint => '例如 列出所有容器';

  @override
  String get snippetsCommandRequired => '命令内容不能为空';

  @override
  String get snippetsDeleteTooltip => '删除片段';

  @override
  String get snippetsEmptyTitle => '还没有快捷片段';

  @override
  String get snippetsEmptyMessage => '保存常用命令后，即可一键插入或直接执行。';

  @override
  String get snippetsLoadFailed => '片段加载失败';

  @override
  String get healthTitle => '集群健康';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total 在线';
  }

  @override
  String get healthProbing => '探测中…';

  @override
  String get healthProbeTooltip => '运行健康检查';

  @override
  String healthProbedAt(String time) {
    return '检查于 $time';
  }

  @override
  String get healthMoodAllOnline => '所有服务器运行正常';

  @override
  String get healthMoodDegraded => '部分服务器不可达';

  @override
  String get healthMoodAllOffline => '所有服务器不可达';

  @override
  String healthOfflineServers(String names) {
    return '离线：$names';
  }

  @override
  String get healthNoData => '点击刷新检查全部服务器';

  @override
  String healthUptime(String brief) {
    return '已运行 $brief';
  }

  @override
  String healthLoad(String value) {
    return '负载 $value';
  }

  @override
  String get healthDiagIntro => '这是我的服务器集群健康报告：';

  @override
  String healthDiagStats(int online, int total) {
    return '$total 台服务器中 $online 台在线。';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name：离线';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name：在线（$details）';
  }

  @override
  String get healthDiagOutro => '请分析这份健康数据，指出异常之处（高负载、近期重启等），并给出下一步排查建议。';

  @override
  String get healthDiagnose => 'AI 诊断';

  @override
  String get healthStaleNote => '部分服务器在最近一次检查后已离线。';

  @override
  String get auditTitle => '命令审计日志';

  @override
  String get auditTileDesc => 'AI 执行过的命令记录';

  @override
  String get auditEmptyTitle => '暂无审计记录';

  @override
  String get auditEmptyMessage => 'AI Agent 执行的命令会记录在这里。';

  @override
  String get auditFilteredEmpty => '没有符合当前筛选条件的记录';

  @override
  String get auditFilterAllServers => '全部服务器';

  @override
  String get auditFilterAllModes => '全部模式';

  @override
  String get auditFilterAllResults => '全部结果';

  @override
  String get auditFilterConfirmed => '确认执行';

  @override
  String get auditFilterAuto => '自动执行';

  @override
  String get auditFilterSuccess => '成功';

  @override
  String get auditFilterFailed => '失败';

  @override
  String get auditModeConfirmed => '确认';

  @override
  String get auditModeAuto => '自动';

  @override
  String get auditStatusSuccess => '成功';

  @override
  String get auditStatusFailed => '失败';

  @override
  String get auditDangerousBadge => '危险';

  @override
  String auditExitCode(int code) {
    return '退出码 $code';
  }

  @override
  String get auditOutputSummary => '输出摘要';

  @override
  String get auditNoOutput => '无输出';

  @override
  String get auditClearTooltip => '清空审计日志';

  @override
  String get auditClearConfirmTitle => '清空审计日志';

  @override
  String auditClearConfirmMessage(int count) {
    return '全部 $count 条审计记录将被永久删除。';
  }

  @override
  String get auditClearAction => '清空';

  @override
  String get auditCleared => '审计日志已清空';

  @override
  String auditEntriesCount(int count) {
    return '$count 条记录';
  }

  @override
  String get serverActionDisconnect => '断开连接';

  @override
  String get exportChatAction => '导出为 Markdown';

  @override
  String get exportChatEmpty => '暂无可导出的对话';

  @override
  String exportChatSuccess(String path) {
    return '对话已导出到 $path';
  }

  @override
  String exportChatFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get diagTitle => '诊断信息';

  @override
  String get diagTileDesc => '应用错误与诊断导出';

  @override
  String get diagEmptyTitle => '暂无捕获的错误';

  @override
  String get diagEmptyMessage => '应用运行中的未捕获异常会记录在这里，便于报障时排查。';

  @override
  String diagEntriesCount(int count) {
    return '共 $count 条错误';
  }

  @override
  String get diagSourceFlutter => '界面错误';

  @override
  String get diagSourcePlatform => '运行时错误';

  @override
  String get diagSourceZone => '异步任务';

  @override
  String get diagStackTrace => '堆栈';

  @override
  String get diagNoStackTrace => '无堆栈信息';

  @override
  String get diagExportAction => '导出诊断报告';

  @override
  String get diagExportEmpty => '诊断内容为空，已导出基础信息';

  @override
  String diagExportSuccess(String path) {
    return '诊断报告已导出到 $path';
  }

  @override
  String diagExportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get diagPrivacyNote => '诊断内容经过脱敏处理，不会包含密码、私钥或 API Key。';

  @override
  String get diagClearTooltip => '清除错误记录';

  @override
  String get diagClearConfirmTitle => '清除错误记录';

  @override
  String diagClearConfirmMessage(int count) {
    return '全部 $count 条错误记录将被永久删除。';
  }

  @override
  String get diagClearAction => '清除';

  @override
  String get diagCleared => '错误记录已清除';

  @override
  String get diagAppInfoTitle => '应用信息';

  @override
  String get diagAppInfoVersion => '版本';

  @override
  String get diagAppInfoPlatform => '平台';

  @override
  String get diagAppInfoLocale => '语言';

  @override
  String get diagAppInfoStorage => '本地数据占用';

  @override
  String get authLockToggleTitle => '生物识别锁';

  @override
  String get authLockToggleDesc => '打开应用时需通过指纹或面部验证';

  @override
  String get authLockEnableFailed => '验证未通过，锁定保持关闭';

  @override
  String get authLockUnavailableDesc => '此设备未录入生物识别信息';

  @override
  String get authLockScreenTitle => 'ShellMind 已锁定';

  @override
  String get authLockScreenSubtitle => '验证身份以继续';

  @override
  String get authLockUnlockAction => '解锁';

  @override
  String get authLockUnlockFailed => '验证未通过，请重试';

  @override
  String get terminalTabPickerTitle => '切换终端';

  @override
  String get terminalTabPickerSubtitle => '选择一个服务器打开为终端标签 — 在线的立即接入，离线的先拨号';

  @override
  String get terminalTabPickerEmpty => '尚未配置任何服务器';

  @override
  String get terminalTabNewTooltip => '新建终端标签';

  @override
  String get terminalTabCloseTooltip => '关闭标签';

  @override
  String get hostKeyConfirmTitle => '信任此主机？';

  @override
  String get hostKeyConfirmMessage => '这是首次连接该服务器。请先核对指纹再决定是否信任 — 以防中间人攻击。';

  @override
  String get hostKeyEndpointLabel => '服务器';

  @override
  String get hostKeyFingerprintLabel => 'SHA-256 指纹';

  @override
  String get hostKeySecurityNote => '请与您从服务器管理员处（带外渠道）获得的指纹比对。信任错误的指纹会暴露您的凭据。';

  @override
  String get hostKeyTrustAndConnect => '信任并连接';

  @override
  String get hostKeyReject => '拒绝';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return '$seconds 秒后自动拒绝 — 仅在您确认后才会记录信任。';
  }

  @override
  String get hostKeyMismatchTitle => '主机密钥已变更';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return '$host:$port 出示的密钥与您此前信任的不一致，连接已被拦截 — 这可能是中间人攻击，或服务器已重装。若您已核实新密钥，请在服务器编辑页重置主机信任后重新连接。';
  }

  @override
  String get hostKeyRejectedMessage => '连接已取消 — 主机密钥未被信任。可重新连接以再次核对指纹。';

  @override
  String get serverResetTrustAction => '重置主机信任';

  @override
  String get serverResetTrustDesc => '清除该服务器已存储的指纹，下次连接将再次请求确认。';

  @override
  String get serverResetTrustConfirmTitle => '重置主机信任？';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return '将移除 $identity:$port 已存储的指纹，下次连接会要求您重新核对主机密钥。';
  }

  @override
  String get serverResetTrustConfirmAction => '重置';

  @override
  String get serverResetTrustDone => '主机信任已重置 — 重新连接以再次核对指纹。';

  @override
  String get agentErrorNoTargetServer => '没有可用的目标服务器';

  @override
  String get agentErrorExecFailed => '命令执行失败';

  @override
  String get agentErrorConnectFailed => '自动连接服务器失败';

  @override
  String get agentErrorConnectAuthRequired => '缺少已保存的凭据，无法自动连接该服务器';

  @override
  String agentErrorDangerSkipped(String command) {
    return '已跳过危险命令：$command';
  }

  @override
  String get agentErrorUnexpected => '发生意外错误';

  @override
  String get exportDocChatTitle => 'Shell-Mind 对话导出';

  @override
  String exportDocExportedAt(String time) {
    return '导出时间：$time';
  }

  @override
  String exportDocMessageCount(int count) {
    return '消息数：$count';
  }

  @override
  String get exportDocUserSection => '用户';

  @override
  String get exportDocAssistantSection => '助手';

  @override
  String get exportDocToolSection => '工具执行';

  @override
  String get exportDocNoContent => '_(无内容)_';

  @override
  String get exportDocUnknownServer => '未知服务器';

  @override
  String exportDocExitCode(int code) {
    return '退出码 $code';
  }

  @override
  String get exportDocCommand => '命令';

  @override
  String get exportDocOutput => '输出';

  @override
  String get exportDocErrorOutput => '错误输出';

  @override
  String get exportDocDiagTitle => 'Shell-Mind 诊断报告';

  @override
  String exportDocDiagCrashCount(int count) {
    return '捕获错误：$count 条';
  }

  @override
  String get exportDocDiagCrashesSection => '捕获的错误';

  @override
  String get exportDocDiagNone => '（无）';

  @override
  String exportDocDiagErrorMessage(String message) {
    return '错误摘要：$message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'App 版本：$version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return '平台：$platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return '语言：$locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return '本地数据占用：$value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'AI 命令审计（最近 $limit 条摘要）';
  }

  @override
  String get exportDocDiagSuccess => '成功';

  @override
  String get exportDocDiagFailed => '失败';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return '退出码 $code';
  }
}
