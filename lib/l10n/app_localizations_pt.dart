// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Servidores';

  @override
  String get navAiChat => 'Chat AI';

  @override
  String get navSettings => 'Configurações';

  @override
  String get pageNotFound => 'Página não encontrada';

  @override
  String get backToServers => 'Voltar aos Servidores';

  @override
  String get serversTitle => 'Servidores';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servidores',
      one: '1 servidor',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Buscar servidores…';

  @override
  String get serversAdd => 'Adicionar servidor';

  @override
  String get serversEmpty => 'Nenhum servidor ainda';

  @override
  String get serversEmptyHint =>
      'Adicione seu primeiro servidor SSH para começar.';

  @override
  String get serversDeleteConfirmTitle => 'Excluir servidor';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return 'Excluir \"$name\"?\n\n$identity:$port e suas credenciais armazenadas serão removidos permanentemente.';
  }

  @override
  String serversDeleted(String identity) {
    return '$identity removido';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Falha ao excluir: $message';
  }

  @override
  String get serversLoading => 'Carregando servidores';

  @override
  String get serversUngrouped => 'Sem grupo';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'recentes';

  @override
  String get serversQuickStart => 'Início rápido';

  @override
  String get serversQuickStep1Title => 'Adicionar um host';

  @override
  String get serversQuickStep1Desc =>
      'Registre um endpoint SSH com autenticação por senha ou chave.';

  @override
  String get serversQuickStep2Title => 'Testar conexão';

  @override
  String get serversQuickStep2Desc =>
      'Verifique a porta antes de confirmar — detecta erros de digitação rapidamente.';

  @override
  String get serversQuickStep3Title => 'Conectar';

  @override
  String get serversQuickStep3Desc =>
      'Abra uma sessão de terminal — PTY completo, cores e vim.';

  @override
  String serversNoMatch(String query) {
    return 'Nenhum resultado: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Limpar filtro';

  @override
  String get serversReadError => 'Não foi possível ler a lista de servidores.';

  @override
  String get serverEditTitle => 'Adicionar servidor';

  @override
  String get serverEditTitleEdit => 'Editar servidor';

  @override
  String get serverNotFound => 'Servidor não encontrado';

  @override
  String get serverValidationNameRequired => 'Nome obrigatório';

  @override
  String get serverValidationHostRequired => 'Host obrigatório';

  @override
  String get serverValidationNoSpaces => 'Espaços não permitidos';

  @override
  String get serverValidationRequired => 'Obrigatório';

  @override
  String get serverValidationNumeric => 'Numérico';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Nome de usuário obrigatório';

  @override
  String get serverValidationPasswordRequired => 'Senha obrigatória';

  @override
  String get serverValidationPrivateKeyRequired => 'Chave privada obrigatória';

  @override
  String serverAdded(String identity, int port) {
    return 'Servidor adicionado: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Salvo: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Falha ao salvar: $message';
  }

  @override
  String get serverTestEnterHost => 'Informe um endereço de host primeiro';

  @override
  String serverTestProbing(String host, int port) {
    return 'Verificando $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — acessível';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — tempo esgotado';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — recusado / inacessível';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — falha na verificação';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port falha no handshake SSH';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port falha na autenticação - verifique o nome de usuário e as credenciais';
  }

  @override
  String get serverLoading => 'Carregando';

  @override
  String get serverSaveChanges => 'Salvar alterações';

  @override
  String get serverSectionIdentity => 'Identidade';

  @override
  String get serverSectionConnection => 'Conexão';

  @override
  String get serverSectionAuthentication => 'Autenticação';

  @override
  String get serverFieldLabel => 'Rótulo';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Grupo (opcional)';

  @override
  String get serverFieldGroupHint => 'produção';

  @override
  String get serverFieldHost => 'Host';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Porta';

  @override
  String get serverFieldUsername => 'Nome de usuário';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Senha';

  @override
  String get serverFieldPasswordStored =>
      'Armazenada — deixe em branco para manter';

  @override
  String get serverFieldPrivateKey => 'Chave privada (PEM)';

  @override
  String get serverFieldPassphrase => 'Senha da chave (opcional)';

  @override
  String get serverAuthPassword => 'Senha';

  @override
  String get serverAuthPrivateKey => 'Chave privada';

  @override
  String get serverTestIdle => 'Toque em \"Testar\" para verificar a conexão';

  @override
  String get serverSecurityNote =>
      'As credenciais são criptografadas no keystore do dispositivo — nunca passam pelo armazenamento de metadados do Hive nem saem deste dispositivo.';

  @override
  String get serverTesting => 'Testando…';

  @override
  String get serverTest => 'Testar';

  @override
  String get serverSaving => 'Salvando…';

  @override
  String serverCopiedAddress(String address) {
    return '$address copiado';
  }

  @override
  String get serverActions => 'Ações do servidor';

  @override
  String get serverActionConnect => 'Conectar';

  @override
  String get serverActionEdit => 'Editar';

  @override
  String get serverActionEditDetails => 'Editar detalhes';

  @override
  String get serverActionCopySsh => 'Copiar comando SSH';

  @override
  String get serverActionDelete => 'Excluir';

  @override
  String get serverActionDeleteServer => 'Excluir servidor';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverNeverConnected => 'Nunca conectado';

  @override
  String get serverJustNow => 'Agora mesmo';

  @override
  String serverMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String serverHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String serverDaysAgo(int days) {
    return 'há $days d';
  }

  @override
  String get terminalHostNotFound => 'Host não encontrado';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Nenhum servidor salvo corresponde ao id \"$id\". Ele pode ter sido excluído.';
  }

  @override
  String get terminalBackToServers => 'Voltar aos servidores';

  @override
  String get terminalConnectionFailed => 'Falha na conexão.';

  @override
  String get terminalSessionClosed => 'Sessão encerrada';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'A conexão com $name foi encerrada.';
  }

  @override
  String get terminalReconnect => 'Reconectar';

  @override
  String get terminalAuthenticating => 'Autenticando';

  @override
  String get terminalConnecting => 'Conectando';

  @override
  String get terminalResolvingHost => 'Resolvendo host…';

  @override
  String get terminalTooltipDisconnectBack => 'Desconectar e voltar';

  @override
  String get terminalTooltipSmallerText => 'Texto menor';

  @override
  String get terminalTooltipLargerText => 'Texto maior';

  @override
  String get terminalTooltipDisconnect => 'Desconectar';

  @override
  String get terminalRetryAvailable => 'Nova tentativa disponível';

  @override
  String get terminalStatusConnected => 'CONECTADO';

  @override
  String get terminalStatusOffline => 'OFFLINE';

  @override
  String get terminalStatusError => 'ERRO';

  @override
  String get aiChatTitle => 'Assistente AI';

  @override
  String get aiChatStatusSetup => 'CONFIGURAÇÃO';

  @override
  String get aiChatStatusStreaming => 'TRANSMITINDO';

  @override
  String get aiChatStatusReady => 'PRONTO';

  @override
  String get aiChatClearConversation => 'Limpar conversa';

  @override
  String get aiChatSuggestion1 => 'Explique o que a saída de ls -la significa';

  @override
  String get aiChatSuggestion2 =>
      'Como descubro qual processo está usando uma porta?';

  @override
  String get aiChatSuggestion3 =>
      'Mostre como acompanhar logs com tail e procurar erros com grep';

  @override
  String get aiChatSuggestion4 =>
      'Escreva um one-liner em awk para somar uma coluna CSV';

  @override
  String get aiChatTryAsking => 'Tente perguntar';

  @override
  String get aiChatIntroTitle => 'Seu companheiro de terminal';

  @override
  String get aiChatIntroBody =>
      'Cole um comando, um erro ou um trecho de saída de log. O ShellMind explica o que aconteceu, sugere o próximo passo e escreve os comandos para você.';

  @override
  String get aiChatNoKeyTitle => 'Nenhuma chave de API configurada';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Adicione sua chave de API da $provider para ativar o assistente. Ela fica armazenada criptografada neste dispositivo e nunca sai dele, exceto para chamar o modelo.';
  }

  @override
  String get aiChatOpenSettings => 'Abrir configurações AI';

  @override
  String get aiChatCheckingCredentials => 'Verificando credenciais';

  @override
  String get aiChatInputHint => 'Pergunte qualquer coisa…';

  @override
  String get aiChatInputDisabled => 'Defina uma chave de API para começar';

  @override
  String get aiChatError => 'Erro';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Copiado';

  @override
  String get aiChatCopy => 'Copiar';

  @override
  String get aiChatThinking => 'Pensando…';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSearchTooltip => 'Buscar configurações';

  @override
  String get settingsStable => 'ESTÁVEL';

  @override
  String get settingsSectionAppearance => 'Aparência e Idioma';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'Provedor AI';

  @override
  String get settingsSectionAiAgent => 'Agente AI';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Servidores';

  @override
  String get settingsSectionAboutUpdate => 'Sobre e Atualização';

  @override
  String get settingsSectionStoragePrivacy => 'Armazenamento e Privacidade';

  @override
  String get settingsSectionResources => 'Recursos';

  @override
  String get settingsTileSecrets => 'Segredos';

  @override
  String get settingsTileEncrypted => 'Criptografado';

  @override
  String get settingsTileLocalCache => 'Cache local';

  @override
  String get settingsTileClearData => 'Limpar todos os dados';

  @override
  String get settingsTileLicenses => 'Licenças de código aberto';

  @override
  String get settingsTileReportIssue => 'Reportar um problema';

  @override
  String get settingsFooter =>
      'SSH + Assistente AI para fluxos de trabalho modernos';

  @override
  String get settingsSecretsDialogTitle => 'Segredos e criptografia';

  @override
  String get settingsSecretsDialogBody =>
      'As credenciais — senhas de servidor, chaves privadas e chaves de API AI — são sempre criptografadas em repouso usando o keystore da plataforma (Android Keystore / iOS Keychain). Essa proteção existe por design e não pode ser desativada. Para alterar uma credencial, edite-a ou remova-a na página de edição do servidor ou nas configurações AI.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Fechar';

  @override
  String get settingsCacheDialogTitle => 'Cache local';

  @override
  String get settingsCacheHiveData => 'Dados do app';

  @override
  String get settingsCacheDownloads => 'Atualizações baixadas';

  @override
  String get settingsCacheTotal => 'Total';

  @override
  String get settingsCacheDialogHint =>
      'Limpar o cache de downloads remove os pacotes de atualização baixados (APKs). Seus servidores, chaves e histórico de conversas são mantidos.';

  @override
  String get settingsCacheClearDownloads => 'Limpar cache de downloads';

  @override
  String settingsCacheCleared(String freed) {
    return '$freed liberados';
  }

  @override
  String get settingsClearDataTitle => 'Limpar todos os dados?';

  @override
  String get settingsClearDataMessage =>
      'Isso exclui permanentemente todos os servidores, credenciais armazenadas, chaves AI, histórico de conversas e preferências deste dispositivo. Essa ação não pode ser desfeita.';

  @override
  String get settingsClearDataConfirm => 'Limpar tudo';

  @override
  String get settingsDataCleared => 'Todos os dados foram limpos';

  @override
  String settingsClearDataFailed(String message) {
    return 'Não foi possível limpar os dados: $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Link do problema copiado para a área de transferência.';

  @override
  String get settingsAboutGithub => 'Repositório no GitHub';

  @override
  String get settingsHideIp => 'Ocultar endereços IP';

  @override
  String get settingsHideIpDesc =>
      'Mascara os endereços IP na lista de servidores e nas páginas AI';

  @override
  String get serverMaskedAddress => 'Endereço oculto';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return 'Chave de API da $provider';
  }

  @override
  String get aiSettingsKeySet => 'definida';

  @override
  String get aiSettingsKeyNotConfigured => 'não configurada';

  @override
  String get aiSettingsGetApiKey => 'Obter uma chave de API';

  @override
  String get aiSettingsTemperature => 'Temperatura';

  @override
  String get aiSettingsRemoveKey => 'Remover chave';

  @override
  String aiSettingsKeySaved(String provider) {
    return 'Chave de API da $provider salva com segurança.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return 'Remover a chave da $provider?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'O assistente deixará de funcionar para este provedor até que uma nova chave seja adicionada.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Remover';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Obter uma chave da $provider';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Abra o console do provedor no seu navegador para criar uma chave de API e depois cole-a aqui.';

  @override
  String get aiSettingsClose => 'Fechar';

  @override
  String get aiSettingsLinkCopied =>
      'Link copiado para a área de transferência.';

  @override
  String get aiSettingsCopyLink => 'Copiar link';

  @override
  String get aiSettingsKeyConfigured => 'Chave configurada';

  @override
  String get aiSettingsNotConfigured => 'Não configurada';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Atualizar a chave da $provider';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Adicionar chave da $provider';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Armazenada criptografada neste dispositivo. Usada apenas para chamar o provedor AI.';

  @override
  String get aiSettingsApiKeyHint => 'Chave de API…';

  @override
  String get aiSettingsSave => 'Salvar';

  @override
  String get modelDescFastAffordable => 'Rápido e acessível';

  @override
  String get modelDescMostCapable => 'Mais capaz';

  @override
  String get modelDescLegacyFast => 'Legado rápido';

  @override
  String get modelDescGeneralConversation => 'Conversa geral';

  @override
  String get modelDescAdvancedReasoning => 'Raciocínio avançado';

  @override
  String get modelDescFastResponse => 'Resposta rápida';

  @override
  String get modelDescBalanced => 'Equilibrado';

  @override
  String get modelDescFreeFast => 'Gratuito e rápido';

  @override
  String get modelDescEnhanced => 'Aprimorado';

  @override
  String get modelDescStandard => 'Padrão';

  @override
  String get modelDescLightweight => 'Leve';

  @override
  String get modelDescRlEnhanced => 'Aprimorado com RL';

  @override
  String get aiModelsTitle => 'Modelo';

  @override
  String get aiModelsRefresh => 'Atualizar lista de modelos';

  @override
  String get aiModelsAddCustom => 'Adicionar modelo personalizado';

  @override
  String get aiModelsAddCustomHint => 'ID do modelo, ex.: deepseek-chat';

  @override
  String get aiModelsAdd => 'Adicionar';

  @override
  String get aiModelsCustomBadge => 'Personalizado';

  @override
  String get aiModelsFetchFailed =>
      'Não foi possível buscar os modelos — exibindo a lista integrada.';

  @override
  String get aiModelsRemoveCustom => 'Remover modelo personalizado';

  @override
  String get aiModelsEmpty => 'Nenhum modelo';

  @override
  String get aiModelsInvalidId => 'Informe um ID de modelo.';

  @override
  String get aiModelsDuplicate => 'Este modelo já está na lista.';

  @override
  String get aiModelsPickerTitle => 'Escolher modelo';

  @override
  String get aiModelsSearchHint => 'Buscar modelos';

  @override
  String get aiModelsSearchEmpty => 'Nenhum modelo corresponde à sua busca.';

  @override
  String get aiProvidersAddTile => 'Adicionar provedor personalizado';

  @override
  String get aiProvidersAddTitle => 'Adicionar provedor personalizado';

  @override
  String get aiProvidersFieldName => 'Nome';

  @override
  String get aiProvidersFieldNameHint => 'ex.: SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'URL base';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Modelo padrão (opcional)';

  @override
  String get aiProvidersFieldModelHint => 'ID do modelo, ex.: deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Adicionar';

  @override
  String get aiProvidersInvalidInput => 'Informe um nome e uma URL base.';

  @override
  String get aiProvidersInvalidUrl =>
      'A URL base deve começar com http:// ou https://';

  @override
  String get aiProvidersDuplicateName => 'Já existe um provedor com este nome.';

  @override
  String get aiProvidersAdded => 'Provedor personalizado adicionado.';

  @override
  String get aiProvidersAddFailed =>
      'Não foi possível adicionar o provedor — verifique os dados.';

  @override
  String get aiProvidersDeleteTile => 'Remover provedor personalizado';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return 'Remover $provider?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Sua chave de API armazenada, o modelo lembrado e os modelos personalizados também serão removidos. Provedores integrados não podem ser excluídos.';

  @override
  String get aiProvidersDeleteConfirm => 'Remover';

  @override
  String get aiProvidersPickerTitle => 'Escolher provedor';

  @override
  String get updateVersion => 'Versão';

  @override
  String get updateSoftwareUpdate => 'Atualização de software';

  @override
  String get updateChecking => 'VERIFICANDO';

  @override
  String get updateUpToDate => 'ATUALIZADO';

  @override
  String get updateCheckAgain => 'Verificar novamente';

  @override
  String get updateReady => 'PRONTO';

  @override
  String get updateNew => 'NOVO';

  @override
  String get updateCheck => 'VERIFICAR';

  @override
  String get updateAwaitingResponse => 'Aguardando resposta';

  @override
  String get updateAlreadyLatest => 'Já está na versão mais recente';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version é a versão mais recente publicada no GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'Executando v$current — a versão remota mais recente é v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Verificado $timeAgo';
  }

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get updatePre => 'PRÉ';

  @override
  String get updateDownloadInstall => 'Baixar e instalar';

  @override
  String get updateLater => 'Depois';

  @override
  String get updateApkHint =>
      'A instalação de APK só é suportada no Android. O arquivo ainda pode ser baixado aqui.';

  @override
  String updateDownloading(String tag) {
    return 'Baixando $tag';
  }

  @override
  String get updateSize => 'tamanho';

  @override
  String get updateRate => 'taxa';

  @override
  String get updateEta => 'tempo restante';

  @override
  String get updateElapsed => 'decorrido';

  @override
  String get updateCancel => 'Cancelar';

  @override
  String get updateKeepForeground => 'Mantenha o app em primeiro plano';

  @override
  String get updateDownloadComplete => 'Download concluído';

  @override
  String get updateInstallHint =>
      'O Android pedirá sua confirmação. O ShellMind fecha enquanto o instalador é executado; seus servidores e histórico são preservados.';

  @override
  String get updateLaunching => 'Iniciando...';

  @override
  String get updateInstallNow => 'Instalar agora';

  @override
  String get updateDelete => 'Excluir';

  @override
  String updateInstallTitle(String tag) {
    return 'Instalar $tag?';
  }

  @override
  String get updateInstallMessage =>
      'O instalador de pacotes do sistema será aberto. O ShellMind fecha durante a instalação e reabre na nova versão.';

  @override
  String get updateNotNow => 'Agora não';

  @override
  String get updateInstall => 'Instalar';

  @override
  String get updateCheckFailed => 'A verificação de atualização falhou.';

  @override
  String get updateErrorTitleNoReleases => 'Nenhuma versão';

  @override
  String get updateErrorTitleGeneric => 'Falha na verificação de atualização';

  @override
  String get updateErrNoReleases =>
      'Nenhuma versão foi publicada para o ShellMind ainda.';

  @override
  String get updateErrRateLimit =>
      'O limite de taxa da API do GitHub foi atingido. Tente novamente mais tarde.';

  @override
  String get updateErrTimeout =>
      'A solicitação ao GitHub expirou. Verifique sua conexão e tente novamente.';

  @override
  String get updateErrNetwork =>
      'Não foi possível acessar o GitHub. Verifique sua conexão de rede.';

  @override
  String get updateErrAuth => 'O GitHub rejeitou a solicitação de atualização.';

  @override
  String get updateErrPermission => 'A solicitação de atualização foi negada.';

  @override
  String get updateErrStorage =>
      'Espaço de armazenamento insuficiente para concluir a atualização.';

  @override
  String get updateErrDigestMismatch =>
      'A atualização baixada falhou na verificação de integridade SHA-256 e foi excluída. Tente baixar novamente.';

  @override
  String get updateErrDigestMissing =>
      'O pacote de atualização não tem um resumo de integridade publicado, então a atualização foi recusada. Tente novamente mais tarde.';

  @override
  String get updateRetry => 'Tentar novamente';

  @override
  String get updateDismiss => 'Dispensar';

  @override
  String updateReleaseNotes(String tag) {
    return 'Versão $tag';
  }

  @override
  String get updateNotesLabel => 'notas';

  @override
  String get updateNewVersionAvailable => 'Nova versão disponível';

  @override
  String get updateRemindLater => 'Lembrar mais tarde';

  @override
  String get updateCancelDownload => 'Cancelar download';

  @override
  String updateInstallTag(String tag) {
    return 'Instalar $tag';
  }

  @override
  String get updateInstallLaterFromSettings =>
      'Instalar depois nas configurações';

  @override
  String get updateCouldNotComplete => 'A atualização não pôde ser concluída.';

  @override
  String get updateClose => 'Fechar';

  @override
  String get updatePromptInstallHint =>
      'O Android fecha o ShellMind enquanto o instalador é executado. Servidores, chaves e histórico de conversas são preservados.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonNoData => 'Sem dados';

  @override
  String get commonNothingToShow => 'Nada para mostrar aqui ainda.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'Executar comandos automaticamente';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Permitir que o agente AI execute comandos analisados sem perguntar a cada vez';

  @override
  String get settingsAiAutoConnectTitle =>
      'Conexão automática de servidores pela AI';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Permitir que o assistente AI se conecte automaticamente a servidores configurados mas offline e execute comandos neles (as credenciais salvas serão usadas)';

  @override
  String get settingsAiMaxAutoLoopsTitle =>
      'Máximo de iterações do loop automático';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Limitar o número de execuções automáticas de comandos por resposta';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Máximo de rodadas de comandos que a AI pode executar por tarefa';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Este é o limite superior de rodadas de execução por tarefa AI — não o número de tentativas de reconexão SSH (isso fica em SSH).';

  @override
  String get terminalAskAi => 'Perguntar à AI';

  @override
  String get terminalAskAiSubtitle =>
      'Enviar o texto selecionado para o assistente AI';

  @override
  String get terminalTooltipAskAi => 'Perguntar à AI';

  @override
  String get aiChatNoConnection =>
      'Conecte-se a um terminal de servidor primeiro';

  @override
  String get aiChatAnalyzePrompt =>
      'Analise a saída do comando acima, explique o que o resultado significa e dê sugestões de acompanhamento quando necessário.';

  @override
  String get aiExecuteButton => 'Executar no servidor';

  @override
  String get aiExecuteTitle => 'Confirmar execução do comando';

  @override
  String get aiExecuteConfirmButton => 'Executar';

  @override
  String get aiExecuteConfirmAnyway => 'Executar mesmo assim';

  @override
  String get aiExecuteDangerWarning => '⚠ Comando perigoso';

  @override
  String get aiExecuteDangerText =>
      'Este comando pode ser destrutivo e causar perda de dados ou danos ao sistema.';

  @override
  String get aiExecuteCommandLabel => 'Comando a executar:';

  @override
  String get aiExecuteTargetServer => 'Servidor(es) de destino:';

  @override
  String get aiExecuteSelectServer => 'Selecionar servidor(es) de destino';

  @override
  String get aiExecuteNoServer => 'Conecte-se a um servidor primeiro';

  @override
  String get aiExecuteAtLeastOne => 'Selecione pelo menos um servidor';

  @override
  String get aiExecuteSelectHint =>
      'Escolha o(s) servidor(es) para executar este comando';

  @override
  String aiExecuteRunCount(int count) {
    return 'Executar ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Selecionar tudo';

  @override
  String get aiExecuteClearSelection => 'Limpar';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours h $minutes min online';
  }

  @override
  String get aiExecuteSuccess => 'Comando executado com sucesso';

  @override
  String get aiExecuteFailed => 'Falha na execução do comando';

  @override
  String get aiServerManageTitle => 'Servidores';

  @override
  String get aiServerManageSubtitle =>
      'Conecte servidores para o assistente AI operar';

  @override
  String aiServerOnlineCount(int count) {
    return '$count online';
  }

  @override
  String get aiServerDone => 'Concluído';

  @override
  String get aiServerConnecting => 'Conectando…';

  @override
  String get aiServerOffline => 'Offline';

  @override
  String get aiServerNoCredential =>
      'Nenhuma credencial armazenada — salve a senha ou a chave na página do servidor primeiro';

  @override
  String get aiServerConnectFailed => 'Falha na conexão';

  @override
  String get aiToolResultCommand => 'Comando';

  @override
  String get aiToolResultOutput => 'Saída do comando';

  @override
  String aiToolResultExitCode(int code) {
    return 'Código de saída: $code';
  }

  @override
  String get aiToolResultElapsed => 'Tempo decorrido';

  @override
  String get aiToolResultAnalyzeButton => 'Deixar a AI analisar a saída';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total linhas a mais';
  }

  @override
  String get aiToolResultExpandedHide => 'Ocultar saída';

  @override
  String get aiToolResultStderrLabel => 'Saída de erro:';

  @override
  String get aiContextToggleAttach => 'Anexar contexto do terminal';

  @override
  String get aiContextToggleDetach => 'Contexto do terminal anexado';

  @override
  String get aiContextBadge => 'Contexto';

  @override
  String aiContextLines(int lines) {
    return '$lines linhas do terminal';
  }

  @override
  String get aiAgentStop => 'Parar modo automático';

  @override
  String get aiAgentExecuting => 'Executando…';

  @override
  String get aiAgentDefaultServer => 'servidor';

  @override
  String get aiTimelineTitle => 'Linha do tempo de execução';

  @override
  String get aiTimelineOpen => 'Linha do tempo de execução';

  @override
  String get aiTimelineEmpty => 'Nenhum comando executado ainda';

  @override
  String get aiTimelineEmptyHint =>
      'Execute comandos pelo chat ou modo automático e a cadeia completa aparecerá aqui.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rodadas',
      one: '1 rodada',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comandos',
      one: '1 comando',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bem-sucedidos',
      one: '1 bem-sucedido',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count falharam',
      one: '1 falhou',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Iniciado $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Encerrado $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Código de saída: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Sem código de saída';

  @override
  String get aiTimelineOutput => 'Saída';

  @override
  String get aiTimelineOutputEmpty => 'Sem saída';

  @override
  String get aiTimelineErrorOutput => 'Saída de erro';

  @override
  String get aiTimelineRunning => 'Executando…';

  @override
  String get aiTimelineClose => 'Fechar';

  @override
  String get sshReconnectToggle => 'Reconectar automaticamente ao desconectar';

  @override
  String get sshReconnectToggleDesc =>
      'Tentar novamente sessões SSH interrompidas com backoff exponencial';

  @override
  String get sshReconnectMaxAttempts => 'Máximo de tentativas de reconexão';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Máximo de tentativas automáticas de reconexão após uma desconexão — 0 significa tentar até conseguir';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Ilimitado';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Reconectando (tentativa $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Reconectando (tentativa $attempt de $max)';
  }

  @override
  String get sshReconnectGaveUp => 'A reconexão automática desistiu';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'Não foi possível alcançar $name após $max tentativas.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'Não foi possível alcançar $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Tentar novamente agora';

  @override
  String get sshReconnectStopAuto => 'Parar';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Reconectado a $name';
  }

  @override
  String get snippetsTitle => 'Trechos de comando';

  @override
  String get snippetsSubtitle => 'Salve comandos para reutilização rápida';

  @override
  String get snippetsAddTooltip => 'Adicionar trecho';

  @override
  String get snippetsAddTitle => 'Novo trecho';

  @override
  String get snippetsSave => 'Salvar';

  @override
  String get snippetsCommandLabel => 'Comando';

  @override
  String get snippetsCommandHint => 'ex.: docker ps -a';

  @override
  String get snippetsNameLabel => 'Nome (opcional)';

  @override
  String get snippetsNameHint => 'ex.: Listar todos os contêineres';

  @override
  String get snippetsCommandRequired => 'O texto do comando é obrigatório';

  @override
  String get snippetsDeleteTooltip => 'Excluir trecho';

  @override
  String get snippetsEmptyTitle => 'Nenhum trecho ainda';

  @override
  String get snippetsEmptyMessage =>
      'Salve comandos usados com frequência e insira-os ou execute-os com um toque.';

  @override
  String get snippetsLoadFailed => 'Não foi possível carregar os trechos';

  @override
  String get healthTitle => 'Saúde da frota';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total online';
  }

  @override
  String get healthProbing => 'Verificando…';

  @override
  String get healthProbeTooltip => 'Executar verificação de saúde';

  @override
  String healthProbedAt(String time) {
    return 'Verificado em $time';
  }

  @override
  String get healthMoodAllOnline => 'Todos os sistemas normais';

  @override
  String get healthMoodDegraded => 'Alguns servidores estão inacessíveis';

  @override
  String get healthMoodAllOffline => 'Todos os servidores inacessíveis';

  @override
  String healthOfflineServers(String names) {
    return 'Offline: $names';
  }

  @override
  String get healthNoData => 'Toque em atualizar para verificar cada servidor';

  @override
  String healthUptime(String brief) {
    return 'ativo $brief';
  }

  @override
  String healthLoad(String value) {
    return 'carga $value';
  }

  @override
  String get healthDiagIntro =>
      'Aqui está o relatório de saúde da minha frota:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online de $total servidores online.';
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
      'Analise os dados de saúde, sinalize qualquer anormalidade (carga alta, reinicializações recentes) e sugira o que verificar em seguida.';

  @override
  String get healthDiagnose => 'Diagnóstico AI';

  @override
  String get healthStaleNote =>
      'Alguns servidores ficaram offline desde a última verificação.';

  @override
  String get auditTitle => 'Registro de auditoria de comandos';

  @override
  String get auditTileDesc => 'Comandos executados pelo agente AI';

  @override
  String get auditEmptyTitle => 'Nenhum registro de auditoria ainda';

  @override
  String get auditEmptyMessage =>
      'Os comandos executados pelo agente AI serão registrados aqui.';

  @override
  String get auditFilteredEmpty =>
      'Nenhum registro corresponde ao filtro atual';

  @override
  String get auditFilterAllServers => 'Todos os servidores';

  @override
  String get auditFilterAllModes => 'Todos os modos';

  @override
  String get auditFilterAllResults => 'Todos os resultados';

  @override
  String get auditFilterConfirmed => 'Confirmado';

  @override
  String get auditFilterAuto => 'Automático';

  @override
  String get auditFilterSuccess => 'Sucesso';

  @override
  String get auditFilterFailed => 'Falhou';

  @override
  String get auditModeConfirmed => 'Confirmado';

  @override
  String get auditModeAuto => 'Automático';

  @override
  String get auditStatusSuccess => 'Sucesso';

  @override
  String get auditStatusFailed => 'Falhou';

  @override
  String get auditDangerousBadge => 'Perigoso';

  @override
  String auditExitCode(int code) {
    return 'Código de saída $code';
  }

  @override
  String get auditOutputSummary => 'Resumo da saída';

  @override
  String get auditNoOutput => 'Sem saída';

  @override
  String get auditClearTooltip => 'Limpar registro de auditoria';

  @override
  String get auditClearConfirmTitle => 'Limpar registro de auditoria';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Todos os $count registros de auditoria serão removidos permanentemente.';
  }

  @override
  String get auditClearAction => 'Limpar';

  @override
  String get auditCleared => 'Registro de auditoria limpo';

  @override
  String auditEntriesCount(int count) {
    return '$count registros';
  }

  @override
  String get serverActionDisconnect => 'Desconectar';

  @override
  String get exportChatAction => 'Exportar como Markdown';

  @override
  String get exportChatEmpty => 'Nada para exportar ainda';

  @override
  String exportChatSuccess(String path) {
    return 'Conversa exportada para $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get diagTitle => 'Diagnóstico';

  @override
  String get diagTileDesc => 'Erros do app e exportação de diagnóstico';

  @override
  String get diagEmptyTitle => 'Nenhum erro capturado';

  @override
  String get diagEmptyMessage =>
      'Exceções não capturadas são registradas aqui para ajudar nos relatórios de problemas.';

  @override
  String diagEntriesCount(int count) {
    return '$count erros';
  }

  @override
  String get diagSourceFlutter => 'Erro de UI';

  @override
  String get diagSourcePlatform => 'Erro de runtime';

  @override
  String get diagSourceZone => 'Tarefa assíncrona';

  @override
  String get diagStackTrace => 'Rastreamento de pilha';

  @override
  String get diagNoStackTrace => 'Sem rastreamento de pilha';

  @override
  String get diagExportAction => 'Exportar relatório de diagnóstico';

  @override
  String get diagExportEmpty =>
      'Nada para relatar — exportando informações básicas';

  @override
  String diagExportSuccess(String path) {
    return 'Relatório de diagnóstico exportado para $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get diagPrivacyNote =>
      'O conteúdo do diagnóstico é ofuscado — nenhuma senha, chave privada ou chave de API é incluída.';

  @override
  String get diagClearTooltip => 'Limpar registros de erro';

  @override
  String get diagClearConfirmTitle => 'Limpar registros de erro';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Todos os $count registros de erro serão removidos permanentemente.';
  }

  @override
  String get diagClearAction => 'Limpar';

  @override
  String get diagCleared => 'Registros de erro limpos';

  @override
  String get diagAppInfoTitle => 'Informações do app';

  @override
  String get diagAppInfoVersion => 'Versão';

  @override
  String get diagAppInfoPlatform => 'Plataforma';

  @override
  String get diagAppInfoLocale => 'Idioma';

  @override
  String get diagAppInfoStorage => 'Tamanho dos dados locais';

  @override
  String get authLockToggleTitle => 'Bloqueio biométrico';

  @override
  String get authLockToggleDesc =>
      'Exigir desbloqueio por impressão digital ou reconhecimento facial ao abrir o app';

  @override
  String get authLockEnableFailed =>
      'Falha na verificação — o bloqueio permanece desativado';

  @override
  String get authLockUnavailableDesc =>
      'Nenhuma biometria cadastrada neste dispositivo';

  @override
  String get authLockScreenTitle => 'O ShellMind está bloqueado';

  @override
  String get authLockScreenSubtitle => 'Verifique para continuar';

  @override
  String get authLockUnlockAction => 'Desbloquear';

  @override
  String get authLockUnlockFailed => 'Falha na verificação — tente novamente';

  @override
  String get terminalTabPickerTitle => 'Alternar terminal';

  @override
  String get terminalTabPickerSubtitle =>
      'Escolha um servidor para abrir como uma aba de terminal — servidores online entram na hora, os offline discam primeiro';

  @override
  String get terminalTabPickerEmpty => 'Nenhum servidor configurado ainda';

  @override
  String get terminalTabNewTooltip => 'Nova aba de terminal';

  @override
  String get terminalTabCloseTooltip => 'Fechar aba';

  @override
  String get hostKeyConfirmTitle => 'Confiar neste host?';

  @override
  String get hostKeyConfirmMessage =>
      'Esta é a primeira conexão com este servidor. Verifique a impressão digital antes de confiar — isso protege contra ataques man-in-the-middle.';

  @override
  String get hostKeyEndpointLabel => 'SERVIDOR';

  @override
  String get hostKeyFingerprintLabel => 'IMPRESSÃO DIGITAL SHA-256';

  @override
  String get hostKeySecurityNote =>
      'Compare a impressão digital com um valor obtido do operador do servidor por outro canal. Confiar em uma impressão digital errada expõe suas credenciais.';

  @override
  String get hostKeyTrustAndConnect => 'Confiar e conectar';

  @override
  String get hostKeyReject => 'Rejeitar';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Rejeita automaticamente em ${seconds}s — a confiança só é registrada quando você confirma.';
  }

  @override
  String get hostKeyMismatchTitle => 'A chave do host mudou';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'A chave apresentada por $host:$port difere daquela em que você confiou anteriormente. A conexão foi bloqueada — isso pode ser um ataque man-in-the-middle ou o servidor foi reinstalado. Se você verificou a nova chave, redefina a confiança do host na página de edição do servidor e reconecte.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Conexão cancelada — a chave do host não era confiável. Você pode conectar novamente para revisar a impressão digital.';

  @override
  String get serverResetTrustAction => 'Redefinir confiança do host';

  @override
  String get serverResetTrustDesc =>
      'Esquecer a impressão digital armazenada deste servidor para que a próxima conexão peça confirmação novamente.';

  @override
  String get serverResetTrustConfirmTitle => 'Redefinir confiança do host?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'A impressão digital armazenada de $identity:$port será removida. A próxima conexão pedirá que você verifique a chave do host novamente.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Redefinir';

  @override
  String get serverResetTrustDone =>
      'Confiança do host redefinida — reconecte para verificar a impressão digital novamente.';

  @override
  String get agentErrorNoTargetServer =>
      'Nenhum servidor de destino disponível';

  @override
  String get agentErrorExecFailed => 'Falha na execução do comando';

  @override
  String get agentErrorConnectFailed =>
      'Falha ao conectar ao servidor automaticamente';

  @override
  String get agentErrorConnectAuthRequired =>
      'Nenhuma credencial salva para este servidor — a conexão automática não é possível';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Comando perigoso ignorado: $command';
  }

  @override
  String get agentErrorUnexpected => 'Erro inesperado';

  @override
  String get exportDocChatTitle => 'Exportação de Chat do Shell-Mind';

  @override
  String exportDocExportedAt(String time) {
    return 'Exportado em: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Mensagens: $count';
  }

  @override
  String get exportDocUserSection => 'Usuário';

  @override
  String get exportDocAssistantSection => 'Assistente';

  @override
  String get exportDocToolSection => 'Execução de ferramenta';

  @override
  String get exportDocNoContent => '_(sem conteúdo)_';

  @override
  String get exportDocUnknownServer => 'Servidor desconhecido';

  @override
  String exportDocExitCode(int code) {
    return 'Código de saída $code';
  }

  @override
  String get exportDocCommand => 'Comando';

  @override
  String get exportDocOutput => 'Saída';

  @override
  String get exportDocErrorOutput => 'Saída de erro';

  @override
  String get exportDocDiagTitle => 'Relatório de Diagnóstico do Shell-Mind';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Erros capturados: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Erros capturados';

  @override
  String get exportDocDiagNone => '(nenhum)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Resumo do erro: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'Versão do app: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Plataforma: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Idioma: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Uso de dados locais: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'Auditoria de comandos AI (últimos $limit resumos)';
  }

  @override
  String get exportDocDiagSuccess => 'sucesso';

  @override
  String get exportDocDiagFailed => 'falhou';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'código de saída $code';
  }

  @override
  String get settingsTerminalScheme => 'Esquema de cores do terminal';

  @override
  String get settingsTerminalSchemeDesc =>
      'Escolha a paleta de cores ANSI para os terminais SSH.';

  @override
  String get settingsSectionDataTransfer => 'Importar e Exportar';

  @override
  String get transferSnippetsTitle => 'Trechos de comando';

  @override
  String get transferServersTitle => 'Configurações de servidor';

  @override
  String get transferExport => 'Exportar';

  @override
  String get transferImport => 'Importar';

  @override
  String get transferExportImport => 'Exportar / Importar';

  @override
  String get transferExportTitle => 'Exportar';

  @override
  String get transferCopyJson => 'Copiar JSON';

  @override
  String get transferCopied => 'Copiado para a área de transferência';

  @override
  String get transferImportHint => 'Cole o JSON exportado aqui…';

  @override
  String get transferSnippetsEmpty => 'Nenhum trecho de comando para exportar.';

  @override
  String get transferServersEmpty => 'Nenhum servidor para exportar.';

  @override
  String get transferImportNothing =>
      'Nenhum item válido encontrado na importação.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trechos importados',
      one: '1 trecho importado',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servidores importados',
      one: '1 servidor importado',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Falha na importação: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Falha na exportação: $message';
  }

  @override
  String get sessionsTitle => 'Conversas';

  @override
  String get sessionsNew => 'Nova conversa';

  @override
  String get sessionsSearch => 'Buscar conversas…';

  @override
  String get sessionsEmpty => 'Nenhuma conversa ainda';

  @override
  String sessionsNoMatch(String query) {
    return 'Nenhum resultado: \"$query\"';
  }

  @override
  String get sessionsRename => 'Renomear';

  @override
  String get sessionsRenameHint => 'Título da conversa';

  @override
  String get sessionsDelete => 'Excluir';

  @override
  String sessionsDeleteConfirm(String title) {
    return 'Excluir \"$title\"? Isso não pode ser desfeito.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens',
      one: '1 mensagem',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Notificações';

  @override
  String get settingsNotificationsTitle => 'Alertas em segundo plano';

  @override
  String get settingsNotificationsDesc =>
      'Notifique quando uma sessão SSH cair ou uma tarefa AI terminar enquanto o app estiver em segundo plano.';

  @override
  String get sftpTitle => 'Arquivos';

  @override
  String get sftpNotConnected => 'Não conectado a este servidor.';

  @override
  String get sftpLoading => 'Carregando arquivos…';

  @override
  String get sftpEmpty => 'Esta pasta está vazia.';

  @override
  String get sftpDownload => 'Baixar';

  @override
  String sftpDownloaded(String path, int size) {
    return '$path baixado ($size bytes)';
  }

  @override
  String get sftpDownloadFailed => 'Falha no download';

  @override
  String get sftpPreviewError => 'Falha na visualização';

  @override
  String get sftpNewFolderName => 'Nova pasta';

  @override
  String get sftpRefresh => 'Atualizar';

  @override
  String get sftpDelete => 'Excluir';

  @override
  String sftpDeleteConfirm(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get sftpRename => 'Renomear';

  @override
  String get sftpTooltip => 'Navegar pelos arquivos (SFTP)';

  @override
  String get terminalMoreTooltip => 'Mais';

  @override
  String get tunnelsTitle => 'Encaminhamento de porta';

  @override
  String get tunnelsEmpty => 'Nenhum túnel ativo.';

  @override
  String get tunnelsAddLocal => 'Encaminhamento local';

  @override
  String get tunnelsAddRemote => 'Encaminhamento remoto';

  @override
  String get tunnelsLocalPort => 'Porta local';

  @override
  String get tunnelsRemoteHost => 'Host remoto';

  @override
  String get tunnelsRemotePort => 'Porta remota';

  @override
  String get tunnelsAdd => 'Adicionar';

  @override
  String get tunnelsClose => 'Fechar';

  @override
  String get tunnelsTooltip => 'Encaminhamento de porta (túnel SSH)';

  @override
  String get tunnelsError => 'Falha no túnel';

  @override
  String get tunnelsInvalidPort => 'A porta deve estar entre 1 e 65535.';

  @override
  String get settingsLanguageTitle => 'Idioma';
}
