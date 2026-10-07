// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Servers';

  @override
  String get navAiChat => 'AI Chat';

  @override
  String get navSettings => 'Settings';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get backToServers => 'Back to Servers';

  @override
  String get serversTitle => 'Servers';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hosts',
      one: '1 host',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Search servers…';

  @override
  String get serversAdd => 'Add server';

  @override
  String get serversEmpty => 'No servers yet';

  @override
  String get serversEmptyHint => 'Add your first SSH server to get started.';

  @override
  String get serversDeleteConfirmTitle => 'Delete server';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return 'Delete \"$name\"?\n\n$identity:$port and its stored credentials will be permanently removed.';
  }

  @override
  String serversDeleted(String identity) {
    return 'Removed $identity';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get serversLoading => 'Loading servers';

  @override
  String get serversUngrouped => 'Ungrouped';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'recent';

  @override
  String get serversQuickStart => 'Quick start';

  @override
  String get serversQuickStep1Title => 'Add a host';

  @override
  String get serversQuickStep1Desc =>
      'Register an SSH endpoint with password or key auth.';

  @override
  String get serversQuickStep2Title => 'Test connection';

  @override
  String get serversQuickStep2Desc =>
      'Probe the port before committing — catches typos fast.';

  @override
  String get serversQuickStep3Title => 'Connect';

  @override
  String get serversQuickStep3Desc =>
      'Open a terminal session — full PTY, colours, and vim.';

  @override
  String serversNoMatch(String query) {
    return 'No match: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Clear filter';

  @override
  String get serversReadError => 'Could not read the server list.';

  @override
  String get serverEditTitle => 'Add server';

  @override
  String get serverEditTitleEdit => 'Edit server';

  @override
  String get serverNotFound => 'Server not found';

  @override
  String get serverValidationNameRequired => 'Name required';

  @override
  String get serverValidationHostRequired => 'Host required';

  @override
  String get serverValidationNoSpaces => 'No spaces allowed';

  @override
  String get serverValidationRequired => 'Required';

  @override
  String get serverValidationNumeric => 'Numeric';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Username required';

  @override
  String get serverValidationPasswordRequired => 'Password required';

  @override
  String get serverValidationPrivateKeyRequired => 'Private key required';

  @override
  String serverAdded(String identity, int port) {
    return 'Server added: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Saved: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Save failed: $message';
  }

  @override
  String get serverTestEnterHost => 'Enter a host address first';

  @override
  String serverTestProbing(String host, int port) {
    return 'Probing $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — reachable';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — timed out';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — refused / unreachable';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — probe failed';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port SSH handshake failed';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port authentication failed - check username and credentials';
  }

  @override
  String get serverLoading => 'Loading';

  @override
  String get serverSaveChanges => 'Save changes';

  @override
  String get serverSectionIdentity => 'Identity';

  @override
  String get serverSectionConnection => 'Connection';

  @override
  String get serverSectionAuthentication => 'Authentication';

  @override
  String get serverFieldLabel => 'Label';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Group (optional)';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => 'Host';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Port';

  @override
  String get serverFieldUsername => 'Username';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Password';

  @override
  String get serverFieldPasswordStored => 'Stored — leave blank to keep';

  @override
  String get serverFieldPrivateKey => 'Private key (PEM)';

  @override
  String get serverFieldPassphrase => 'Key passphrase (optional)';

  @override
  String get serverAuthPassword => 'Password';

  @override
  String get serverAuthPrivateKey => 'Private key';

  @override
  String get serverTestIdle => 'Tap \"Test\" to probe the connection';

  @override
  String get serverSecurityNote =>
      'Credentials are encrypted in the device keystore — they never touch the Hive metadata store or leave this device.';

  @override
  String get serverTesting => 'Testing…';

  @override
  String get serverTest => 'Test';

  @override
  String get serverSaving => 'Saving…';

  @override
  String serverCopiedAddress(String address) {
    return 'Copied $address';
  }

  @override
  String get serverActions => 'Server actions';

  @override
  String get serverActionConnect => 'Connect';

  @override
  String get serverActionEdit => 'Edit';

  @override
  String get serverActionEditDetails => 'Edit details';

  @override
  String get serverActionCopySsh => 'Copy SSH command';

  @override
  String get serverActionDelete => 'Delete';

  @override
  String get serverActionDeleteServer => 'Delete server';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverNeverConnected => 'Never connected';

  @override
  String get serverJustNow => 'Just now';

  @override
  String serverMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String serverHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String serverDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get terminalHostNotFound => 'Host not found';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'No saved server matches id \"$id\". It may have been deleted.';
  }

  @override
  String get terminalBackToServers => 'Back to servers';

  @override
  String get terminalConnectionFailed => 'Connection failed.';

  @override
  String get terminalSessionClosed => 'Session closed';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'The connection to $name was terminated.';
  }

  @override
  String get terminalReconnect => 'Reconnect';

  @override
  String get terminalAuthenticating => 'Authenticating';

  @override
  String get terminalConnecting => 'Connecting';

  @override
  String get terminalResolvingHost => 'Resolving host…';

  @override
  String get terminalTooltipDisconnectBack => 'Disconnect & back';

  @override
  String get terminalTooltipSmallerText => 'Smaller text';

  @override
  String get terminalTooltipLargerText => 'Larger text';

  @override
  String get terminalTooltipDisconnect => 'Disconnect';

  @override
  String get terminalRetryAvailable => 'Retry available';

  @override
  String get terminalStatusConnected => 'CONNECTED';

  @override
  String get terminalStatusOffline => 'OFFLINE';

  @override
  String get terminalStatusError => 'ERROR';

  @override
  String get aiChatTitle => 'AI Assistant';

  @override
  String get aiChatStatusSetup => 'SETUP';

  @override
  String get aiChatStatusStreaming => 'STREAMING';

  @override
  String get aiChatStatusReady => 'READY';

  @override
  String get aiChatClearConversation => 'Clear conversation';

  @override
  String get aiChatSuggestion1 => 'Explain what ls -la output means';

  @override
  String get aiChatSuggestion2 =>
      'How do I find which process is using a port?';

  @override
  String get aiChatSuggestion3 =>
      'Show me how to tail logs and grep for errors';

  @override
  String get aiChatSuggestion4 => 'Write an awk one-liner to sum a CSV column';

  @override
  String get aiChatTryAsking => 'Try asking';

  @override
  String get aiChatIntroTitle => 'Your terminal companion';

  @override
  String get aiChatIntroBody =>
      'Paste a command, an error, or a chunk of log output. ShellMind explains what happened, suggests the next move, and writes the commands so you don\'t have to.';

  @override
  String get aiChatNoKeyTitle => 'No API key configured';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Add your $provider API key to wake the assistant. It\'s stored encrypted on this device and never leaves it except to call the model.';
  }

  @override
  String get aiChatOpenSettings => 'Open AI settings';

  @override
  String get aiChatCheckingCredentials => 'Checking credentials';

  @override
  String get aiChatInputHint => 'Ask anything…';

  @override
  String get aiChatInputDisabled => 'Set an API key to begin';

  @override
  String get aiChatError => 'Error';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Copied';

  @override
  String get aiChatCopy => 'Copy';

  @override
  String get aiChatThinking => 'Thinking…';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSearchTooltip => 'Search settings';

  @override
  String get settingsStable => 'STABLE';

  @override
  String get settingsSectionAppearance => 'Appearance & Language';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'AI Provider';

  @override
  String get settingsSectionAiAgent => 'AI Agent';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Servers';

  @override
  String get settingsSectionAboutUpdate => 'About & Update';

  @override
  String get settingsSectionStoragePrivacy => 'Storage & Privacy';

  @override
  String get settingsSectionResources => 'Resources';

  @override
  String get settingsTileSecrets => 'Secrets';

  @override
  String get settingsTileEncrypted => 'Encrypted';

  @override
  String get settingsTileLocalCache => 'Local cache';

  @override
  String get settingsTileClearData => 'Clear all data';

  @override
  String get settingsTileLicenses => 'Open-source licences';

  @override
  String get settingsTileReportIssue => 'Report an issue';

  @override
  String get settingsFooter => 'SSH + AI Assistant for modern workflows';

  @override
  String get settingsSecretsDialogTitle => 'Secrets & encryption';

  @override
  String get settingsSecretsDialogBody =>
      'Credentials — server passwords, private keys and AI API keys — are always encrypted at rest using the platform keystore (Android Keystore / iOS Keychain). This protection is by design and cannot be turned off. To change a credential, edit or remove it on the server edit page or in AI settings.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Close';

  @override
  String get settingsCacheDialogTitle => 'Local cache';

  @override
  String get settingsCacheHiveData => 'App data';

  @override
  String get settingsCacheDownloads => 'Downloaded updates';

  @override
  String get settingsCacheTotal => 'Total';

  @override
  String get settingsCacheDialogHint =>
      'Clearing the download cache removes downloaded update packages (APKs). Your servers, keys and chat history are kept.';

  @override
  String get settingsCacheClearDownloads => 'Clear download cache';

  @override
  String settingsCacheCleared(String freed) {
    return 'Freed $freed';
  }

  @override
  String get settingsClearDataTitle => 'Clear all data?';

  @override
  String get settingsClearDataMessage =>
      'This permanently deletes every server, stored credential, AI key, chat history and preference on this device. This action cannot be undone.';

  @override
  String get settingsClearDataConfirm => 'Clear everything';

  @override
  String get settingsDataCleared => 'All data cleared';

  @override
  String settingsClearDataFailed(String message) {
    return 'Couldn\'t clear data: $message';
  }

  @override
  String get settingsIssueLinkCopied => 'Issue link copied to clipboard.';

  @override
  String get settingsAboutGithub => 'GitHub repository';

  @override
  String get settingsHideIp => 'Hide IP addresses';

  @override
  String get settingsHideIpDesc =>
      'Mask IP addresses in the server list and AI pages';

  @override
  String get serverMaskedAddress => 'Address hidden';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return '$provider API key';
  }

  @override
  String get aiSettingsKeySet => 'set';

  @override
  String get aiSettingsKeyNotConfigured => 'not configured';

  @override
  String get aiSettingsGetApiKey => 'Get an API key';

  @override
  String get aiSettingsTemperature => 'Temperature';

  @override
  String get aiSettingsRemoveKey => 'Remove key';

  @override
  String aiSettingsKeySaved(String provider) {
    return '$provider API key saved securely.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return 'Remove $provider key?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'The assistant will stop working for this provider until a new key is added.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Remove';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Get a $provider key';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Open the provider console in your browser to create an API key, then paste it back here.';

  @override
  String get aiSettingsClose => 'Close';

  @override
  String get aiSettingsLinkCopied => 'Link copied to clipboard.';

  @override
  String get aiSettingsCopyLink => 'Copy link';

  @override
  String get aiSettingsKeyConfigured => 'Key configured';

  @override
  String get aiSettingsNotConfigured => 'Not configured';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Update $provider key';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Add $provider key';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Stored encrypted on this device. Used only to call the AI provider.';

  @override
  String get aiSettingsApiKeyHint => 'API key…';

  @override
  String get aiSettingsSave => 'Save';

  @override
  String get modelDescFastAffordable => 'Fast & affordable';

  @override
  String get modelDescMostCapable => 'Most capable';

  @override
  String get modelDescLegacyFast => 'Legacy fast';

  @override
  String get modelDescGeneralConversation => 'General conversation';

  @override
  String get modelDescAdvancedReasoning => 'Advanced reasoning';

  @override
  String get modelDescFastResponse => 'Fast response';

  @override
  String get modelDescBalanced => 'Balanced';

  @override
  String get modelDescFreeFast => 'Free & fast';

  @override
  String get modelDescEnhanced => 'Enhanced';

  @override
  String get modelDescStandard => 'Standard';

  @override
  String get modelDescLightweight => 'Lightweight';

  @override
  String get modelDescRlEnhanced => 'RL enhanced';

  @override
  String get aiModelsTitle => 'Model';

  @override
  String get aiModelsRefresh => 'Refresh model list';

  @override
  String get aiModelsAddCustom => 'Add custom model';

  @override
  String get aiModelsAddCustomHint => 'Model ID, e.g. deepseek-chat';

  @override
  String get aiModelsAdd => 'Add';

  @override
  String get aiModelsCustomBadge => 'Custom';

  @override
  String get aiModelsFetchFailed =>
      'Couldn\'t fetch models — showing the built-in list.';

  @override
  String get aiModelsRemoveCustom => 'Remove custom model';

  @override
  String get aiModelsEmpty => 'No models';

  @override
  String get aiModelsInvalidId => 'Enter a model ID.';

  @override
  String get aiModelsDuplicate => 'This model is already in the list.';

  @override
  String get aiModelsPickerTitle => 'Choose model';

  @override
  String get aiModelsSearchHint => 'Search models';

  @override
  String get aiModelsSearchEmpty => 'No models match your search.';

  @override
  String get aiProvidersAddTile => 'Add custom provider';

  @override
  String get aiProvidersAddTitle => 'Add custom provider';

  @override
  String get aiProvidersFieldName => 'Name';

  @override
  String get aiProvidersFieldNameHint => 'e.g. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'Base URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Default model (optional)';

  @override
  String get aiProvidersFieldModelHint => 'Model ID, e.g. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Add';

  @override
  String get aiProvidersInvalidInput => 'Enter a name and a base URL.';

  @override
  String get aiProvidersInvalidUrl =>
      'Base URL must start with http:// or https://';

  @override
  String get aiProvidersDuplicateName =>
      'A provider with this name already exists.';

  @override
  String get aiProvidersAdded => 'Custom provider added.';

  @override
  String get aiProvidersAddFailed =>
      'Couldn\'t add the provider — check the inputs.';

  @override
  String get aiProvidersDeleteTile => 'Remove custom provider';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return 'Remove $provider?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Its stored API key, remembered model and custom models will be removed too. Built-in providers can\'t be deleted.';

  @override
  String get aiProvidersDeleteConfirm => 'Remove';

  @override
  String get aiProvidersPickerTitle => 'Choose provider';

  @override
  String get updateVersion => 'Version';

  @override
  String get updateSoftwareUpdate => 'Software update';

  @override
  String get updateChecking => 'CHECKING';

  @override
  String get updateUpToDate => 'UP TO DATE';

  @override
  String get updateCheckAgain => 'Check again';

  @override
  String get updateReady => 'READY';

  @override
  String get updateNew => 'NEW';

  @override
  String get updateCheck => 'CHECK';

  @override
  String get updateAwaitingResponse => 'Awaiting response';

  @override
  String get updateAlreadyLatest => 'Already on the latest build';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version is the newest release published on GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'Running v$current — remote head is v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Checked $timeAgo';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updatePre => 'PRE';

  @override
  String get updateDownloadInstall => 'Download & Install';

  @override
  String get updateLater => 'Later';

  @override
  String get updateApkHint =>
      'APK installation is only supported on Android. The file can still be downloaded here.';

  @override
  String updateDownloading(String tag) {
    return 'Downloading $tag';
  }

  @override
  String get updateSize => 'size';

  @override
  String get updateRate => 'rate';

  @override
  String get updateEta => 'eta';

  @override
  String get updateElapsed => 'elapsed';

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateKeepForeground => 'Keep the app in the foreground';

  @override
  String get updateDownloadComplete => 'Download complete';

  @override
  String get updateInstallHint =>
      'Android will ask you to confirm. ShellMind closes while the installer runs; your servers and history are preserved.';

  @override
  String get updateLaunching => 'Launching...';

  @override
  String get updateInstallNow => 'Install Now';

  @override
  String get updateDelete => 'Delete';

  @override
  String updateInstallTitle(String tag) {
    return 'Install $tag?';
  }

  @override
  String get updateInstallMessage =>
      'The system package installer will open. ShellMind closes during installation and reopens on the new version.';

  @override
  String get updateNotNow => 'Not now';

  @override
  String get updateInstall => 'Install';

  @override
  String get updateCheckFailed => 'The update check failed.';

  @override
  String get updateErrorTitleNoReleases => 'No releases';

  @override
  String get updateErrorTitleGeneric => 'Update check failed';

  @override
  String get updateErrNoReleases =>
      'No releases have been published for ShellMind yet.';

  @override
  String get updateErrRateLimit =>
      'GitHub\'s API rate limit was reached. Please try again later.';

  @override
  String get updateErrTimeout =>
      'The request to GitHub timed out. Check your connection and retry.';

  @override
  String get updateErrNetwork =>
      'Couldn\'t reach GitHub. Check your network connection.';

  @override
  String get updateErrAuth => 'GitHub rejected the update request.';

  @override
  String get updateErrPermission => 'The update request was denied.';

  @override
  String get updateErrStorage =>
      'Not enough storage space to complete the update.';

  @override
  String get updateErrDigestMismatch =>
      'The downloaded update failed the SHA-256 integrity check and was deleted. Please retry the download.';

  @override
  String get updateErrDigestMissing =>
      'The update package has no published integrity digest, so the update was refused. Please retry later.';

  @override
  String get updateRetry => 'Retry';

  @override
  String get updateDismiss => 'Dismiss';

  @override
  String updateReleaseNotes(String tag) {
    return 'Release $tag';
  }

  @override
  String get updateNotesLabel => 'notes';

  @override
  String get updateNewVersionAvailable => 'New version available';

  @override
  String get updateRemindLater => 'Remind me later';

  @override
  String get updateCancelDownload => 'Cancel Download';

  @override
  String updateInstallTag(String tag) {
    return 'Install $tag';
  }

  @override
  String get updateInstallLaterFromSettings => 'Install later from settings';

  @override
  String get updateCouldNotComplete => 'The update could not be completed.';

  @override
  String get updateClose => 'Close';

  @override
  String get updatePromptInstallHint =>
      'Android closes ShellMind while the installer runs. Servers, keys and chat history are preserved.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonNothingToShow => 'Nothing to show here yet.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'Auto-execute commands';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Allow the AI agent to run parsed commands without asking each time';

  @override
  String get settingsAiAutoConnectTitle => 'AI Auto-Connect Servers';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Allow the AI assistant to automatically connect to configured-but-offline servers and run commands on them (saved credentials will be used)';

  @override
  String get settingsAiMaxAutoLoopsTitle => 'Max auto-loop iterations';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Cap the number of automatic command executions per response';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Max command rounds the AI may run per task';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'This is the upper limit of execution rounds per AI task — not the number of SSH reconnect attempts (that lives under SSH).';

  @override
  String get terminalAskAi => 'Ask AI';

  @override
  String get terminalAskAiSubtitle =>
      'Send the selected text to the AI assistant';

  @override
  String get terminalTooltipAskAi => 'Ask AI';

  @override
  String get aiChatNoConnection => 'Connect to a server terminal first';

  @override
  String get aiChatAnalyzePrompt =>
      'Please analyze the command output above, explain what the result means and give follow-up suggestions where needed.';

  @override
  String get aiExecuteButton => 'Run on server';

  @override
  String get aiExecuteTitle => 'Confirm command execution';

  @override
  String get aiExecuteConfirmButton => 'Execute';

  @override
  String get aiExecuteConfirmAnyway => 'Execute anyway';

  @override
  String get aiExecuteDangerWarning => '⚠ Dangerous command';

  @override
  String get aiExecuteDangerText =>
      'This command may be destructive and could cause data loss or system damage.';

  @override
  String get aiExecuteCommandLabel => 'Command to run:';

  @override
  String get aiExecuteTargetServer => 'Target server(s):';

  @override
  String get aiExecuteSelectServer => 'Select target server(s)';

  @override
  String get aiExecuteNoServer => 'Please connect to a server first';

  @override
  String get aiExecuteAtLeastOne => 'Select at least one server';

  @override
  String get aiExecuteSelectHint =>
      'Choose the server(s) to run this command on';

  @override
  String aiExecuteRunCount(int count) {
    return 'Execute ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Select all';

  @override
  String get aiExecuteClearSelection => 'Clear';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '${hours}h ${minutes}m online';
  }

  @override
  String get aiExecuteSuccess => 'Command executed successfully';

  @override
  String get aiExecuteFailed => 'Command execution failed';

  @override
  String get aiServerManageTitle => 'Servers';

  @override
  String get aiServerManageSubtitle =>
      'Connect servers for the AI assistant to operate';

  @override
  String aiServerOnlineCount(int count) {
    return '$count online';
  }

  @override
  String get aiServerDone => 'Done';

  @override
  String get aiServerConnecting => 'Connecting…';

  @override
  String get aiServerOffline => 'Offline';

  @override
  String get aiServerNoCredential =>
      'No stored credential — save the password or key on the server page first';

  @override
  String get aiServerConnectFailed => 'Connect failed';

  @override
  String get aiToolResultCommand => 'Command';

  @override
  String get aiToolResultOutput => 'Command output';

  @override
  String aiToolResultExitCode(int code) {
    return 'Exit code: $code';
  }

  @override
  String get aiToolResultElapsed => 'Time elapsed';

  @override
  String get aiToolResultAnalyzeButton => 'Let AI analyze output';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total more lines';
  }

  @override
  String get aiToolResultExpandedHide => 'Hide output';

  @override
  String get aiToolResultStderrLabel => 'Error output:';

  @override
  String get aiContextToggleAttach => 'Attach terminal context';

  @override
  String get aiContextToggleDetach => 'Terminal context attached';

  @override
  String get aiContextBadge => 'Context';

  @override
  String aiContextLines(int lines) {
    return '$lines lines from terminal';
  }

  @override
  String get aiAgentStop => 'Stop auto mode';

  @override
  String get aiAgentExecuting => 'Executing…';

  @override
  String get aiAgentDefaultServer => 'server';

  @override
  String get aiTimelineTitle => 'Execution timeline';

  @override
  String get aiTimelineOpen => 'Execution timeline';

  @override
  String get aiTimelineEmpty => 'No commands executed yet';

  @override
  String get aiTimelineEmptyHint =>
      'Run commands via chat or auto mode and the full chain will appear here.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commands',
      one: '1 command',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count succeeded',
      one: '1 succeeded',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Started $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Ended $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Exit code: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'No exit code';

  @override
  String get aiTimelineOutput => 'Output';

  @override
  String get aiTimelineOutputEmpty => 'No output';

  @override
  String get aiTimelineErrorOutput => 'Error output';

  @override
  String get aiTimelineRunning => 'Running…';

  @override
  String get aiTimelineClose => 'Close';

  @override
  String get sshReconnectToggle => 'Auto-reconnect on disconnect';

  @override
  String get sshReconnectToggleDesc =>
      'Retry dropped SSH sessions with exponential backoff';

  @override
  String get sshReconnectMaxAttempts => 'Max reconnect attempts';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Max automatic reconnect attempts after a disconnect — 0 means retry until it succeeds';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Unlimited';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Reconnecting (attempt $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Reconnecting (attempt $attempt of $max)';
  }

  @override
  String get sshReconnectGaveUp => 'Auto-reconnect gave up';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'Could not reach $name after $max attempts.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'Could not reach $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Retry now';

  @override
  String get sshReconnectStopAuto => 'Stop';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Reconnected to $name';
  }

  @override
  String get snippetsTitle => 'Command snippets';

  @override
  String get snippetsSubtitle => 'Save commands for quick re-use';

  @override
  String get snippetsAddTooltip => 'Add snippet';

  @override
  String get snippetsAddTitle => 'New snippet';

  @override
  String get snippetsSave => 'Save';

  @override
  String get snippetsCommandLabel => 'Command';

  @override
  String get snippetsCommandHint => 'e.g. docker ps -a';

  @override
  String get snippetsNameLabel => 'Name (optional)';

  @override
  String get snippetsNameHint => 'e.g. List all containers';

  @override
  String get snippetsCommandRequired => 'Command text is required';

  @override
  String get snippetsDeleteTooltip => 'Delete snippet';

  @override
  String get snippetsEmptyTitle => 'No snippets yet';

  @override
  String get snippetsEmptyMessage =>
      'Save frequently used commands and insert or run them with one tap.';

  @override
  String get snippetsLoadFailed => 'Could not load snippets';

  @override
  String get healthTitle => 'Fleet health';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total online';
  }

  @override
  String get healthProbing => 'Probing…';

  @override
  String get healthProbeTooltip => 'Run health check';

  @override
  String healthProbedAt(String time) {
    return 'Checked at $time';
  }

  @override
  String get healthMoodAllOnline => 'All systems nominal';

  @override
  String get healthMoodDegraded => 'Some servers are unreachable';

  @override
  String get healthMoodAllOffline => 'All servers unreachable';

  @override
  String healthOfflineServers(String names) {
    return 'Offline: $names';
  }

  @override
  String get healthNoData => 'Tap refresh to check every server';

  @override
  String healthUptime(String brief) {
    return 'up $brief';
  }

  @override
  String healthLoad(String value) {
    return 'load $value';
  }

  @override
  String get healthDiagIntro => 'Here is my fleet\'s health report:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online of $total servers online.';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name: offline';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name: online ($details)';
  }

  @override
  String get healthDiagOutro =>
      'Please analyze the health data, flag anything abnormal (high load, recent reboots) and suggest what to check next.';

  @override
  String get healthDiagnose => 'AI diagnostics';

  @override
  String get healthStaleNote =>
      'Some servers went offline since the last check.';

  @override
  String get auditTitle => 'Command audit log';

  @override
  String get auditTileDesc => 'Commands run by the AI agent';

  @override
  String get auditEmptyTitle => 'No audit entries yet';

  @override
  String get auditEmptyMessage =>
      'Commands executed by the AI agent will be recorded here.';

  @override
  String get auditFilteredEmpty => 'No entries match the current filter';

  @override
  String get auditFilterAllServers => 'All servers';

  @override
  String get auditFilterAllModes => 'All modes';

  @override
  String get auditFilterAllResults => 'All results';

  @override
  String get auditFilterConfirmed => 'Confirmed';

  @override
  String get auditFilterAuto => 'Auto';

  @override
  String get auditFilterSuccess => 'Success';

  @override
  String get auditFilterFailed => 'Failed';

  @override
  String get auditModeConfirmed => 'Confirmed';

  @override
  String get auditModeAuto => 'Auto';

  @override
  String get auditStatusSuccess => 'Success';

  @override
  String get auditStatusFailed => 'Failed';

  @override
  String get auditDangerousBadge => 'Dangerous';

  @override
  String auditExitCode(int code) {
    return 'Exit code $code';
  }

  @override
  String get auditOutputSummary => 'Output summary';

  @override
  String get auditNoOutput => 'No output';

  @override
  String get auditClearTooltip => 'Clear audit log';

  @override
  String get auditClearConfirmTitle => 'Clear audit log';

  @override
  String auditClearConfirmMessage(int count) {
    return 'All $count audit entries will be permanently removed.';
  }

  @override
  String get auditClearAction => 'Clear';

  @override
  String get auditCleared => 'Audit log cleared';

  @override
  String auditEntriesCount(int count) {
    return '$count entries';
  }

  @override
  String get serverActionDisconnect => 'Disconnect';

  @override
  String get exportChatAction => 'Export as Markdown';

  @override
  String get exportChatEmpty => 'Nothing to export yet';

  @override
  String exportChatSuccess(String path) {
    return 'Conversation exported to $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get diagTitle => 'Diagnostics';

  @override
  String get diagTileDesc => 'App errors & diagnostic export';

  @override
  String get diagEmptyTitle => 'No errors captured';

  @override
  String get diagEmptyMessage =>
      'Uncaught exceptions are recorded here to help with issue reports.';

  @override
  String diagEntriesCount(int count) {
    return '$count errors';
  }

  @override
  String get diagSourceFlutter => 'UI error';

  @override
  String get diagSourcePlatform => 'Runtime error';

  @override
  String get diagSourceZone => 'Async task';

  @override
  String get diagStackTrace => 'Stack trace';

  @override
  String get diagNoStackTrace => 'No stack trace';

  @override
  String get diagExportAction => 'Export diagnostic report';

  @override
  String get diagExportEmpty => 'Nothing to report — exporting basic info';

  @override
  String diagExportSuccess(String path) {
    return 'Diagnostic report exported to $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get diagPrivacyNote =>
      'Diagnostic content is redacted — no passwords, private keys or API keys are included.';

  @override
  String get diagClearTooltip => 'Clear error records';

  @override
  String get diagClearConfirmTitle => 'Clear error records';

  @override
  String diagClearConfirmMessage(int count) {
    return 'All $count error records will be permanently removed.';
  }

  @override
  String get diagClearAction => 'Clear';

  @override
  String get diagCleared => 'Error records cleared';

  @override
  String get diagAppInfoTitle => 'App info';

  @override
  String get diagAppInfoVersion => 'Version';

  @override
  String get diagAppInfoPlatform => 'Platform';

  @override
  String get diagAppInfoLocale => 'Language';

  @override
  String get diagAppInfoStorage => 'Local data size';

  @override
  String get authLockToggleTitle => 'Biometric lock';

  @override
  String get authLockToggleDesc =>
      'Require fingerprint or face unlock when opening the app';

  @override
  String get authLockEnableFailed => 'Verification failed — lock stays off';

  @override
  String get authLockUnavailableDesc => 'No biometrics enrolled on this device';

  @override
  String get authLockScreenTitle => 'ShellMind is locked';

  @override
  String get authLockScreenSubtitle => 'Verify to continue';

  @override
  String get authLockUnlockAction => 'Unlock';

  @override
  String get authLockUnlockFailed => 'Verification failed — try again';

  @override
  String get terminalTabPickerTitle => 'Switch terminal';

  @override
  String get terminalTabPickerSubtitle =>
      'Pick a server to open as a terminal tab — online servers join instantly, offline ones dial first';

  @override
  String get terminalTabPickerEmpty => 'No servers configured yet';

  @override
  String get terminalTabNewTooltip => 'New terminal tab';

  @override
  String get terminalTabCloseTooltip => 'Close tab';

  @override
  String get hostKeyConfirmTitle => 'Trust this host?';

  @override
  String get hostKeyConfirmMessage =>
      'This is the first connection to this server. Verify its fingerprint before trusting it — this protects against man-in-the-middle attacks.';

  @override
  String get hostKeyEndpointLabel => 'SERVER';

  @override
  String get hostKeyFingerprintLabel => 'SHA-256 FINGERPRINT';

  @override
  String get hostKeySecurityNote =>
      'Compare the fingerprint against a value you obtained from the server operator out-of-band. Trusting a wrong fingerprint exposes your credentials.';

  @override
  String get hostKeyTrustAndConnect => 'Trust and connect';

  @override
  String get hostKeyReject => 'Reject';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Auto-rejects in ${seconds}s — trust is only recorded when you confirm.';
  }

  @override
  String get hostKeyMismatchTitle => 'Host key changed';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'The key presented by $host:$port differs from the one you previously trusted. The connection was blocked — this may be a man-in-the-middle attack, or the server was reinstalled. If you verified the new key, reset host trust on the server edit page and reconnect.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Connection cancelled — the host key was not trusted. You can connect again to review the fingerprint.';

  @override
  String get serverResetTrustAction => 'Reset host trust';

  @override
  String get serverResetTrustDesc =>
      'Forget this server\'s stored fingerprint so the next connection asks for confirmation again.';

  @override
  String get serverResetTrustConfirmTitle => 'Reset host trust?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'The stored fingerprint for $identity:$port will be removed. The next connection will ask you to verify the host key again.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Reset';

  @override
  String get serverResetTrustDone =>
      'Host trust reset — reconnect to verify the fingerprint again.';

  @override
  String get agentErrorNoTargetServer => 'No target server available';

  @override
  String get agentErrorExecFailed => 'Command execution failed';

  @override
  String get agentErrorConnectFailed =>
      'Failed to connect to the server automatically';

  @override
  String get agentErrorConnectAuthRequired =>
      'No saved credentials for this server — auto-connect is not possible';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Skipped dangerous command: $command';
  }

  @override
  String get agentErrorUnexpected => 'Unexpected error';

  @override
  String get exportDocChatTitle => 'Shell-Mind Chat Export';

  @override
  String exportDocExportedAt(String time) {
    return 'Exported at: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Messages: $count';
  }

  @override
  String get exportDocUserSection => 'User';

  @override
  String get exportDocAssistantSection => 'Assistant';

  @override
  String get exportDocToolSection => 'Tool execution';

  @override
  String get exportDocNoContent => '_(no content)_';

  @override
  String get exportDocUnknownServer => 'Unknown server';

  @override
  String exportDocExitCode(int code) {
    return 'Exit code $code';
  }

  @override
  String get exportDocCommand => 'Command';

  @override
  String get exportDocOutput => 'Output';

  @override
  String get exportDocErrorOutput => 'Error output';

  @override
  String get exportDocDiagTitle => 'Shell-Mind Diagnostic Report';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Captured errors: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Captured errors';

  @override
  String get exportDocDiagNone => '(none)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Error summary: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'App version: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Platform: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Language: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Local data usage: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'AI command audit (last $limit summaries)';
  }

  @override
  String get exportDocDiagSuccess => 'success';

  @override
  String get exportDocDiagFailed => 'failed';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'exit code $code';
  }

  @override
  String get settingsTerminalScheme => 'Terminal color scheme';

  @override
  String get settingsTerminalSchemeDesc =>
      'Choose the ANSI color palette for SSH terminals.';

  @override
  String get settingsSectionDataTransfer => 'Import & Export';

  @override
  String get transferSnippetsTitle => 'Command snippets';

  @override
  String get transferServersTitle => 'Server configurations';

  @override
  String get transferExport => 'Export';

  @override
  String get transferImport => 'Import';

  @override
  String get transferExportImport => 'Export / Import';

  @override
  String get transferExportTitle => 'Export';

  @override
  String get transferCopyJson => 'Copy JSON';

  @override
  String get transferCopied => 'Copied to clipboard';

  @override
  String get transferImportHint => 'Paste the exported JSON here…';

  @override
  String get transferSnippetsEmpty => 'No command snippets to export.';

  @override
  String get transferServersEmpty => 'No servers to export.';

  @override
  String get transferImportNothing => 'No valid items found in the import.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count snippets',
      one: 'Imported 1 snippet',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count servers',
      one: 'Imported 1 server',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Import failed: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Export failed: $message';
  }

  @override
  String transferExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionsTitle => 'Conversations';

  @override
  String get sessionsNew => 'New conversation';

  @override
  String get sessionsSearch => 'Search conversations…';

  @override
  String get sessionsEmpty => 'No conversations yet';

  @override
  String sessionsNoMatch(String query) {
    return 'No match: \"$query\"';
  }

  @override
  String get sessionsRename => 'Rename';

  @override
  String get sessionsRenameHint => 'Conversation title';

  @override
  String get sessionsDelete => 'Delete';

  @override
  String sessionsDeleteConfirm(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotificationsTitle => 'Background alerts';

  @override
  String get settingsNotificationsDesc =>
      'Notify when an SSH session drops or an AI task finishes while the app is in the background.';

  @override
  String get sftpTitle => 'Files';

  @override
  String get sftpNotConnected => 'Not connected to this server.';

  @override
  String get sftpLoading => 'Loading files…';

  @override
  String get sftpEmpty => 'This folder is empty.';

  @override
  String get sftpDownload => 'Download';

  @override
  String sftpDownloaded(String path, int size) {
    return 'Downloaded $path ($size bytes)';
  }

  @override
  String get sftpDownloadFailed => 'Download failed';

  @override
  String get sftpPreviewError => 'Preview failed';

  @override
  String get sftpNewFolderName => 'New folder';

  @override
  String get sftpRefresh => 'Refresh';

  @override
  String get sftpDelete => 'Delete';

  @override
  String sftpDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get sftpRename => 'Rename';

  @override
  String get sftpTooltip => 'Browse files (SFTP)';

  @override
  String get terminalMoreTooltip => 'More';

  @override
  String get tunnelsTitle => 'Port forwarding';

  @override
  String get tunnelsEmpty => 'No active tunnels.';

  @override
  String get tunnelsAddLocal => 'Local forward';

  @override
  String get tunnelsAddRemote => 'Remote forward';

  @override
  String get tunnelsLocalPort => 'Local port';

  @override
  String get tunnelsRemoteHost => 'Remote host';

  @override
  String get tunnelsRemotePort => 'Remote port';

  @override
  String get tunnelsAdd => 'Add';

  @override
  String get tunnelsClose => 'Close';

  @override
  String get tunnelsTooltip => 'Port forwarding (SSH tunnel)';

  @override
  String get tunnelsError => 'Tunnel failed';

  @override
  String get tunnelsInvalidPort => 'Port must be between 1 and 65535.';

  @override
  String get settingsLanguageTitle => 'Language';
}
