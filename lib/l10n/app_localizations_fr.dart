// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Serveurs';

  @override
  String get navAiChat => 'Chat IA';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String get backToServers => 'Retour aux serveurs';

  @override
  String get serversTitle => 'Serveurs';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hôtes',
      one: '1 hôte',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Rechercher des serveurs…';

  @override
  String get serversAdd => 'Ajouter un serveur';

  @override
  String get serversEmpty => 'Aucun serveur pour l\'instant';

  @override
  String get serversEmptyHint =>
      'Ajoutez votre premier serveur SSH pour commencer.';

  @override
  String get serversDeleteConfirmTitle => 'Supprimer le serveur';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return 'Supprimer \"$name\" ?\n\n$identity:$port et ses identifiants enregistrés seront définitivement supprimés.';
  }

  @override
  String serversDeleted(String identity) {
    return '$identity supprimé';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Échec de la suppression : $message';
  }

  @override
  String get serversLoading => 'Chargement des serveurs';

  @override
  String get serversUngrouped => 'Non groupés';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'récents';

  @override
  String get serversQuickStart => 'Démarrage rapide';

  @override
  String get serversQuickStep1Title => 'Ajouter un hôte';

  @override
  String get serversQuickStep1Desc =>
      'Enregistrez un point de terminaison SSH avec une authentification par mot de passe ou par clé.';

  @override
  String get serversQuickStep2Title => 'Tester la connexion';

  @override
  String get serversQuickStep2Desc =>
      'Testez le port avant de valider — détecte rapidement les fautes de frappe.';

  @override
  String get serversQuickStep3Title => 'Se connecter';

  @override
  String get serversQuickStep3Desc =>
      'Ouvrez une session de terminal — PTY complet, couleurs et vim.';

  @override
  String serversNoMatch(String query) {
    return 'Aucun résultat : \"$query\"';
  }

  @override
  String get serversClearFilter => 'Effacer le filtre';

  @override
  String get serversReadError => 'Impossible de lire la liste des serveurs.';

  @override
  String get serverEditTitle => 'Ajouter un serveur';

  @override
  String get serverEditTitleEdit => 'Modifier le serveur';

  @override
  String get serverNotFound => 'Serveur introuvable';

  @override
  String get serverValidationNameRequired => 'Nom requis';

  @override
  String get serverValidationHostRequired => 'Hôte requis';

  @override
  String get serverValidationNoSpaces => 'Espaces non autorisés';

  @override
  String get serverValidationRequired => 'Requis';

  @override
  String get serverValidationNumeric => 'Numérique';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Nom d\'utilisateur requis';

  @override
  String get serverValidationPasswordRequired => 'Mot de passe requis';

  @override
  String get serverValidationPrivateKeyRequired => 'Clé privée requise';

  @override
  String serverAdded(String identity, int port) {
    return 'Serveur ajouté : $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Enregistré : $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Échec de l\'enregistrement : $message';
  }

  @override
  String get serverTestEnterHost => 'Saisissez d\'abord une adresse d\'hôte';

  @override
  String serverTestProbing(String host, int port) {
    return 'Test de $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — joignable';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — délai dépassé';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — refusé / injoignable';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — échec du test';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port échec de la négociation SSH';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port échec de l\'authentification - vérifiez le nom d\'utilisateur et les identifiants';
  }

  @override
  String get serverLoading => 'Chargement';

  @override
  String get serverSaveChanges => 'Enregistrer les modifications';

  @override
  String get serverSectionIdentity => 'Identité';

  @override
  String get serverSectionConnection => 'Connexion';

  @override
  String get serverSectionAuthentication => 'Authentification';

  @override
  String get serverFieldLabel => 'Libellé';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Groupe (facultatif)';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => 'Hôte';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Port';

  @override
  String get serverFieldUsername => 'Nom d\'utilisateur';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Mot de passe';

  @override
  String get serverFieldPasswordStored =>
      'Enregistré — laissez vide pour conserver';

  @override
  String get serverFieldPrivateKey => 'Clé privée (PEM)';

  @override
  String get serverFieldPassphrase => 'Phrase secrète de la clé (facultatif)';

  @override
  String get serverAuthPassword => 'Mot de passe';

  @override
  String get serverAuthPrivateKey => 'Clé privée';

  @override
  String get serverTestIdle => 'Appuyez sur \"Test\" pour tester la connexion';

  @override
  String get serverSecurityNote =>
      'Les identifiants sont chiffrés dans le keystore de l\'appareil — ils ne touchent jamais le stockage de métadonnées Hive et ne quittent jamais cet appareil.';

  @override
  String get serverTesting => 'Test en cours…';

  @override
  String get serverTest => 'Tester';

  @override
  String get serverSaving => 'Enregistrement…';

  @override
  String serverCopiedAddress(String address) {
    return '$address copié';
  }

  @override
  String get serverActions => 'Actions du serveur';

  @override
  String get serverActionConnect => 'Se connecter';

  @override
  String get serverActionEdit => 'Modifier';

  @override
  String get serverActionEditDetails => 'Modifier les détails';

  @override
  String get serverActionCopySsh => 'Copier la commande SSH';

  @override
  String get serverActionDelete => 'Supprimer';

  @override
  String get serverActionDeleteServer => 'Supprimer le serveur';

  @override
  String get serverOnline => 'En ligne';

  @override
  String get serverNeverConnected => 'Jamais connecté';

  @override
  String get serverJustNow => 'À l\'instant';

  @override
  String serverMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String serverHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String serverDaysAgo(int days) {
    return 'il y a $days j';
  }

  @override
  String get terminalHostNotFound => 'Hôte introuvable';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Aucun serveur enregistré ne correspond à l\'id \"$id\". Il a peut-être été supprimé.';
  }

  @override
  String get terminalBackToServers => 'Retour aux serveurs';

  @override
  String get terminalConnectionFailed => 'Échec de la connexion.';

  @override
  String get terminalSessionClosed => 'Session fermée';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'La connexion vers $name a été interrompue.';
  }

  @override
  String get terminalReconnect => 'Reconnecter';

  @override
  String get terminalAuthenticating => 'Authentification';

  @override
  String get terminalConnecting => 'Connexion';

  @override
  String get terminalResolvingHost => 'Résolution de l\'hôte…';

  @override
  String get terminalTooltipDisconnectBack => 'Déconnecter et revenir';

  @override
  String get terminalTooltipSmallerText => 'Texte plus petit';

  @override
  String get terminalTooltipLargerText => 'Texte plus grand';

  @override
  String get terminalTooltipDisconnect => 'Déconnecter';

  @override
  String get terminalRetryAvailable => 'Nouvel essai disponible';

  @override
  String get terminalStatusConnected => 'CONNECTÉ';

  @override
  String get terminalStatusOffline => 'HORS LIGNE';

  @override
  String get terminalStatusError => 'ERREUR';

  @override
  String get aiChatTitle => 'Assistant IA';

  @override
  String get aiChatStatusSetup => 'CONFIGURATION';

  @override
  String get aiChatStatusStreaming => 'DIFFUSION';

  @override
  String get aiChatStatusReady => 'PRÊT';

  @override
  String get aiChatClearConversation => 'Effacer la conversation';

  @override
  String get aiChatSuggestion1 =>
      'Expliquez ce que signifie la sortie de ls -la';

  @override
  String get aiChatSuggestion2 =>
      'Comment trouver quel processus utilise un port ?';

  @override
  String get aiChatSuggestion3 =>
      'Montrez-moi comment suivre les journaux avec tail et grep pour les erreurs';

  @override
  String get aiChatSuggestion4 =>
      'Écrivez une commande awk en une ligne pour additionner une colonne CSV';

  @override
  String get aiChatTryAsking => 'Essayez de demander';

  @override
  String get aiChatIntroTitle => 'Votre compagnon de terminal';

  @override
  String get aiChatIntroBody =>
      'Collez une commande, une erreur ou un extrait de sortie de journal. ShellMind explique ce qui s\'est passé, suggère la prochaine étape et rédige les commandes à votre place.';

  @override
  String get aiChatNoKeyTitle => 'Aucune clé API configurée';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Ajoutez votre clé API $provider pour réveiller l\'assistant. Elle est stockée chiffrée sur cet appareil et ne le quitte jamais, sauf pour appeler le modèle.';
  }

  @override
  String get aiChatOpenSettings => 'Ouvrir les paramètres IA';

  @override
  String get aiChatCheckingCredentials => 'Vérification des identifiants';

  @override
  String get aiChatInputHint => 'Posez votre question…';

  @override
  String get aiChatInputDisabled => 'Définissez une clé API pour commencer';

  @override
  String get aiChatError => 'Erreur';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Copié';

  @override
  String get aiChatCopy => 'Copier';

  @override
  String get aiChatThinking => 'Réflexion…';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSearchTooltip => 'Rechercher dans les paramètres';

  @override
  String get settingsStable => 'STABLE';

  @override
  String get settingsSectionAppearance => 'Apparence et langue';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'Anglais';

  @override
  String get settingsSectionAiProvider => 'Fournisseur d\'IA';

  @override
  String get settingsSectionAiAgent => 'Agent IA';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Serveurs';

  @override
  String get settingsSectionAboutUpdate => 'À propos et mise à jour';

  @override
  String get settingsSectionStoragePrivacy => 'Stockage et confidentialité';

  @override
  String get settingsSectionResources => 'Ressources';

  @override
  String get settingsTileSecrets => 'Secrets';

  @override
  String get settingsTileEncrypted => 'Chiffré';

  @override
  String get settingsTileLocalCache => 'Cache local';

  @override
  String get settingsTileClearData => 'Effacer toutes les données';

  @override
  String get settingsTileLicenses => 'Licences open source';

  @override
  String get settingsTileReportIssue => 'Signaler un problème';

  @override
  String get settingsFooter =>
      'SSH + assistant IA pour des flux de travail modernes';

  @override
  String get settingsSecretsDialogTitle => 'Secrets et chiffrement';

  @override
  String get settingsSecretsDialogBody =>
      'Les identifiants — mots de passe de serveur, clés privées et clés API d\'IA — sont toujours chiffrés au repos à l\'aide du keystore de la plateforme (Android Keystore / iOS Keychain). Cette protection est prévue par conception et ne peut pas être désactivée. Pour modifier un identifiant, modifiez-le ou supprimez-le sur la page de modification du serveur ou dans les paramètres IA.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Fermer';

  @override
  String get settingsCacheDialogTitle => 'Cache local';

  @override
  String get settingsCacheHiveData => 'Données de l\'application';

  @override
  String get settingsCacheDownloads => 'Mises à jour téléchargées';

  @override
  String get settingsCacheTotal => 'Total';

  @override
  String get settingsCacheDialogHint =>
      'Effacer le cache de téléchargement supprime les paquets de mise à jour téléchargés (APK). Vos serveurs, clés et historique des conversations sont conservés.';

  @override
  String get settingsCacheClearDownloads =>
      'Effacer le cache de téléchargement';

  @override
  String settingsCacheCleared(String freed) {
    return 'Espace libéré : $freed';
  }

  @override
  String get settingsClearDataTitle => 'Effacer toutes les données ?';

  @override
  String get settingsClearDataMessage =>
      'Cela supprime définitivement tous les serveurs, identifiants enregistrés, clés IA, historiques de conversation et préférences de cet appareil. Cette action est irréversible.';

  @override
  String get settingsClearDataConfirm => 'Tout effacer';

  @override
  String get settingsDataCleared => 'Toutes les données ont été effacées';

  @override
  String settingsClearDataFailed(String message) {
    return 'Impossible d\'effacer les données : $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Lien du problème copié dans le presse-papiers.';

  @override
  String get settingsAboutGithub => 'Dépôt GitHub';

  @override
  String get settingsHideIp => 'Masquer les adresses IP';

  @override
  String get settingsHideIpDesc =>
      'Masquer les adresses IP dans la liste des serveurs et les pages IA';

  @override
  String get serverMaskedAddress => 'Adresse masquée';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return 'Clé API $provider';
  }

  @override
  String get aiSettingsKeySet => 'définie';

  @override
  String get aiSettingsKeyNotConfigured => 'non configurée';

  @override
  String get aiSettingsGetApiKey => 'Obtenir une clé API';

  @override
  String get aiSettingsTemperature => 'Température';

  @override
  String get aiSettingsRemoveKey => 'Supprimer la clé';

  @override
  String aiSettingsKeySaved(String provider) {
    return 'Clé API $provider enregistrée en toute sécurité.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return 'Supprimer la clé $provider ?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'L\'assistant cessera de fonctionner pour ce fournisseur jusqu\'à l\'ajout d\'une nouvelle clé.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Supprimer';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Obtenir une clé $provider';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Ouvrez la console du fournisseur dans votre navigateur pour créer une clé API, puis collez-la ici.';

  @override
  String get aiSettingsClose => 'Fermer';

  @override
  String get aiSettingsLinkCopied => 'Lien copié dans le presse-papiers.';

  @override
  String get aiSettingsCopyLink => 'Copier le lien';

  @override
  String get aiSettingsKeyConfigured => 'Clé configurée';

  @override
  String get aiSettingsNotConfigured => 'Non configurée';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Mettre à jour la clé $provider';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Ajouter une clé $provider';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Stockée chiffrée sur cet appareil. Utilisée uniquement pour appeler le fournisseur d\'IA.';

  @override
  String get aiSettingsApiKeyHint => 'Clé API…';

  @override
  String get aiSettingsSave => 'Enregistrer';

  @override
  String get modelDescFastAffordable => 'Rapide et abordable';

  @override
  String get modelDescMostCapable => 'Le plus performant';

  @override
  String get modelDescLegacyFast => 'Rapide (ancien)';

  @override
  String get modelDescGeneralConversation => 'Conversation générale';

  @override
  String get modelDescAdvancedReasoning => 'Raisonnement avancé';

  @override
  String get modelDescFastResponse => 'Réponse rapide';

  @override
  String get modelDescBalanced => 'Équilibré';

  @override
  String get modelDescFreeFast => 'Gratuit et rapide';

  @override
  String get modelDescEnhanced => 'Amélioré';

  @override
  String get modelDescStandard => 'Standard';

  @override
  String get modelDescLightweight => 'Léger';

  @override
  String get modelDescRlEnhanced => 'Amélioré par RL';

  @override
  String get aiModelsTitle => 'Modèle';

  @override
  String get aiModelsRefresh => 'Actualiser la liste des modèles';

  @override
  String get aiModelsAddCustom => 'Ajouter un modèle personnalisé';

  @override
  String get aiModelsAddCustomHint => 'ID du modèle, ex. deepseek-chat';

  @override
  String get aiModelsAdd => 'Ajouter';

  @override
  String get aiModelsCustomBadge => 'Personnalisé';

  @override
  String get aiModelsFetchFailed =>
      'Impossible de récupérer les modèles — affichage de la liste intégrée.';

  @override
  String get aiModelsRemoveCustom => 'Supprimer le modèle personnalisé';

  @override
  String get aiModelsEmpty => 'Aucun modèle';

  @override
  String get aiModelsInvalidId => 'Saisissez un ID de modèle.';

  @override
  String get aiModelsDuplicate => 'Ce modèle figure déjà dans la liste.';

  @override
  String get aiModelsPickerTitle => 'Choisir un modèle';

  @override
  String get aiModelsSearchHint => 'Rechercher des modèles';

  @override
  String get aiModelsSearchEmpty =>
      'Aucun modèle ne correspond à votre recherche.';

  @override
  String get aiProvidersAddTile => 'Ajouter un fournisseur personnalisé';

  @override
  String get aiProvidersAddTitle => 'Ajouter un fournisseur personnalisé';

  @override
  String get aiProvidersFieldName => 'Nom';

  @override
  String get aiProvidersFieldNameHint => 'ex. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'URL de base';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Modèle par défaut (facultatif)';

  @override
  String get aiProvidersFieldModelHint => 'ID du modèle, ex. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Ajouter';

  @override
  String get aiProvidersInvalidInput => 'Saisissez un nom et une URL de base.';

  @override
  String get aiProvidersInvalidUrl =>
      'L\'URL de base doit commencer par http:// ou https://';

  @override
  String get aiProvidersDuplicateName =>
      'Un fournisseur portant ce nom existe déjà.';

  @override
  String get aiProvidersAdded => 'Fournisseur personnalisé ajouté.';

  @override
  String get aiProvidersAddFailed =>
      'Impossible d\'ajouter le fournisseur — vérifiez les champs.';

  @override
  String get aiProvidersDeleteTile => 'Supprimer le fournisseur personnalisé';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return 'Supprimer $provider ?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Sa clé API enregistrée, son modèle mémorisé et ses modèles personnalisés seront également supprimés. Les fournisseurs intégrés ne peuvent pas être supprimés.';

  @override
  String get aiProvidersDeleteConfirm => 'Supprimer';

  @override
  String get aiProvidersPickerTitle => 'Choisir un fournisseur';

  @override
  String get updateVersion => 'Version';

  @override
  String get updateSoftwareUpdate => 'Mise à jour du logiciel';

  @override
  String get updateChecking => 'VÉRIFICATION';

  @override
  String get updateUpToDate => 'À JOUR';

  @override
  String get updateCheckAgain => 'Vérifier à nouveau';

  @override
  String get updateReady => 'PRÊT';

  @override
  String get updateNew => 'NOUVEAU';

  @override
  String get updateCheck => 'VÉRIFIER';

  @override
  String get updateAwaitingResponse => 'En attente de réponse';

  @override
  String get updateAlreadyLatest => 'Déjà sur la dernière version';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'La v$version est la version la plus récente publiée sur GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'Version actuelle v$current — dernière version distante v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Vérifié il y a $timeAgo';
  }

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get updatePre => 'PRÉ';

  @override
  String get updateDownloadInstall => 'Télécharger et installer';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateApkHint =>
      'L\'installation d\'APK n\'est prise en charge que sur Android. Le fichier peut toutefois être téléchargé ici.';

  @override
  String updateDownloading(String tag) {
    return 'Téléchargement de $tag';
  }

  @override
  String get updateSize => 'taille';

  @override
  String get updateRate => 'débit';

  @override
  String get updateEta => 'temps restant';

  @override
  String get updateElapsed => 'écoulé';

  @override
  String get updateCancel => 'Annuler';

  @override
  String get updateKeepForeground => 'Garder l\'application au premier plan';

  @override
  String get updateDownloadComplete => 'Téléchargement terminé';

  @override
  String get updateInstallHint =>
      'Android vous demandera de confirmer. ShellMind se ferme pendant l\'exécution du programme d\'installation ; vos serveurs et votre historique sont conservés.';

  @override
  String get updateLaunching => 'Lancement...';

  @override
  String get updateInstallNow => 'Installer maintenant';

  @override
  String get updateDelete => 'Supprimer';

  @override
  String updateInstallTitle(String tag) {
    return 'Installer $tag ?';
  }

  @override
  String get updateInstallMessage =>
      'Le programme d\'installation de paquets du système va s\'ouvrir. ShellMind se ferme pendant l\'installation et rouvre sur la nouvelle version.';

  @override
  String get updateNotNow => 'Pas maintenant';

  @override
  String get updateInstall => 'Installer';

  @override
  String get updateCheckFailed => 'La vérification de mise à jour a échoué.';

  @override
  String get updateErrorTitleNoReleases => 'Aucune version';

  @override
  String get updateErrorTitleGeneric =>
      'Échec de la vérification de mise à jour';

  @override
  String get updateErrNoReleases =>
      'Aucune version n\'a encore été publiée pour ShellMind.';

  @override
  String get updateErrRateLimit =>
      'La limite de débit de l\'API GitHub a été atteinte. Veuillez réessayer plus tard.';

  @override
  String get updateErrTimeout =>
      'La requête vers GitHub a expiré. Vérifiez votre connexion et réessayez.';

  @override
  String get updateErrNetwork =>
      'Impossible de joindre GitHub. Vérifiez votre connexion réseau.';

  @override
  String get updateErrAuth => 'GitHub a rejeté la requête de mise à jour.';

  @override
  String get updateErrPermission => 'La requête de mise à jour a été refusée.';

  @override
  String get updateErrStorage =>
      'Espace de stockage insuffisant pour terminer la mise à jour.';

  @override
  String get updateErrDigestMismatch =>
      'La mise à jour téléchargée a échoué au contrôle d\'intégrité SHA-256 et a été supprimée. Veuillez relancer le téléchargement.';

  @override
  String get updateErrDigestMissing =>
      'Le paquet de mise à jour n\'a pas d\'empreinte d\'intégrité publiée, la mise à jour a donc été refusée. Veuillez réessayer plus tard.';

  @override
  String get updateRetry => 'Réessayer';

  @override
  String get updateDismiss => 'Ignorer';

  @override
  String updateReleaseNotes(String tag) {
    return 'Version $tag';
  }

  @override
  String get updateNotesLabel => 'notes';

  @override
  String get updateNewVersionAvailable => 'Nouvelle version disponible';

  @override
  String get updateRemindLater => 'Me le rappeler plus tard';

  @override
  String get updateCancelDownload => 'Annuler le téléchargement';

  @override
  String updateInstallTag(String tag) {
    return 'Installer $tag';
  }

  @override
  String get updateInstallLaterFromSettings =>
      'Installer plus tard depuis les paramètres';

  @override
  String get updateCouldNotComplete =>
      'La mise à jour n\'a pas pu être terminée.';

  @override
  String get updateClose => 'Fermer';

  @override
  String get updatePromptInstallHint =>
      'Android ferme ShellMind pendant l\'exécution du programme d\'installation. Les serveurs, les clés et l\'historique des conversations sont conservés.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String get commonNothingToShow => 'Rien à afficher ici pour le moment.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle =>
      'Exécution automatique des commandes';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Autoriser l\'agent IA à exécuter les commandes analysées sans demander à chaque fois';

  @override
  String get settingsAiAutoConnectTitle =>
      'Connexion automatique des serveurs par l\'IA';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Autoriser l\'assistant IA à se connecter automatiquement aux serveurs configurés mais hors ligne et à y exécuter des commandes (les identifiants enregistrés seront utilisés)';

  @override
  String get settingsAiMaxAutoLoopsTitle =>
      'Itérations maximales de la boucle automatique';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Limiter le nombre d\'exécutions automatiques de commandes par réponse';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Nombre maximal de séries de commandes que l\'IA peut exécuter par tâche';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Il s\'agit de la limite supérieure de séries d\'exécution par tâche IA — pas du nombre de tentatives de reconnexion SSH (celui-ci se trouve dans la section SSH).';

  @override
  String get terminalAskAi => 'Demander à l\'IA';

  @override
  String get terminalAskAiSubtitle =>
      'Envoyer le texte sélectionné à l\'assistant IA';

  @override
  String get terminalTooltipAskAi => 'Demander à l\'IA';

  @override
  String get aiChatNoConnection =>
      'Connectez-vous d\'abord à un terminal de serveur';

  @override
  String get aiChatAnalyzePrompt =>
      'Analysez la sortie de commande ci-dessus, expliquez ce que signifie le résultat et proposez des suggestions de suivi si nécessaire.';

  @override
  String get aiExecuteButton => 'Exécuter sur le serveur';

  @override
  String get aiExecuteTitle => 'Confirmer l\'exécution de la commande';

  @override
  String get aiExecuteConfirmButton => 'Exécuter';

  @override
  String get aiExecuteConfirmAnyway => 'Exécuter quand même';

  @override
  String get aiExecuteDangerWarning => '⚠ Commande dangereuse';

  @override
  String get aiExecuteDangerText =>
      'Cette commande peut être destructrice et entraîner une perte de données ou des dommages au système.';

  @override
  String get aiExecuteCommandLabel => 'Commande à exécuter :';

  @override
  String get aiExecuteTargetServer => 'Serveur(s) cible(s) :';

  @override
  String get aiExecuteSelectServer => 'Sélectionner le(s) serveur(s) cible(s)';

  @override
  String get aiExecuteNoServer => 'Connectez-vous d\'abord à un serveur';

  @override
  String get aiExecuteAtLeastOne => 'Sélectionnez au moins un serveur';

  @override
  String get aiExecuteSelectHint =>
      'Choisissez le(s) serveur(s) sur le(s)quel(s) exécuter cette commande';

  @override
  String aiExecuteRunCount(int count) {
    return 'Exécuter ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Tout sélectionner';

  @override
  String get aiExecuteClearSelection => 'Effacer';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return 'en ligne depuis $hours h $minutes min';
  }

  @override
  String get aiExecuteSuccess => 'Commande exécutée avec succès';

  @override
  String get aiExecuteFailed => 'Échec de l\'exécution de la commande';

  @override
  String get aiServerManageTitle => 'Serveurs';

  @override
  String get aiServerManageSubtitle =>
      'Connectez des serveurs pour que l\'assistant IA puisse agir';

  @override
  String aiServerOnlineCount(int count) {
    return '$count en ligne';
  }

  @override
  String get aiServerDone => 'Terminé';

  @override
  String get aiServerConnecting => 'Connexion…';

  @override
  String get aiServerOffline => 'Hors ligne';

  @override
  String get aiServerNoCredential =>
      'Aucun identifiant enregistré — enregistrez d\'abord le mot de passe ou la clé sur la page du serveur';

  @override
  String get aiServerConnectFailed => 'Échec de la connexion';

  @override
  String get aiToolResultCommand => 'Commande';

  @override
  String get aiToolResultOutput => 'Sortie de la commande';

  @override
  String aiToolResultExitCode(int code) {
    return 'Code de sortie : $code';
  }

  @override
  String get aiToolResultElapsed => 'Temps écoulé';

  @override
  String get aiToolResultAnalyzeButton => 'Laisser l\'IA analyser la sortie';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total lignes supplémentaires';
  }

  @override
  String get aiToolResultExpandedHide => 'Masquer la sortie';

  @override
  String get aiToolResultStderrLabel => 'Sortie d\'erreur :';

  @override
  String get aiContextToggleAttach => 'Joindre le contexte du terminal';

  @override
  String get aiContextToggleDetach => 'Contexte du terminal joint';

  @override
  String get aiContextBadge => 'Contexte';

  @override
  String aiContextLines(int lines) {
    return '$lines lignes du terminal';
  }

  @override
  String get aiAgentStop => 'Arrêter le mode automatique';

  @override
  String get aiAgentExecuting => 'Exécution…';

  @override
  String get aiAgentDefaultServer => 'serveur';

  @override
  String get aiTimelineTitle => 'Chronologie d\'exécution';

  @override
  String get aiTimelineOpen => 'Chronologie d\'exécution';

  @override
  String get aiTimelineEmpty => 'Aucune commande exécutée pour le moment';

  @override
  String get aiTimelineEmptyHint =>
      'Exécutez des commandes via le chat ou le mode automatique et la chaîne complète apparaîtra ici.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes',
      one: '1 commande',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réussies',
      one: '1 réussie',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échouées',
      one: '1 échouée',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Démarré $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Terminé $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Code de sortie : $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Aucun code de sortie';

  @override
  String get aiTimelineOutput => 'Sortie';

  @override
  String get aiTimelineOutputEmpty => 'Aucune sortie';

  @override
  String get aiTimelineErrorOutput => 'Sortie d\'erreur';

  @override
  String get aiTimelineRunning => 'En cours…';

  @override
  String get aiTimelineClose => 'Fermer';

  @override
  String get sshReconnectToggle =>
      'Reconnexion automatique en cas de déconnexion';

  @override
  String get sshReconnectToggleDesc =>
      'Réessayer les sessions SSH interrompues avec un délai exponentiel';

  @override
  String get sshReconnectMaxAttempts => 'Tentatives de reconnexion maximales';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Nombre maximal de tentatives de reconnexion automatique après une déconnexion — 0 signifie réessayer jusqu\'à réussir';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Illimité';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Reconnexion (tentative $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Reconnexion (tentative $attempt sur $max)';
  }

  @override
  String get sshReconnectGaveUp => 'La reconnexion automatique a abandonné';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'Impossible de joindre $name après $max tentatives.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'Impossible de joindre $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Réessayer maintenant';

  @override
  String get sshReconnectStopAuto => 'Arrêter';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Reconnecté à $name';
  }

  @override
  String get snippetsTitle => 'Extraits de commande';

  @override
  String get snippetsSubtitle =>
      'Enregistrez des commandes pour les réutiliser rapidement';

  @override
  String get snippetsAddTooltip => 'Ajouter un extrait';

  @override
  String get snippetsAddTitle => 'Nouvel extrait';

  @override
  String get snippetsSave => 'Enregistrer';

  @override
  String get snippetsCommandLabel => 'Commande';

  @override
  String get snippetsCommandHint => 'ex. docker ps -a';

  @override
  String get snippetsNameLabel => 'Nom (facultatif)';

  @override
  String get snippetsNameHint => 'ex. Liste de tous les conteneurs';

  @override
  String get snippetsCommandRequired => 'Le texte de la commande est requis';

  @override
  String get snippetsDeleteTooltip => 'Supprimer l\'extrait';

  @override
  String get snippetsEmptyTitle => 'Aucun extrait pour le moment';

  @override
  String get snippetsEmptyMessage =>
      'Enregistrez les commandes fréquemment utilisées pour les insérer ou les exécuter en un seul appui.';

  @override
  String get snippetsLoadFailed => 'Impossible de charger les extraits';

  @override
  String get healthTitle => 'État de la flotte';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total en ligne';
  }

  @override
  String get healthProbing => 'Test en cours…';

  @override
  String get healthProbeTooltip => 'Lancer le contrôle d\'état';

  @override
  String healthProbedAt(String time) {
    return 'Vérifié à $time';
  }

  @override
  String get healthMoodAllOnline => 'Tous les systèmes sont opérationnels';

  @override
  String get healthMoodDegraded => 'Certains serveurs sont injoignables';

  @override
  String get healthMoodAllOffline => 'Tous les serveurs sont injoignables';

  @override
  String healthOfflineServers(String names) {
    return 'Hors ligne : $names';
  }

  @override
  String get healthNoData =>
      'Appuyez sur actualiser pour vérifier chaque serveur';

  @override
  String healthUptime(String brief) {
    return 'en service $brief';
  }

  @override
  String healthLoad(String value) {
    return 'charge $value';
  }

  @override
  String get healthDiagIntro => 'Voici le rapport d\'état de ma flotte :';

  @override
  String healthDiagStats(int online, int total) {
    return '$online serveurs en ligne sur $total.';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name : hors ligne';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name : en ligne ($details)';
  }

  @override
  String get healthDiagOutro =>
      'Analysez les données d\'état, signalez toute anomalie (charge élevée, redémarrages récents) et suggérez ce qu\'il faut vérifier ensuite.';

  @override
  String get healthDiagnose => 'Diagnostics IA';

  @override
  String get healthStaleNote =>
      'Certains serveurs sont passés hors ligne depuis la dernière vérification.';

  @override
  String get auditTitle => 'Journal d\'audit des commandes';

  @override
  String get auditTileDesc => 'Commandes exécutées par l\'agent IA';

  @override
  String get auditEmptyTitle => 'Aucune entrée d\'audit pour le moment';

  @override
  String get auditEmptyMessage =>
      'Les commandes exécutées par l\'agent IA seront enregistrées ici.';

  @override
  String get auditFilteredEmpty =>
      'Aucune entrée ne correspond au filtre actuel';

  @override
  String get auditFilterAllServers => 'Tous les serveurs';

  @override
  String get auditFilterAllModes => 'Tous les modes';

  @override
  String get auditFilterAllResults => 'Tous les résultats';

  @override
  String get auditFilterConfirmed => 'Confirmé';

  @override
  String get auditFilterAuto => 'Auto';

  @override
  String get auditFilterSuccess => 'Réussite';

  @override
  String get auditFilterFailed => 'Échec';

  @override
  String get auditModeConfirmed => 'Confirmé';

  @override
  String get auditModeAuto => 'Auto';

  @override
  String get auditStatusSuccess => 'Réussite';

  @override
  String get auditStatusFailed => 'Échec';

  @override
  String get auditDangerousBadge => 'Dangereuse';

  @override
  String auditExitCode(int code) {
    return 'Code de sortie $code';
  }

  @override
  String get auditOutputSummary => 'Résumé de la sortie';

  @override
  String get auditNoOutput => 'Aucune sortie';

  @override
  String get auditClearTooltip => 'Effacer le journal d\'audit';

  @override
  String get auditClearConfirmTitle => 'Effacer le journal d\'audit';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Les $count entrées d\'audit seront définitivement supprimées.';
  }

  @override
  String get auditClearAction => 'Effacer';

  @override
  String get auditCleared => 'Journal d\'audit effacé';

  @override
  String auditEntriesCount(int count) {
    return '$count entrées';
  }

  @override
  String get serverActionDisconnect => 'Déconnecter';

  @override
  String get exportChatAction => 'Exporter en Markdown';

  @override
  String get exportChatEmpty => 'Rien à exporter pour le moment';

  @override
  String exportChatSuccess(String path) {
    return 'Conversation exportée vers $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get diagTitle => 'Diagnostics';

  @override
  String get diagTileDesc =>
      'Erreurs de l\'application et export de diagnostic';

  @override
  String get diagEmptyTitle => 'Aucune erreur capturée';

  @override
  String get diagEmptyMessage =>
      'Les exceptions non interceptées sont enregistrées ici pour faciliter les signalements de problèmes.';

  @override
  String diagEntriesCount(int count) {
    return '$count erreurs';
  }

  @override
  String get diagSourceFlutter => 'Erreur d\'interface';

  @override
  String get diagSourcePlatform => 'Erreur d\'exécution';

  @override
  String get diagSourceZone => 'Tâche asynchrone';

  @override
  String get diagStackTrace => 'Trace de pile';

  @override
  String get diagNoStackTrace => 'Aucune trace de pile';

  @override
  String get diagExportAction => 'Exporter le rapport de diagnostic';

  @override
  String get diagExportEmpty =>
      'Rien à signaler — export des informations de base';

  @override
  String diagExportSuccess(String path) {
    return 'Rapport de diagnostic exporté vers $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get diagPrivacyNote =>
      'Le contenu du diagnostic est caviardé — aucun mot de passe, aucune clé privée ni clé API n\'y figure.';

  @override
  String get diagClearTooltip => 'Effacer les enregistrements d\'erreur';

  @override
  String get diagClearConfirmTitle => 'Effacer les enregistrements d\'erreur';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Les $count enregistrements d\'erreur seront définitivement supprimés.';
  }

  @override
  String get diagClearAction => 'Effacer';

  @override
  String get diagCleared => 'Enregistrements d\'erreur effacés';

  @override
  String get diagAppInfoTitle => 'Informations sur l\'application';

  @override
  String get diagAppInfoVersion => 'Version';

  @override
  String get diagAppInfoPlatform => 'Plateforme';

  @override
  String get diagAppInfoLocale => 'Langue';

  @override
  String get diagAppInfoStorage => 'Taille des données locales';

  @override
  String get authLockToggleTitle => 'Verrouillage biométrique';

  @override
  String get authLockToggleDesc =>
      'Exiger le déverrouillage par empreinte digitale ou reconnaissance faciale à l\'ouverture de l\'application';

  @override
  String get authLockEnableFailed =>
      'Échec de la vérification — le verrouillage reste désactivé';

  @override
  String get authLockUnavailableDesc =>
      'Aucune donnée biométrique enregistrée sur cet appareil';

  @override
  String get authLockScreenTitle => 'ShellMind est verrouillé';

  @override
  String get authLockScreenSubtitle => 'Vérifiez votre identité pour continuer';

  @override
  String get authLockUnlockAction => 'Déverrouiller';

  @override
  String get authLockUnlockFailed => 'Échec de la vérification — réessayez';

  @override
  String get terminalTabPickerTitle => 'Changer de terminal';

  @override
  String get terminalTabPickerSubtitle =>
      'Choisissez un serveur à ouvrir dans un onglet de terminal — les serveurs en ligne se connectent instantanément, les serveurs hors ligne établissent d\'abord la connexion';

  @override
  String get terminalTabPickerEmpty => 'Aucun serveur configuré pour le moment';

  @override
  String get terminalTabNewTooltip => 'Nouvel onglet de terminal';

  @override
  String get terminalTabCloseTooltip => 'Fermer l\'onglet';

  @override
  String get hostKeyConfirmTitle => 'Faire confiance à cet hôte ?';

  @override
  String get hostKeyConfirmMessage =>
      'Il s\'agit de la première connexion à ce serveur. Vérifiez son empreinte avant de lui faire confiance — cela protège contre les attaques de l\'homme du milieu.';

  @override
  String get hostKeyEndpointLabel => 'SERVEUR';

  @override
  String get hostKeyFingerprintLabel => 'EMPREINTE SHA-256';

  @override
  String get hostKeySecurityNote =>
      'Comparez l\'empreinte à une valeur obtenue auprès de l\'opérateur du serveur par un canal externe. Faire confiance à une mauvaise empreinte expose vos identifiants.';

  @override
  String get hostKeyTrustAndConnect => 'Faire confiance et se connecter';

  @override
  String get hostKeyReject => 'Refuser';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Refus automatique dans $seconds s — la confiance n\'est enregistrée que si vous confirmez.';
  }

  @override
  String get hostKeyMismatchTitle => 'La clé de l\'hôte a changé';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'La clé présentée par $host:$port diffère de celle à laquelle vous aviez accordé votre confiance. La connexion a été bloquée — il peut s\'agir d\'une attaque de l\'homme du milieu, ou le serveur a été réinstallé. Si vous avez vérifié la nouvelle clé, réinitialisez la confiance de l\'hôte sur la page de modification du serveur et reconnectez-vous.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Connexion annulée — la clé de l\'hôte n\'a pas été approuvée. Vous pouvez vous reconnecter pour examiner l\'empreinte.';

  @override
  String get serverResetTrustAction => 'Réinitialiser la confiance de l\'hôte';

  @override
  String get serverResetTrustDesc =>
      'Oublier l\'empreinte enregistrée de ce serveur afin que la prochaine connexion redemande une confirmation.';

  @override
  String get serverResetTrustConfirmTitle =>
      'Réinitialiser la confiance de l\'hôte ?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'L\'empreinte enregistrée pour $identity:$port sera supprimée. La prochaine connexion vous demandera à nouveau de vérifier la clé de l\'hôte.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Réinitialiser';

  @override
  String get serverResetTrustDone =>
      'Confiance de l\'hôte réinitialisée — reconnectez-vous pour vérifier à nouveau l\'empreinte.';

  @override
  String get agentErrorNoTargetServer => 'Aucun serveur cible disponible';

  @override
  String get agentErrorExecFailed => 'Échec de l\'exécution de la commande';

  @override
  String get agentErrorConnectFailed =>
      'Échec de la connexion automatique au serveur';

  @override
  String get agentErrorConnectAuthRequired =>
      'Aucun identifiant enregistré pour ce serveur — la connexion automatique est impossible';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Commande dangereuse ignorée : $command';
  }

  @override
  String get agentErrorUnexpected => 'Erreur inattendue';

  @override
  String get exportDocChatTitle => 'Export de conversation Shell-Mind';

  @override
  String exportDocExportedAt(String time) {
    return 'Exporté à : $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Messages : $count';
  }

  @override
  String get exportDocUserSection => 'Utilisateur';

  @override
  String get exportDocAssistantSection => 'Assistant';

  @override
  String get exportDocToolSection => 'Exécution d\'outil';

  @override
  String get exportDocNoContent => '_(aucun contenu)_';

  @override
  String get exportDocUnknownServer => 'Serveur inconnu';

  @override
  String exportDocExitCode(int code) {
    return 'Code de sortie $code';
  }

  @override
  String get exportDocCommand => 'Commande';

  @override
  String get exportDocOutput => 'Sortie';

  @override
  String get exportDocErrorOutput => 'Sortie d\'erreur';

  @override
  String get exportDocDiagTitle => 'Rapport de diagnostic Shell-Mind';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Erreurs capturées : $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Erreurs capturées';

  @override
  String get exportDocDiagNone => '(aucune)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Résumé de l\'erreur : $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'Version de l\'application : $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Plateforme : $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Langue : $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Utilisation des données locales : $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'Audit des commandes IA ($limit derniers résumés)';
  }

  @override
  String get exportDocDiagSuccess => 'réussite';

  @override
  String get exportDocDiagFailed => 'échec';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'code de sortie $code';
  }

  @override
  String get settingsTerminalScheme => 'Palette de couleurs du terminal';

  @override
  String get settingsTerminalSchemeDesc =>
      'Choisissez la palette de couleurs ANSI pour les terminaux SSH.';

  @override
  String get settingsSectionDataTransfer => 'Import et export';

  @override
  String get transferSnippetsTitle => 'Extraits de commande';

  @override
  String get transferServersTitle => 'Configurations de serveur';

  @override
  String get transferExport => 'Exporter';

  @override
  String get transferImport => 'Importer';

  @override
  String get transferExportImport => 'Exporter / Importer';

  @override
  String get transferExportTitle => 'Exporter';

  @override
  String get transferCopyJson => 'Copier le JSON';

  @override
  String get transferCopied => 'Copié dans le presse-papiers';

  @override
  String get transferImportHint => 'Collez ici le JSON exporté…';

  @override
  String get transferSnippetsEmpty => 'Aucun extrait de commande à exporter.';

  @override
  String get transferServersEmpty => 'Aucun serveur à exporter.';

  @override
  String get transferImportNothing =>
      'Aucun élément valide trouvé dans l\'import.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count extraits importés',
      one: '1 extrait importé',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serveurs importés',
      one: '1 serveur importé',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Échec de l\'import : $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Échec de l\'export : $message';
  }

  @override
  String transferExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionsTitle => 'Conversations';

  @override
  String get sessionsNew => 'Nouvelle conversation';

  @override
  String get sessionsSearch => 'Rechercher des conversations…';

  @override
  String get sessionsEmpty => 'Aucune conversation pour le moment';

  @override
  String sessionsNoMatch(String query) {
    return 'Aucun résultat : \"$query\"';
  }

  @override
  String get sessionsRename => 'Renommer';

  @override
  String get sessionsRenameHint => 'Titre de la conversation';

  @override
  String get sessionsDelete => 'Supprimer';

  @override
  String sessionsDeleteConfirm(String title) {
    return 'Supprimer \"$title\" ? Cette action est irréversible.';
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
  String get settingsNotificationsTitle => 'Alertes en arrière-plan';

  @override
  String get settingsNotificationsDesc =>
      'Notifier lorsqu\'une session SSH est interrompue ou qu\'une tâche IA se termine pendant que l\'application est en arrière-plan.';

  @override
  String get sftpTitle => 'Fichiers';

  @override
  String get sftpNotConnected => 'Non connecté à ce serveur.';

  @override
  String get sftpLoading => 'Chargement des fichiers…';

  @override
  String get sftpEmpty => 'Ce dossier est vide.';

  @override
  String get sftpDownload => 'Télécharger';

  @override
  String sftpDownloaded(String path, int size) {
    return 'Téléchargé : $path ($size octets)';
  }

  @override
  String get sftpDownloadFailed => 'Échec du téléchargement';

  @override
  String get sftpPreviewError => 'Échec de l\'aperçu';

  @override
  String get sftpNewFolderName => 'Nouveau dossier';

  @override
  String get sftpRefresh => 'Actualiser';

  @override
  String get sftpDelete => 'Supprimer';

  @override
  String sftpDeleteConfirm(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String get sftpRename => 'Renommer';

  @override
  String get sftpTooltip => 'Parcourir les fichiers (SFTP)';

  @override
  String get terminalMoreTooltip => 'Plus';

  @override
  String get tunnelsTitle => 'Redirection de port';

  @override
  String get tunnelsEmpty => 'Aucun tunnel actif.';

  @override
  String get tunnelsAddLocal => 'Redirection locale';

  @override
  String get tunnelsAddRemote => 'Redirection distante';

  @override
  String get tunnelsLocalPort => 'Port local';

  @override
  String get tunnelsRemoteHost => 'Hôte distant';

  @override
  String get tunnelsRemotePort => 'Port distant';

  @override
  String get tunnelsAdd => 'Ajouter';

  @override
  String get tunnelsClose => 'Fermer';

  @override
  String get tunnelsTooltip => 'Redirection de port (tunnel SSH)';

  @override
  String get tunnelsError => 'Échec du tunnel';

  @override
  String get tunnelsInvalidPort =>
      'Le port doit être compris entre 1 et 65535.';

  @override
  String get settingsLanguageTitle => 'Langue';
}
