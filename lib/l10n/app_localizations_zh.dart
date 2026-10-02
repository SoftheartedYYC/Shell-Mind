// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Shell-Mind';

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
      '粘贴一个命令、一段报错或一块日志输出。Shell-Mind 会解释发生了什么、建议下一步操作，并帮你编写命令。';

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
  String get aiChatAssistantName => 'Shell-Mind';

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
  String get settingsSectionAppearance => '外观';

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
      'Android 会要求你确认。安装期间 Shell-Mind 会关闭；你的服务器和历史记录将被保留。';

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
      '系统安装程序将会打开。安装期间 Shell-Mind 会关闭，完成后自动以新版本重新打开。';

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
  String get updateErrNoReleases => 'Shell-Mind 目前还没有发布任何版本。';

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
      '安装期间 Android 会关闭 Shell-Mind。服务器、密钥和聊天历史将被保留。';

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
  String get settingsAiMaxAutoLoopsTitle => '最大自动循环次数';

  @override
  String get settingsAiMaxAutoLoopsSub => '限制每次响应后的自动命令执行次数上限';

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
  String get aiAgentAutoModeOn => '自动模式：开';

  @override
  String get aiAgentAutoModeOff => '自动模式：关';

  @override
  String get aiAgentStop => '停止自动模式';

  @override
  String get aiAgentExecuting => '执行中…';

  @override
  String get aiAgentDefaultServer => '服务器';
}
