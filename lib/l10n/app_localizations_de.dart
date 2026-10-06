// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Server';

  @override
  String get navAiChat => 'AI-Chat';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String get backToServers => 'Zurück zu den Servern';

  @override
  String get serversTitle => 'Server';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Hosts',
      one: '1 Host',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Server suchen…';

  @override
  String get serversAdd => 'Server hinzufügen';

  @override
  String get serversEmpty => 'Noch keine Server';

  @override
  String get serversEmptyHint =>
      'Fügen Sie Ihren ersten SSH-Server hinzu, um loszulegen.';

  @override
  String get serversDeleteConfirmTitle => 'Server löschen';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return '\"$name\" löschen?\n\n$identity:$port und die gespeicherten Anmeldedaten werden dauerhaft entfernt.';
  }

  @override
  String serversDeleted(String identity) {
    return '$identity entfernt';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Löschen fehlgeschlagen: $message';
  }

  @override
  String get serversLoading => 'Server werden geladen';

  @override
  String get serversUngrouped => 'Ohne Gruppe';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'zuletzt';

  @override
  String get serversQuickStart => 'Schnellstart';

  @override
  String get serversQuickStep1Title => 'Host hinzufügen';

  @override
  String get serversQuickStep1Desc =>
      'Registrieren Sie einen SSH-Endpunkt mit Passwort- oder Schlüssel-Authentifizierung.';

  @override
  String get serversQuickStep2Title => 'Verbindung testen';

  @override
  String get serversQuickStep2Desc =>
      'Prüfen Sie den Port vor dem Speichern – erkennt Tippfehler schnell.';

  @override
  String get serversQuickStep3Title => 'Verbinden';

  @override
  String get serversQuickStep3Desc =>
      'Öffnen Sie eine Terminal-Sitzung – vollständiges PTY, Farben und vim.';

  @override
  String serversNoMatch(String query) {
    return 'Keine Übereinstimmung: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Filter löschen';

  @override
  String get serversReadError => 'Die Serverliste konnte nicht gelesen werden.';

  @override
  String get serverEditTitle => 'Server hinzufügen';

  @override
  String get serverEditTitleEdit => 'Server bearbeiten';

  @override
  String get serverNotFound => 'Server nicht gefunden';

  @override
  String get serverValidationNameRequired => 'Name erforderlich';

  @override
  String get serverValidationHostRequired => 'Host erforderlich';

  @override
  String get serverValidationNoSpaces => 'Keine Leerzeichen erlaubt';

  @override
  String get serverValidationRequired => 'Erforderlich';

  @override
  String get serverValidationNumeric => 'Numerisch';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Benutzername erforderlich';

  @override
  String get serverValidationPasswordRequired => 'Passwort erforderlich';

  @override
  String get serverValidationPrivateKeyRequired =>
      'Privater Schlüssel erforderlich';

  @override
  String serverAdded(String identity, int port) {
    return 'Server hinzugefügt: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Gespeichert: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Speichern fehlgeschlagen: $message';
  }

  @override
  String get serverTestEnterHost => 'Geben Sie zuerst eine Host-Adresse ein';

  @override
  String serverTestProbing(String host, int port) {
    return '$host:$port wird geprüft…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — erreichbar';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — Zeitüberschreitung';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — abgelehnt / nicht erreichbar';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — Prüfung fehlgeschlagen';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port SSH-Handshake fehlgeschlagen';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port Authentifizierung fehlgeschlagen – Benutzername und Anmeldedaten prüfen';
  }

  @override
  String get serverLoading => 'Wird geladen';

  @override
  String get serverSaveChanges => 'Änderungen speichern';

  @override
  String get serverSectionIdentity => 'Identität';

  @override
  String get serverSectionConnection => 'Verbindung';

  @override
  String get serverSectionAuthentication => 'Authentifizierung';

  @override
  String get serverFieldLabel => 'Bezeichnung';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Gruppe (optional)';

  @override
  String get serverFieldGroupHint => 'produktion';

  @override
  String get serverFieldHost => 'Host';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Port';

  @override
  String get serverFieldUsername => 'Benutzername';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Passwort';

  @override
  String get serverFieldPasswordStored =>
      'Gespeichert – leer lassen, um zu behalten';

  @override
  String get serverFieldPrivateKey => 'Privater Schlüssel (PEM)';

  @override
  String get serverFieldPassphrase => 'Schlüssel-Passphrase (optional)';

  @override
  String get serverAuthPassword => 'Passwort';

  @override
  String get serverAuthPrivateKey => 'Privater Schlüssel';

  @override
  String get serverTestIdle =>
      'Tippen Sie auf \"Testen\", um die Verbindung zu prüfen';

  @override
  String get serverSecurityNote =>
      'Anmeldedaten werden im Keystore des Geräts verschlüsselt – sie gelangen nie in den Hive-Metadatenspeicher und verlassen dieses Gerät nicht.';

  @override
  String get serverTesting => 'Wird getestet…';

  @override
  String get serverTest => 'Testen';

  @override
  String get serverSaving => 'Wird gespeichert…';

  @override
  String serverCopiedAddress(String address) {
    return '$address kopiert';
  }

  @override
  String get serverActions => 'Server-Aktionen';

  @override
  String get serverActionConnect => 'Verbinden';

  @override
  String get serverActionEdit => 'Bearbeiten';

  @override
  String get serverActionEditDetails => 'Details bearbeiten';

  @override
  String get serverActionCopySsh => 'SSH-Befehl kopieren';

  @override
  String get serverActionDelete => 'Löschen';

  @override
  String get serverActionDeleteServer => 'Server löschen';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverNeverConnected => 'Nie verbunden';

  @override
  String get serverJustNow => 'Gerade eben';

  @override
  String serverMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String serverHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String serverDaysAgo(int days) {
    return 'vor $days T.';
  }

  @override
  String get terminalHostNotFound => 'Host nicht gefunden';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Kein gespeicherter Server entspricht der ID \"$id\". Er wurde möglicherweise gelöscht.';
  }

  @override
  String get terminalBackToServers => 'Zurück zu den Servern';

  @override
  String get terminalConnectionFailed => 'Verbindung fehlgeschlagen.';

  @override
  String get terminalSessionClosed => 'Sitzung geschlossen';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'Die Verbindung zu $name wurde beendet.';
  }

  @override
  String get terminalReconnect => 'Erneut verbinden';

  @override
  String get terminalAuthenticating => 'Authentifizierung läuft';

  @override
  String get terminalConnecting => 'Verbindung wird hergestellt';

  @override
  String get terminalResolvingHost => 'Host wird aufgelöst…';

  @override
  String get terminalTooltipDisconnectBack => 'Trennen & zurück';

  @override
  String get terminalTooltipSmallerText => 'Kleinere Schrift';

  @override
  String get terminalTooltipLargerText => 'Größere Schrift';

  @override
  String get terminalTooltipDisconnect => 'Trennen';

  @override
  String get terminalRetryAvailable => 'Erneuter Versuch verfügbar';

  @override
  String get terminalStatusConnected => 'VERBUNDEN';

  @override
  String get terminalStatusOffline => 'OFFLINE';

  @override
  String get terminalStatusError => 'FEHLER';

  @override
  String get aiChatTitle => 'AI-Assistent';

  @override
  String get aiChatStatusSetup => 'EINRICHTUNG';

  @override
  String get aiChatStatusStreaming => 'STREAMING';

  @override
  String get aiChatStatusReady => 'BEREIT';

  @override
  String get aiChatClearConversation => 'Konversation löschen';

  @override
  String get aiChatSuggestion1 =>
      'Erklären Sie, was die Ausgabe von ls -la bedeutet';

  @override
  String get aiChatSuggestion2 =>
      'Wie finde ich heraus, welcher Prozess einen Port verwendet?';

  @override
  String get aiChatSuggestion3 =>
      'Zeigen Sie mir, wie ich Logs mit tail verfolge und mit grep nach Fehlern suche';

  @override
  String get aiChatSuggestion4 =>
      'Schreiben Sie einen awk-Einzeiler, um eine CSV-Spalte zu summieren';

  @override
  String get aiChatTryAsking => 'Probieren Sie diese Fragen';

  @override
  String get aiChatIntroTitle => 'Ihr Terminal-Begleiter';

  @override
  String get aiChatIntroBody =>
      'Fügen Sie einen Befehl, einen Fehler oder einen Logausschnitt ein. ShellMind erklärt, was passiert ist, schlägt den nächsten Schritt vor und schreibt die Befehle für Sie.';

  @override
  String get aiChatNoKeyTitle => 'Kein API-Schlüssel konfiguriert';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Fügen Sie Ihren $provider-API-Schlüssel hinzu, um den Assistenten zu aktivieren. Er wird verschlüsselt auf diesem Gerät gespeichert und verlässt es nur, um das Modell aufzurufen.';
  }

  @override
  String get aiChatOpenSettings => 'AI-Einstellungen öffnen';

  @override
  String get aiChatCheckingCredentials => 'Anmeldedaten werden geprüft';

  @override
  String get aiChatInputHint => 'Fragen Sie alles…';

  @override
  String get aiChatInputDisabled =>
      'Legen Sie einen API-Schlüssel fest, um zu beginnen';

  @override
  String get aiChatError => 'Fehler';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Kopiert';

  @override
  String get aiChatCopy => 'Kopieren';

  @override
  String get aiChatThinking => 'Denkt nach…';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSearchTooltip => 'Einstellungen durchsuchen';

  @override
  String get settingsStable => 'STABIL';

  @override
  String get settingsSectionAppearance => 'Darstellung & Sprache';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'Englisch';

  @override
  String get settingsSectionAiProvider => 'AI-Anbieter';

  @override
  String get settingsSectionAiAgent => 'AI-Agent';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Server';

  @override
  String get settingsSectionAboutUpdate => 'Info & Update';

  @override
  String get settingsSectionStoragePrivacy => 'Speicher & Datenschutz';

  @override
  String get settingsSectionResources => 'Ressourcen';

  @override
  String get settingsTileSecrets => 'Geheimnisse';

  @override
  String get settingsTileEncrypted => 'Verschlüsselt';

  @override
  String get settingsTileLocalCache => 'Lokaler Cache';

  @override
  String get settingsTileClearData => 'Alle Daten löschen';

  @override
  String get settingsTileLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsTileReportIssue => 'Problem melden';

  @override
  String get settingsFooter => 'SSH + AI-Assistent für moderne Arbeitsabläufe';

  @override
  String get settingsSecretsDialogTitle => 'Geheimnisse & Verschlüsselung';

  @override
  String get settingsSecretsDialogBody =>
      'Anmeldedaten – Server-Passwörter, private Schlüssel und AI-API-Schlüssel – werden im Ruhezustand immer mit dem Plattform-Keystore verschlüsselt (Android Keystore / iOS Keychain). Dieser Schutz ist gewollt und kann nicht deaktiviert werden. Um eine Anmeldedaten zu ändern, bearbeiten oder entfernen Sie sie auf der Server-Bearbeitungsseite oder in den AI-Einstellungen.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Schließen';

  @override
  String get settingsCacheDialogTitle => 'Lokaler Cache';

  @override
  String get settingsCacheHiveData => 'App-Daten';

  @override
  String get settingsCacheDownloads => 'Heruntergeladene Updates';

  @override
  String get settingsCacheTotal => 'Gesamt';

  @override
  String get settingsCacheDialogHint =>
      'Das Leeren des Download-Cache entfernt heruntergeladene Update-Pakete (APKs). Ihre Server, Schlüssel und der Chat-Verlauf bleiben erhalten.';

  @override
  String get settingsCacheClearDownloads => 'Download-Cache leeren';

  @override
  String settingsCacheCleared(String freed) {
    return '$freed freigegeben';
  }

  @override
  String get settingsClearDataTitle => 'Alle Daten löschen?';

  @override
  String get settingsClearDataMessage =>
      'Dadurch werden alle Server, gespeicherten Anmeldedaten, AI-Schlüssel, der Chat-Verlauf und alle Einstellungen auf diesem Gerät dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get settingsClearDataConfirm => 'Alles löschen';

  @override
  String get settingsDataCleared => 'Alle Daten gelöscht';

  @override
  String settingsClearDataFailed(String message) {
    return 'Daten konnten nicht gelöscht werden: $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Problem-Link in die Zwischenablage kopiert.';

  @override
  String get settingsAboutGithub => 'GitHub-Repository';

  @override
  String get settingsHideIp => 'IP-Adressen ausblenden';

  @override
  String get settingsHideIpDesc =>
      'IP-Adressen in der Serverliste und auf den AI-Seiten maskieren';

  @override
  String get serverMaskedAddress => 'Adresse ausgeblendet';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return '$provider-API-Schlüssel';
  }

  @override
  String get aiSettingsKeySet => 'gesetzt';

  @override
  String get aiSettingsKeyNotConfigured => 'nicht konfiguriert';

  @override
  String get aiSettingsGetApiKey => 'API-Schlüssel erhalten';

  @override
  String get aiSettingsTemperature => 'Temperatur';

  @override
  String get aiSettingsRemoveKey => 'Schlüssel entfernen';

  @override
  String aiSettingsKeySaved(String provider) {
    return '$provider-API-Schlüssel sicher gespeichert.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return '$provider-Schlüssel entfernen?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'Der Assistent funktioniert für diesen Anbieter erst wieder, wenn ein neuer Schlüssel hinzugefügt wird.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Entfernen';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return '$provider-Schlüssel erhalten';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Öffnen Sie die Anbieter-Konsole in Ihrem Browser, um einen API-Schlüssel zu erstellen, und fügen Sie ihn anschließend hier ein.';

  @override
  String get aiSettingsClose => 'Schließen';

  @override
  String get aiSettingsLinkCopied => 'Link in die Zwischenablage kopiert.';

  @override
  String get aiSettingsCopyLink => 'Link kopieren';

  @override
  String get aiSettingsKeyConfigured => 'Schlüssel konfiguriert';

  @override
  String get aiSettingsNotConfigured => 'Nicht konfiguriert';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return '$provider-Schlüssel aktualisieren';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return '$provider-Schlüssel hinzufügen';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Verschlüsselt auf diesem Gerät gespeichert. Wird nur verwendet, um den AI-Anbieter aufzurufen.';

  @override
  String get aiSettingsApiKeyHint => 'API-Schlüssel…';

  @override
  String get aiSettingsSave => 'Speichern';

  @override
  String get modelDescFastAffordable => 'Schnell & günstig';

  @override
  String get modelDescMostCapable => 'Am leistungsfähigsten';

  @override
  String get modelDescLegacyFast => 'Legacy – schnell';

  @override
  String get modelDescGeneralConversation => 'Allgemeine Konversation';

  @override
  String get modelDescAdvancedReasoning => 'Erweitertes Schlussfolgern';

  @override
  String get modelDescFastResponse => 'Schnelle Antwort';

  @override
  String get modelDescBalanced => 'Ausgewogen';

  @override
  String get modelDescFreeFast => 'Kostenlos & schnell';

  @override
  String get modelDescEnhanced => 'Verbessert';

  @override
  String get modelDescStandard => 'Standard';

  @override
  String get modelDescLightweight => 'Leichtgewichtig';

  @override
  String get modelDescRlEnhanced => 'RL-verbessert';

  @override
  String get aiModelsTitle => 'Modell';

  @override
  String get aiModelsRefresh => 'Modellliste aktualisieren';

  @override
  String get aiModelsAddCustom => 'Benutzerdefiniertes Modell hinzufügen';

  @override
  String get aiModelsAddCustomHint => 'Modell-ID, z. B. deepseek-chat';

  @override
  String get aiModelsAdd => 'Hinzufügen';

  @override
  String get aiModelsCustomBadge => 'Benutzerdefiniert';

  @override
  String get aiModelsFetchFailed =>
      'Modelle konnten nicht abgerufen werden – die integrierte Liste wird angezeigt.';

  @override
  String get aiModelsRemoveCustom => 'Benutzerdefiniertes Modell entfernen';

  @override
  String get aiModelsEmpty => 'Keine Modelle';

  @override
  String get aiModelsInvalidId => 'Geben Sie eine Modell-ID ein.';

  @override
  String get aiModelsDuplicate => 'Dieses Modell ist bereits in der Liste.';

  @override
  String get aiModelsPickerTitle => 'Modell wählen';

  @override
  String get aiModelsSearchHint => 'Modelle durchsuchen';

  @override
  String get aiModelsSearchEmpty => 'Keine Modelle entsprechen Ihrer Suche.';

  @override
  String get aiProvidersAddTile => 'Benutzerdefinierten Anbieter hinzufügen';

  @override
  String get aiProvidersAddTitle => 'Benutzerdefinierten Anbieter hinzufügen';

  @override
  String get aiProvidersFieldName => 'Name';

  @override
  String get aiProvidersFieldNameHint => 'z. B. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'Basis-URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Standardmodell (optional)';

  @override
  String get aiProvidersFieldModelHint => 'Modell-ID, z. B. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Hinzufügen';

  @override
  String get aiProvidersInvalidInput =>
      'Geben Sie einen Namen und eine Basis-URL ein.';

  @override
  String get aiProvidersInvalidUrl =>
      'Die Basis-URL muss mit http:// oder https:// beginnen';

  @override
  String get aiProvidersDuplicateName =>
      'Ein Anbieter mit diesem Namen existiert bereits.';

  @override
  String get aiProvidersAdded => 'Benutzerdefinierter Anbieter hinzugefügt.';

  @override
  String get aiProvidersAddFailed =>
      'Der Anbieter konnte nicht hinzugefügt werden – überprüfen Sie die Eingaben.';

  @override
  String get aiProvidersDeleteTile => 'Benutzerdefinierten Anbieter entfernen';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return '$provider entfernen?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Der gespeicherte API-Schlüssel, das gemerkte Modell und die benutzerdefinierten Modelle werden ebenfalls entfernt. Integrierte Anbieter können nicht gelöscht werden.';

  @override
  String get aiProvidersDeleteConfirm => 'Entfernen';

  @override
  String get aiProvidersPickerTitle => 'Anbieter wählen';

  @override
  String get updateVersion => 'Version';

  @override
  String get updateSoftwareUpdate => 'Software-Update';

  @override
  String get updateChecking => 'PRÜFUNG';

  @override
  String get updateUpToDate => 'AKTUELL';

  @override
  String get updateCheckAgain => 'Erneut prüfen';

  @override
  String get updateReady => 'BEREIT';

  @override
  String get updateNew => 'NEU';

  @override
  String get updateCheck => 'PRÜFEN';

  @override
  String get updateAwaitingResponse => 'Warten auf Antwort';

  @override
  String get updateAlreadyLatest => 'Bereits auf dem neuesten Stand';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version ist die neueste auf GitHub veröffentlichte Version.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'Aktuell läuft v$current – der neueste Stand ist v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Zuletzt geprüft $timeAgo';
  }

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updatePre => 'PRE';

  @override
  String get updateDownloadInstall => 'Herunterladen & Installieren';

  @override
  String get updateLater => 'Später';

  @override
  String get updateApkHint =>
      'Die APK-Installation wird nur unter Android unterstützt. Die Datei kann hier dennoch heruntergeladen werden.';

  @override
  String updateDownloading(String tag) {
    return '$tag wird heruntergeladen';
  }

  @override
  String get updateSize => 'Größe';

  @override
  String get updateRate => 'Rate';

  @override
  String get updateEta => 'ETA';

  @override
  String get updateElapsed => 'verstrichen';

  @override
  String get updateCancel => 'Abbrechen';

  @override
  String get updateKeepForeground => 'App im Vordergrund behalten';

  @override
  String get updateDownloadComplete => 'Download abgeschlossen';

  @override
  String get updateInstallHint =>
      'Android bittet Sie um Bestätigung. ShellMind wird geschlossen, während das Installationsprogramm läuft; Ihre Server und der Verlauf bleiben erhalten.';

  @override
  String get updateLaunching => 'Wird gestartet...';

  @override
  String get updateInstallNow => 'Jetzt installieren';

  @override
  String get updateDelete => 'Löschen';

  @override
  String updateInstallTitle(String tag) {
    return '$tag installieren?';
  }

  @override
  String get updateInstallMessage =>
      'Der System-Paketinstaller wird geöffnet. ShellMind wird während der Installation geschlossen und mit der neuen Version wieder geöffnet.';

  @override
  String get updateNotNow => 'Nicht jetzt';

  @override
  String get updateInstall => 'Installieren';

  @override
  String get updateCheckFailed => 'Die Update-Prüfung ist fehlgeschlagen.';

  @override
  String get updateErrorTitleNoReleases => 'Keine Releases';

  @override
  String get updateErrorTitleGeneric => 'Update-Prüfung fehlgeschlagen';

  @override
  String get updateErrNoReleases =>
      'Es wurden noch keine Releases für ShellMind veröffentlicht.';

  @override
  String get updateErrRateLimit =>
      'Das API-Ratenlimit von GitHub wurde erreicht. Bitte versuchen Sie es später erneut.';

  @override
  String get updateErrTimeout =>
      'Die Anfrage an GitHub hat eine Zeitüberschreitung verursacht. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get updateErrNetwork =>
      'GitHub konnte nicht erreicht werden. Überprüfen Sie Ihre Netzwerkverbindung.';

  @override
  String get updateErrAuth => 'GitHub hat die Update-Anfrage abgelehnt.';

  @override
  String get updateErrPermission => 'Die Update-Anfrage wurde verweigert.';

  @override
  String get updateErrStorage =>
      'Nicht genügend Speicherplatz, um das Update abzuschließen.';

  @override
  String get updateErrDigestMismatch =>
      'Das heruntergeladene Update hat die SHA-256-Integritätsprüfung nicht bestanden und wurde gelöscht. Bitte wiederholen Sie den Download.';

  @override
  String get updateErrDigestMissing =>
      'Das Update-Paket hat keinen veröffentlichten Integritäts-Digest, daher wurde das Update abgelehnt. Bitte versuchen Sie es später erneut.';

  @override
  String get updateRetry => 'Erneut versuchen';

  @override
  String get updateDismiss => 'Verwerfen';

  @override
  String updateReleaseNotes(String tag) {
    return 'Release $tag';
  }

  @override
  String get updateNotesLabel => 'Hinweise';

  @override
  String get updateNewVersionAvailable => 'Neue Version verfügbar';

  @override
  String get updateRemindLater => 'Später erinnern';

  @override
  String get updateCancelDownload => 'Download abbrechen';

  @override
  String updateInstallTag(String tag) {
    return '$tag installieren';
  }

  @override
  String get updateInstallLaterFromSettings =>
      'Später über die Einstellungen installieren';

  @override
  String get updateCouldNotComplete =>
      'Das Update konnte nicht abgeschlossen werden.';

  @override
  String get updateClose => 'Schließen';

  @override
  String get updatePromptInstallHint =>
      'Android schließt ShellMind, während das Installationsprogramm läuft. Server, Schlüssel und Chat-Verlauf bleiben erhalten.';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String get commonNoData => 'Keine Daten';

  @override
  String get commonNothingToShow => 'Hier gibt es noch nichts anzuzeigen.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'Befehle automatisch ausführen';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Dem AI-Agenten erlauben, analysierte Befehle ohne erneute Rückfrage auszuführen';

  @override
  String get settingsAiAutoConnectTitle => 'AI-Auto-Verbindung zu Servern';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Dem AI-Assistenten erlauben, sich automatisch mit konfigurierten, aber offline befindlichen Servern zu verbinden und darauf Befehle auszuführen (gespeicherte Anmeldedaten werden verwendet)';

  @override
  String get settingsAiMaxAutoLoopsTitle => 'Maximale Auto-Loop-Iterationen';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Begrenzt die Anzahl automatischer Befehlsausführungen pro Antwort';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Maximale Befehlsrunden, die die AI pro Aufgabe ausführen darf';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Dies ist die Obergrenze der Ausführungsrunden pro AI-Aufgabe – nicht die Anzahl der SSH-Neuverbindungsversuche (diese befindet sich unter SSH).';

  @override
  String get terminalAskAi => 'AI fragen';

  @override
  String get terminalAskAiSubtitle =>
      'Den ausgewählten Text an den AI-Assistenten senden';

  @override
  String get terminalTooltipAskAi => 'AI fragen';

  @override
  String get aiChatNoConnection =>
      'Verbinden Sie sich zuerst mit einem Server-Terminal';

  @override
  String get aiChatAnalyzePrompt =>
      'Bitte analysieren Sie die obige Befehlsausgabe, erklären Sie, was das Ergebnis bedeutet, und geben Sie bei Bedarf weiterführende Vorschläge.';

  @override
  String get aiExecuteButton => 'Auf Server ausführen';

  @override
  String get aiExecuteTitle => 'Befehlsausführung bestätigen';

  @override
  String get aiExecuteConfirmButton => 'Ausführen';

  @override
  String get aiExecuteConfirmAnyway => 'Trotzdem ausführen';

  @override
  String get aiExecuteDangerWarning => '⚠ Gefährlicher Befehl';

  @override
  String get aiExecuteDangerText =>
      'Dieser Befehl kann destruktiv sein und Datenverlust oder Systemschäden verursachen.';

  @override
  String get aiExecuteCommandLabel => 'Auszuführender Befehl:';

  @override
  String get aiExecuteTargetServer => 'Zielserver:';

  @override
  String get aiExecuteSelectServer => 'Zielserver auswählen';

  @override
  String get aiExecuteNoServer =>
      'Verbinden Sie sich bitte zuerst mit einem Server';

  @override
  String get aiExecuteAtLeastOne => 'Wählen Sie mindestens einen Server';

  @override
  String get aiExecuteSelectHint =>
      'Wählen Sie den bzw. die Server, auf denen dieser Befehl ausgeführt werden soll';

  @override
  String aiExecuteRunCount(int count) {
    return 'Ausführen ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Alle auswählen';

  @override
  String get aiExecuteClearSelection => 'Auswahl aufheben';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours Std. $minutes Min. online';
  }

  @override
  String get aiExecuteSuccess => 'Befehl erfolgreich ausgeführt';

  @override
  String get aiExecuteFailed => 'Befehlsausführung fehlgeschlagen';

  @override
  String get aiServerManageTitle => 'Server';

  @override
  String get aiServerManageSubtitle =>
      'Server verbinden, damit der AI-Assistent arbeiten kann';

  @override
  String aiServerOnlineCount(int count) {
    return '$count online';
  }

  @override
  String get aiServerDone => 'Fertig';

  @override
  String get aiServerConnecting => 'Verbindung wird hergestellt…';

  @override
  String get aiServerOffline => 'Offline';

  @override
  String get aiServerNoCredential =>
      'Keine gespeicherten Anmeldedaten – speichern Sie zuerst das Passwort oder den Schlüssel auf der Serverseite';

  @override
  String get aiServerConnectFailed => 'Verbindung fehlgeschlagen';

  @override
  String get aiToolResultCommand => 'Befehl';

  @override
  String get aiToolResultOutput => 'Befehlsausgabe';

  @override
  String aiToolResultExitCode(int code) {
    return 'Exit-Code: $code';
  }

  @override
  String get aiToolResultElapsed => 'Verstrichene Zeit';

  @override
  String get aiToolResultAnalyzeButton => 'Ausgabe von AI analysieren lassen';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total weitere Zeilen';
  }

  @override
  String get aiToolResultExpandedHide => 'Ausgabe ausblenden';

  @override
  String get aiToolResultStderrLabel => 'Fehlerausgabe:';

  @override
  String get aiContextToggleAttach => 'Terminal-Kontext anhängen';

  @override
  String get aiContextToggleDetach => 'Terminal-Kontext angehängt';

  @override
  String get aiContextBadge => 'Kontext';

  @override
  String aiContextLines(int lines) {
    return '$lines Zeilen vom Terminal';
  }

  @override
  String get aiAgentStop => 'Auto-Modus stoppen';

  @override
  String get aiAgentExecuting => 'Wird ausgeführt…';

  @override
  String get aiAgentDefaultServer => 'Server';

  @override
  String get aiTimelineTitle => 'Ausführungsverlauf';

  @override
  String get aiTimelineOpen => 'Ausführungsverlauf';

  @override
  String get aiTimelineEmpty => 'Noch keine Befehle ausgeführt';

  @override
  String get aiTimelineEmptyHint =>
      'Führen Sie Befehle über den Chat oder den Auto-Modus aus, und die vollständige Kette erscheint hier.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Befehle',
      one: '1 Befehl',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erfolgreich',
      one: '1 erfolgreich',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlgeschlagen',
      one: '1 fehlgeschlagen',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Gestartet $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Beendet $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Exit-Code: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Kein Exit-Code';

  @override
  String get aiTimelineOutput => 'Ausgabe';

  @override
  String get aiTimelineOutputEmpty => 'Keine Ausgabe';

  @override
  String get aiTimelineErrorOutput => 'Fehlerausgabe';

  @override
  String get aiTimelineRunning => 'Wird ausgeführt…';

  @override
  String get aiTimelineClose => 'Schließen';

  @override
  String get sshReconnectToggle => 'Automatische Wiederverbindung bei Trennung';

  @override
  String get sshReconnectToggleDesc =>
      'Abgebrochene SSH-Sitzungen mit exponentiellem Backoff erneut versuchen';

  @override
  String get sshReconnectMaxAttempts => 'Maximale Wiederverbindungsversuche';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Maximale automatische Wiederverbindungsversuche nach einer Trennung – 0 bedeutet, bis zum Erfolg wiederholen';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Unbegrenzt';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Wiederverbindung (Versuch $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Wiederverbindung (Versuch $attempt von $max)';
  }

  @override
  String get sshReconnectGaveUp => 'Automatische Wiederverbindung aufgegeben';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return '$name konnte nach $max Versuchen nicht erreicht werden.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return '$name konnte nicht erreicht werden.';
  }

  @override
  String get sshReconnectRetryNow => 'Jetzt erneut versuchen';

  @override
  String get sshReconnectStopAuto => 'Stopp';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Wieder mit $name verbunden';
  }

  @override
  String get snippetsTitle => 'Befehls-Snippets';

  @override
  String get snippetsSubtitle =>
      'Befehle für die schnelle Wiederverwendung speichern';

  @override
  String get snippetsAddTooltip => 'Snippet hinzufügen';

  @override
  String get snippetsAddTitle => 'Neues Snippet';

  @override
  String get snippetsSave => 'Speichern';

  @override
  String get snippetsCommandLabel => 'Befehl';

  @override
  String get snippetsCommandHint => 'z. B. docker ps -a';

  @override
  String get snippetsNameLabel => 'Name (optional)';

  @override
  String get snippetsNameHint => 'z. B. Alle Container auflisten';

  @override
  String get snippetsCommandRequired => 'Befehlstext ist erforderlich';

  @override
  String get snippetsDeleteTooltip => 'Snippet löschen';

  @override
  String get snippetsEmptyTitle => 'Noch keine Snippets';

  @override
  String get snippetsEmptyMessage =>
      'Speichern Sie häufig verwendete Befehle und fügen Sie sie mit einem Tippen ein oder führen Sie sie aus.';

  @override
  String get snippetsLoadFailed => 'Snippets konnten nicht geladen werden';

  @override
  String get healthTitle => 'Flottenzustand';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total online';
  }

  @override
  String get healthProbing => 'Wird geprüft…';

  @override
  String get healthProbeTooltip => 'Zustandsprüfung ausführen';

  @override
  String healthProbedAt(String time) {
    return 'Geprüft um $time';
  }

  @override
  String get healthMoodAllOnline => 'Alle Systeme in Ordnung';

  @override
  String get healthMoodDegraded => 'Einige Server sind nicht erreichbar';

  @override
  String get healthMoodAllOffline => 'Alle Server nicht erreichbar';

  @override
  String healthOfflineServers(String names) {
    return 'Offline: $names';
  }

  @override
  String get healthNoData =>
      'Tippen Sie auf Aktualisieren, um jeden Server zu prüfen';

  @override
  String healthUptime(String brief) {
    return 'läuft seit $brief';
  }

  @override
  String healthLoad(String value) {
    return 'Last $value';
  }

  @override
  String get healthDiagIntro => 'Hier ist der Zustandsbericht meiner Flotte:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online von $total Servern online.';
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
      'Bitte analysieren Sie die Zustandsdaten, markieren Sie alles Auffällige (hohe Last, kürzliche Neustarts) und schlagen Sie vor, was als Nächstes geprüft werden sollte.';

  @override
  String get healthDiagnose => 'AI-Diagnose';

  @override
  String get healthStaleNote =>
      'Einige Server sind seit der letzten Prüfung offline gegangen.';

  @override
  String get auditTitle => 'Befehls-Auditprotokoll';

  @override
  String get auditTileDesc => 'Vom AI-Agenten ausgeführte Befehle';

  @override
  String get auditEmptyTitle => 'Noch keine Audit-Einträge';

  @override
  String get auditEmptyMessage =>
      'Vom AI-Agenten ausgeführte Befehle werden hier aufgezeichnet.';

  @override
  String get auditFilteredEmpty =>
      'Keine Einträge entsprechen dem aktuellen Filter';

  @override
  String get auditFilterAllServers => 'Alle Server';

  @override
  String get auditFilterAllModes => 'Alle Modi';

  @override
  String get auditFilterAllResults => 'Alle Ergebnisse';

  @override
  String get auditFilterConfirmed => 'Bestätigt';

  @override
  String get auditFilterAuto => 'Auto';

  @override
  String get auditFilterSuccess => 'Erfolg';

  @override
  String get auditFilterFailed => 'Fehlgeschlagen';

  @override
  String get auditModeConfirmed => 'Bestätigt';

  @override
  String get auditModeAuto => 'Auto';

  @override
  String get auditStatusSuccess => 'Erfolg';

  @override
  String get auditStatusFailed => 'Fehlgeschlagen';

  @override
  String get auditDangerousBadge => 'Gefährlich';

  @override
  String auditExitCode(int code) {
    return 'Exit-Code $code';
  }

  @override
  String get auditOutputSummary => 'Ausgabezusammenfassung';

  @override
  String get auditNoOutput => 'Keine Ausgabe';

  @override
  String get auditClearTooltip => 'Auditprotokoll löschen';

  @override
  String get auditClearConfirmTitle => 'Auditprotokoll löschen';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Alle $count Audit-Einträge werden dauerhaft entfernt.';
  }

  @override
  String get auditClearAction => 'Löschen';

  @override
  String get auditCleared => 'Auditprotokoll gelöscht';

  @override
  String auditEntriesCount(int count) {
    return '$count Einträge';
  }

  @override
  String get serverActionDisconnect => 'Trennen';

  @override
  String get exportChatAction => 'Als Markdown exportieren';

  @override
  String get exportChatEmpty => 'Noch nichts zu exportieren';

  @override
  String exportChatSuccess(String path) {
    return 'Konversation nach $path exportiert';
  }

  @override
  String exportChatFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get diagTitle => 'Diagnose';

  @override
  String get diagTileDesc => 'App-Fehler & Diagnose-Export';

  @override
  String get diagEmptyTitle => 'Keine Fehler erfasst';

  @override
  String get diagEmptyMessage =>
      'Nicht abgefangene Ausnahmen werden hier aufgezeichnet, um bei Problemberichten zu helfen.';

  @override
  String diagEntriesCount(int count) {
    return '$count Fehler';
  }

  @override
  String get diagSourceFlutter => 'UI-Fehler';

  @override
  String get diagSourcePlatform => 'Laufzeitfehler';

  @override
  String get diagSourceZone => 'Asynchrone Aufgabe';

  @override
  String get diagStackTrace => 'Stack-Trace';

  @override
  String get diagNoStackTrace => 'Kein Stack-Trace';

  @override
  String get diagExportAction => 'Diagnosebericht exportieren';

  @override
  String get diagExportEmpty =>
      'Nichts zu melden – Basisinformationen werden exportiert';

  @override
  String diagExportSuccess(String path) {
    return 'Diagnosebericht nach $path exportiert';
  }

  @override
  String diagExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get diagPrivacyNote =>
      'Der Diagnoseinhalt wird geschwärzt – es sind keine Passwörter, privaten Schlüssel oder API-Schlüssel enthalten.';

  @override
  String get diagClearTooltip => 'Fehlerdatensätze löschen';

  @override
  String get diagClearConfirmTitle => 'Fehlerdatensätze löschen';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Alle $count Fehlerdatensätze werden dauerhaft entfernt.';
  }

  @override
  String get diagClearAction => 'Löschen';

  @override
  String get diagCleared => 'Fehlerdatensätze gelöscht';

  @override
  String get diagAppInfoTitle => 'App-Informationen';

  @override
  String get diagAppInfoVersion => 'Version';

  @override
  String get diagAppInfoPlatform => 'Plattform';

  @override
  String get diagAppInfoLocale => 'Sprache';

  @override
  String get diagAppInfoStorage => 'Größe der lokalen Daten';

  @override
  String get authLockToggleTitle => 'Biometrische Sperre';

  @override
  String get authLockToggleDesc =>
      'Beim Öffnen der App Fingerabdruck- oder Gesichtsentsperrung verlangen';

  @override
  String get authLockEnableFailed =>
      'Verifizierung fehlgeschlagen – Sperre bleibt deaktiviert';

  @override
  String get authLockUnavailableDesc =>
      'Auf diesem Gerät sind keine biometrischen Daten eingerichtet';

  @override
  String get authLockScreenTitle => 'ShellMind ist gesperrt';

  @override
  String get authLockScreenSubtitle => 'Verifizieren, um fortzufahren';

  @override
  String get authLockUnlockAction => 'Entsperren';

  @override
  String get authLockUnlockFailed =>
      'Verifizierung fehlgeschlagen – erneut versuchen';

  @override
  String get terminalTabPickerTitle => 'Terminal wechseln';

  @override
  String get terminalTabPickerSubtitle =>
      'Wählen Sie einen Server, um ihn als Terminal-Tab zu öffnen – Online-Server verbinden sich sofort, Offline-Server wählen sich zuerst ein';

  @override
  String get terminalTabPickerEmpty => 'Noch keine Server konfiguriert';

  @override
  String get terminalTabNewTooltip => 'Neuer Terminal-Tab';

  @override
  String get terminalTabCloseTooltip => 'Tab schließen';

  @override
  String get hostKeyConfirmTitle => 'Diesem Host vertrauen?';

  @override
  String get hostKeyConfirmMessage =>
      'Dies ist die erste Verbindung zu diesem Server. Überprüfen Sie den Fingerabdruck, bevor Sie vertrauen – dies schützt vor Man-in-the-Middle-Angriffen.';

  @override
  String get hostKeyEndpointLabel => 'SERVER';

  @override
  String get hostKeyFingerprintLabel => 'SHA-256-FINGERABDRUCK';

  @override
  String get hostKeySecurityNote =>
      'Vergleichen Sie den Fingerabdruck mit einem Wert, den Sie außerhalb dieser Verbindung vom Serverbetreiber erhalten haben. Einem falschen Fingerabdruck zu vertrauen, setzt Ihre Anmeldedaten einem Risiko aus.';

  @override
  String get hostKeyTrustAndConnect => 'Vertrauen und verbinden';

  @override
  String get hostKeyReject => 'Ablehnen';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Automatische Ablehnung in $seconds s – Vertrauen wird nur aufgezeichnet, wenn Sie bestätigen.';
  }

  @override
  String get hostKeyMismatchTitle => 'Host-Schlüssel geändert';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'Der von $host:$port präsentierte Schlüssel unterscheidet sich von dem, dem Sie zuvor vertraut haben. Die Verbindung wurde blockiert – dies kann ein Man-in-the-Middle-Angriff sein oder der Server wurde neu installiert. Wenn Sie den neuen Schlüssel verifiziert haben, setzen Sie das Host-Vertrauen auf der Server-Bearbeitungsseite zurück und verbinden Sie sich erneut.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Verbindung abgebrochen – dem Host-Schlüssel wurde nicht vertraut. Sie können sich erneut verbinden, um den Fingerabdruck zu prüfen.';

  @override
  String get serverResetTrustAction => 'Host-Vertrauen zurücksetzen';

  @override
  String get serverResetTrustDesc =>
      'Den gespeicherten Fingerabdruck dieses Servers vergessen, damit die nächste Verbindung erneut eine Bestätigung anfordert.';

  @override
  String get serverResetTrustConfirmTitle => 'Host-Vertrauen zurücksetzen?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'Der gespeicherte Fingerabdruck für $identity:$port wird entfernt. Bei der nächsten Verbindung werden Sie erneut aufgefordert, den Host-Schlüssel zu verifizieren.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Zurücksetzen';

  @override
  String get serverResetTrustDone =>
      'Host-Vertrauen zurückgesetzt – verbinden Sie sich erneut, um den Fingerabdruck erneut zu verifizieren.';

  @override
  String get agentErrorNoTargetServer => 'Kein Zielserver verfügbar';

  @override
  String get agentErrorExecFailed => 'Befehlsausführung fehlgeschlagen';

  @override
  String get agentErrorConnectFailed =>
      'Automatische Verbindung zum Server fehlgeschlagen';

  @override
  String get agentErrorConnectAuthRequired =>
      'Keine gespeicherten Anmeldedaten für diesen Server – automatische Verbindung ist nicht möglich';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Gefährlichen Befehl übersprungen: $command';
  }

  @override
  String get agentErrorUnexpected => 'Unerwarteter Fehler';

  @override
  String get exportDocChatTitle => 'Shell-Mind Chat-Export';

  @override
  String exportDocExportedAt(String time) {
    return 'Exportiert am: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Nachrichten: $count';
  }

  @override
  String get exportDocUserSection => 'Benutzer';

  @override
  String get exportDocAssistantSection => 'Assistent';

  @override
  String get exportDocToolSection => 'Tool-Ausführung';

  @override
  String get exportDocNoContent => '_(kein Inhalt)_';

  @override
  String get exportDocUnknownServer => 'Unbekannter Server';

  @override
  String exportDocExitCode(int code) {
    return 'Exit-Code $code';
  }

  @override
  String get exportDocCommand => 'Befehl';

  @override
  String get exportDocOutput => 'Ausgabe';

  @override
  String get exportDocErrorOutput => 'Fehlerausgabe';

  @override
  String get exportDocDiagTitle => 'Shell-Mind-Diagnosebericht';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Erfasste Fehler: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Erfasste Fehler';

  @override
  String get exportDocDiagNone => '(keine)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Fehlerzusammenfassung: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'App-Version: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Plattform: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Sprache: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Lokale Datennutzung: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'AI-Befehlsaudit (letzte $limit Zusammenfassungen)';
  }

  @override
  String get exportDocDiagSuccess => 'Erfolg';

  @override
  String get exportDocDiagFailed => 'fehlgeschlagen';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'Exit-Code $code';
  }

  @override
  String get settingsTerminalScheme => 'Terminal-Farbschema';

  @override
  String get settingsTerminalSchemeDesc =>
      'Wählen Sie die ANSI-Farbpalette für SSH-Terminals.';

  @override
  String get settingsSectionDataTransfer => 'Import & Export';

  @override
  String get transferSnippetsTitle => 'Befehls-Snippets';

  @override
  String get transferServersTitle => 'Serverkonfigurationen';

  @override
  String get transferExport => 'Exportieren';

  @override
  String get transferImport => 'Importieren';

  @override
  String get transferExportImport => 'Exportieren / Importieren';

  @override
  String get transferExportTitle => 'Export';

  @override
  String get transferCopyJson => 'JSON kopieren';

  @override
  String get transferCopied => 'In die Zwischenablage kopiert';

  @override
  String get transferImportHint => 'Exportierte JSON hier einfügen…';

  @override
  String get transferSnippetsEmpty => 'Keine Befehls-Snippets zum Exportieren.';

  @override
  String get transferServersEmpty => 'Keine Server zum Exportieren.';

  @override
  String get transferImportNothing =>
      'Keine gültigen Elemente im Import gefunden.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Snippets importiert',
      one: '1 Snippet importiert',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Server importiert',
      one: '1 Server importiert',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Import fehlgeschlagen: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Export fehlgeschlagen: $message';
  }

  @override
  String get sessionsTitle => 'Konversationen';

  @override
  String get sessionsNew => 'Neue Konversation';

  @override
  String get sessionsSearch => 'Konversationen durchsuchen…';

  @override
  String get sessionsEmpty => 'Noch keine Konversationen';

  @override
  String sessionsNoMatch(String query) {
    return 'Keine Übereinstimmung: \"$query\"';
  }

  @override
  String get sessionsRename => 'Umbenennen';

  @override
  String get sessionsRenameHint => 'Konversationstitel';

  @override
  String get sessionsDelete => 'Löschen';

  @override
  String sessionsDeleteConfirm(String title) {
    return '\"$title\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsTitle => 'Hintergrund-Benachrichtigungen';

  @override
  String get settingsNotificationsDesc =>
      'Benachrichtigen, wenn eine SSH-Sitzung abbricht oder eine AI-Aufgabe abgeschlossen wird, während die App im Hintergrund ist.';

  @override
  String get sftpTitle => 'Dateien';

  @override
  String get sftpNotConnected => 'Nicht mit diesem Server verbunden.';

  @override
  String get sftpLoading => 'Dateien werden geladen…';

  @override
  String get sftpEmpty => 'Dieser Ordner ist leer.';

  @override
  String get sftpDownload => 'Herunterladen';

  @override
  String sftpDownloaded(String path, int size) {
    return '$path heruntergeladen ($size Bytes)';
  }

  @override
  String get sftpDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get sftpPreviewError => 'Vorschau fehlgeschlagen';

  @override
  String get sftpNewFolderName => 'Neuer Ordner';

  @override
  String get sftpRefresh => 'Aktualisieren';

  @override
  String get sftpDelete => 'Löschen';

  @override
  String sftpDeleteConfirm(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get sftpRename => 'Umbenennen';

  @override
  String get sftpTooltip => 'Dateien durchsuchen (SFTP)';

  @override
  String get terminalMoreTooltip => 'Mehr';

  @override
  String get tunnelsTitle => 'Portweiterleitung';

  @override
  String get tunnelsEmpty => 'Keine aktiven Tunnel.';

  @override
  String get tunnelsAddLocal => 'Lokale Weiterleitung';

  @override
  String get tunnelsAddRemote => 'Remote-Weiterleitung';

  @override
  String get tunnelsLocalPort => 'Lokaler Port';

  @override
  String get tunnelsRemoteHost => 'Remote-Host';

  @override
  String get tunnelsRemotePort => 'Remote-Port';

  @override
  String get tunnelsAdd => 'Hinzufügen';

  @override
  String get tunnelsClose => 'Schließen';

  @override
  String get tunnelsTooltip => 'Portweiterleitung (SSH-Tunnel)';

  @override
  String get tunnelsError => 'Tunnel fehlgeschlagen';

  @override
  String get tunnelsInvalidPort => 'Der Port muss zwischen 1 und 65535 liegen.';

  @override
  String get settingsLanguageTitle => 'Sprache';
}
