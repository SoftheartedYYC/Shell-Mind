import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShellMind'**
  String get appTitle;

  /// No description provided for @navServers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navServers;

  /// No description provided for @navAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get navAiChat;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @backToServers.
  ///
  /// In en, this message translates to:
  /// **'Back to Servers'**
  String get backToServers;

  /// No description provided for @serversTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serversTitle;

  /// No description provided for @serversHostCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 host} other{{count} hosts}}'**
  String serversHostCount(int count);

  /// No description provided for @serversSearch.
  ///
  /// In en, this message translates to:
  /// **'Search servers…'**
  String get serversSearch;

  /// No description provided for @serversAdd.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get serversAdd;

  /// No description provided for @serversEmpty.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get serversEmpty;

  /// No description provided for @serversEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first SSH server to get started.'**
  String get serversEmptyHint;

  /// No description provided for @serversDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get serversDeleteConfirmTitle;

  /// No description provided for @serversDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?\n\n{identity}:{port} and its stored credentials will be permanently removed.'**
  String serversDeleteConfirmMessage(String name, String identity, int port);

  /// No description provided for @serversDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed {identity}'**
  String serversDeleted(String identity);

  /// No description provided for @serversDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {message}'**
  String serversDeleteFailed(String message);

  /// No description provided for @serversLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading servers'**
  String get serversLoading;

  /// No description provided for @serversUngrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get serversUngrouped;

  /// No description provided for @serversSortName.
  ///
  /// In en, this message translates to:
  /// **'a–z'**
  String get serversSortName;

  /// No description provided for @serversSortRecent.
  ///
  /// In en, this message translates to:
  /// **'recent'**
  String get serversSortRecent;

  /// No description provided for @serversQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get serversQuickStart;

  /// No description provided for @serversQuickStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Add a host'**
  String get serversQuickStep1Title;

  /// No description provided for @serversQuickStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Register an SSH endpoint with password or key auth.'**
  String get serversQuickStep1Desc;

  /// No description provided for @serversQuickStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get serversQuickStep2Title;

  /// No description provided for @serversQuickStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Probe the port before committing — catches typos fast.'**
  String get serversQuickStep2Desc;

  /// No description provided for @serversQuickStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get serversQuickStep3Title;

  /// No description provided for @serversQuickStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Open a terminal session — full PTY, colours, and vim.'**
  String get serversQuickStep3Desc;

  /// No description provided for @serversNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match: \"{query}\"'**
  String serversNoMatch(String query);

  /// No description provided for @serversClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get serversClearFilter;

  /// No description provided for @serversReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the server list.'**
  String get serversReadError;

  /// No description provided for @serverEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get serverEditTitle;

  /// No description provided for @serverEditTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit server'**
  String get serverEditTitleEdit;

  /// No description provided for @serverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Server not found'**
  String get serverNotFound;

  /// No description provided for @serverValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get serverValidationNameRequired;

  /// No description provided for @serverValidationHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Host required'**
  String get serverValidationHostRequired;

  /// No description provided for @serverValidationNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'No spaces allowed'**
  String get serverValidationNoSpaces;

  /// No description provided for @serverValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get serverValidationRequired;

  /// No description provided for @serverValidationNumeric.
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get serverValidationNumeric;

  /// No description provided for @serverValidationPortRange.
  ///
  /// In en, this message translates to:
  /// **'1–65535'**
  String get serverValidationPortRange;

  /// No description provided for @serverValidationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username required'**
  String get serverValidationUsernameRequired;

  /// No description provided for @serverValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get serverValidationPasswordRequired;

  /// No description provided for @serverValidationPrivateKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Private key required'**
  String get serverValidationPrivateKeyRequired;

  /// No description provided for @serverAdded.
  ///
  /// In en, this message translates to:
  /// **'Server added: {identity}:{port}'**
  String serverAdded(String identity, int port);

  /// No description provided for @serverSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {identity}:{port}'**
  String serverSaved(String identity, int port);

  /// No description provided for @serverSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {message}'**
  String serverSaveFailed(String message);

  /// No description provided for @serverTestEnterHost.
  ///
  /// In en, this message translates to:
  /// **'Enter a host address first'**
  String get serverTestEnterHost;

  /// No description provided for @serverTestProbing.
  ///
  /// In en, this message translates to:
  /// **'Probing {host}:{port}…'**
  String serverTestProbing(String host, int port);

  /// No description provided for @serverTestReachable.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} — reachable'**
  String serverTestReachable(String host, int port);

  /// No description provided for @serverTestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} — timed out'**
  String serverTestTimedOut(String host, int port);

  /// No description provided for @serverTestRefused.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} — refused / unreachable'**
  String serverTestRefused(String host, int port);

  /// No description provided for @serverTestProbeFailed.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} — probe failed'**
  String serverTestProbeFailed(String host, int port);

  /// No description provided for @serverTestHandshakeFailed.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} SSH handshake failed'**
  String serverTestHandshakeFailed(String host, int port);

  /// No description provided for @serverTestAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port} authentication failed - check username and credentials'**
  String serverTestAuthFailed(String host, int port);

  /// No description provided for @serverLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get serverLoading;

  /// No description provided for @serverSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get serverSaveChanges;

  /// No description provided for @serverSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get serverSectionIdentity;

  /// No description provided for @serverSectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get serverSectionConnection;

  /// No description provided for @serverSectionAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get serverSectionAuthentication;

  /// No description provided for @serverFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get serverFieldLabel;

  /// No description provided for @serverFieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'prod-web-01'**
  String get serverFieldLabelHint;

  /// No description provided for @serverFieldGroup.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get serverFieldGroup;

  /// No description provided for @serverFieldGroupHint.
  ///
  /// In en, this message translates to:
  /// **'production'**
  String get serverFieldGroupHint;

  /// No description provided for @serverFieldHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get serverFieldHost;

  /// No description provided for @serverFieldHostHint.
  ///
  /// In en, this message translates to:
  /// **'10.0.0.5'**
  String get serverFieldHostHint;

  /// No description provided for @serverFieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get serverFieldPort;

  /// No description provided for @serverFieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get serverFieldUsername;

  /// No description provided for @serverFieldUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'root'**
  String get serverFieldUsernameHint;

  /// No description provided for @serverFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get serverFieldPassword;

  /// No description provided for @serverFieldPasswordStored.
  ///
  /// In en, this message translates to:
  /// **'Stored — leave blank to keep'**
  String get serverFieldPasswordStored;

  /// No description provided for @serverFieldPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key (PEM)'**
  String get serverFieldPrivateKey;

  /// No description provided for @serverFieldPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Key passphrase (optional)'**
  String get serverFieldPassphrase;

  /// No description provided for @serverAuthPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get serverAuthPassword;

  /// No description provided for @serverAuthPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get serverAuthPrivateKey;

  /// No description provided for @serverTestIdle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Test\" to probe the connection'**
  String get serverTestIdle;

  /// No description provided for @serverSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Credentials are encrypted in the device keystore — they never touch the Hive metadata store or leave this device.'**
  String get serverSecurityNote;

  /// No description provided for @serverTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get serverTesting;

  /// No description provided for @serverTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get serverTest;

  /// No description provided for @serverSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get serverSaving;

  /// No description provided for @serverCopiedAddress.
  ///
  /// In en, this message translates to:
  /// **'Copied {address}'**
  String serverCopiedAddress(String address);

  /// No description provided for @serverActions.
  ///
  /// In en, this message translates to:
  /// **'Server actions'**
  String get serverActions;

  /// No description provided for @serverActionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get serverActionConnect;

  /// No description provided for @serverActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get serverActionEdit;

  /// No description provided for @serverActionEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get serverActionEditDetails;

  /// No description provided for @serverActionCopySsh.
  ///
  /// In en, this message translates to:
  /// **'Copy SSH command'**
  String get serverActionCopySsh;

  /// No description provided for @serverActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get serverActionDelete;

  /// No description provided for @serverActionDeleteServer.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get serverActionDeleteServer;

  /// No description provided for @serverOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get serverOnline;

  /// No description provided for @serverNeverConnected.
  ///
  /// In en, this message translates to:
  /// **'Never connected'**
  String get serverNeverConnected;

  /// No description provided for @serverJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get serverJustNow;

  /// No description provided for @serverMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String serverMinutesAgo(int minutes);

  /// No description provided for @serverHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String serverHoursAgo(int hours);

  /// No description provided for @serverDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String serverDaysAgo(int days);

  /// No description provided for @terminalHostNotFound.
  ///
  /// In en, this message translates to:
  /// **'Host not found'**
  String get terminalHostNotFound;

  /// No description provided for @terminalHostNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No saved server matches id \"{id}\". It may have been deleted.'**
  String terminalHostNotFoundMessage(String id);

  /// No description provided for @terminalBackToServers.
  ///
  /// In en, this message translates to:
  /// **'Back to servers'**
  String get terminalBackToServers;

  /// No description provided for @terminalConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed.'**
  String get terminalConnectionFailed;

  /// No description provided for @terminalSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session closed'**
  String get terminalSessionClosed;

  /// No description provided for @terminalSessionClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'The connection to {name} was terminated.'**
  String terminalSessionClosedMessage(String name);

  /// No description provided for @terminalReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get terminalReconnect;

  /// No description provided for @terminalAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating'**
  String get terminalAuthenticating;

  /// No description provided for @terminalConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get terminalConnecting;

  /// No description provided for @terminalResolvingHost.
  ///
  /// In en, this message translates to:
  /// **'Resolving host…'**
  String get terminalResolvingHost;

  /// No description provided for @terminalTooltipDisconnectBack.
  ///
  /// In en, this message translates to:
  /// **'Disconnect & back'**
  String get terminalTooltipDisconnectBack;

  /// No description provided for @terminalTooltipSmallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get terminalTooltipSmallerText;

  /// No description provided for @terminalTooltipLargerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get terminalTooltipLargerText;

  /// No description provided for @terminalTooltipDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get terminalTooltipDisconnect;

  /// No description provided for @terminalRetryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Retry available'**
  String get terminalRetryAvailable;

  /// No description provided for @terminalStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get terminalStatusConnected;

  /// No description provided for @terminalStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get terminalStatusOffline;

  /// No description provided for @terminalStatusError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get terminalStatusError;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiChatTitle;

  /// No description provided for @aiChatStatusSetup.
  ///
  /// In en, this message translates to:
  /// **'SETUP'**
  String get aiChatStatusSetup;

  /// No description provided for @aiChatStatusStreaming.
  ///
  /// In en, this message translates to:
  /// **'STREAMING'**
  String get aiChatStatusStreaming;

  /// No description provided for @aiChatStatusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get aiChatStatusReady;

  /// No description provided for @aiChatClearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get aiChatClearConversation;

  /// No description provided for @aiChatSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Explain what ls -la output means'**
  String get aiChatSuggestion1;

  /// No description provided for @aiChatSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'How do I find which process is using a port?'**
  String get aiChatSuggestion2;

  /// No description provided for @aiChatSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Show me how to tail logs and grep for errors'**
  String get aiChatSuggestion3;

  /// No description provided for @aiChatSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Write an awk one-liner to sum a CSV column'**
  String get aiChatSuggestion4;

  /// No description provided for @aiChatTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get aiChatTryAsking;

  /// No description provided for @aiChatIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your terminal companion'**
  String get aiChatIntroTitle;

  /// No description provided for @aiChatIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a command, an error, or a chunk of log output. ShellMind explains what happened, suggests the next move, and writes the commands so you don\'t have to.'**
  String get aiChatIntroBody;

  /// No description provided for @aiChatNoKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'No API key configured'**
  String get aiChatNoKeyTitle;

  /// No description provided for @aiChatNoKeyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your {provider} API key to wake the assistant. It\'s stored encrypted on this device and never leaves it except to call the model.'**
  String aiChatNoKeyMessage(String provider);

  /// No description provided for @aiChatOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open AI settings'**
  String get aiChatOpenSettings;

  /// No description provided for @aiChatCheckingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Checking credentials'**
  String get aiChatCheckingCredentials;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything…'**
  String get aiChatInputHint;

  /// No description provided for @aiChatInputDisabled.
  ///
  /// In en, this message translates to:
  /// **'Set an API key to begin'**
  String get aiChatInputDisabled;

  /// No description provided for @aiChatError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get aiChatError;

  /// No description provided for @aiChatAssistantName.
  ///
  /// In en, this message translates to:
  /// **'ShellMind'**
  String get aiChatAssistantName;

  /// No description provided for @aiChatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiChatCopied;

  /// No description provided for @aiChatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiChatCopy;

  /// No description provided for @aiChatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiChatThinking;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchTooltip;

  /// No description provided for @settingsStable.
  ///
  /// In en, this message translates to:
  /// **'STABLE'**
  String get settingsStable;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsSectionAiProvider.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get settingsSectionAiProvider;

  /// No description provided for @settingsSectionAiAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get settingsSectionAiAgent;

  /// No description provided for @settingsSectionSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get settingsSectionSsh;

  /// No description provided for @settingsSectionServers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get settingsSectionServers;

  /// No description provided for @settingsSectionAboutUpdate.
  ///
  /// In en, this message translates to:
  /// **'About & Update'**
  String get settingsSectionAboutUpdate;

  /// No description provided for @settingsSectionStoragePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Storage & Privacy'**
  String get settingsSectionStoragePrivacy;

  /// No description provided for @settingsSectionResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get settingsSectionResources;

  /// No description provided for @settingsTileSecrets.
  ///
  /// In en, this message translates to:
  /// **'Secrets'**
  String get settingsTileSecrets;

  /// No description provided for @settingsTileEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get settingsTileEncrypted;

  /// No description provided for @settingsTileLocalCache.
  ///
  /// In en, this message translates to:
  /// **'Local cache'**
  String get settingsTileLocalCache;

  /// No description provided for @settingsTileClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get settingsTileClearData;

  /// No description provided for @settingsTileLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsTileLicenses;

  /// No description provided for @settingsTileReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get settingsTileReportIssue;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'SSH + AI Assistant for modern workflows'**
  String get settingsFooter;

  /// No description provided for @settingsSecretsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Secrets & encryption'**
  String get settingsSecretsDialogTitle;

  /// No description provided for @settingsSecretsDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Credentials — server passwords, private keys and AI API keys — are always encrypted at rest using the platform keystore (Android Keystore / iOS Keychain). This protection is by design and cannot be turned off. To change a credential, edit or remove it on the server edit page or in AI settings.'**
  String get settingsSecretsDialogBody;

  /// No description provided for @settingsDialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get settingsDialogOk;

  /// No description provided for @settingsDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsDialogClose;

  /// No description provided for @settingsCacheDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Local cache'**
  String get settingsCacheDialogTitle;

  /// No description provided for @settingsCacheHiveData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get settingsCacheHiveData;

  /// No description provided for @settingsCacheDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloaded updates'**
  String get settingsCacheDownloads;

  /// No description provided for @settingsCacheTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get settingsCacheTotal;

  /// No description provided for @settingsCacheDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Clearing the download cache removes downloaded update packages (APKs). Your servers, keys and chat history are kept.'**
  String get settingsCacheDialogHint;

  /// No description provided for @settingsCacheClearDownloads.
  ///
  /// In en, this message translates to:
  /// **'Clear download cache'**
  String get settingsCacheClearDownloads;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Freed {freed}'**
  String settingsCacheCleared(String freed);

  /// No description provided for @settingsClearDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all data?'**
  String get settingsClearDataTitle;

  /// No description provided for @settingsClearDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every server, stored credential, AI key, chat history and preference on this device. This action cannot be undone.'**
  String get settingsClearDataMessage;

  /// No description provided for @settingsClearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear everything'**
  String get settingsClearDataConfirm;

  /// No description provided for @settingsDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get settingsDataCleared;

  /// No description provided for @settingsClearDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear data: {message}'**
  String settingsClearDataFailed(String message);

  /// No description provided for @settingsIssueLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Issue link copied to clipboard.'**
  String get settingsIssueLinkCopied;

  /// No description provided for @settingsAboutGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get settingsAboutGithub;

  /// No description provided for @settingsHideIp.
  ///
  /// In en, this message translates to:
  /// **'Hide IP addresses'**
  String get settingsHideIp;

  /// No description provided for @settingsHideIpDesc.
  ///
  /// In en, this message translates to:
  /// **'Mask IP addresses in the server list and AI pages'**
  String get settingsHideIpDesc;

  /// No description provided for @serverMaskedAddress.
  ///
  /// In en, this message translates to:
  /// **'Address hidden'**
  String get serverMaskedAddress;

  /// No description provided for @aiSettingsApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'{provider} API key'**
  String aiSettingsApiKeyTitle(String provider);

  /// No description provided for @aiSettingsKeySet.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get aiSettingsKeySet;

  /// No description provided for @aiSettingsKeyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'not configured'**
  String get aiSettingsKeyNotConfigured;

  /// No description provided for @aiSettingsGetApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get an API key'**
  String get aiSettingsGetApiKey;

  /// No description provided for @aiSettingsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get aiSettingsTemperature;

  /// No description provided for @aiSettingsRemoveKey.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get aiSettingsRemoveKey;

  /// No description provided for @aiSettingsKeySaved.
  ///
  /// In en, this message translates to:
  /// **'{provider} API key saved securely.'**
  String aiSettingsKeySaved(String provider);

  /// No description provided for @aiSettingsRemoveKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {provider} key?'**
  String aiSettingsRemoveKeyTitle(String provider);

  /// No description provided for @aiSettingsRemoveKeyMessage.
  ///
  /// In en, this message translates to:
  /// **'The assistant will stop working for this provider until a new key is added.'**
  String get aiSettingsRemoveKeyMessage;

  /// No description provided for @aiSettingsRemoveKeyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get aiSettingsRemoveKeyConfirm;

  /// No description provided for @aiSettingsGetKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a {provider} key'**
  String aiSettingsGetKeyTitle(String provider);

  /// No description provided for @aiSettingsGetKeyMessage.
  ///
  /// In en, this message translates to:
  /// **'Open the provider console in your browser to create an API key, then paste it back here.'**
  String get aiSettingsGetKeyMessage;

  /// No description provided for @aiSettingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aiSettingsClose;

  /// No description provided for @aiSettingsLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard.'**
  String get aiSettingsLinkCopied;

  /// No description provided for @aiSettingsCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get aiSettingsCopyLink;

  /// No description provided for @aiSettingsKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Key configured'**
  String get aiSettingsKeyConfigured;

  /// No description provided for @aiSettingsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get aiSettingsNotConfigured;

  /// No description provided for @aiSettingsUpdateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {provider} key'**
  String aiSettingsUpdateKeyTitle(String provider);

  /// No description provided for @aiSettingsAddKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {provider} key'**
  String aiSettingsAddKeyTitle(String provider);

  /// No description provided for @aiSettingsKeyStorageNote.
  ///
  /// In en, this message translates to:
  /// **'Stored encrypted on this device. Used only to call the AI provider.'**
  String get aiSettingsKeyStorageNote;

  /// No description provided for @aiSettingsApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'API key…'**
  String get aiSettingsApiKeyHint;

  /// No description provided for @aiSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get aiSettingsSave;

  /// No description provided for @modelDescFastAffordable.
  ///
  /// In en, this message translates to:
  /// **'Fast & affordable'**
  String get modelDescFastAffordable;

  /// No description provided for @modelDescMostCapable.
  ///
  /// In en, this message translates to:
  /// **'Most capable'**
  String get modelDescMostCapable;

  /// No description provided for @modelDescLegacyFast.
  ///
  /// In en, this message translates to:
  /// **'Legacy fast'**
  String get modelDescLegacyFast;

  /// No description provided for @modelDescGeneralConversation.
  ///
  /// In en, this message translates to:
  /// **'General conversation'**
  String get modelDescGeneralConversation;

  /// No description provided for @modelDescAdvancedReasoning.
  ///
  /// In en, this message translates to:
  /// **'Advanced reasoning'**
  String get modelDescAdvancedReasoning;

  /// No description provided for @modelDescFastResponse.
  ///
  /// In en, this message translates to:
  /// **'Fast response'**
  String get modelDescFastResponse;

  /// No description provided for @modelDescBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get modelDescBalanced;

  /// No description provided for @modelDescFreeFast.
  ///
  /// In en, this message translates to:
  /// **'Free & fast'**
  String get modelDescFreeFast;

  /// No description provided for @modelDescEnhanced.
  ///
  /// In en, this message translates to:
  /// **'Enhanced'**
  String get modelDescEnhanced;

  /// No description provided for @modelDescStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get modelDescStandard;

  /// No description provided for @modelDescLightweight.
  ///
  /// In en, this message translates to:
  /// **'Lightweight'**
  String get modelDescLightweight;

  /// No description provided for @modelDescRlEnhanced.
  ///
  /// In en, this message translates to:
  /// **'RL enhanced'**
  String get modelDescRlEnhanced;

  /// No description provided for @aiModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModelsTitle;

  /// No description provided for @aiModelsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh model list'**
  String get aiModelsRefresh;

  /// No description provided for @aiModelsAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom model'**
  String get aiModelsAddCustom;

  /// No description provided for @aiModelsAddCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Model ID, e.g. deepseek-chat'**
  String get aiModelsAddCustomHint;

  /// No description provided for @aiModelsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get aiModelsAdd;

  /// No description provided for @aiModelsCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get aiModelsCustomBadge;

  /// No description provided for @aiModelsFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch models — showing the built-in list.'**
  String get aiModelsFetchFailed;

  /// No description provided for @aiModelsRemoveCustom.
  ///
  /// In en, this message translates to:
  /// **'Remove custom model'**
  String get aiModelsRemoveCustom;

  /// No description provided for @aiModelsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No models'**
  String get aiModelsEmpty;

  /// No description provided for @aiModelsInvalidId.
  ///
  /// In en, this message translates to:
  /// **'Enter a model ID.'**
  String get aiModelsInvalidId;

  /// No description provided for @aiModelsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This model is already in the list.'**
  String get aiModelsDuplicate;

  /// No description provided for @aiModelsPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose model'**
  String get aiModelsPickerTitle;

  /// No description provided for @aiModelsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get aiModelsSearchHint;

  /// No description provided for @aiModelsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No models match your search.'**
  String get aiModelsSearchEmpty;

  /// No description provided for @aiProvidersAddTile.
  ///
  /// In en, this message translates to:
  /// **'Add custom provider'**
  String get aiProvidersAddTile;

  /// No description provided for @aiProvidersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom provider'**
  String get aiProvidersAddTitle;

  /// No description provided for @aiProvidersFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aiProvidersFieldName;

  /// No description provided for @aiProvidersFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. SiliconFlow'**
  String get aiProvidersFieldNameHint;

  /// No description provided for @aiProvidersFieldBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiProvidersFieldBaseUrl;

  /// No description provided for @aiProvidersFieldBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://api.example.com/v1'**
  String get aiProvidersFieldBaseUrlHint;

  /// No description provided for @aiProvidersFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Default model (optional)'**
  String get aiProvidersFieldModel;

  /// No description provided for @aiProvidersFieldModelHint.
  ///
  /// In en, this message translates to:
  /// **'Model ID, e.g. deepseek-chat'**
  String get aiProvidersFieldModelHint;

  /// No description provided for @aiProvidersAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get aiProvidersAddConfirm;

  /// No description provided for @aiProvidersInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and a base URL.'**
  String get aiProvidersInvalidInput;

  /// No description provided for @aiProvidersInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL must start with http:// or https://'**
  String get aiProvidersInvalidUrl;

  /// No description provided for @aiProvidersDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'A provider with this name already exists.'**
  String get aiProvidersDuplicateName;

  /// No description provided for @aiProvidersAdded.
  ///
  /// In en, this message translates to:
  /// **'Custom provider added.'**
  String get aiProvidersAdded;

  /// No description provided for @aiProvidersAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the provider — check the inputs.'**
  String get aiProvidersAddFailed;

  /// No description provided for @aiProvidersDeleteTile.
  ///
  /// In en, this message translates to:
  /// **'Remove custom provider'**
  String get aiProvidersDeleteTile;

  /// No description provided for @aiProvidersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {provider}?'**
  String aiProvidersDeleteTitle(String provider);

  /// No description provided for @aiProvidersDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Its stored API key, remembered model and custom models will be removed too. Built-in providers can\'t be deleted.'**
  String get aiProvidersDeleteMessage;

  /// No description provided for @aiProvidersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get aiProvidersDeleteConfirm;

  /// No description provided for @updateVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get updateVersion;

  /// No description provided for @updateSoftwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software update'**
  String get updateSoftwareUpdate;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'CHECKING'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'UP TO DATE'**
  String get updateUpToDate;

  /// No description provided for @updateCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get updateCheckAgain;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get updateReady;

  /// No description provided for @updateNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get updateNew;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get updateCheck;

  /// No description provided for @updateAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get updateAwaitingResponse;

  /// No description provided for @updateAlreadyLatest.
  ///
  /// In en, this message translates to:
  /// **'Already on the latest build'**
  String get updateAlreadyLatest;

  /// No description provided for @updateCurrentVersionLatest.
  ///
  /// In en, this message translates to:
  /// **'v{version} is the newest release published on GitHub.'**
  String updateCurrentVersionLatest(String version);

  /// No description provided for @updateRunningVersion.
  ///
  /// In en, this message translates to:
  /// **'Running v{current} — remote head is v{latest}.'**
  String updateRunningVersion(String current, String latest);

  /// No description provided for @updateCheckedAgo.
  ///
  /// In en, this message translates to:
  /// **'Checked {timeAgo}'**
  String updateCheckedAgo(String timeAgo);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updatePre.
  ///
  /// In en, this message translates to:
  /// **'PRE'**
  String get updatePre;

  /// No description provided for @updateDownloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get updateDownloadInstall;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateApkHint.
  ///
  /// In en, this message translates to:
  /// **'APK installation is only supported on Android. The file can still be downloaded here.'**
  String get updateApkHint;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {tag}'**
  String updateDownloading(String tag);

  /// No description provided for @updateSize.
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get updateSize;

  /// No description provided for @updateRate.
  ///
  /// In en, this message translates to:
  /// **'rate'**
  String get updateRate;

  /// No description provided for @updateEta.
  ///
  /// In en, this message translates to:
  /// **'eta'**
  String get updateEta;

  /// No description provided for @updateElapsed.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get updateElapsed;

  /// No description provided for @updateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get updateCancel;

  /// No description provided for @updateKeepForeground.
  ///
  /// In en, this message translates to:
  /// **'Keep the app in the foreground'**
  String get updateKeepForeground;

  /// No description provided for @updateDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get updateDownloadComplete;

  /// No description provided for @updateInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Android will ask you to confirm. ShellMind closes while the installer runs; your servers and history are preserved.'**
  String get updateInstallHint;

  /// No description provided for @updateLaunching.
  ///
  /// In en, this message translates to:
  /// **'Launching...'**
  String get updateLaunching;

  /// No description provided for @updateInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install Now'**
  String get updateInstallNow;

  /// No description provided for @updateDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get updateDelete;

  /// No description provided for @updateInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install {tag}?'**
  String updateInstallTitle(String tag);

  /// No description provided for @updateInstallMessage.
  ///
  /// In en, this message translates to:
  /// **'The system package installer will open. ShellMind closes during installation and reopens on the new version.'**
  String get updateInstallMessage;

  /// No description provided for @updateNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get updateNotNow;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstall;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The update check failed.'**
  String get updateCheckFailed;

  /// No description provided for @updateErrorTitleNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases'**
  String get updateErrorTitleNoReleases;

  /// No description provided for @updateErrorTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateErrorTitleGeneric;

  /// No description provided for @updateErrNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases have been published for ShellMind yet.'**
  String get updateErrNoReleases;

  /// No description provided for @updateErrRateLimit.
  ///
  /// In en, this message translates to:
  /// **'GitHub\'s API rate limit was reached. Please try again later.'**
  String get updateErrRateLimit;

  /// No description provided for @updateErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request to GitHub timed out. Check your connection and retry.'**
  String get updateErrTimeout;

  /// No description provided for @updateErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach GitHub. Check your network connection.'**
  String get updateErrNetwork;

  /// No description provided for @updateErrAuth.
  ///
  /// In en, this message translates to:
  /// **'GitHub rejected the update request.'**
  String get updateErrAuth;

  /// No description provided for @updateErrPermission.
  ///
  /// In en, this message translates to:
  /// **'The update request was denied.'**
  String get updateErrPermission;

  /// No description provided for @updateErrStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space to complete the update.'**
  String get updateErrStorage;

  /// No description provided for @updateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get updateRetry;

  /// No description provided for @updateDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get updateDismiss;

  /// No description provided for @updateReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release {tag}'**
  String updateReleaseNotes(String tag);

  /// No description provided for @updateNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get updateNotesLabel;

  /// No description provided for @updateNewVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateNewVersionAvailable;

  /// No description provided for @updateRemindLater.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get updateRemindLater;

  /// No description provided for @updateCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get updateCancelDownload;

  /// No description provided for @updateInstallTag.
  ///
  /// In en, this message translates to:
  /// **'Install {tag}'**
  String updateInstallTag(String tag);

  /// No description provided for @updateInstallLaterFromSettings.
  ///
  /// In en, this message translates to:
  /// **'Install later from settings'**
  String get updateInstallLaterFromSettings;

  /// No description provided for @updateCouldNotComplete.
  ///
  /// In en, this message translates to:
  /// **'The update could not be completed.'**
  String get updateCouldNotComplete;

  /// No description provided for @updateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateClose;

  /// No description provided for @updatePromptInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Android closes ShellMind while the installer runs. Servers, keys and chat history are preserved.'**
  String get updatePromptInstallHint;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// No description provided for @commonNothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here yet.'**
  String get commonNothingToShow;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @settingsAiAutoExecuteTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-execute commands'**
  String get settingsAiAutoExecuteTitle;

  /// No description provided for @settingsAiAutoExecuteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the AI agent to run parsed commands without asking each time'**
  String get settingsAiAutoExecuteSubtitle;

  /// No description provided for @settingsAiMaxAutoLoopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Max auto-loop iterations'**
  String get settingsAiMaxAutoLoopsTitle;

  /// No description provided for @settingsAiMaxAutoLoopsSub.
  ///
  /// In en, this message translates to:
  /// **'Cap the number of automatic command executions per response'**
  String get settingsAiMaxAutoLoopsSub;

  /// No description provided for @settingsAiMaxAutoLoopsTileDesc.
  ///
  /// In en, this message translates to:
  /// **'Max command rounds the AI may run per task'**
  String get settingsAiMaxAutoLoopsTileDesc;

  /// No description provided for @settingsAiMaxAutoLoopsHint.
  ///
  /// In en, this message translates to:
  /// **'This is the upper limit of execution rounds per AI task — not the number of SSH reconnect attempts (that lives under SSH).'**
  String get settingsAiMaxAutoLoopsHint;

  /// No description provided for @terminalAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get terminalAskAi;

  /// No description provided for @terminalAskAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send the selected text to the AI assistant'**
  String get terminalAskAiSubtitle;

  /// No description provided for @terminalTooltipAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get terminalTooltipAskAi;

  /// No description provided for @aiChatNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server terminal first'**
  String get aiChatNoConnection;

  /// No description provided for @aiChatAnalyzePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please analyze the command output above, explain what the result means and give follow-up suggestions where needed.'**
  String get aiChatAnalyzePrompt;

  /// No description provided for @aiExecuteButton.
  ///
  /// In en, this message translates to:
  /// **'Run on server'**
  String get aiExecuteButton;

  /// No description provided for @aiExecuteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm command execution'**
  String get aiExecuteTitle;

  /// No description provided for @aiExecuteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get aiExecuteConfirmButton;

  /// No description provided for @aiExecuteConfirmAnyway.
  ///
  /// In en, this message translates to:
  /// **'Execute anyway'**
  String get aiExecuteConfirmAnyway;

  /// No description provided for @aiExecuteDangerWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ Dangerous command'**
  String get aiExecuteDangerWarning;

  /// No description provided for @aiExecuteDangerText.
  ///
  /// In en, this message translates to:
  /// **'This command may be destructive and could cause data loss or system damage.'**
  String get aiExecuteDangerText;

  /// No description provided for @aiExecuteCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command to run:'**
  String get aiExecuteCommandLabel;

  /// No description provided for @aiExecuteTargetServer.
  ///
  /// In en, this message translates to:
  /// **'Target server(s):'**
  String get aiExecuteTargetServer;

  /// No description provided for @aiExecuteSelectServer.
  ///
  /// In en, this message translates to:
  /// **'Select target server(s)'**
  String get aiExecuteSelectServer;

  /// No description provided for @aiExecuteNoServer.
  ///
  /// In en, this message translates to:
  /// **'Please connect to a server first'**
  String get aiExecuteNoServer;

  /// No description provided for @aiExecuteAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one server'**
  String get aiExecuteAtLeastOne;

  /// No description provided for @aiExecuteSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the server(s) to run this command on'**
  String get aiExecuteSelectHint;

  /// No description provided for @aiExecuteRunCount.
  ///
  /// In en, this message translates to:
  /// **'Execute ({count})'**
  String aiExecuteRunCount(int count);

  /// No description provided for @aiExecuteSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get aiExecuteSelectAll;

  /// No description provided for @aiExecuteClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get aiExecuteClearSelection;

  /// No description provided for @aiExecuteUptime.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m online'**
  String aiExecuteUptime(int hours, int minutes);

  /// No description provided for @aiExecuteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Command executed successfully'**
  String get aiExecuteSuccess;

  /// No description provided for @aiExecuteFailed.
  ///
  /// In en, this message translates to:
  /// **'Command execution failed'**
  String get aiExecuteFailed;

  /// No description provided for @aiServerManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get aiServerManageTitle;

  /// No description provided for @aiServerManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect servers for the AI assistant to operate'**
  String get aiServerManageSubtitle;

  /// No description provided for @aiServerOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} online'**
  String aiServerOnlineCount(int count);

  /// No description provided for @aiServerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aiServerDone;

  /// No description provided for @aiServerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get aiServerConnecting;

  /// No description provided for @aiServerOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get aiServerOffline;

  /// No description provided for @aiServerNoCredential.
  ///
  /// In en, this message translates to:
  /// **'No stored credential — save the password or key on the server page first'**
  String get aiServerNoCredential;

  /// No description provided for @aiServerConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connect failed'**
  String get aiServerConnectFailed;

  /// No description provided for @aiToolResultCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get aiToolResultCommand;

  /// No description provided for @aiToolResultOutput.
  ///
  /// In en, this message translates to:
  /// **'Command output'**
  String get aiToolResultOutput;

  /// No description provided for @aiToolResultExitCode.
  ///
  /// In en, this message translates to:
  /// **'Exit code: {code}'**
  String aiToolResultExitCode(int code);

  /// No description provided for @aiToolResultElapsed.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get aiToolResultElapsed;

  /// No description provided for @aiToolResultAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Let AI analyze output'**
  String get aiToolResultAnalyzeButton;

  /// No description provided for @aiToolResultCollapsedShow.
  ///
  /// In en, this message translates to:
  /// **'{total} more lines'**
  String aiToolResultCollapsedShow(int total);

  /// No description provided for @aiToolResultExpandedHide.
  ///
  /// In en, this message translates to:
  /// **'Hide output'**
  String get aiToolResultExpandedHide;

  /// No description provided for @aiToolResultStderrLabel.
  ///
  /// In en, this message translates to:
  /// **'Error output:'**
  String get aiToolResultStderrLabel;

  /// No description provided for @aiContextToggleAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach terminal context'**
  String get aiContextToggleAttach;

  /// No description provided for @aiContextToggleDetach.
  ///
  /// In en, this message translates to:
  /// **'Terminal context attached'**
  String get aiContextToggleDetach;

  /// No description provided for @aiContextBadge.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get aiContextBadge;

  /// No description provided for @aiContextLines.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines from terminal'**
  String aiContextLines(int lines);

  /// No description provided for @aiAgentAutoModeOn.
  ///
  /// In en, this message translates to:
  /// **'Auto mode: on'**
  String get aiAgentAutoModeOn;

  /// No description provided for @aiAgentAutoModeOff.
  ///
  /// In en, this message translates to:
  /// **'Auto mode: off'**
  String get aiAgentAutoModeOff;

  /// No description provided for @aiAgentStop.
  ///
  /// In en, this message translates to:
  /// **'Stop auto mode'**
  String get aiAgentStop;

  /// No description provided for @aiAgentExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing…'**
  String get aiAgentExecuting;

  /// No description provided for @aiAgentDefaultServer.
  ///
  /// In en, this message translates to:
  /// **'server'**
  String get aiAgentDefaultServer;

  /// No description provided for @aiTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Execution timeline'**
  String get aiTimelineTitle;

  /// No description provided for @aiTimelineOpen.
  ///
  /// In en, this message translates to:
  /// **'Execution timeline'**
  String get aiTimelineOpen;

  /// No description provided for @aiTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commands executed yet'**
  String get aiTimelineEmpty;

  /// No description provided for @aiTimelineEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Run commands via chat or auto mode and the full chain will appear here.'**
  String get aiTimelineEmptyHint;

  /// No description provided for @aiTimelineStatRounds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round} other{{count} rounds}}'**
  String aiTimelineStatRounds(int count);

  /// No description provided for @aiTimelineStatCommands.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 command} other{{count} commands}}'**
  String aiTimelineStatCommands(int count);

  /// No description provided for @aiTimelineStatSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 succeeded} other{{count} succeeded}}'**
  String aiTimelineStatSuccess(int count);

  /// No description provided for @aiTimelineStatFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 failed} other{{count} failed}}'**
  String aiTimelineStatFailed(int count);

  /// No description provided for @aiTimelineStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {time}'**
  String aiTimelineStarted(String time);

  /// No description provided for @aiTimelineEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended {time}'**
  String aiTimelineEnded(String time);

  /// No description provided for @aiTimelineExitCode.
  ///
  /// In en, this message translates to:
  /// **'Exit code: {code}'**
  String aiTimelineExitCode(int code);

  /// No description provided for @aiTimelineNoExitCode.
  ///
  /// In en, this message translates to:
  /// **'No exit code'**
  String get aiTimelineNoExitCode;

  /// No description provided for @aiTimelineOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get aiTimelineOutput;

  /// No description provided for @aiTimelineOutputEmpty.
  ///
  /// In en, this message translates to:
  /// **'No output'**
  String get aiTimelineOutputEmpty;

  /// No description provided for @aiTimelineErrorOutput.
  ///
  /// In en, this message translates to:
  /// **'Error output'**
  String get aiTimelineErrorOutput;

  /// No description provided for @aiTimelineRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get aiTimelineRunning;

  /// No description provided for @aiTimelineClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aiTimelineClose;

  /// No description provided for @sshReconnectToggle.
  ///
  /// In en, this message translates to:
  /// **'Auto-reconnect on disconnect'**
  String get sshReconnectToggle;

  /// No description provided for @sshReconnectToggleDesc.
  ///
  /// In en, this message translates to:
  /// **'Retry dropped SSH sessions with exponential backoff'**
  String get sshReconnectToggleDesc;

  /// No description provided for @sshReconnectMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Max reconnect attempts'**
  String get sshReconnectMaxAttempts;

  /// No description provided for @sshReconnectMaxAttemptsDesc.
  ///
  /// In en, this message translates to:
  /// **'Max automatic reconnect attempts after a disconnect — 0 means retry until it succeeds'**
  String get sshReconnectMaxAttemptsDesc;

  /// No description provided for @sshReconnectMaxAttemptsValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String sshReconnectMaxAttemptsValue(int count);

  /// No description provided for @sshReconnectMaxAttemptsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get sshReconnectMaxAttemptsUnlimited;

  /// No description provided for @sshReconnectStatusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting (attempt {attempt})'**
  String sshReconnectStatusReconnecting(int attempt);

  /// No description provided for @sshReconnectStatusReconnectingOf.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting (attempt {attempt} of {max})'**
  String sshReconnectStatusReconnectingOf(int attempt, int max);

  /// No description provided for @sshReconnectGaveUp.
  ///
  /// In en, this message translates to:
  /// **'Auto-reconnect gave up'**
  String get sshReconnectGaveUp;

  /// No description provided for @sshReconnectGaveUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {name} after {max} attempts.'**
  String sshReconnectGaveUpMessage(String name, int max);

  /// No description provided for @sshReconnectGaveUpMessageUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {name}.'**
  String sshReconnectGaveUpMessageUnlimited(String name);

  /// No description provided for @sshReconnectRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get sshReconnectRetryNow;

  /// No description provided for @sshReconnectStopAuto.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sshReconnectStopAuto;

  /// No description provided for @sshReconnectReconnectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Reconnected to {name}'**
  String sshReconnectReconnectedSnack(String name);

  /// No description provided for @snippetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Command snippets'**
  String get snippetsTitle;

  /// No description provided for @snippetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save commands for quick re-use'**
  String get snippetsSubtitle;

  /// No description provided for @snippetsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add snippet'**
  String get snippetsAddTooltip;

  /// No description provided for @snippetsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New snippet'**
  String get snippetsAddTitle;

  /// No description provided for @snippetsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get snippetsSave;

  /// No description provided for @snippetsCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get snippetsCommandLabel;

  /// No description provided for @snippetsCommandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. docker ps -a'**
  String get snippetsCommandHint;

  /// No description provided for @snippetsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get snippetsNameLabel;

  /// No description provided for @snippetsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. List all containers'**
  String get snippetsNameHint;

  /// No description provided for @snippetsCommandRequired.
  ///
  /// In en, this message translates to:
  /// **'Command text is required'**
  String get snippetsCommandRequired;

  /// No description provided for @snippetsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete snippet'**
  String get snippetsDeleteTooltip;

  /// No description provided for @snippetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No snippets yet'**
  String get snippetsEmptyTitle;

  /// No description provided for @snippetsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Save frequently used commands and insert or run them with one tap.'**
  String get snippetsEmptyMessage;

  /// No description provided for @snippetsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load snippets'**
  String get snippetsLoadFailed;

  /// No description provided for @healthTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet health'**
  String get healthTitle;

  /// No description provided for @healthOnlineRatio.
  ///
  /// In en, this message translates to:
  /// **'{online}/{total} online'**
  String healthOnlineRatio(int online, int total);

  /// No description provided for @healthProbing.
  ///
  /// In en, this message translates to:
  /// **'Probing…'**
  String get healthProbing;

  /// No description provided for @healthProbeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Run health check'**
  String get healthProbeTooltip;

  /// No description provided for @healthProbedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked at {time}'**
  String healthProbedAt(String time);

  /// No description provided for @healthMoodAllOnline.
  ///
  /// In en, this message translates to:
  /// **'All systems nominal'**
  String get healthMoodAllOnline;

  /// No description provided for @healthMoodDegraded.
  ///
  /// In en, this message translates to:
  /// **'Some servers are unreachable'**
  String get healthMoodDegraded;

  /// No description provided for @healthMoodAllOffline.
  ///
  /// In en, this message translates to:
  /// **'All servers unreachable'**
  String get healthMoodAllOffline;

  /// No description provided for @healthOfflineServers.
  ///
  /// In en, this message translates to:
  /// **'Offline: {names}'**
  String healthOfflineServers(String names);

  /// No description provided for @healthNoData.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to check every server'**
  String get healthNoData;

  /// No description provided for @healthUptime.
  ///
  /// In en, this message translates to:
  /// **'up {brief}'**
  String healthUptime(String brief);

  /// No description provided for @healthLoad.
  ///
  /// In en, this message translates to:
  /// **'load {value}'**
  String healthLoad(String value);

  /// No description provided for @healthDiagIntro.
  ///
  /// In en, this message translates to:
  /// **'Here is my fleet\'s health report:'**
  String get healthDiagIntro;

  /// No description provided for @healthDiagStats.
  ///
  /// In en, this message translates to:
  /// **'{online} of {total} servers online.'**
  String healthDiagStats(int online, int total);

  /// No description provided for @healthDiagOfflineItem.
  ///
  /// In en, this message translates to:
  /// **'- {name}: offline'**
  String healthDiagOfflineItem(String name);

  /// No description provided for @healthDiagOnlineItem.
  ///
  /// In en, this message translates to:
  /// **'- {name}: online ({details})'**
  String healthDiagOnlineItem(String name, String details);

  /// No description provided for @healthDiagOutro.
  ///
  /// In en, this message translates to:
  /// **'Please analyze the health data, flag anything abnormal (high load, recent reboots) and suggest what to check next.'**
  String get healthDiagOutro;

  /// No description provided for @healthDiagnose.
  ///
  /// In en, this message translates to:
  /// **'AI diagnostics'**
  String get healthDiagnose;

  /// No description provided for @healthStaleNote.
  ///
  /// In en, this message translates to:
  /// **'Some servers went offline since the last check.'**
  String get healthStaleNote;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Command audit log'**
  String get auditTitle;

  /// No description provided for @auditTileDesc.
  ///
  /// In en, this message translates to:
  /// **'Commands run by the AI agent'**
  String get auditTileDesc;

  /// No description provided for @auditEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No audit entries yet'**
  String get auditEmptyTitle;

  /// No description provided for @auditEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Commands executed by the AI agent will be recorded here.'**
  String get auditEmptyMessage;

  /// No description provided for @auditFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries match the current filter'**
  String get auditFilteredEmpty;

  /// No description provided for @auditFilterAllServers.
  ///
  /// In en, this message translates to:
  /// **'All servers'**
  String get auditFilterAllServers;

  /// No description provided for @auditFilterAllModes.
  ///
  /// In en, this message translates to:
  /// **'All modes'**
  String get auditFilterAllModes;

  /// No description provided for @auditFilterAllResults.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get auditFilterAllResults;

  /// No description provided for @auditFilterConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get auditFilterConfirmed;

  /// No description provided for @auditFilterAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auditFilterAuto;

  /// No description provided for @auditFilterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get auditFilterSuccess;

  /// No description provided for @auditFilterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get auditFilterFailed;

  /// No description provided for @auditModeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get auditModeConfirmed;

  /// No description provided for @auditModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auditModeAuto;

  /// No description provided for @auditStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get auditStatusSuccess;

  /// No description provided for @auditStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get auditStatusFailed;

  /// No description provided for @auditDangerousBadge.
  ///
  /// In en, this message translates to:
  /// **'Dangerous'**
  String get auditDangerousBadge;

  /// No description provided for @auditExitCode.
  ///
  /// In en, this message translates to:
  /// **'Exit code {code}'**
  String auditExitCode(int code);

  /// No description provided for @auditOutputSummary.
  ///
  /// In en, this message translates to:
  /// **'Output summary'**
  String get auditOutputSummary;

  /// No description provided for @auditNoOutput.
  ///
  /// In en, this message translates to:
  /// **'No output'**
  String get auditNoOutput;

  /// No description provided for @auditClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear audit log'**
  String get auditClearTooltip;

  /// No description provided for @auditClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear audit log'**
  String get auditClearConfirmTitle;

  /// No description provided for @auditClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All {count} audit entries will be permanently removed.'**
  String auditClearConfirmMessage(int count);

  /// No description provided for @auditClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get auditClearAction;

  /// No description provided for @auditCleared.
  ///
  /// In en, this message translates to:
  /// **'Audit log cleared'**
  String get auditCleared;

  /// No description provided for @auditEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String auditEntriesCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
