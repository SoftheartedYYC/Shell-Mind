// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Servidores';

  @override
  String get navAiChat => 'Chat de IA';

  @override
  String get navSettings => 'Configuración';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get backToServers => 'Volver a Servidores';

  @override
  String get serversTitle => 'Servidores';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '1 equipo',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Buscar servidores…';

  @override
  String get serversAdd => 'Añadir servidor';

  @override
  String get serversEmpty => 'Aún no hay servidores';

  @override
  String get serversEmptyHint => 'Añada su primer servidor SSH para empezar.';

  @override
  String get serversDeleteConfirmTitle => 'Eliminar servidor';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return '¿Eliminar \"$name\"?\n\n$identity:$port y sus credenciales almacenadas se eliminarán de forma permanente.';
  }

  @override
  String serversDeleted(String identity) {
    return 'Se eliminó $identity';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'No se pudo eliminar: $message';
  }

  @override
  String get serversLoading => 'Cargando servidores';

  @override
  String get serversUngrouped => 'Sin grupo';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => 'recientes';

  @override
  String get serversQuickStart => 'Inicio rápido';

  @override
  String get serversQuickStep1Title => 'Añadir un host';

  @override
  String get serversQuickStep1Desc =>
      'Registre un endpoint SSH con autenticación por contraseña o clave.';

  @override
  String get serversQuickStep2Title => 'Probar conexión';

  @override
  String get serversQuickStep2Desc =>
      'Compruebe el puerto antes de confirmar: detecta errores de escritura rápidamente.';

  @override
  String get serversQuickStep3Title => 'Conectar';

  @override
  String get serversQuickStep3Desc =>
      'Abra una sesión de terminal: PTY completo, colores y vim.';

  @override
  String serversNoMatch(String query) {
    return 'Sin coincidencias: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Limpiar filtro';

  @override
  String get serversReadError => 'No se pudo leer la lista de servidores.';

  @override
  String get serverEditTitle => 'Añadir servidor';

  @override
  String get serverEditTitleEdit => 'Editar servidor';

  @override
  String get serverNotFound => 'Servidor no encontrado';

  @override
  String get serverValidationNameRequired => 'Nombre obligatorio';

  @override
  String get serverValidationHostRequired => 'Host obligatorio';

  @override
  String get serverValidationNoSpaces => 'No se permiten espacios';

  @override
  String get serverValidationRequired => 'Obligatorio';

  @override
  String get serverValidationNumeric => 'Numérico';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired =>
      'Nombre de usuario obligatorio';

  @override
  String get serverValidationPasswordRequired => 'Contraseña obligatoria';

  @override
  String get serverValidationPrivateKeyRequired => 'Clave privada obligatoria';

  @override
  String serverAdded(String identity, int port) {
    return 'Servidor añadido: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Guardado: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'No se pudo guardar: $message';
  }

  @override
  String get serverTestEnterHost => 'Introduzca primero una dirección de host';

  @override
  String serverTestProbing(String host, int port) {
    return 'Comprobando $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — accesible';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — tiempo de espera agotado';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — rechazado / inaccesible';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — comprobación fallida';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port falló el handshake SSH';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port falló la autenticación: compruebe el nombre de usuario y las credenciales';
  }

  @override
  String get serverLoading => 'Cargando';

  @override
  String get serverSaveChanges => 'Guardar cambios';

  @override
  String get serverSectionIdentity => 'Identidad';

  @override
  String get serverSectionConnection => 'Conexión';

  @override
  String get serverSectionAuthentication => 'Autenticación';

  @override
  String get serverFieldLabel => 'Etiqueta';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Grupo (opcional)';

  @override
  String get serverFieldGroupHint => 'producción';

  @override
  String get serverFieldHost => 'Host';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Puerto';

  @override
  String get serverFieldUsername => 'Nombre de usuario';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Contraseña';

  @override
  String get serverFieldPasswordStored =>
      'Almacenada: deje en blanco para mantenerla';

  @override
  String get serverFieldPrivateKey => 'Clave privada (PEM)';

  @override
  String get serverFieldPassphrase =>
      'Frase de contraseña de la clave (opcional)';

  @override
  String get serverAuthPassword => 'Contraseña';

  @override
  String get serverAuthPrivateKey => 'Clave privada';

  @override
  String get serverTestIdle => 'Pulse \"Probar\" para comprobar la conexión';

  @override
  String get serverSecurityNote =>
      'Las credenciales se cifran en el almacén de claves del dispositivo: nunca tocan el almacén de metadatos Hive ni salen de este dispositivo.';

  @override
  String get serverTesting => 'Probando…';

  @override
  String get serverTest => 'Probar';

  @override
  String get serverSaving => 'Guardando…';

  @override
  String serverCopiedAddress(String address) {
    return 'Dirección $address copiada';
  }

  @override
  String get serverActions => 'Acciones del servidor';

  @override
  String get serverActionConnect => 'Conectar';

  @override
  String get serverActionEdit => 'Editar';

  @override
  String get serverActionEditDetails => 'Editar detalles';

  @override
  String get serverActionCopySsh => 'Copiar comando SSH';

  @override
  String get serverActionDelete => 'Eliminar';

  @override
  String get serverActionDeleteServer => 'Eliminar servidor';

  @override
  String get serverOnline => 'En línea';

  @override
  String get serverNeverConnected => 'Nunca conectado';

  @override
  String get serverJustNow => 'Ahora mismo';

  @override
  String serverMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String serverHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String serverDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String get terminalHostNotFound => 'Host no encontrado';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Ningún servidor guardado coincide con el id \"$id\". Es posible que se haya eliminado.';
  }

  @override
  String get terminalBackToServers => 'Volver a servidores';

  @override
  String get terminalConnectionFailed => 'Error de conexión.';

  @override
  String get terminalSessionClosed => 'Sesión cerrada';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'La conexión con $name se ha terminado.';
  }

  @override
  String get terminalReconnect => 'Reconectar';

  @override
  String get terminalAuthenticating => 'Autenticando';

  @override
  String get terminalConnecting => 'Conectando';

  @override
  String get terminalResolvingHost => 'Resolviendo host…';

  @override
  String get terminalTooltipDisconnectBack => 'Desconectar y volver';

  @override
  String get terminalTooltipSmallerText => 'Texto más pequeño';

  @override
  String get terminalTooltipLargerText => 'Texto más grande';

  @override
  String get terminalTooltipDisconnect => 'Desconectar';

  @override
  String get terminalRetryAvailable => 'Reintento disponible';

  @override
  String get terminalStatusConnected => 'CONECTADO';

  @override
  String get terminalStatusOffline => 'SIN CONEXIÓN';

  @override
  String get terminalStatusError => 'ERROR';

  @override
  String get aiChatTitle => 'Asistente de IA';

  @override
  String get aiChatStatusSetup => 'CONFIGURACIÓN';

  @override
  String get aiChatStatusStreaming => 'TRANSMITIENDO';

  @override
  String get aiChatStatusReady => 'LISTO';

  @override
  String get aiChatClearConversation => 'Borrar conversación';

  @override
  String get aiChatSuggestion1 => 'Explique qué significa la salida de ls -la';

  @override
  String get aiChatSuggestion2 =>
      '¿Cómo averiguo qué proceso está usando un puerto?';

  @override
  String get aiChatSuggestion3 =>
      'Muéstreme cómo hacer tail de logs y grep de errores';

  @override
  String get aiChatSuggestion4 =>
      'Escriba un one-liner de awk para sumar una columna CSV';

  @override
  String get aiChatTryAsking => 'Pruebe a preguntar';

  @override
  String get aiChatIntroTitle => 'Su compañero de terminal';

  @override
  String get aiChatIntroBody =>
      'Pegue un comando, un error o un fragmento de salida de registro. ShellMind explica lo que ha ocurrido, sugiere el siguiente paso y escribe los comandos para que usted no tenga que hacerlo.';

  @override
  String get aiChatNoKeyTitle => 'No hay ninguna clave de API configurada';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Añada su clave de API de $provider para activar el asistente. Se almacena cifrada en este dispositivo y nunca sale de él salvo para llamar al modelo.';
  }

  @override
  String get aiChatOpenSettings => 'Abrir configuración de IA';

  @override
  String get aiChatCheckingCredentials => 'Comprobando credenciales';

  @override
  String get aiChatInputHint => 'Pregunte lo que quiera…';

  @override
  String get aiChatInputDisabled => 'Configure una clave de API para empezar';

  @override
  String get aiChatError => 'Error';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Copiado';

  @override
  String get aiChatCopy => 'Copiar';

  @override
  String get aiChatThinking => 'Pensando…';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSearchTooltip => 'Buscar en configuración';

  @override
  String get settingsStable => 'ESTABLE';

  @override
  String get settingsSectionAppearance => 'Apariencia e idioma';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'Proveedor de IA';

  @override
  String get settingsSectionAiAgent => 'Agente de IA';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Servidores';

  @override
  String get settingsSectionAboutUpdate => 'Acerca de y actualización';

  @override
  String get settingsSectionStoragePrivacy => 'Almacenamiento y privacidad';

  @override
  String get settingsSectionResources => 'Recursos';

  @override
  String get settingsTileSecrets => 'Secretos';

  @override
  String get settingsTileEncrypted => 'Cifrado';

  @override
  String get settingsTileLocalCache => 'Caché local';

  @override
  String get settingsTileClearData => 'Borrar todos los datos';

  @override
  String get settingsTileLicenses => 'Licencias de código abierto';

  @override
  String get settingsTileReportIssue => 'Informar de un problema';

  @override
  String get settingsFooter =>
      'SSH + Asistente de IA para flujos de trabajo modernos';

  @override
  String get settingsSecretsDialogTitle => 'Secretos y cifrado';

  @override
  String get settingsSecretsDialogBody =>
      'Las credenciales (contraseñas de servidores, claves privadas y claves de API de IA) siempre se cifran en reposo mediante el almacén de claves de la plataforma (Android Keystore / iOS Keychain). Esta protección es intencionada y no se puede desactivar. Para cambiar una credencial, edítela o elimínela en la página de edición del servidor o en la configuración de IA.';

  @override
  String get settingsDialogOk => 'Aceptar';

  @override
  String get settingsDialogClose => 'Cerrar';

  @override
  String get settingsCacheDialogTitle => 'Caché local';

  @override
  String get settingsCacheHiveData => 'Datos de la app';

  @override
  String get settingsCacheDownloads => 'Actualizaciones descargadas';

  @override
  String get settingsCacheTotal => 'Total';

  @override
  String get settingsCacheDialogHint =>
      'Al borrar la caché de descargas se eliminan los paquetes de actualización descargados (APK). Sus servidores, claves e historial de chat se conservan.';

  @override
  String get settingsCacheClearDownloads => 'Borrar caché de descargas';

  @override
  String settingsCacheCleared(String freed) {
    return 'Liberado $freed';
  }

  @override
  String get settingsClearDataTitle => '¿Borrar todos los datos?';

  @override
  String get settingsClearDataMessage =>
      'Esto elimina de forma permanente todos los servidores, credenciales almacenadas, claves de IA, historial de chat y preferencias de este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get settingsClearDataConfirm => 'Borrar todo';

  @override
  String get settingsDataCleared => 'Todos los datos eliminados';

  @override
  String settingsClearDataFailed(String message) {
    return 'No se pudieron borrar los datos: $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Enlace del problema copiado al portapapeles.';

  @override
  String get settingsAboutGithub => 'Repositorio de GitHub';

  @override
  String get settingsHideIp => 'Ocultar direcciones IP';

  @override
  String get settingsHideIpDesc =>
      'Enmascarar las direcciones IP en la lista de servidores y en las páginas de IA';

  @override
  String get serverMaskedAddress => 'Dirección oculta';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return 'Clave de API de $provider';
  }

  @override
  String get aiSettingsKeySet => 'configurada';

  @override
  String get aiSettingsKeyNotConfigured => 'no configurada';

  @override
  String get aiSettingsGetApiKey => 'Obtener una clave de API';

  @override
  String get aiSettingsTemperature => 'Temperatura';

  @override
  String get aiSettingsRemoveKey => 'Eliminar clave';

  @override
  String aiSettingsKeySaved(String provider) {
    return 'Clave de API de $provider guardada de forma segura.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return '¿Eliminar la clave de $provider?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'El asistente dejará de funcionar con este proveedor hasta que se añada una nueva clave.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Eliminar';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Obtener una clave de $provider';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Abra la consola del proveedor en su navegador para crear una clave de API y péguela aquí.';

  @override
  String get aiSettingsClose => 'Cerrar';

  @override
  String get aiSettingsLinkCopied => 'Enlace copiado al portapapeles.';

  @override
  String get aiSettingsCopyLink => 'Copiar enlace';

  @override
  String get aiSettingsKeyConfigured => 'Clave configurada';

  @override
  String get aiSettingsNotConfigured => 'No configurada';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Actualizar la clave de $provider';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Añadir la clave de $provider';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Se almacena cifrada en este dispositivo. Se usa solo para llamar al proveedor de IA.';

  @override
  String get aiSettingsApiKeyHint => 'Clave de API…';

  @override
  String get aiSettingsSave => 'Guardar';

  @override
  String get modelDescFastAffordable => 'Rápido y asequible';

  @override
  String get modelDescMostCapable => 'El más capaz';

  @override
  String get modelDescLegacyFast => 'Rápido (heredado)';

  @override
  String get modelDescGeneralConversation => 'Conversación general';

  @override
  String get modelDescAdvancedReasoning => 'Razonamiento avanzado';

  @override
  String get modelDescFastResponse => 'Respuesta rápida';

  @override
  String get modelDescBalanced => 'Equilibrado';

  @override
  String get modelDescFreeFast => 'Gratuito y rápido';

  @override
  String get modelDescEnhanced => 'Mejorado';

  @override
  String get modelDescStandard => 'Estándar';

  @override
  String get modelDescLightweight => 'Ligero';

  @override
  String get modelDescRlEnhanced => 'RL mejorado';

  @override
  String get aiModelsTitle => 'Modelo';

  @override
  String get aiModelsRefresh => 'Actualizar lista de modelos';

  @override
  String get aiModelsAddCustom => 'Añadir modelo personalizado';

  @override
  String get aiModelsAddCustomHint => 'ID de modelo, p. ej. deepseek-chat';

  @override
  String get aiModelsAdd => 'Añadir';

  @override
  String get aiModelsCustomBadge => 'Personalizado';

  @override
  String get aiModelsFetchFailed =>
      'No se pudieron obtener los modelos: se muestra la lista integrada.';

  @override
  String get aiModelsRemoveCustom => 'Eliminar modelo personalizado';

  @override
  String get aiModelsEmpty => 'No hay modelos';

  @override
  String get aiModelsInvalidId => 'Introduzca un ID de modelo.';

  @override
  String get aiModelsDuplicate => 'Este modelo ya está en la lista.';

  @override
  String get aiModelsPickerTitle => 'Elegir modelo';

  @override
  String get aiModelsSearchHint => 'Buscar modelos';

  @override
  String get aiModelsSearchEmpty => 'Ningún modelo coincide con su búsqueda.';

  @override
  String get aiProvidersAddTile => 'Añadir proveedor personalizado';

  @override
  String get aiProvidersAddTitle => 'Añadir proveedor personalizado';

  @override
  String get aiProvidersFieldName => 'Nombre';

  @override
  String get aiProvidersFieldNameHint => 'p. ej. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'URL base';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Modelo predeterminado (opcional)';

  @override
  String get aiProvidersFieldModelHint => 'ID de modelo, p. ej. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Añadir';

  @override
  String get aiProvidersInvalidInput => 'Introduzca un nombre y una URL base.';

  @override
  String get aiProvidersInvalidUrl =>
      'La URL base debe empezar por http:// o https://';

  @override
  String get aiProvidersDuplicateName =>
      'Ya existe un proveedor con este nombre.';

  @override
  String get aiProvidersAdded => 'Proveedor personalizado añadido.';

  @override
  String get aiProvidersAddFailed =>
      'No se pudo añadir el proveedor: compruebe los datos.';

  @override
  String get aiProvidersDeleteTile => 'Eliminar proveedor personalizado';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return '¿Eliminar $provider?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'También se eliminarán su clave de API almacenada, el modelo recordado y los modelos personalizados. Los proveedores integrados no se pueden eliminar.';

  @override
  String get aiProvidersDeleteConfirm => 'Eliminar';

  @override
  String get aiProvidersPickerTitle => 'Elegir proveedor';

  @override
  String get updateVersion => 'Versión';

  @override
  String get updateSoftwareUpdate => 'Actualización de software';

  @override
  String get updateChecking => 'COMPROBANDO';

  @override
  String get updateUpToDate => 'ACTUALIZADO';

  @override
  String get updateCheckAgain => 'Comprobar de nuevo';

  @override
  String get updateReady => 'LISTO';

  @override
  String get updateNew => 'NUEVO';

  @override
  String get updateCheck => 'COMPROBAR';

  @override
  String get updateAwaitingResponse => 'Esperando respuesta';

  @override
  String get updateAlreadyLatest => 'Ya tiene la última versión';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version es la versión más reciente publicada en GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'En ejecución v$current: la versión remota más reciente es v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Comprobado $timeAgo';
  }

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get updatePre => 'PRE';

  @override
  String get updateDownloadInstall => 'Descargar e instalar';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateApkHint =>
      'La instalación de APK solo es compatible con Android. El archivo se puede descargar aquí igualmente.';

  @override
  String updateDownloading(String tag) {
    return 'Descargando $tag';
  }

  @override
  String get updateSize => 'tamaño';

  @override
  String get updateRate => 'velocidad';

  @override
  String get updateEta => 'tiempo restante';

  @override
  String get updateElapsed => 'transcurrido';

  @override
  String get updateCancel => 'Cancelar';

  @override
  String get updateKeepForeground => 'Mantenga la app en primer plano';

  @override
  String get updateDownloadComplete => 'Descarga completada';

  @override
  String get updateInstallHint =>
      'Android le pedirá confirmación. ShellMind se cerrará mientras se ejecuta el instalador; sus servidores e historial se conservan.';

  @override
  String get updateLaunching => 'Iniciando...';

  @override
  String get updateInstallNow => 'Instalar ahora';

  @override
  String get updateDelete => 'Eliminar';

  @override
  String updateInstallTitle(String tag) {
    return '¿Instalar $tag?';
  }

  @override
  String get updateInstallMessage =>
      'Se abrirá el instalador de paquetes del sistema. ShellMind se cierra durante la instalación y se reabre con la nueva versión.';

  @override
  String get updateNotNow => 'Ahora no';

  @override
  String get updateInstall => 'Instalar';

  @override
  String get updateCheckFailed =>
      'La comprobación de actualizaciones ha fallado.';

  @override
  String get updateErrorTitleNoReleases => 'No hay versiones';

  @override
  String get updateErrorTitleGeneric =>
      'La comprobación de actualizaciones ha fallado';

  @override
  String get updateErrNoReleases =>
      'Aún no se ha publicado ninguna versión de ShellMind.';

  @override
  String get updateErrRateLimit =>
      'Se ha alcanzado el límite de la API de GitHub. Inténtelo de nuevo más tarde.';

  @override
  String get updateErrTimeout =>
      'La solicitud a GitHub ha agotado el tiempo de espera. Compruebe su conexión y vuelva a intentarlo.';

  @override
  String get updateErrNetwork =>
      'No se pudo acceder a GitHub. Compruebe su conexión de red.';

  @override
  String get updateErrAuth =>
      'GitHub ha rechazado la solicitud de actualización.';

  @override
  String get updateErrPermission =>
      'La solicitud de actualización fue denegada.';

  @override
  String get updateErrStorage =>
      'No hay suficiente espacio de almacenamiento para completar la actualización.';

  @override
  String get updateErrDigestMismatch =>
      'La actualización descargada no superó la comprobación de integridad SHA-256 y se eliminó. Vuelva a intentar la descarga.';

  @override
  String get updateErrDigestMissing =>
      'El paquete de actualización no tiene un resumen de integridad publicado, por lo que se rechazó la actualización. Inténtelo más tarde.';

  @override
  String get updateRetry => 'Reintentar';

  @override
  String get updateDismiss => 'Descartar';

  @override
  String updateReleaseNotes(String tag) {
    return 'Versión $tag';
  }

  @override
  String get updateNotesLabel => 'notas';

  @override
  String get updateNewVersionAvailable => 'Nueva versión disponible';

  @override
  String get updateRemindLater => 'Recordármelo más tarde';

  @override
  String get updateCancelDownload => 'Cancelar descarga';

  @override
  String updateInstallTag(String tag) {
    return 'Instalar $tag';
  }

  @override
  String get updateInstallLaterFromSettings =>
      'Instalar más tarde desde configuración';

  @override
  String get updateCouldNotComplete => 'No se pudo completar la actualización.';

  @override
  String get updateClose => 'Cerrar';

  @override
  String get updatePromptInstallHint =>
      'Android cierra ShellMind mientras se ejecuta el instalador. Los servidores, las claves y el historial de chat se conservan.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonNoData => 'No hay datos';

  @override
  String get commonNothingToShow => 'Aún no hay nada que mostrar aquí.';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get settingsAiAutoExecuteTitle => 'Ejecutar comandos automáticamente';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Permitir que el agente de IA ejecute los comandos analizados sin preguntar cada vez';

  @override
  String get settingsAiAutoConnectTitle =>
      'Conexión automática de servidores por IA';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Permitir que el asistente de IA se conecte automáticamente a servidores configurados pero sin conexión y ejecute comandos en ellos (se usarán las credenciales guardadas)';

  @override
  String get settingsAiMaxAutoLoopsTitle =>
      'Iteraciones máximas del bucle automático';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Limita el número de ejecuciones automáticas de comandos por respuesta';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Rondas de comandos máximas que la IA puede ejecutar por tarea';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Este es el límite superior de rondas de ejecución por tarea de IA, no el número de intentos de reconexión SSH (que se configura en SSH).';

  @override
  String get terminalAskAi => 'Preguntar a la IA';

  @override
  String get terminalAskAiSubtitle =>
      'Enviar el texto seleccionado al asistente de IA';

  @override
  String get terminalTooltipAskAi => 'Preguntar a la IA';

  @override
  String get aiChatNoConnection =>
      'Conéctese primero a un terminal de servidor';

  @override
  String get aiChatAnalyzePrompt =>
      'Analice la salida del comando anterior, explique qué significa el resultado y ofrezca sugerencias de seguimiento cuando sea necesario.';

  @override
  String get aiExecuteButton => 'Ejecutar en el servidor';

  @override
  String get aiExecuteTitle => 'Confirmar ejecución del comando';

  @override
  String get aiExecuteConfirmButton => 'Ejecutar';

  @override
  String get aiExecuteConfirmAnyway => 'Ejecutar de todos modos';

  @override
  String get aiExecuteDangerWarning => '⚠ Comando peligroso';

  @override
  String get aiExecuteDangerText =>
      'Este comando puede ser destructivo y podría causar pérdida de datos o daños en el sistema.';

  @override
  String get aiExecuteCommandLabel => 'Comando a ejecutar:';

  @override
  String get aiExecuteTargetServer => 'Servidor(es) de destino:';

  @override
  String get aiExecuteSelectServer => 'Seleccionar servidor(es) de destino';

  @override
  String get aiExecuteNoServer => 'Conéctese primero a un servidor';

  @override
  String get aiExecuteAtLeastOne => 'Seleccione al menos un servidor';

  @override
  String get aiExecuteSelectHint =>
      'Elija el/los servidor(es) en los que ejecutar este comando';

  @override
  String aiExecuteRunCount(int count) {
    return 'Ejecutar ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Seleccionar todo';

  @override
  String get aiExecuteClearSelection => 'Limpiar';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours h $minutes min en línea';
  }

  @override
  String get aiExecuteSuccess => 'Comando ejecutado correctamente';

  @override
  String get aiExecuteFailed => 'Error al ejecutar el comando';

  @override
  String get aiServerManageTitle => 'Servidores';

  @override
  String get aiServerManageSubtitle =>
      'Conecte servidores para que el asistente de IA pueda operar';

  @override
  String aiServerOnlineCount(int count) {
    return '$count en línea';
  }

  @override
  String get aiServerDone => 'Hecho';

  @override
  String get aiServerConnecting => 'Conectando…';

  @override
  String get aiServerOffline => 'Sin conexión';

  @override
  String get aiServerNoCredential =>
      'No hay credencial guardada: guarde primero la contraseña o la clave en la página del servidor';

  @override
  String get aiServerConnectFailed => 'Error de conexión';

  @override
  String get aiToolResultCommand => 'Comando';

  @override
  String get aiToolResultOutput => 'Salida del comando';

  @override
  String aiToolResultExitCode(int code) {
    return 'Código de salida: $code';
  }

  @override
  String get aiToolResultElapsed => 'Tiempo transcurrido';

  @override
  String get aiToolResultAnalyzeButton => 'Dejar que la IA analice la salida';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total líneas más';
  }

  @override
  String get aiToolResultExpandedHide => 'Ocultar salida';

  @override
  String get aiToolResultStderrLabel => 'Salida de error:';

  @override
  String get aiContextToggleAttach => 'Adjuntar contexto del terminal';

  @override
  String get aiContextToggleDetach => 'Contexto del terminal adjuntado';

  @override
  String get aiContextBadge => 'Contexto';

  @override
  String aiContextLines(int lines) {
    return '$lines líneas del terminal';
  }

  @override
  String get aiAgentStop => 'Detener modo automático';

  @override
  String get aiAgentExecuting => 'Ejecutando…';

  @override
  String get aiAgentDefaultServer => 'servidor';

  @override
  String get aiTimelineTitle => 'Cronología de ejecución';

  @override
  String get aiTimelineOpen => 'Cronología de ejecución';

  @override
  String get aiTimelineEmpty => 'Aún no se ha ejecutado ningún comando';

  @override
  String get aiTimelineEmptyHint =>
      'Ejecute comandos mediante el chat o el modo automático y la cadena completa aparecerá aquí.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas',
      one: '1 ronda',
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
      other: '$count correctos',
      one: '1 correcto',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fallidos',
      one: '1 fallido',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Iniciado $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Finalizado $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Código de salida: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Sin código de salida';

  @override
  String get aiTimelineOutput => 'Salida';

  @override
  String get aiTimelineOutputEmpty => 'Sin salida';

  @override
  String get aiTimelineErrorOutput => 'Salida de error';

  @override
  String get aiTimelineRunning => 'Ejecutando…';

  @override
  String get aiTimelineClose => 'Cerrar';

  @override
  String get sshReconnectToggle => 'Reconexión automática al desconectar';

  @override
  String get sshReconnectToggleDesc =>
      'Reintenta las sesiones SSH caídas con retroceso exponencial';

  @override
  String get sshReconnectMaxAttempts => 'Intentos máximos de reconexión';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Intentos máximos de reconexión automática tras una desconexión: 0 significa reintentar hasta que tenga éxito';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Ilimitado';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Reconectando (intento $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Reconectando (intento $attempt de $max)';
  }

  @override
  String get sshReconnectGaveUp => 'La reconexión automática se ha rendido';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'No se pudo acceder a $name tras $max intentos.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'No se pudo acceder a $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Reintentar ahora';

  @override
  String get sshReconnectStopAuto => 'Detener';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Reconectado a $name';
  }

  @override
  String get snippetsTitle => 'Fragmentos de comandos';

  @override
  String get snippetsSubtitle =>
      'Guarde comandos para reutilizarlos rápidamente';

  @override
  String get snippetsAddTooltip => 'Añadir fragmento';

  @override
  String get snippetsAddTitle => 'Nuevo fragmento';

  @override
  String get snippetsSave => 'Guardar';

  @override
  String get snippetsCommandLabel => 'Comando';

  @override
  String get snippetsCommandHint => 'p. ej. docker ps -a';

  @override
  String get snippetsNameLabel => 'Nombre (opcional)';

  @override
  String get snippetsNameHint => 'p. ej. Listar todos los contenedores';

  @override
  String get snippetsCommandRequired => 'El texto del comando es obligatorio';

  @override
  String get snippetsDeleteTooltip => 'Eliminar fragmento';

  @override
  String get snippetsEmptyTitle => 'Aún no hay fragmentos';

  @override
  String get snippetsEmptyMessage =>
      'Guarde comandos de uso frecuente e insértelos o ejecútelos con un solo toque.';

  @override
  String get snippetsLoadFailed => 'No se pudieron cargar los fragmentos';

  @override
  String get healthTitle => 'Estado de la flota';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total en línea';
  }

  @override
  String get healthProbing => 'Comprobando…';

  @override
  String get healthProbeTooltip => 'Ejecutar comprobación de estado';

  @override
  String healthProbedAt(String time) {
    return 'Comprobado a las $time';
  }

  @override
  String get healthMoodAllOnline => 'Todos los sistemas en orden';

  @override
  String get healthMoodDegraded => 'Algunos servidores son inaccesibles';

  @override
  String get healthMoodAllOffline => 'Todos los servidores inaccesibles';

  @override
  String healthOfflineServers(String names) {
    return 'Sin conexión: $names';
  }

  @override
  String get healthNoData => 'Pulse actualizar para comprobar cada servidor';

  @override
  String healthUptime(String brief) {
    return 'activo $brief';
  }

  @override
  String healthLoad(String value) {
    return 'carga $value';
  }

  @override
  String get healthDiagIntro => 'Este es el informe de estado de mi flota:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online de $total servidores en línea.';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name: sin conexión';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name: en línea ($details)';
  }

  @override
  String get healthDiagOutro =>
      'Analice los datos de estado, señale cualquier anomalía (carga alta, reinicios recientes) y sugiera qué comprobar a continuación.';

  @override
  String get healthDiagnose => 'Diagnóstico con IA';

  @override
  String get healthStaleNote =>
      'Algunos servidores se desconectaron desde la última comprobación.';

  @override
  String get auditTitle => 'Registro de auditoría de comandos';

  @override
  String get auditTileDesc => 'Comandos ejecutados por el agente de IA';

  @override
  String get auditEmptyTitle => 'Aún no hay entradas de auditoría';

  @override
  String get auditEmptyMessage =>
      'Aquí se registrarán los comandos ejecutados por el agente de IA.';

  @override
  String get auditFilteredEmpty =>
      'Ninguna entrada coincide con el filtro actual';

  @override
  String get auditFilterAllServers => 'Todos los servidores';

  @override
  String get auditFilterAllModes => 'Todos los modos';

  @override
  String get auditFilterAllResults => 'Todos los resultados';

  @override
  String get auditFilterConfirmed => 'Confirmado';

  @override
  String get auditFilterAuto => 'Automático';

  @override
  String get auditFilterSuccess => 'Correcto';

  @override
  String get auditFilterFailed => 'Fallido';

  @override
  String get auditModeConfirmed => 'Confirmado';

  @override
  String get auditModeAuto => 'Automático';

  @override
  String get auditStatusSuccess => 'Correcto';

  @override
  String get auditStatusFailed => 'Fallido';

  @override
  String get auditDangerousBadge => 'Peligroso';

  @override
  String auditExitCode(int code) {
    return 'Código de salida $code';
  }

  @override
  String get auditOutputSummary => 'Resumen de salida';

  @override
  String get auditNoOutput => 'Sin salida';

  @override
  String get auditClearTooltip => 'Borrar registro de auditoría';

  @override
  String get auditClearConfirmTitle => 'Borrar registro de auditoría';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Se eliminarán de forma permanente las $count entradas de auditoría.';
  }

  @override
  String get auditClearAction => 'Borrar';

  @override
  String get auditCleared => 'Registro de auditoría borrado';

  @override
  String auditEntriesCount(int count) {
    return '$count entradas';
  }

  @override
  String get serverActionDisconnect => 'Desconectar';

  @override
  String get exportChatAction => 'Exportar como Markdown';

  @override
  String get exportChatEmpty => 'Aún no hay nada que exportar';

  @override
  String exportChatSuccess(String path) {
    return 'Conversación exportada a $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get diagTitle => 'Diagnóstico';

  @override
  String get diagTileDesc => 'Errores de la app y exportación de diagnóstico';

  @override
  String get diagEmptyTitle => 'No se ha capturado ningún error';

  @override
  String get diagEmptyMessage =>
      'Las excepciones no capturadas se registran aquí para ayudar con los informes de problemas.';

  @override
  String diagEntriesCount(int count) {
    return '$count errores';
  }

  @override
  String get diagSourceFlutter => 'Error de interfaz';

  @override
  String get diagSourcePlatform => 'Error en tiempo de ejecución';

  @override
  String get diagSourceZone => 'Tarea asíncrona';

  @override
  String get diagStackTrace => 'Traza de pila';

  @override
  String get diagNoStackTrace => 'Sin traza de pila';

  @override
  String get diagExportAction => 'Exportar informe de diagnóstico';

  @override
  String get diagExportEmpty =>
      'No hay nada que informar: se exporta la información básica';

  @override
  String diagExportSuccess(String path) {
    return 'Informe de diagnóstico exportado a $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get diagPrivacyNote =>
      'El contenido del diagnóstico está censurado: no se incluyen contraseñas, claves privadas ni claves de API.';

  @override
  String get diagClearTooltip => 'Borrar registros de errores';

  @override
  String get diagClearConfirmTitle => 'Borrar registros de errores';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Se eliminarán de forma permanente los $count registros de errores.';
  }

  @override
  String get diagClearAction => 'Borrar';

  @override
  String get diagCleared => 'Registros de errores borrados';

  @override
  String get diagAppInfoTitle => 'Información de la app';

  @override
  String get diagAppInfoVersion => 'Versión';

  @override
  String get diagAppInfoPlatform => 'Plataforma';

  @override
  String get diagAppInfoLocale => 'Idioma';

  @override
  String get diagAppInfoStorage => 'Tamaño de los datos locales';

  @override
  String get authLockToggleTitle => 'Bloqueo biométrico';

  @override
  String get authLockToggleDesc =>
      'Exigir desbloqueo por huella dactilar o rostro al abrir la app';

  @override
  String get authLockEnableFailed =>
      'La verificación ha fallado: el bloqueo permanece desactivado';

  @override
  String get authLockUnavailableDesc =>
      'No hay datos biométricos registrados en este dispositivo';

  @override
  String get authLockScreenTitle => 'ShellMind está bloqueado';

  @override
  String get authLockScreenSubtitle => 'Verifique para continuar';

  @override
  String get authLockUnlockAction => 'Desbloquear';

  @override
  String get authLockUnlockFailed =>
      'La verificación ha fallado: inténtelo de nuevo';

  @override
  String get terminalTabPickerTitle => 'Cambiar de terminal';

  @override
  String get terminalTabPickerSubtitle =>
      'Elija un servidor para abrirlo como pestaña de terminal: los servidores en línea se unen al instante, los que están sin conexión se conectan primero';

  @override
  String get terminalTabPickerEmpty => 'Aún no hay servidores configurados';

  @override
  String get terminalTabNewTooltip => 'Nueva pestaña de terminal';

  @override
  String get terminalTabCloseTooltip => 'Cerrar pestaña';

  @override
  String get hostKeyConfirmTitle => '¿Confiar en este host?';

  @override
  String get hostKeyConfirmMessage =>
      'Esta es la primera conexión con este servidor. Verifique su huella antes de confiar en él: esto protege contra ataques de intermediario (man-in-the-middle).';

  @override
  String get hostKeyEndpointLabel => 'SERVIDOR';

  @override
  String get hostKeyFingerprintLabel => 'HUELLA SHA-256';

  @override
  String get hostKeySecurityNote =>
      'Compare la huella con un valor obtenido del operador del servidor por un canal externo. Confiar en una huella incorrecta expone sus credenciales.';

  @override
  String get hostKeyTrustAndConnect => 'Confiar y conectar';

  @override
  String get hostKeyReject => 'Rechazar';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Se rechaza automáticamente en $seconds s: la confianza solo se registra cuando usted confirma.';
  }

  @override
  String get hostKeyMismatchTitle => 'La clave del host ha cambiado';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'La clave presentada por $host:$port difiere de aquella en la que usted confió anteriormente. La conexión se ha bloqueado: puede ser un ataque de intermediario (man-in-the-middle) o que el servidor se haya reinstalado. Si ha verificado la nueva clave, restablezca la confianza del host en la página de edición del servidor y vuelva a conectarse.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Conexión cancelada: no se confió en la clave del host. Puede volver a conectarse para revisar la huella.';

  @override
  String get serverResetTrustAction => 'Restablecer confianza del host';

  @override
  String get serverResetTrustDesc =>
      'Olvidar la huella almacenada de este servidor para que la próxima conexión vuelva a pedir confirmación.';

  @override
  String get serverResetTrustConfirmTitle =>
      '¿Restablecer la confianza del host?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'Se eliminará la huella almacenada para $identity:$port. La próxima conexión le pedirá que verifique de nuevo la clave del host.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Restablecer';

  @override
  String get serverResetTrustDone =>
      'Confianza del host restablecida: vuelva a conectarse para verificar de nuevo la huella.';

  @override
  String get agentErrorNoTargetServer =>
      'No hay servidor de destino disponible';

  @override
  String get agentErrorExecFailed => 'Error al ejecutar el comando';

  @override
  String get agentErrorConnectFailed =>
      'No se pudo conectar al servidor automáticamente';

  @override
  String get agentErrorConnectAuthRequired =>
      'No hay credenciales guardadas para este servidor: la conexión automática no es posible';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Comando peligroso omitido: $command';
  }

  @override
  String get agentErrorUnexpected => 'Error inesperado';

  @override
  String get exportDocChatTitle => 'Exportación de chat de Shell-Mind';

  @override
  String exportDocExportedAt(String time) {
    return 'Exportado a las: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Mensajes: $count';
  }

  @override
  String get exportDocUserSection => 'Usuario';

  @override
  String get exportDocAssistantSection => 'Asistente';

  @override
  String get exportDocToolSection => 'Ejecución de herramienta';

  @override
  String get exportDocNoContent => '_(sin contenido)_';

  @override
  String get exportDocUnknownServer => 'Servidor desconocido';

  @override
  String exportDocExitCode(int code) {
    return 'Código de salida $code';
  }

  @override
  String get exportDocCommand => 'Comando';

  @override
  String get exportDocOutput => 'Salida';

  @override
  String get exportDocErrorOutput => 'Salida de error';

  @override
  String get exportDocDiagTitle => 'Informe de diagnóstico de Shell-Mind';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Errores capturados: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Errores capturados';

  @override
  String get exportDocDiagNone => '(ninguno)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Resumen del error: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'Versión de la app: $version';
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
    return 'Uso de datos locales: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'Auditoría de comandos de IA (últimos $limit resúmenes)';
  }

  @override
  String get exportDocDiagSuccess => 'correcto';

  @override
  String get exportDocDiagFailed => 'fallido';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'código de salida $code';
  }

  @override
  String get settingsTerminalScheme => 'Esquema de colores del terminal';

  @override
  String get settingsTerminalSchemeDesc =>
      'Elija la paleta de colores ANSI para los terminales SSH.';

  @override
  String get settingsSectionDataTransfer => 'Importar y exportar';

  @override
  String get transferSnippetsTitle => 'Fragmentos de comandos';

  @override
  String get transferServersTitle => 'Configuraciones de servidores';

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
  String get transferCopied => 'Copiado al portapapeles';

  @override
  String get transferImportHint => 'Pegue aquí el JSON exportado…';

  @override
  String get transferSnippetsEmpty =>
      'No hay fragmentos de comandos que exportar.';

  @override
  String get transferServersEmpty => 'No hay servidores que exportar.';

  @override
  String get transferImportNothing =>
      'No se encontraron elementos válidos en la importación.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragmentos importados',
      one: '1 fragmento importado',
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
    return 'Error al importar: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Error al exportar: $message';
  }

  @override
  String transferExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionsTitle => 'Conversaciones';

  @override
  String get sessionsNew => 'Nueva conversación';

  @override
  String get sessionsSearch => 'Buscar conversaciones…';

  @override
  String get sessionsEmpty => 'Aún no hay conversaciones';

  @override
  String sessionsNoMatch(String query) {
    return 'Sin coincidencias: \"$query\"';
  }

  @override
  String get sessionsRename => 'Renombrar';

  @override
  String get sessionsRenameHint => 'Título de la conversación';

  @override
  String get sessionsDelete => 'Eliminar';

  @override
  String sessionsDeleteConfirm(String title) {
    return '¿Eliminar \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes',
      one: '1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsTitle => 'Alertas en segundo plano';

  @override
  String get settingsNotificationsDesc =>
      'Avisar cuando se caiga una sesión SSH o termine una tarea de IA mientras la app está en segundo plano.';

  @override
  String get sftpTitle => 'Archivos';

  @override
  String get sftpNotConnected => 'No está conectado a este servidor.';

  @override
  String get sftpLoading => 'Cargando archivos…';

  @override
  String get sftpEmpty => 'Esta carpeta está vacía.';

  @override
  String get sftpDownload => 'Descargar';

  @override
  String sftpDownloaded(String path, int size) {
    return 'Descargado $path ($size bytes)';
  }

  @override
  String get sftpDownloadFailed => 'Error al descargar';

  @override
  String get sftpPreviewError => 'Error al previsualizar';

  @override
  String get sftpNewFolderName => 'Nueva carpeta';

  @override
  String get sftpRefresh => 'Actualizar';

  @override
  String get sftpDelete => 'Eliminar';

  @override
  String sftpDeleteConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get sftpRename => 'Renombrar';

  @override
  String get sftpTooltip => 'Explorar archivos (SFTP)';

  @override
  String get terminalMoreTooltip => 'Más';

  @override
  String get tunnelsTitle => 'Reenvío de puertos';

  @override
  String get tunnelsEmpty => 'No hay túneles activos.';

  @override
  String get tunnelsAddLocal => 'Reenvío local';

  @override
  String get tunnelsAddRemote => 'Reenvío remoto';

  @override
  String get tunnelsLocalPort => 'Puerto local';

  @override
  String get tunnelsRemoteHost => 'Host remoto';

  @override
  String get tunnelsRemotePort => 'Puerto remoto';

  @override
  String get tunnelsAdd => 'Añadir';

  @override
  String get tunnelsClose => 'Cerrar';

  @override
  String get tunnelsTooltip => 'Reenvío de puertos (túnel SSH)';

  @override
  String get tunnelsError => 'Error en el túnel';

  @override
  String get tunnelsInvalidPort => 'El puerto debe estar entre 1 y 65535.';

  @override
  String get settingsLanguageTitle => 'Idioma';
}
