// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shell-Mind';

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
      'Paste a command, an error, or a chunk of log output. Shell-Mind explains what happened, suggests the next move, and writes the commands so you don\'t have to.';

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
  String get aiChatAssistantName => 'Shell-Mind';

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
  String get settingsSectionAppearance => 'Appearance';

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
      'Android will ask you to confirm. Shell-Mind closes while the installer runs; your servers and history are preserved.';

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
      'The system package installer will open. Shell-Mind closes during installation and reopens on the new version.';

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
      'No releases have been published for Shell-Mind yet.';

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
      'Android closes Shell-Mind while the installer runs. Servers, keys and chat history are preserved.';

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
  String get settingsAiMaxAutoLoopsTitle => 'Max auto-loop iterations';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Cap the number of automatic command executions per response';

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
  String get aiAgentAutoModeOn => 'Auto mode: on';

  @override
  String get aiAgentAutoModeOff => 'Auto mode: off';

  @override
  String get aiAgentStop => 'Stop auto mode';

  @override
  String get aiAgentExecuting => 'Executing…';

  @override
  String get aiAgentDefaultServer => 'server';
}
