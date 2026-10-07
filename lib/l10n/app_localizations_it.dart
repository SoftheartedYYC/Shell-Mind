// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Server';

  @override
  String get navAiChat => 'Chat AI';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get pageNotFound => 'Pagina non trovata';

  @override
  String get backToServers => 'Torni ai Server';

  @override
  String get serversTitle => 'Server';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count host',
      one: '1 host',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Cerchi server…';

  @override
  String get serversAdd => 'Aggiunga server';

  @override
  String get serversEmpty => 'Nessun server ancora';

  @override
  String get serversEmptyHint =>
      'Aggiunga il Suo primo server SSH per iniziare.';

  @override
  String get serversDeleteConfirmTitle => 'Elimini server';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return 'Eliminare \"$name\"?\n\n$identity:$port e le credenziali salvate associate verranno rimossi definitivamente.';
  }

  @override
  String serversDeleted(String identity) {
    return 'Rimosso $identity';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Eliminazione non riuscita: $message';
  }

  @override
  String get serversLoading => 'Caricamento server';

  @override
  String get serversUngrouped => 'Senza gruppo';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'recenti';

  @override
  String get serversQuickStart => 'Avvio rapido';

  @override
  String get serversQuickStep1Title => 'Aggiunga un host';

  @override
  String get serversQuickStep1Desc =>
      'Registri un endpoint SSH con autenticazione tramite password o chiave.';

  @override
  String get serversQuickStep2Title => 'Verifichi la connessione';

  @override
  String get serversQuickStep2Desc =>
      'Verifichi la porta prima di confermare: rileva subito gli errori di digitazione.';

  @override
  String get serversQuickStep3Title => 'Si connetta';

  @override
  String get serversQuickStep3Desc =>
      'Apra una sessione di terminale: PTY completo, colori e vim.';

  @override
  String serversNoMatch(String query) {
    return 'Nessuna corrispondenza: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Azzeri il filtro';

  @override
  String get serversReadError => 'Impossibile leggere l\'elenco dei server.';

  @override
  String get serverEditTitle => 'Aggiunga server';

  @override
  String get serverEditTitleEdit => 'Modifichi server';

  @override
  String get serverNotFound => 'Server non trovato';

  @override
  String get serverValidationNameRequired => 'Nome obbligatorio';

  @override
  String get serverValidationHostRequired => 'Host obbligatorio';

  @override
  String get serverValidationNoSpaces => 'Nessuno spazio consentito';

  @override
  String get serverValidationRequired => 'Obbligatorio';

  @override
  String get serverValidationNumeric => 'Numerico';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Nome utente obbligatorio';

  @override
  String get serverValidationPasswordRequired => 'Password obbligatoria';

  @override
  String get serverValidationPrivateKeyRequired =>
      'Chiave privata obbligatoria';

  @override
  String serverAdded(String identity, int port) {
    return 'Server aggiunto: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Salvato: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Salvataggio non riuscito: $message';
  }

  @override
  String get serverTestEnterHost => 'Inserisca prima un indirizzo host';

  @override
  String serverTestProbing(String host, int port) {
    return 'Verifica di $host:$port in corso…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — raggiungibile';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — timeout';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — rifiutato / non raggiungibile';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — verifica non riuscita';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port handshake SSH non riuscito';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port autenticazione non riuscita - controlli nome utente e credenziali';
  }

  @override
  String get serverLoading => 'Caricamento';

  @override
  String get serverSaveChanges => 'Salvi le modifiche';

  @override
  String get serverSectionIdentity => 'Identità';

  @override
  String get serverSectionConnection => 'Connessione';

  @override
  String get serverSectionAuthentication => 'Autenticazione';

  @override
  String get serverFieldLabel => 'Etichetta';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Gruppo (facoltativo)';

  @override
  String get serverFieldGroupHint => 'produzione';

  @override
  String get serverFieldHost => 'Host';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Porta';

  @override
  String get serverFieldUsername => 'Nome utente';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Password';

  @override
  String get serverFieldPasswordStored =>
      'Salvata — lasci vuoto per mantenerla';

  @override
  String get serverFieldPrivateKey => 'Chiave privata (PEM)';

  @override
  String get serverFieldPassphrase => 'Passphrase della chiave (facoltativa)';

  @override
  String get serverAuthPassword => 'Password';

  @override
  String get serverAuthPrivateKey => 'Chiave privata';

  @override
  String get serverTestIdle => 'Tocchi \"Test\" per verificare la connessione';

  @override
  String get serverSecurityNote =>
      'Le credenziali sono cifrate nel keystore del dispositivo: non vengono mai salvate nell\'archivio dei metadati Hive né lasciano questo dispositivo.';

  @override
  String get serverTesting => 'Test in corso…';

  @override
  String get serverTest => 'Test';

  @override
  String get serverSaving => 'Salvataggio…';

  @override
  String serverCopiedAddress(String address) {
    return 'Copiato $address';
  }

  @override
  String get serverActions => 'Azioni server';

  @override
  String get serverActionConnect => 'Si connetta';

  @override
  String get serverActionEdit => 'Modifichi';

  @override
  String get serverActionEditDetails => 'Modifichi i dettagli';

  @override
  String get serverActionCopySsh => 'Copi comando SSH';

  @override
  String get serverActionDelete => 'Elimini';

  @override
  String get serverActionDeleteServer => 'Elimini server';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverNeverConnected => 'Mai connesso';

  @override
  String get serverJustNow => 'Adesso';

  @override
  String serverMinutesAgo(int minutes) {
    return '$minutes min fa';
  }

  @override
  String serverHoursAgo(int hours) {
    return '$hours h fa';
  }

  @override
  String serverDaysAgo(int days) {
    return '$days g fa';
  }

  @override
  String get terminalHostNotFound => 'Host non trovato';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Nessun server salvato corrisponde all\'id \"$id\". Potrebbe essere stato eliminato.';
  }

  @override
  String get terminalBackToServers => 'Torni ai server';

  @override
  String get terminalConnectionFailed => 'Connessione non riuscita.';

  @override
  String get terminalSessionClosed => 'Sessione chiusa';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'La connessione a $name è stata interrotta.';
  }

  @override
  String get terminalReconnect => 'Si riconnetta';

  @override
  String get terminalAuthenticating => 'Autenticazione in corso';

  @override
  String get terminalConnecting => 'Connessione in corso';

  @override
  String get terminalResolvingHost => 'Risoluzione dell\'host…';

  @override
  String get terminalTooltipDisconnectBack => 'Si disconnetta e torni indietro';

  @override
  String get terminalTooltipSmallerText => 'Testo più piccolo';

  @override
  String get terminalTooltipLargerText => 'Testo più grande';

  @override
  String get terminalTooltipDisconnect => 'Si disconnetta';

  @override
  String get terminalRetryAvailable => 'Riprova disponibile';

  @override
  String get terminalStatusConnected => 'CONNESSO';

  @override
  String get terminalStatusOffline => 'OFFLINE';

  @override
  String get terminalStatusError => 'ERRORE';

  @override
  String get aiChatTitle => 'Assistente AI';

  @override
  String get aiChatStatusSetup => 'CONFIGURAZIONE';

  @override
  String get aiChatStatusStreaming => 'STREAMING';

  @override
  String get aiChatStatusReady => 'PRONTO';

  @override
  String get aiChatClearConversation => 'Azzeri la conversazione';

  @override
  String get aiChatSuggestion1 => 'Spieghi cosa significa l\'output di ls -la';

  @override
  String get aiChatSuggestion2 =>
      'Come faccio a trovare quale processo sta usando una porta?';

  @override
  String get aiChatSuggestion3 =>
      'Mi mostri come fare tail dei log e cercare errori con grep';

  @override
  String get aiChatSuggestion4 =>
      'Scriva un one-liner awk per sommare una colonna CSV';

  @override
  String get aiChatTryAsking => 'Provi a chiedere';

  @override
  String get aiChatIntroTitle => 'Il Suo compagno di terminale';

  @override
  String get aiChatIntroBody =>
      'Incolli un comando, un errore o una porzione di output di log. ShellMind spiega cosa è successo, suggerisce la mossa successiva e scrive i comandi al posto Suo.';

  @override
  String get aiChatNoKeyTitle => 'Nessuna chiave API configurata';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Aggiunga la Sua chiave API $provider per attivare l\'assistente. Viene salvata cifrata su questo dispositivo e non lo lascia mai, se non per chiamare il modello.';
  }

  @override
  String get aiChatOpenSettings => 'Apra le impostazioni AI';

  @override
  String get aiChatCheckingCredentials => 'Verifica delle credenziali';

  @override
  String get aiChatInputHint => 'Chieda qualsiasi cosa…';

  @override
  String get aiChatInputDisabled => 'Imposti una chiave API per iniziare';

  @override
  String get aiChatError => 'Errore';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Copiato';

  @override
  String get aiChatCopy => 'Copi';

  @override
  String get aiChatThinking => 'Riflessione…';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSearchTooltip => 'Cerchi nelle impostazioni';

  @override
  String get settingsStable => 'STABILE';

  @override
  String get settingsSectionAppearance => 'Aspetto e lingua';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsSectionLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'Provider AI';

  @override
  String get settingsSectionAiAgent => 'Agente AI';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Server';

  @override
  String get settingsSectionAboutUpdate => 'Informazioni e aggiornamenti';

  @override
  String get settingsSectionStoragePrivacy => 'Archiviazione e privacy';

  @override
  String get settingsSectionResources => 'Risorse';

  @override
  String get settingsTileSecrets => 'Segreti';

  @override
  String get settingsTileEncrypted => 'Cifrato';

  @override
  String get settingsTileLocalCache => 'Cache locale';

  @override
  String get settingsTileClearData => 'Cancella tutti i dati';

  @override
  String get settingsTileLicenses => 'Licenze open source';

  @override
  String get settingsTileReportIssue => 'Segnali un problema';

  @override
  String get settingsFooter =>
      'SSH + Assistente AI per flussi di lavoro moderni';

  @override
  String get settingsSecretsDialogTitle => 'Segreti e cifratura';

  @override
  String get settingsSecretsDialogBody =>
      'Le credenziali — password dei server, chiavi private e chiavi API AI — sono sempre cifrate a riposo tramite il keystore della piattaforma (Android Keystore / iOS Keychain). Questa protezione è prevista per impostazione e non può essere disattivata. Per modificare una credenziale, la modifichi o la rimuova nella pagina di modifica del server o nelle impostazioni AI.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Chiuda';

  @override
  String get settingsCacheDialogTitle => 'Cache locale';

  @override
  String get settingsCacheHiveData => 'Dati dell\'app';

  @override
  String get settingsCacheDownloads => 'Aggiornamenti scaricati';

  @override
  String get settingsCacheTotal => 'Totale';

  @override
  String get settingsCacheDialogHint =>
      'Cancellando la cache dei download vengono rimossi i pacchetti di aggiornamento scaricati (APK). I Suoi server, le chiavi e la cronologia delle chat vengono conservati.';

  @override
  String get settingsCacheClearDownloads => 'Svuoti la cache dei download';

  @override
  String settingsCacheCleared(String freed) {
    return 'Liberati $freed';
  }

  @override
  String get settingsClearDataTitle => 'Cancellare tutti i dati?';

  @override
  String get settingsClearDataMessage =>
      'Questa operazione elimina definitivamente ogni server, credenziale salvata, chiave AI, cronologia delle chat e preferenza su questo dispositivo. L\'operazione non può essere annullata.';

  @override
  String get settingsClearDataConfirm => 'Cancelli tutto';

  @override
  String get settingsDataCleared => 'Tutti i dati cancellati';

  @override
  String settingsClearDataFailed(String message) {
    return 'Impossibile cancellare i dati: $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Link del problema copiato negli appunti.';

  @override
  String get settingsAboutGithub => 'Repository GitHub';

  @override
  String get settingsHideIp => 'Nasconda gli indirizzi IP';

  @override
  String get settingsHideIpDesc =>
      'Mascheri gli indirizzi IP nell\'elenco dei server e nelle pagine AI';

  @override
  String get serverMaskedAddress => 'Indirizzo nascosto';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return 'Chiave API $provider';
  }

  @override
  String get aiSettingsKeySet => 'impostata';

  @override
  String get aiSettingsKeyNotConfigured => 'non configurata';

  @override
  String get aiSettingsGetApiKey => 'Ottenga una chiave API';

  @override
  String get aiSettingsTemperature => 'Temperatura';

  @override
  String get aiSettingsRemoveKey => 'Rimuova la chiave';

  @override
  String aiSettingsKeySaved(String provider) {
    return 'Chiave API $provider salvata in modo sicuro.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return 'Rimuovere la chiave $provider?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'L\'assistente smetterà di funzionare per questo provider finché non verrà aggiunta una nuova chiave.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Rimuova';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Ottenga una chiave $provider';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Apra la console del provider nel Suo browser per creare una chiave API, quindi la incolli di nuovo qui.';

  @override
  String get aiSettingsClose => 'Chiuda';

  @override
  String get aiSettingsLinkCopied => 'Link copiato negli appunti.';

  @override
  String get aiSettingsCopyLink => 'Copi link';

  @override
  String get aiSettingsKeyConfigured => 'Chiave configurata';

  @override
  String get aiSettingsNotConfigured => 'Non configurata';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Aggiorni la chiave $provider';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Aggiunga la chiave $provider';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Salvata cifrata su questo dispositivo. Utilizzata solo per chiamare il provider AI.';

  @override
  String get aiSettingsApiKeyHint => 'Chiave API…';

  @override
  String get aiSettingsSave => 'Salvi';

  @override
  String get modelDescFastAffordable => 'Veloce ed economico';

  @override
  String get modelDescMostCapable => 'Il più capace';

  @override
  String get modelDescLegacyFast => 'Veloce (legacy)';

  @override
  String get modelDescGeneralConversation => 'Conversazione generale';

  @override
  String get modelDescAdvancedReasoning => 'Ragionamento avanzato';

  @override
  String get modelDescFastResponse => 'Risposta rapida';

  @override
  String get modelDescBalanced => 'Bilanciato';

  @override
  String get modelDescFreeFast => 'Gratuito e veloce';

  @override
  String get modelDescEnhanced => 'Potenziato';

  @override
  String get modelDescStandard => 'Standard';

  @override
  String get modelDescLightweight => 'Leggero';

  @override
  String get modelDescRlEnhanced => 'Potenziato con RL';

  @override
  String get aiModelsTitle => 'Modello';

  @override
  String get aiModelsRefresh => 'Aggiorni l\'elenco dei modelli';

  @override
  String get aiModelsAddCustom => 'Aggiunga modello personalizzato';

  @override
  String get aiModelsAddCustomHint => 'ID modello, ad es. deepseek-chat';

  @override
  String get aiModelsAdd => 'Aggiunga';

  @override
  String get aiModelsCustomBadge => 'Personalizzato';

  @override
  String get aiModelsFetchFailed =>
      'Impossibile recuperare i modelli: viene mostrato l\'elenco integrato.';

  @override
  String get aiModelsRemoveCustom => 'Rimuova modello personalizzato';

  @override
  String get aiModelsEmpty => 'Nessun modello';

  @override
  String get aiModelsInvalidId => 'Inserisca un ID modello.';

  @override
  String get aiModelsDuplicate => 'Questo modello è già presente nell\'elenco.';

  @override
  String get aiModelsPickerTitle => 'Scelga il modello';

  @override
  String get aiModelsSearchHint => 'Cerchi modelli';

  @override
  String get aiModelsSearchEmpty =>
      'Nessun modello corrisponde alla Sua ricerca.';

  @override
  String get aiProvidersAddTile => 'Aggiunga provider personalizzato';

  @override
  String get aiProvidersAddTitle => 'Aggiunga provider personalizzato';

  @override
  String get aiProvidersFieldName => 'Nome';

  @override
  String get aiProvidersFieldNameHint => 'ad es. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'URL di base';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Modello predefinito (facoltativo)';

  @override
  String get aiProvidersFieldModelHint => 'ID modello, ad es. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Aggiunga';

  @override
  String get aiProvidersInvalidInput => 'Inserisca un nome e un URL di base.';

  @override
  String get aiProvidersInvalidUrl =>
      'L\'URL di base deve iniziare con http:// o https://';

  @override
  String get aiProvidersDuplicateName =>
      'Esiste già un provider con questo nome.';

  @override
  String get aiProvidersAdded => 'Provider personalizzato aggiunto.';

  @override
  String get aiProvidersAddFailed =>
      'Impossibile aggiungere il provider: controlli i dati inseriti.';

  @override
  String get aiProvidersDeleteTile => 'Rimuova provider personalizzato';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return 'Rimuovere $provider?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Verranno rimossi anche la chiave API salvata, il modello memorizzato e i modelli personalizzati. I provider integrati non possono essere eliminati.';

  @override
  String get aiProvidersDeleteConfirm => 'Rimuova';

  @override
  String get aiProvidersPickerTitle => 'Scelga il provider';

  @override
  String get updateVersion => 'Versione';

  @override
  String get updateSoftwareUpdate => 'Aggiornamento software';

  @override
  String get updateChecking => 'VERIFICA';

  @override
  String get updateUpToDate => 'AGGIORNATO';

  @override
  String get updateCheckAgain => 'Verifichi di nuovo';

  @override
  String get updateReady => 'PRONTO';

  @override
  String get updateNew => 'NUOVO';

  @override
  String get updateCheck => 'VERIFICA';

  @override
  String get updateAwaitingResponse => 'In attesa di risposta';

  @override
  String get updateAlreadyLatest => 'Già sulla build più recente';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version è l\'ultima release pubblicata su GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'In esecuzione: v$current — la versione remota più recente è v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Verificato $timeAgo';
  }

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get updatePre => 'PRE';

  @override
  String get updateDownloadInstall => 'Scarica e installa';

  @override
  String get updateLater => 'Più tardi';

  @override
  String get updateApkHint =>
      'L\'installazione di APK è supportata solo su Android. Il file può comunque essere scaricato qui.';

  @override
  String updateDownloading(String tag) {
    return 'Scaricamento di $tag';
  }

  @override
  String get updateSize => 'dimensione';

  @override
  String get updateRate => 'velocità';

  @override
  String get updateEta => 'ETA';

  @override
  String get updateElapsed => 'trascorso';

  @override
  String get updateCancel => 'Annulli';

  @override
  String get updateKeepForeground => 'Mantenga l\'app in primo piano';

  @override
  String get updateDownloadComplete => 'Download completato';

  @override
  String get updateInstallHint =>
      'Android Le chiederà di confermare. ShellMind si chiude mentre l\'installer è in esecuzione; i Suoi server e la cronologia vengono conservati.';

  @override
  String get updateLaunching => 'Avvio...';

  @override
  String get updateInstallNow => 'Installi ora';

  @override
  String get updateDelete => 'Elimini';

  @override
  String updateInstallTitle(String tag) {
    return 'Installare $tag?';
  }

  @override
  String get updateInstallMessage =>
      'Si aprirà l\'installer dei pacchetti di sistema. ShellMind si chiude durante l\'installazione e si riapre sulla nuova versione.';

  @override
  String get updateNotNow => 'Non ora';

  @override
  String get updateInstall => 'Installi';

  @override
  String get updateCheckFailed => 'Verifica degli aggiornamenti non riuscita.';

  @override
  String get updateErrorTitleNoReleases => 'Nessuna release';

  @override
  String get updateErrorTitleGeneric => 'Verifica aggiornamenti non riuscita';

  @override
  String get updateErrNoReleases =>
      'Non è ancora stata pubblicata alcuna release per ShellMind.';

  @override
  String get updateErrRateLimit =>
      'È stato raggiunto il limite di richieste dell\'API di GitHub. Riprovi più tardi.';

  @override
  String get updateErrTimeout =>
      'La richiesta a GitHub è scaduta. Controlli la connessione e riprovi.';

  @override
  String get updateErrNetwork =>
      'Impossibile raggiungere GitHub. Controlli la connessione di rete.';

  @override
  String get updateErrAuth =>
      'GitHub ha rifiutato la richiesta di aggiornamento.';

  @override
  String get updateErrPermission =>
      'La richiesta di aggiornamento è stata negata.';

  @override
  String get updateErrStorage =>
      'Spazio di archiviazione insufficiente per completare l\'aggiornamento.';

  @override
  String get updateErrDigestMismatch =>
      'L\'aggiornamento scaricato non ha superato il controllo di integrità SHA-256 ed è stato eliminato. Riprovi il download.';

  @override
  String get updateErrDigestMissing =>
      'Il pacchetto di aggiornamento non ha un digest di integrità pubblicato, pertanto l\'aggiornamento è stato rifiutato. Riprovi più tardi.';

  @override
  String get updateRetry => 'Riprovi';

  @override
  String get updateDismiss => 'Ignori';

  @override
  String updateReleaseNotes(String tag) {
    return 'Release $tag';
  }

  @override
  String get updateNotesLabel => 'note';

  @override
  String get updateNewVersionAvailable => 'Nuova versione disponibile';

  @override
  String get updateRemindLater => 'Me lo ricordi più tardi';

  @override
  String get updateCancelDownload => 'Annulli il download';

  @override
  String updateInstallTag(String tag) {
    return 'Installi $tag';
  }

  @override
  String get updateInstallLaterFromSettings =>
      'Installi più tardi dalle impostazioni';

  @override
  String get updateCouldNotComplete =>
      'Impossibile completare l\'aggiornamento.';

  @override
  String get updateClose => 'Chiuda';

  @override
  String get updatePromptInstallHint =>
      'Android chiude ShellMind mentre l\'installer è in esecuzione. Server, chiavi e cronologia delle chat vengono conservati.';

  @override
  String get commonCancel => 'Annulli';

  @override
  String get commonDelete => 'Elimini';

  @override
  String get commonRetry => 'Riprovi';

  @override
  String get commonLoading => 'Caricamento...';

  @override
  String get commonNoData => 'Nessun dato';

  @override
  String get commonNothingToShow => 'Non c\'è ancora nulla da mostrare qui.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'Esecuzione automatica dei comandi';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Consenta all\'agente AI di eseguire i comandi analizzati senza chiedere conferma ogni volta';

  @override
  String get settingsAiAutoConnectTitle =>
      'Connessione automatica AI ai server';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Consenta all\'assistente AI di connettersi automaticamente ai server configurati ma offline e di eseguire comandi su di essi (verranno usate le credenziali salvate)';

  @override
  String get settingsAiMaxAutoLoopsTitle =>
      'Iterazioni massime del ciclo automatico';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Limita il numero di esecuzioni automatiche di comandi per risposta';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Numero massimo di round di comandi che l\'AI può eseguire per attività';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Questo è il limite superiore dei round di esecuzione per attività AI, non il numero di tentativi di riconnessione SSH (quello si trova nella sezione SSH).';

  @override
  String get terminalAskAi => 'Chieda all\'AI';

  @override
  String get terminalAskAiSubtitle =>
      'Invia il testo selezionato all\'assistente AI';

  @override
  String get terminalTooltipAskAi => 'Chieda all\'AI';

  @override
  String get aiChatNoConnection => 'Si connetta prima a un terminale server';

  @override
  String get aiChatAnalyzePrompt =>
      'Analizzi l\'output del comando qui sopra, spieghi cosa significa il risultato e fornisca suggerimenti di follow-up dove necessario.';

  @override
  String get aiExecuteButton => 'Esegua sul server';

  @override
  String get aiExecuteTitle => 'Conferma esecuzione comando';

  @override
  String get aiExecuteConfirmButton => 'Esegua';

  @override
  String get aiExecuteConfirmAnyway => 'Esegua comunque';

  @override
  String get aiExecuteDangerWarning => '⚠ Comando pericoloso';

  @override
  String get aiExecuteDangerText =>
      'Questo comando potrebbe essere distruttivo e causare perdita di dati o danni al sistema.';

  @override
  String get aiExecuteCommandLabel => 'Comando da eseguire:';

  @override
  String get aiExecuteTargetServer => 'Server di destinazione:';

  @override
  String get aiExecuteSelectServer => 'Selezioni i server di destinazione';

  @override
  String get aiExecuteNoServer => 'Si connetta prima a un server';

  @override
  String get aiExecuteAtLeastOne => 'Selezioni almeno un server';

  @override
  String get aiExecuteSelectHint =>
      'Scelga i server su cui eseguire questo comando';

  @override
  String aiExecuteRunCount(int count) {
    return 'Esegua ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Selezioni tutto';

  @override
  String get aiExecuteClearSelection => 'Azzeri';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours h $minutes min online';
  }

  @override
  String get aiExecuteSuccess => 'Comando eseguito correttamente';

  @override
  String get aiExecuteFailed => 'Esecuzione del comando non riuscita';

  @override
  String get aiServerManageTitle => 'Server';

  @override
  String get aiServerManageSubtitle =>
      'Connetta i server per consentire all\'assistente AI di operare';

  @override
  String aiServerOnlineCount(int count) {
    return '$count online';
  }

  @override
  String get aiServerDone => 'Fatto';

  @override
  String get aiServerConnecting => 'Connessione in corso…';

  @override
  String get aiServerOffline => 'Offline';

  @override
  String get aiServerNoCredential =>
      'Nessuna credenziale salvata: salvi prima la password o la chiave nella pagina del server';

  @override
  String get aiServerConnectFailed => 'Connessione non riuscita';

  @override
  String get aiToolResultCommand => 'Comando';

  @override
  String get aiToolResultOutput => 'Output del comando';

  @override
  String aiToolResultExitCode(int code) {
    return 'Codice di uscita: $code';
  }

  @override
  String get aiToolResultElapsed => 'Tempo trascorso';

  @override
  String get aiToolResultAnalyzeButton => 'Lasci che l\'AI analizzi l\'output';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total righe in più';
  }

  @override
  String get aiToolResultExpandedHide => 'Nasconda output';

  @override
  String get aiToolResultStderrLabel => 'Output di errore:';

  @override
  String get aiContextToggleAttach => 'Alleghi il contesto del terminale';

  @override
  String get aiContextToggleDetach => 'Contesto del terminale collegato';

  @override
  String get aiContextBadge => 'Contesto';

  @override
  String aiContextLines(int lines) {
    return '$lines righe dal terminale';
  }

  @override
  String get aiAgentStop => 'Interrompa la modalità automatica';

  @override
  String get aiAgentExecuting => 'Esecuzione in corso…';

  @override
  String get aiAgentDefaultServer => 'server';

  @override
  String get aiTimelineTitle => 'Cronologia di esecuzione';

  @override
  String get aiTimelineOpen => 'Cronologia di esecuzione';

  @override
  String get aiTimelineEmpty => 'Nessun comando eseguito finora';

  @override
  String get aiTimelineEmptyHint =>
      'Esegua i comandi tramite chat o modalità automatica e la sequenza completa apparirà qui.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count round',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comandi',
      one: '1 comando',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count riusciti',
      one: '1 riuscito',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non riusciti',
      one: '1 non riuscito',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Avviato $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Terminato $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Codice di uscita: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Nessun codice di uscita';

  @override
  String get aiTimelineOutput => 'Output';

  @override
  String get aiTimelineOutputEmpty => 'Nessun output';

  @override
  String get aiTimelineErrorOutput => 'Output di errore';

  @override
  String get aiTimelineRunning => 'In esecuzione…';

  @override
  String get aiTimelineClose => 'Chiuda';

  @override
  String get sshReconnectToggle =>
      'Riconnessione automatica alla disconnessione';

  @override
  String get sshReconnectToggleDesc =>
      'Riprova le sessioni SSH interrotte con backoff esponenziale';

  @override
  String get sshReconnectMaxAttempts => 'Tentativi massimi di riconnessione';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Tentativi massimi di riconnessione automatica dopo una disconnessione: 0 significa riprovare finché non riesce';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Illimitato';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Riconnessione in corso (tentativo $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Riconnessione in corso (tentativo $attempt di $max)';
  }

  @override
  String get sshReconnectGaveUp => 'Riconnessione automatica interrotta';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'Impossibile raggiungere $name dopo $max tentativi.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'Impossibile raggiungere $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Riprovi ora';

  @override
  String get sshReconnectStopAuto => 'Fermi';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Riconnesso a $name';
  }

  @override
  String get snippetsTitle => 'Frammenti di comando';

  @override
  String get snippetsSubtitle =>
      'Salvi i comandi per riutilizzarli rapidamente';

  @override
  String get snippetsAddTooltip => 'Aggiunga frammento';

  @override
  String get snippetsAddTitle => 'Nuovo frammento';

  @override
  String get snippetsSave => 'Salvi';

  @override
  String get snippetsCommandLabel => 'Comando';

  @override
  String get snippetsCommandHint => 'ad es. docker ps -a';

  @override
  String get snippetsNameLabel => 'Nome (facoltativo)';

  @override
  String get snippetsNameHint => 'ad es. Elenca tutti i container';

  @override
  String get snippetsCommandRequired => 'Il testo del comando è obbligatorio';

  @override
  String get snippetsDeleteTooltip => 'Elimini frammento';

  @override
  String get snippetsEmptyTitle => 'Nessun frammento ancora';

  @override
  String get snippetsEmptyMessage =>
      'Salvi i comandi usati di frequente e li inserisca o li esegua con un solo tocco.';

  @override
  String get snippetsLoadFailed => 'Impossibile caricare i frammenti';

  @override
  String get healthTitle => 'Stato della flotta';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total online';
  }

  @override
  String get healthProbing => 'Verifica in corso…';

  @override
  String get healthProbeTooltip => 'Esegua il controllo dello stato';

  @override
  String healthProbedAt(String time) {
    return 'Verificato alle $time';
  }

  @override
  String get healthMoodAllOnline => 'Tutti i sistemi nominali';

  @override
  String get healthMoodDegraded => 'Alcuni server non sono raggiungibili';

  @override
  String get healthMoodAllOffline => 'Tutti i server non raggiungibili';

  @override
  String healthOfflineServers(String names) {
    return 'Offline: $names';
  }

  @override
  String get healthNoData => 'Tocchi Aggiorna per verificare ogni server';

  @override
  String healthUptime(String brief) {
    return 'attivo $brief';
  }

  @override
  String healthLoad(String value) {
    return 'carico $value';
  }

  @override
  String get healthDiagIntro =>
      'Ecco il rapporto sullo stato della mia flotta:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online di $total server online.';
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
      'Analizzi i dati sullo stato, segnali qualsiasi anomalia (carico elevato, riavvii recenti) e suggerisca cosa controllare in seguito.';

  @override
  String get healthDiagnose => 'Diagnostica AI';

  @override
  String get healthStaleNote =>
      'Alcuni server sono andati offline dall\'ultima verifica.';

  @override
  String get auditTitle => 'Registro di controllo dei comandi';

  @override
  String get auditTileDesc => 'Comandi eseguiti dall\'agente AI';

  @override
  String get auditEmptyTitle => 'Nessuna voce di controllo ancora';

  @override
  String get auditEmptyMessage =>
      'I comandi eseguiti dall\'agente AI verranno registrati qui.';

  @override
  String get auditFilteredEmpty =>
      'Nessuna voce corrisponde al filtro corrente';

  @override
  String get auditFilterAllServers => 'Tutti i server';

  @override
  String get auditFilterAllModes => 'Tutte le modalità';

  @override
  String get auditFilterAllResults => 'Tutti i risultati';

  @override
  String get auditFilterConfirmed => 'Confermato';

  @override
  String get auditFilterAuto => 'Auto';

  @override
  String get auditFilterSuccess => 'Riuscito';

  @override
  String get auditFilterFailed => 'Non riuscito';

  @override
  String get auditModeConfirmed => 'Confermato';

  @override
  String get auditModeAuto => 'Auto';

  @override
  String get auditStatusSuccess => 'Riuscito';

  @override
  String get auditStatusFailed => 'Non riuscito';

  @override
  String get auditDangerousBadge => 'Pericoloso';

  @override
  String auditExitCode(int code) {
    return 'Codice di uscita $code';
  }

  @override
  String get auditOutputSummary => 'Riepilogo dell\'output';

  @override
  String get auditNoOutput => 'Nessun output';

  @override
  String get auditClearTooltip => 'Azzeri il registro di controllo';

  @override
  String get auditClearConfirmTitle => 'Azzera il registro di controllo';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Tutte le $count voci di controllo verranno rimosse definitivamente.';
  }

  @override
  String get auditClearAction => 'Azzera';

  @override
  String get auditCleared => 'Registro di controllo azzerato';

  @override
  String auditEntriesCount(int count) {
    return '$count voci';
  }

  @override
  String get serverActionDisconnect => 'Si disconnetta';

  @override
  String get exportChatAction => 'Esporti come Markdown';

  @override
  String get exportChatEmpty => 'Nulla da esportare ancora';

  @override
  String exportChatSuccess(String path) {
    return 'Conversazione esportata in $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get diagTitle => 'Diagnostica';

  @override
  String get diagTileDesc =>
      'Errori dell\'app ed esportazione della diagnostica';

  @override
  String get diagEmptyTitle => 'Nessun errore acquisito';

  @override
  String get diagEmptyMessage =>
      'Le eccezioni non gestite vengono registrate qui per facilitare le segnalazioni di problemi.';

  @override
  String diagEntriesCount(int count) {
    return '$count errori';
  }

  @override
  String get diagSourceFlutter => 'Errore UI';

  @override
  String get diagSourcePlatform => 'Errore di runtime';

  @override
  String get diagSourceZone => 'Attività asincrona';

  @override
  String get diagStackTrace => 'Stack trace';

  @override
  String get diagNoStackTrace => 'Nessuno stack trace';

  @override
  String get diagExportAction => 'Esporti il rapporto di diagnostica';

  @override
  String get diagExportEmpty =>
      'Nulla da segnalare: si esportano le informazioni di base';

  @override
  String diagExportSuccess(String path) {
    return 'Rapporto di diagnostica esportato in $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get diagPrivacyNote =>
      'Il contenuto della diagnostica è oscurato: non vengono incluse password, chiavi private o chiavi API.';

  @override
  String get diagClearTooltip => 'Azzeri i record degli errori';

  @override
  String get diagClearConfirmTitle => 'Azzera i record degli errori';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Tutti i $count record degli errori verranno rimossi definitivamente.';
  }

  @override
  String get diagClearAction => 'Azzera';

  @override
  String get diagCleared => 'Record degli errori azzerati';

  @override
  String get diagAppInfoTitle => 'Informazioni sull\'app';

  @override
  String get diagAppInfoVersion => 'Versione';

  @override
  String get diagAppInfoPlatform => 'Piattaforma';

  @override
  String get diagAppInfoLocale => 'Lingua';

  @override
  String get diagAppInfoStorage => 'Dimensione dei dati locali';

  @override
  String get authLockToggleTitle => 'Blocco biometrico';

  @override
  String get authLockToggleDesc =>
      'Richieda lo sblocco con impronta digitale o volto all\'apertura dell\'app';

  @override
  String get authLockEnableFailed =>
      'Verifica non riuscita: il blocco resta disattivato';

  @override
  String get authLockUnavailableDesc =>
      'Nessun dato biometrico registrato su questo dispositivo';

  @override
  String get authLockScreenTitle => 'ShellMind è bloccato';

  @override
  String get authLockScreenSubtitle => 'Verifichi per continuare';

  @override
  String get authLockUnlockAction => 'Sblocchi';

  @override
  String get authLockUnlockFailed => 'Verifica non riuscita: riprovi';

  @override
  String get terminalTabPickerTitle => 'Cambi terminale';

  @override
  String get terminalTabPickerSubtitle =>
      'Scelga un server da aprire come scheda del terminale: i server online si collegano subito, quelli offline compongono prima la connessione';

  @override
  String get terminalTabPickerEmpty => 'Nessun server configurato ancora';

  @override
  String get terminalTabNewTooltip => 'Nuova scheda del terminale';

  @override
  String get terminalTabCloseTooltip => 'Chiuda la scheda';

  @override
  String get hostKeyConfirmTitle => 'Considerare attendibile questo host?';

  @override
  String get hostKeyConfirmMessage =>
      'Questa è la prima connessione a questo server. Verifichi la sua impronta prima di considerarlo attendibile: questo protegge dagli attacchi man-in-the-middle.';

  @override
  String get hostKeyEndpointLabel => 'SERVER';

  @override
  String get hostKeyFingerprintLabel => 'IMPRONTA SHA-256';

  @override
  String get hostKeySecurityNote =>
      'Confronti l\'impronta con un valore ottenuto dall\'operatore del server tramite un canale sicuro. Considerare attendibile un\'impronta errata espone le Sue credenziali.';

  @override
  String get hostKeyTrustAndConnect => 'Si fidi e si connetta';

  @override
  String get hostKeyReject => 'Rifiuti';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Rifiuto automatico tra ${seconds}s: la fiducia viene registrata solo quando Lei conferma.';
  }

  @override
  String get hostKeyMismatchTitle => 'Chiave host modificata';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'La chiave presentata da $host:$port differisce da quella che Lei aveva considerato attendibile in precedenza. La connessione è stata bloccata: potrebbe trattarsi di un attacco man-in-the-middle oppure il server è stato reinstallato. Se ha verificato la nuova chiave, reimposti la fiducia dell\'host nella pagina di modifica del server e si riconnetta.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Connessione annullata: la chiave host non è stata considerata attendibile. Può connettersi di nuovo per esaminare l\'impronta.';

  @override
  String get serverResetTrustAction => 'Reimposti la fiducia dell\'host';

  @override
  String get serverResetTrustDesc =>
      'Rimuova l\'impronta salvata di questo server affinché la prossima connessione richieda di nuovo la conferma.';

  @override
  String get serverResetTrustConfirmTitle =>
      'Reimpostare la fiducia dell\'host?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'L\'impronta salvata per $identity:$port verrà rimossa. La prossima connessione Le chiederà di verificare di nuovo la chiave host.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Reimposti';

  @override
  String get serverResetTrustDone =>
      'Fiducia dell\'host reimpostata: si riconnetta per verificare di nuovo l\'impronta.';

  @override
  String get agentErrorNoTargetServer =>
      'Nessun server di destinazione disponibile';

  @override
  String get agentErrorExecFailed => 'Esecuzione del comando non riuscita';

  @override
  String get agentErrorConnectFailed =>
      'Connessione automatica al server non riuscita';

  @override
  String get agentErrorConnectAuthRequired =>
      'Nessuna credenziale salvata per questo server: la connessione automatica non è possibile';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Comando pericoloso ignorato: $command';
  }

  @override
  String get agentErrorUnexpected => 'Errore imprevisto';

  @override
  String get exportDocChatTitle => 'Esportazione chat Shell-Mind';

  @override
  String exportDocExportedAt(String time) {
    return 'Esportato il: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Messaggi: $count';
  }

  @override
  String get exportDocUserSection => 'Utente';

  @override
  String get exportDocAssistantSection => 'Assistente';

  @override
  String get exportDocToolSection => 'Esecuzione strumento';

  @override
  String get exportDocNoContent => '_(nessun contenuto)_';

  @override
  String get exportDocUnknownServer => 'Server sconosciuto';

  @override
  String exportDocExitCode(int code) {
    return 'Codice di uscita $code';
  }

  @override
  String get exportDocCommand => 'Comando';

  @override
  String get exportDocOutput => 'Output';

  @override
  String get exportDocErrorOutput => 'Output di errore';

  @override
  String get exportDocDiagTitle => 'Rapporto di diagnostica Shell-Mind';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Errori acquisiti: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Errori acquisiti';

  @override
  String get exportDocDiagNone => '(nessuno)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Riepilogo errore: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'Versione app: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Piattaforma: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Lingua: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Utilizzo dei dati locali: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'Controllo dei comandi AI (ultimi $limit riepiloghi)';
  }

  @override
  String get exportDocDiagSuccess => 'riuscito';

  @override
  String get exportDocDiagFailed => 'non riuscito';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'codice di uscita $code';
  }

  @override
  String get settingsTerminalScheme => 'Schema di colori del terminale';

  @override
  String get settingsTerminalSchemeDesc =>
      'Scelga la palette di colori ANSI per i terminali SSH.';

  @override
  String get settingsSectionDataTransfer => 'Importazione ed esportazione';

  @override
  String get transferSnippetsTitle => 'Frammenti di comando';

  @override
  String get transferServersTitle => 'Configurazioni dei server';

  @override
  String get transferExport => 'Esporti';

  @override
  String get transferImport => 'Importi';

  @override
  String get transferExportImport => 'Esportazione / Importazione';

  @override
  String get transferExportTitle => 'Esportazione';

  @override
  String get transferCopyJson => 'Copi JSON';

  @override
  String get transferCopied => 'Copiato negli appunti';

  @override
  String get transferImportHint => 'Incolli qui il JSON esportato…';

  @override
  String get transferSnippetsEmpty =>
      'Nessun frammento di comando da esportare.';

  @override
  String get transferServersEmpty => 'Nessun server da esportare.';

  @override
  String get transferImportNothing =>
      'Nessun elemento valido trovato nell\'importazione.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importati $count frammenti',
      one: 'Importato 1 frammento',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importati $count server',
      one: 'Importato 1 server',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Importazione non riuscita: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Esportazione non riuscita: $message';
  }

  @override
  String transferExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionsTitle => 'Conversazioni';

  @override
  String get sessionsNew => 'Nuova conversazione';

  @override
  String get sessionsSearch => 'Cerchi conversazioni…';

  @override
  String get sessionsEmpty => 'Nessuna conversazione ancora';

  @override
  String sessionsNoMatch(String query) {
    return 'Nessuna corrispondenza: \"$query\"';
  }

  @override
  String get sessionsRename => 'Rinomini';

  @override
  String get sessionsRenameHint => 'Titolo della conversazione';

  @override
  String get sessionsDelete => 'Elimini';

  @override
  String sessionsDeleteConfirm(String title) {
    return 'Eliminare \"$title\"? L\'operazione non può essere annullata.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi',
      one: '1 messaggio',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Notifiche';

  @override
  String get settingsNotificationsTitle => 'Avvisi in background';

  @override
  String get settingsNotificationsDesc =>
      'Avvisi quando una sessione SSH si interrompe o un\'attività AI termina mentre l\'app è in background.';

  @override
  String get sftpTitle => 'File';

  @override
  String get sftpNotConnected => 'Non connesso a questo server.';

  @override
  String get sftpLoading => 'Caricamento file…';

  @override
  String get sftpEmpty => 'Questa cartella è vuota.';

  @override
  String get sftpDownload => 'Scarica';

  @override
  String sftpDownloaded(String path, int size) {
    return 'Scaricato $path ($size byte)';
  }

  @override
  String get sftpDownloadFailed => 'Download non riuscito';

  @override
  String get sftpPreviewError => 'Anteprima non riuscita';

  @override
  String get sftpNewFolderName => 'Nuova cartella';

  @override
  String get sftpRefresh => 'Aggiorni';

  @override
  String get sftpDelete => 'Elimini';

  @override
  String sftpDeleteConfirm(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get sftpRename => 'Rinomini';

  @override
  String get sftpTooltip => 'Sfoglia file (SFTP)';

  @override
  String get terminalMoreTooltip => 'Altro';

  @override
  String get tunnelsTitle => 'Port forwarding';

  @override
  String get tunnelsEmpty => 'Nessun tunnel attivo.';

  @override
  String get tunnelsAddLocal => 'Inoltro locale';

  @override
  String get tunnelsAddRemote => 'Inoltro remoto';

  @override
  String get tunnelsLocalPort => 'Porta locale';

  @override
  String get tunnelsRemoteHost => 'Host remoto';

  @override
  String get tunnelsRemotePort => 'Porta remota';

  @override
  String get tunnelsAdd => 'Aggiunga';

  @override
  String get tunnelsClose => 'Chiuda';

  @override
  String get tunnelsTooltip => 'Port forwarding (tunnel SSH)';

  @override
  String get tunnelsError => 'Tunnel non riuscito';

  @override
  String get tunnelsInvalidPort =>
      'La porta deve essere compresa tra 1 e 65535.';

  @override
  String get settingsLanguageTitle => 'Lingua';
}
