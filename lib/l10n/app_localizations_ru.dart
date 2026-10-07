// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => 'Серверы';

  @override
  String get navAiChat => 'AI-чат';

  @override
  String get navSettings => 'Настройки';

  @override
  String get pageNotFound => 'Страница не найдена';

  @override
  String get backToServers => 'Назад к серверам';

  @override
  String get serversTitle => 'Серверы';

  @override
  String serversHostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хоста',
      many: '$count хостов',
      few: '$count хоста',
      one: '1 хост',
    );
    return '$_temp0';
  }

  @override
  String get serversSearch => 'Поиск серверов…';

  @override
  String get serversAdd => 'Добавить сервер';

  @override
  String get serversEmpty => 'Пока нет серверов';

  @override
  String get serversEmptyHint => 'Добавьте первый SSH-сервер, чтобы начать.';

  @override
  String get serversDeleteConfirmTitle => 'Удалить сервер';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return 'Удалить \"$name\"?\n\n$identity:$port и его сохранённые учётные данные будут удалены навсегда.';
  }

  @override
  String serversDeleted(String identity) {
    return 'Удалён $identity';
  }

  @override
  String serversDeleteFailed(String message) {
    return 'Не удалось удалить: $message';
  }

  @override
  String get serversLoading => 'Загрузка серверов';

  @override
  String get serversUngrouped => 'Без группы';

  @override
  String get serversSortName => 'а–я';

  @override
  String get serversSortRecent => 'недавние';

  @override
  String get serversQuickStart => 'Быстрый старт';

  @override
  String get serversQuickStep1Title => 'Добавьте хост';

  @override
  String get serversQuickStep1Desc =>
      'Зарегистрируйте SSH-узел с аутентификацией по паролю или ключу.';

  @override
  String get serversQuickStep2Title => 'Проверьте соединение';

  @override
  String get serversQuickStep2Desc =>
      'Проверьте порт перед сохранением — это быстро выявляет опечатки.';

  @override
  String get serversQuickStep3Title => 'Подключитесь';

  @override
  String get serversQuickStep3Desc =>
      'Откройте сеанс терминала — полный PTY, цвета и vim.';

  @override
  String serversNoMatch(String query) {
    return 'Совпадений нет: \"$query\"';
  }

  @override
  String get serversClearFilter => 'Сбросить фильтр';

  @override
  String get serversReadError => 'Не удалось прочитать список серверов.';

  @override
  String get serverEditTitle => 'Добавить сервер';

  @override
  String get serverEditTitleEdit => 'Изменить сервер';

  @override
  String get serverNotFound => 'Сервер не найден';

  @override
  String get serverValidationNameRequired => 'Укажите имя';

  @override
  String get serverValidationHostRequired => 'Укажите хост';

  @override
  String get serverValidationNoSpaces => 'Пробелы не допускаются';

  @override
  String get serverValidationRequired => 'Обязательно';

  @override
  String get serverValidationNumeric => 'Число';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => 'Укажите имя пользователя';

  @override
  String get serverValidationPasswordRequired => 'Укажите пароль';

  @override
  String get serverValidationPrivateKeyRequired => 'Укажите закрытый ключ';

  @override
  String serverAdded(String identity, int port) {
    return 'Сервер добавлен: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return 'Сохранено: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return 'Не удалось сохранить: $message';
  }

  @override
  String get serverTestEnterHost => 'Сначала укажите адрес хоста';

  @override
  String serverTestProbing(String host, int port) {
    return 'Проверка $host:$port…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — доступен';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — истекло время ожидания';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — отклонено / недоступно';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — проверка не удалась';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port — ошибка рукопожатия SSH';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port — ошибка аутентификации: проверьте имя пользователя и учётные данные';
  }

  @override
  String get serverLoading => 'Загрузка';

  @override
  String get serverSaveChanges => 'Сохранить изменения';

  @override
  String get serverSectionIdentity => 'Идентификация';

  @override
  String get serverSectionConnection => 'Соединение';

  @override
  String get serverSectionAuthentication => 'Аутентификация';

  @override
  String get serverFieldLabel => 'Метка';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => 'Группа (необязательно)';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => 'Хост';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => 'Порт';

  @override
  String get serverFieldUsername => 'Имя пользователя';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => 'Пароль';

  @override
  String get serverFieldPasswordStored =>
      'Сохранён — оставьте пустым, чтобы не изменять';

  @override
  String get serverFieldPrivateKey => 'Закрытый ключ (PEM)';

  @override
  String get serverFieldPassphrase => 'Парольная фраза ключа (необязательно)';

  @override
  String get serverAuthPassword => 'Пароль';

  @override
  String get serverAuthPrivateKey => 'Закрытый ключ';

  @override
  String get serverTestIdle =>
      'Нажмите \"Проверить\", чтобы проверить соединение';

  @override
  String get serverSecurityNote =>
      'Учётные данные шифруются в хранилище ключей устройства — они не попадают в хранилище метаданных Hive и не покидают это устройство.';

  @override
  String get serverTesting => 'Проверка…';

  @override
  String get serverTest => 'Проверить';

  @override
  String get serverSaving => 'Сохранение…';

  @override
  String serverCopiedAddress(String address) {
    return 'Скопировано $address';
  }

  @override
  String get serverActions => 'Действия с сервером';

  @override
  String get serverActionConnect => 'Подключиться';

  @override
  String get serverActionEdit => 'Изменить';

  @override
  String get serverActionEditDetails => 'Изменить данные';

  @override
  String get serverActionCopySsh => 'Копировать SSH-команду';

  @override
  String get serverActionDelete => 'Удалить';

  @override
  String get serverActionDeleteServer => 'Удалить сервер';

  @override
  String get serverOnline => 'В сети';

  @override
  String get serverNeverConnected => 'Не подключался';

  @override
  String get serverJustNow => 'Только что';

  @override
  String serverMinutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String serverHoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String serverDaysAgo(int days) {
    return '$days дн назад';
  }

  @override
  String get terminalHostNotFound => 'Хост не найден';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'Нет сохранённого сервера с идентификатором \"$id\". Возможно, он был удалён.';
  }

  @override
  String get terminalBackToServers => 'Назад к серверам';

  @override
  String get terminalConnectionFailed => 'Не удалось подключиться.';

  @override
  String get terminalSessionClosed => 'Сеанс закрыт';

  @override
  String terminalSessionClosedMessage(String name) {
    return 'Соединение с $name было прервано.';
  }

  @override
  String get terminalReconnect => 'Переподключиться';

  @override
  String get terminalAuthenticating => 'Аутентификация';

  @override
  String get terminalConnecting => 'Подключение';

  @override
  String get terminalResolvingHost => 'Разрешение имени хоста…';

  @override
  String get terminalTooltipDisconnectBack => 'Отключиться и назад';

  @override
  String get terminalTooltipSmallerText => 'Уменьшить текст';

  @override
  String get terminalTooltipLargerText => 'Увеличить текст';

  @override
  String get terminalTooltipDisconnect => 'Отключиться';

  @override
  String get terminalRetryAvailable => 'Повтор доступен';

  @override
  String get terminalStatusConnected => 'ПОДКЛЮЧЕНО';

  @override
  String get terminalStatusOffline => 'НЕ В СЕТИ';

  @override
  String get terminalStatusError => 'ОШИБКА';

  @override
  String get aiChatTitle => 'AI-ассистент';

  @override
  String get aiChatStatusSetup => 'НАСТРОЙКА';

  @override
  String get aiChatStatusStreaming => 'ПОТОК';

  @override
  String get aiChatStatusReady => 'ГОТОВО';

  @override
  String get aiChatClearConversation => 'Очистить диалог';

  @override
  String get aiChatSuggestion1 =>
      'Объясните, что означает вывод команды ls -la';

  @override
  String get aiChatSuggestion2 => 'Как узнать, какой процесс занимает порт?';

  @override
  String get aiChatSuggestion3 =>
      'Покажите, как просматривать журналы и искать в них ошибки с помощью grep';

  @override
  String get aiChatSuggestion4 =>
      'Напишите однострочник на awk для суммирования столбца CSV';

  @override
  String get aiChatTryAsking => 'Попробуйте спросить';

  @override
  String get aiChatIntroTitle => 'Ваш помощник по терминалу';

  @override
  String get aiChatIntroBody =>
      'Вставьте команду, ошибку или фрагмент вывода журнала. ShellMind объяснит, что произошло, подскажет следующий шаг и напишет команды за вас.';

  @override
  String get aiChatNoKeyTitle => 'API-ключ не настроен';

  @override
  String aiChatNoKeyMessage(String provider) {
    return 'Добавьте API-ключ $provider, чтобы активировать ассистента. Он хранится в зашифрованном виде на этом устройстве и не покидает его, кроме как для вызова модели.';
  }

  @override
  String get aiChatOpenSettings => 'Открыть настройки AI';

  @override
  String get aiChatCheckingCredentials => 'Проверка учётных данных';

  @override
  String get aiChatInputHint => 'Спросите о чём угодно…';

  @override
  String get aiChatInputDisabled => 'Укажите API-ключ, чтобы начать';

  @override
  String get aiChatError => 'Ошибка';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => 'Скопировано';

  @override
  String get aiChatCopy => 'Копировать';

  @override
  String get aiChatThinking => 'Обдумываю…';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSearchTooltip => 'Поиск по настройкам';

  @override
  String get settingsStable => 'СТАБИЛЬНАЯ';

  @override
  String get settingsSectionAppearance => 'Внешний вид и язык';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsSectionLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Системный';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'Провайдер AI';

  @override
  String get settingsSectionAiAgent => 'AI-агент';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => 'Серверы';

  @override
  String get settingsSectionAboutUpdate => 'О приложении и обновление';

  @override
  String get settingsSectionStoragePrivacy => 'Хранилище и конфиденциальность';

  @override
  String get settingsSectionResources => 'Ресурсы';

  @override
  String get settingsTileSecrets => 'Секреты';

  @override
  String get settingsTileEncrypted => 'Зашифровано';

  @override
  String get settingsTileLocalCache => 'Локальный кэш';

  @override
  String get settingsTileClearData => 'Удалить все данные';

  @override
  String get settingsTileLicenses => 'Лицензии открытого ПО';

  @override
  String get settingsTileReportIssue => 'Сообщить о проблеме';

  @override
  String get settingsFooter =>
      'SSH + AI-ассистент для современных рабочих процессов';

  @override
  String get settingsSecretsDialogTitle => 'Секреты и шифрование';

  @override
  String get settingsSecretsDialogBody =>
      'Учётные данные — пароли серверов, закрытые ключи и API-ключи AI — всегда шифруются в состоянии хранения с помощью системного хранилища ключей (Android Keystore / iOS Keychain). Эта защита предусмотрена по умолчанию и не может быть отключена. Чтобы изменить учётные данные, отредактируйте или удалите их на странице редактирования сервера или в настройках AI.';

  @override
  String get settingsDialogOk => 'OK';

  @override
  String get settingsDialogClose => 'Закрыть';

  @override
  String get settingsCacheDialogTitle => 'Локальный кэш';

  @override
  String get settingsCacheHiveData => 'Данные приложения';

  @override
  String get settingsCacheDownloads => 'Загруженные обновления';

  @override
  String get settingsCacheTotal => 'Итого';

  @override
  String get settingsCacheDialogHint =>
      'Очистка кэша загрузок удаляет загруженные пакеты обновлений (APK). Ваши серверы, ключи и история чата сохраняются.';

  @override
  String get settingsCacheClearDownloads => 'Очистить кэш загрузок';

  @override
  String settingsCacheCleared(String freed) {
    return 'Освобождено $freed';
  }

  @override
  String get settingsClearDataTitle => 'Удалить все данные?';

  @override
  String get settingsClearDataMessage =>
      'Это навсегда удалит все серверы, сохранённые учётные данные, ключи AI, историю чата и настройки на этом устройстве. Это действие необратимо.';

  @override
  String get settingsClearDataConfirm => 'Удалить всё';

  @override
  String get settingsDataCleared => 'Все данные удалены';

  @override
  String settingsClearDataFailed(String message) {
    return 'Не удалось удалить данные: $message';
  }

  @override
  String get settingsIssueLinkCopied =>
      'Ссылка на проблему скопирована в буфер обмена.';

  @override
  String get settingsAboutGithub => 'Репозиторий GitHub';

  @override
  String get settingsHideIp => 'Скрывать IP-адреса';

  @override
  String get settingsHideIpDesc =>
      'Скрывать IP-адреса в списке серверов и на страницах AI';

  @override
  String get serverMaskedAddress => 'Адрес скрыт';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return 'API-ключ $provider';
  }

  @override
  String get aiSettingsKeySet => 'задан';

  @override
  String get aiSettingsKeyNotConfigured => 'не настроен';

  @override
  String get aiSettingsGetApiKey => 'Получить API-ключ';

  @override
  String get aiSettingsTemperature => 'Температура';

  @override
  String get aiSettingsRemoveKey => 'Удалить ключ';

  @override
  String aiSettingsKeySaved(String provider) {
    return 'API-ключ $provider сохранён безопасно.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return 'Удалить ключ $provider?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      'Ассистент перестанет работать с этим провайдером, пока не будет добавлен новый ключ.';

  @override
  String get aiSettingsRemoveKeyConfirm => 'Удалить';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return 'Получить ключ $provider';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      'Откройте консоль провайдера в браузере, чтобы создать API-ключ, затем вставьте его сюда.';

  @override
  String get aiSettingsClose => 'Закрыть';

  @override
  String get aiSettingsLinkCopied => 'Ссылка скопирована в буфер обмена.';

  @override
  String get aiSettingsCopyLink => 'Копировать ссылку';

  @override
  String get aiSettingsKeyConfigured => 'Ключ настроен';

  @override
  String get aiSettingsNotConfigured => 'Не настроен';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return 'Обновить ключ $provider';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return 'Добавить ключ $provider';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      'Хранится в зашифрованном виде на этом устройстве. Используется только для вызова провайдера AI.';

  @override
  String get aiSettingsApiKeyHint => 'API-ключ…';

  @override
  String get aiSettingsSave => 'Сохранить';

  @override
  String get modelDescFastAffordable => 'Быстрая и доступная';

  @override
  String get modelDescMostCapable => 'Наиболее функциональная';

  @override
  String get modelDescLegacyFast => 'Прежняя быстрая';

  @override
  String get modelDescGeneralConversation => 'Обычный диалог';

  @override
  String get modelDescAdvancedReasoning => 'Продвинутое рассуждение';

  @override
  String get modelDescFastResponse => 'Быстрый отклик';

  @override
  String get modelDescBalanced => 'Сбалансированная';

  @override
  String get modelDescFreeFast => 'Бесплатная и быстрая';

  @override
  String get modelDescEnhanced => 'Улучшенная';

  @override
  String get modelDescStandard => 'Стандартная';

  @override
  String get modelDescLightweight => 'Облегчённая';

  @override
  String get modelDescRlEnhanced => 'Улучшенная RL';

  @override
  String get aiModelsTitle => 'Модель';

  @override
  String get aiModelsRefresh => 'Обновить список моделей';

  @override
  String get aiModelsAddCustom => 'Добавить свою модель';

  @override
  String get aiModelsAddCustomHint =>
      'Идентификатор модели, напр. deepseek-chat';

  @override
  String get aiModelsAdd => 'Добавить';

  @override
  String get aiModelsCustomBadge => 'Своя';

  @override
  String get aiModelsFetchFailed =>
      'Не удалось загрузить модели — показан встроенный список.';

  @override
  String get aiModelsRemoveCustom => 'Удалить свою модель';

  @override
  String get aiModelsEmpty => 'Нет моделей';

  @override
  String get aiModelsInvalidId => 'Укажите идентификатор модели.';

  @override
  String get aiModelsDuplicate => 'Эта модель уже есть в списке.';

  @override
  String get aiModelsPickerTitle => 'Выберите модель';

  @override
  String get aiModelsSearchHint => 'Поиск моделей';

  @override
  String get aiModelsSearchEmpty => 'Нет моделей, соответствующих поиску.';

  @override
  String get aiProvidersAddTile => 'Добавить своего провайдера';

  @override
  String get aiProvidersAddTitle => 'Добавить своего провайдера';

  @override
  String get aiProvidersFieldName => 'Имя';

  @override
  String get aiProvidersFieldNameHint => 'напр. SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => 'Базовый URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => 'Модель по умолчанию (необязательно)';

  @override
  String get aiProvidersFieldModelHint =>
      'Идентификатор модели, напр. deepseek-chat';

  @override
  String get aiProvidersAddConfirm => 'Добавить';

  @override
  String get aiProvidersInvalidInput => 'Укажите имя и базовый URL.';

  @override
  String get aiProvidersInvalidUrl =>
      'Базовый URL должен начинаться с http:// или https://';

  @override
  String get aiProvidersDuplicateName =>
      'Провайдер с таким именем уже существует.';

  @override
  String get aiProvidersAdded => 'Свой провайдер добавлен.';

  @override
  String get aiProvidersAddFailed =>
      'Не удалось добавить провайдера — проверьте введённые данные.';

  @override
  String get aiProvidersDeleteTile => 'Удалить своего провайдера';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return 'Удалить $provider?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      'Его сохранённый API-ключ, запомненная модель и свои модели также будут удалены. Встроенных провайдеров удалить нельзя.';

  @override
  String get aiProvidersDeleteConfirm => 'Удалить';

  @override
  String get aiProvidersPickerTitle => 'Выберите провайдера';

  @override
  String get updateVersion => 'Версия';

  @override
  String get updateSoftwareUpdate => 'Обновление ПО';

  @override
  String get updateChecking => 'ПРОВЕРКА';

  @override
  String get updateUpToDate => 'АКТУАЛЬНО';

  @override
  String get updateCheckAgain => 'Проверить снова';

  @override
  String get updateReady => 'ГОТОВО';

  @override
  String get updateNew => 'НОВОЕ';

  @override
  String get updateCheck => 'ПРОВЕРИТЬ';

  @override
  String get updateAwaitingResponse => 'Ожидание ответа';

  @override
  String get updateAlreadyLatest => 'Уже установлена последняя сборка';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version — это последний выпуск, опубликованный на GitHub.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'Запущена v$current — последняя удалённая версия v$latest.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return 'Проверено $timeAgo';
  }

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updatePre => 'ПРЕДРЕЛИЗ';

  @override
  String get updateDownloadInstall => 'Скачать и установить';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateApkHint =>
      'Установка APK поддерживается только на Android. Файл всё равно можно скачать здесь.';

  @override
  String updateDownloading(String tag) {
    return 'Загрузка $tag';
  }

  @override
  String get updateSize => 'размер';

  @override
  String get updateRate => 'скорость';

  @override
  String get updateEta => 'осталось';

  @override
  String get updateElapsed => 'прошло';

  @override
  String get updateCancel => 'Отмена';

  @override
  String get updateKeepForeground => 'Держать приложение на переднем плане';

  @override
  String get updateDownloadComplete => 'Загрузка завершена';

  @override
  String get updateInstallHint =>
      'Android попросит подтверждения. ShellMind закроется на время работы установщика; ваши серверы и история сохранятся.';

  @override
  String get updateLaunching => 'Запуск...';

  @override
  String get updateInstallNow => 'Установить сейчас';

  @override
  String get updateDelete => 'Удалить';

  @override
  String updateInstallTitle(String tag) {
    return 'Установить $tag?';
  }

  @override
  String get updateInstallMessage =>
      'Откроется системный установщик пакетов. ShellMind закроется во время установки и снова откроется в новой версии.';

  @override
  String get updateNotNow => 'Не сейчас';

  @override
  String get updateInstall => 'Установить';

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления.';

  @override
  String get updateErrorTitleNoReleases => 'Нет выпусков';

  @override
  String get updateErrorTitleGeneric => 'Не удалось проверить обновления';

  @override
  String get updateErrNoReleases =>
      'Для ShellMind ещё не опубликовано ни одного выпуска.';

  @override
  String get updateErrRateLimit =>
      'Достигнут лимит запросов API GitHub. Попробуйте позже.';

  @override
  String get updateErrTimeout =>
      'Истекло время ожидания запроса к GitHub. Проверьте соединение и повторите.';

  @override
  String get updateErrNetwork =>
      'Не удалось связаться с GitHub. Проверьте сетевое соединение.';

  @override
  String get updateErrAuth => 'GitHub отклонил запрос обновления.';

  @override
  String get updateErrPermission => 'В запросе обновления отказано.';

  @override
  String get updateErrStorage =>
      'Недостаточно места для завершения обновления.';

  @override
  String get updateErrDigestMismatch =>
      'Загруженное обновление не прошло проверку целостности SHA-256 и было удалено. Повторите загрузку.';

  @override
  String get updateErrDigestMissing =>
      'У пакета обновления нет опубликованной контрольной суммы целостности, поэтому обновление было отклонено. Повторите позже.';

  @override
  String get updateRetry => 'Повторить';

  @override
  String get updateDismiss => 'Закрыть';

  @override
  String updateReleaseNotes(String tag) {
    return 'Выпуск $tag';
  }

  @override
  String get updateNotesLabel => 'примечания';

  @override
  String get updateNewVersionAvailable => 'Доступна новая версия';

  @override
  String get updateRemindLater => 'Напомнить позже';

  @override
  String get updateCancelDownload => 'Отменить загрузку';

  @override
  String updateInstallTag(String tag) {
    return 'Установить $tag';
  }

  @override
  String get updateInstallLaterFromSettings => 'Установить позже из настроек';

  @override
  String get updateCouldNotComplete => 'Не удалось завершить обновление.';

  @override
  String get updateClose => 'Закрыть';

  @override
  String get updatePromptInstallHint =>
      'Android закрывает ShellMind на время работы установщика. Серверы, ключи и история чата сохраняются.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String get commonNoData => 'Нет данных';

  @override
  String get commonNothingToShow => 'Здесь пока нечего показывать.';

  @override
  String get commonOk => 'OK';

  @override
  String get settingsAiAutoExecuteTitle => 'Автовыполнение команд';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'Разрешить AI-агенту выполнять разобранные команды без запроса каждый раз';

  @override
  String get settingsAiAutoConnectTitle => 'Автоподключение AI к серверам';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'Разрешить AI-ассистенту автоматически подключаться к настроенным, но офлайн-серверам и выполнять на них команды (будут использованы сохранённые учётные данные)';

  @override
  String get settingsAiMaxAutoLoopsTitle => 'Макс. число итераций автоцикла';

  @override
  String get settingsAiMaxAutoLoopsSub =>
      'Ограничить число автоматических выполнений команд на один ответ';

  @override
  String get settingsAiMaxAutoLoopsTileDesc =>
      'Макс. число раундов команд, которые AI может выполнить на задачу';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'Это верхний предел раундов выполнения на одну задачу AI — не число попыток переподключения SSH (оно настраивается в разделе SSH).';

  @override
  String get terminalAskAi => 'Спросить AI';

  @override
  String get terminalAskAiSubtitle =>
      'Отправить выделенный текст AI-ассистенту';

  @override
  String get terminalTooltipAskAi => 'Спросить AI';

  @override
  String get aiChatNoConnection => 'Сначала подключитесь к терминалу сервера';

  @override
  String get aiChatAnalyzePrompt =>
      'Проанализируйте вывод команды выше, объясните, что означает результат, и при необходимости дайте дальнейшие рекомендации.';

  @override
  String get aiExecuteButton => 'Выполнить на сервере';

  @override
  String get aiExecuteTitle => 'Подтвердите выполнение команды';

  @override
  String get aiExecuteConfirmButton => 'Выполнить';

  @override
  String get aiExecuteConfirmAnyway => 'Всё равно выполнить';

  @override
  String get aiExecuteDangerWarning => '⚠ Опасная команда';

  @override
  String get aiExecuteDangerText =>
      'Эта команда может быть разрушительной и привести к потере данных или повреждению системы.';

  @override
  String get aiExecuteCommandLabel => 'Команда для выполнения:';

  @override
  String get aiExecuteTargetServer => 'Целевой сервер(ы):';

  @override
  String get aiExecuteSelectServer => 'Выберите целевой сервер(ы)';

  @override
  String get aiExecuteNoServer => 'Сначала подключитесь к серверу';

  @override
  String get aiExecuteAtLeastOne => 'Выберите хотя бы один сервер';

  @override
  String get aiExecuteSelectHint =>
      'Выберите сервер(ы), на которых выполнить эту команду';

  @override
  String aiExecuteRunCount(int count) {
    return 'Выполнить ($count)';
  }

  @override
  String get aiExecuteSelectAll => 'Выбрать все';

  @override
  String get aiExecuteClearSelection => 'Сбросить';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours ч $minutes мин в сети';
  }

  @override
  String get aiExecuteSuccess => 'Команда выполнена успешно';

  @override
  String get aiExecuteFailed => 'Не удалось выполнить команду';

  @override
  String get aiServerManageTitle => 'Серверы';

  @override
  String get aiServerManageSubtitle =>
      'Подключите серверы, чтобы AI-ассистент мог работать';

  @override
  String aiServerOnlineCount(int count) {
    return '$count в сети';
  }

  @override
  String get aiServerDone => 'Готово';

  @override
  String get aiServerConnecting => 'Подключение…';

  @override
  String get aiServerOffline => 'Не в сети';

  @override
  String get aiServerNoCredential =>
      'Нет сохранённых учётных данных — сначала сохраните пароль или ключ на странице сервера';

  @override
  String get aiServerConnectFailed => 'Не удалось подключиться';

  @override
  String get aiToolResultCommand => 'Команда';

  @override
  String get aiToolResultOutput => 'Вывод команды';

  @override
  String aiToolResultExitCode(int code) {
    return 'Код завершения: $code';
  }

  @override
  String get aiToolResultElapsed => 'Затраченное время';

  @override
  String get aiToolResultAnalyzeButton => 'Попросить AI проанализировать вывод';

  @override
  String aiToolResultCollapsedShow(int total) {
    return 'Ещё $total строк';
  }

  @override
  String get aiToolResultExpandedHide => 'Скрыть вывод';

  @override
  String get aiToolResultStderrLabel => 'Вывод ошибок:';

  @override
  String get aiContextToggleAttach => 'Прикрепить контекст терминала';

  @override
  String get aiContextToggleDetach => 'Контекст терминала прикреплён';

  @override
  String get aiContextBadge => 'Контекст';

  @override
  String aiContextLines(int lines) {
    return '$lines строк из терминала';
  }

  @override
  String get aiAgentStop => 'Остановить авторежим';

  @override
  String get aiAgentExecuting => 'Выполнение…';

  @override
  String get aiAgentDefaultServer => 'сервер';

  @override
  String get aiTimelineTitle => 'Хронология выполнения';

  @override
  String get aiTimelineOpen => 'Хронология выполнения';

  @override
  String get aiTimelineEmpty => 'Команды ещё не выполнялись';

  @override
  String get aiTimelineEmptyHint =>
      'Выполняйте команды через чат или авторежим, и вся цепочка появится здесь.';

  @override
  String aiTimelineStatRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раунда',
      many: '$count раундов',
      few: '$count раунда',
      one: '1 раунд',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count команды',
      many: '$count команд',
      few: '$count команды',
      one: '1 команда',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count успешно',
      many: '$count успешно',
      few: '$count успешно',
      one: '1 успешно',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStatFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count с ошибкой',
      many: '$count с ошибкой',
      few: '$count с ошибкой',
      one: '1 с ошибкой',
    );
    return '$_temp0';
  }

  @override
  String aiTimelineStarted(String time) {
    return 'Начато $time';
  }

  @override
  String aiTimelineEnded(String time) {
    return 'Завершено $time';
  }

  @override
  String aiTimelineExitCode(int code) {
    return 'Код завершения: $code';
  }

  @override
  String get aiTimelineNoExitCode => 'Нет кода завершения';

  @override
  String get aiTimelineOutput => 'Вывод';

  @override
  String get aiTimelineOutputEmpty => 'Нет вывода';

  @override
  String get aiTimelineErrorOutput => 'Вывод ошибок';

  @override
  String get aiTimelineRunning => 'Выполняется…';

  @override
  String get aiTimelineClose => 'Закрыть';

  @override
  String get sshReconnectToggle => 'Автопереподключение при разрыве';

  @override
  String get sshReconnectToggleDesc =>
      'Повторять оборванные SSH-сеансы с экспоненциальной задержкой';

  @override
  String get sshReconnectMaxAttempts => 'Макс. число попыток переподключения';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      'Максимальное число автоматических попыток переподключения после разрыва — 0 означает повторять до успеха';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => 'Без ограничений';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return 'Переподключение (попытка $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return 'Переподключение (попытка $attempt из $max)';
  }

  @override
  String get sshReconnectGaveUp => 'Автопереподключение прекращено';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return 'Не удалось связаться с $name после $max попыток.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return 'Не удалось связаться с $name.';
  }

  @override
  String get sshReconnectRetryNow => 'Повторить сейчас';

  @override
  String get sshReconnectStopAuto => 'Остановить';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return 'Переподключено к $name';
  }

  @override
  String get snippetsTitle => 'Сниппеты команд';

  @override
  String get snippetsSubtitle =>
      'Сохраняйте команды для быстрого повторного использования';

  @override
  String get snippetsAddTooltip => 'Добавить сниппет';

  @override
  String get snippetsAddTitle => 'Новый сниппет';

  @override
  String get snippetsSave => 'Сохранить';

  @override
  String get snippetsCommandLabel => 'Команда';

  @override
  String get snippetsCommandHint => 'напр. docker ps -a';

  @override
  String get snippetsNameLabel => 'Имя (необязательно)';

  @override
  String get snippetsNameHint => 'напр. Список всех контейнеров';

  @override
  String get snippetsCommandRequired => 'Текст команды обязателен';

  @override
  String get snippetsDeleteTooltip => 'Удалить сниппет';

  @override
  String get snippetsEmptyTitle => 'Пока нет сниппетов';

  @override
  String get snippetsEmptyMessage =>
      'Сохраняйте часто используемые команды и вставляйте или запускайте их одним касанием.';

  @override
  String get snippetsLoadFailed => 'Не удалось загрузить сниппеты';

  @override
  String get healthTitle => 'Состояние парка серверов';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total в сети';
  }

  @override
  String get healthProbing => 'Проверка…';

  @override
  String get healthProbeTooltip => 'Запустить проверку состояния';

  @override
  String healthProbedAt(String time) {
    return 'Проверено в $time';
  }

  @override
  String get healthMoodAllOnline => 'Все системы в норме';

  @override
  String get healthMoodDegraded => 'Некоторые серверы недоступны';

  @override
  String get healthMoodAllOffline => 'Все серверы недоступны';

  @override
  String healthOfflineServers(String names) {
    return 'Не в сети: $names';
  }

  @override
  String get healthNoData =>
      'Нажмите «Обновить», чтобы проверить каждый сервер';

  @override
  String healthUptime(String brief) {
    return 'работает $brief';
  }

  @override
  String healthLoad(String value) {
    return 'нагрузка $value';
  }

  @override
  String get healthDiagIntro => 'Вот отчёт о состоянии моего парка серверов:';

  @override
  String healthDiagStats(int online, int total) {
    return '$online из $total серверов в сети.';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name: не в сети';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name: в сети ($details)';
  }

  @override
  String get healthDiagOutro =>
      'Проанализируйте данные о состоянии, отметьте всё необычное (высокая нагрузка, недавние перезагрузки) и предложите, что проверить дальше.';

  @override
  String get healthDiagnose => 'Диагностика AI';

  @override
  String get healthStaleNote =>
      'Некоторые серверы ушли в офлайн с момента последней проверки.';

  @override
  String get auditTitle => 'Журнал аудита команд';

  @override
  String get auditTileDesc => 'Команды, выполненные AI-агентом';

  @override
  String get auditEmptyTitle => 'Пока нет записей аудита';

  @override
  String get auditEmptyMessage =>
      'Здесь будут записываться команды, выполненные AI-агентом.';

  @override
  String get auditFilteredEmpty =>
      'Нет записей, соответствующих текущему фильтру';

  @override
  String get auditFilterAllServers => 'Все серверы';

  @override
  String get auditFilterAllModes => 'Все режимы';

  @override
  String get auditFilterAllResults => 'Все результаты';

  @override
  String get auditFilterConfirmed => 'Подтверждённые';

  @override
  String get auditFilterAuto => 'Авто';

  @override
  String get auditFilterSuccess => 'Успешно';

  @override
  String get auditFilterFailed => 'С ошибкой';

  @override
  String get auditModeConfirmed => 'Подтверждено';

  @override
  String get auditModeAuto => 'Авто';

  @override
  String get auditStatusSuccess => 'Успешно';

  @override
  String get auditStatusFailed => 'С ошибкой';

  @override
  String get auditDangerousBadge => 'Опасная';

  @override
  String auditExitCode(int code) {
    return 'Код завершения $code';
  }

  @override
  String get auditOutputSummary => 'Сводка вывода';

  @override
  String get auditNoOutput => 'Нет вывода';

  @override
  String get auditClearTooltip => 'Очистить журнал аудита';

  @override
  String get auditClearConfirmTitle => 'Очистить журнал аудита';

  @override
  String auditClearConfirmMessage(int count) {
    return 'Все $count записей аудита будут удалены навсегда.';
  }

  @override
  String get auditClearAction => 'Очистить';

  @override
  String get auditCleared => 'Журнал аудита очищен';

  @override
  String auditEntriesCount(int count) {
    return '$count записей';
  }

  @override
  String get serverActionDisconnect => 'Отключиться';

  @override
  String get exportChatAction => 'Экспортировать в Markdown';

  @override
  String get exportChatEmpty => 'Пока нечего экспортировать';

  @override
  String exportChatSuccess(String path) {
    return 'Диалог экспортирован в $path';
  }

  @override
  String exportChatFailed(String error) {
    return 'Не удалось экспортировать: $error';
  }

  @override
  String get diagTitle => 'Диагностика';

  @override
  String get diagTileDesc => 'Ошибки приложения и экспорт диагностики';

  @override
  String get diagEmptyTitle => 'Ошибок не зафиксировано';

  @override
  String get diagEmptyMessage =>
      'Неперехваченные исключения записываются здесь, чтобы помочь с отчётами о проблемах.';

  @override
  String diagEntriesCount(int count) {
    return '$count ошибок';
  }

  @override
  String get diagSourceFlutter => 'Ошибка интерфейса';

  @override
  String get diagSourcePlatform => 'Ошибка выполнения';

  @override
  String get diagSourceZone => 'Асинхронная задача';

  @override
  String get diagStackTrace => 'Трассировка стека';

  @override
  String get diagNoStackTrace => 'Нет трассировки стека';

  @override
  String get diagExportAction => 'Экспортировать диагностический отчёт';

  @override
  String get diagExportEmpty =>
      'Нечего сообщать — экспортируются основные сведения';

  @override
  String diagExportSuccess(String path) {
    return 'Диагностический отчёт экспортирован в $path';
  }

  @override
  String diagExportFailed(String error) {
    return 'Не удалось экспортировать: $error';
  }

  @override
  String get diagPrivacyNote =>
      'Содержимое диагностики отредактировано — пароли, закрытые ключи и API-ключи не включаются.';

  @override
  String get diagClearTooltip => 'Очистить записи об ошибках';

  @override
  String get diagClearConfirmTitle => 'Очистить записи об ошибках';

  @override
  String diagClearConfirmMessage(int count) {
    return 'Все $count записей об ошибках будут удалены навсегда.';
  }

  @override
  String get diagClearAction => 'Очистить';

  @override
  String get diagCleared => 'Записи об ошибках очищены';

  @override
  String get diagAppInfoTitle => 'Сведения о приложении';

  @override
  String get diagAppInfoVersion => 'Версия';

  @override
  String get diagAppInfoPlatform => 'Платформа';

  @override
  String get diagAppInfoLocale => 'Язык';

  @override
  String get diagAppInfoStorage => 'Размер локальных данных';

  @override
  String get authLockToggleTitle => 'Биометрическая блокировка';

  @override
  String get authLockToggleDesc =>
      'Требовать разблокировку по отпечатку пальца или лицу при открытии приложения';

  @override
  String get authLockEnableFailed =>
      'Проверка не пройдена — блокировка остаётся выключенной';

  @override
  String get authLockUnavailableDesc =>
      'На этом устройстве не зарегистрированы биометрические данные';

  @override
  String get authLockScreenTitle => 'ShellMind заблокирован';

  @override
  String get authLockScreenSubtitle => 'Подтвердите, чтобы продолжить';

  @override
  String get authLockUnlockAction => 'Разблокировать';

  @override
  String get authLockUnlockFailed => 'Проверка не пройдена — попробуйте снова';

  @override
  String get terminalTabPickerTitle => 'Переключить терминал';

  @override
  String get terminalTabPickerSubtitle =>
      'Выберите сервер, чтобы открыть его вкладкой терминала — серверы в сети подключаются сразу, офлайн-серверы сначала устанавливают соединение';

  @override
  String get terminalTabPickerEmpty => 'Серверы ещё не настроены';

  @override
  String get terminalTabNewTooltip => 'Новая вкладка терминала';

  @override
  String get terminalTabCloseTooltip => 'Закрыть вкладку';

  @override
  String get hostKeyConfirmTitle => 'Доверять этому хосту?';

  @override
  String get hostKeyConfirmMessage =>
      'Это первое подключение к этому серверу. Проверьте его отпечаток, прежде чем доверять ему, — это защищает от атак типа «человек посередине».';

  @override
  String get hostKeyEndpointLabel => 'СЕРВЕР';

  @override
  String get hostKeyFingerprintLabel => 'ОТПЕЧАТОК SHA-256';

  @override
  String get hostKeySecurityNote =>
      'Сравните отпечаток со значением, полученным от оператора сервера по отдельному каналу. Доверие неверному отпечатку раскроет ваши учётные данные.';

  @override
  String get hostKeyTrustAndConnect => 'Доверять и подключиться';

  @override
  String get hostKeyReject => 'Отклонить';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return 'Автоотклонение через $seconds с — доверие записывается только при подтверждении.';
  }

  @override
  String get hostKeyMismatchTitle => 'Ключ хоста изменился';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return 'Ключ, предъявленный $host:$port, отличается от того, которому вы ранее доверяли. Подключение было заблокировано — возможно, это атака типа «человек посередине» либо сервер был переустановлен. Если вы проверили новый ключ, сбросьте доверие к хосту на странице редактирования сервера и подключитесь снова.';
  }

  @override
  String get hostKeyRejectedMessage =>
      'Подключение отменено — ключу хоста не доверяли. Вы можете подключиться снова, чтобы просмотреть отпечаток.';

  @override
  String get serverResetTrustAction => 'Сбросить доверие к хосту';

  @override
  String get serverResetTrustDesc =>
      'Удалить сохранённый отпечаток этого сервера, чтобы при следующем подключении снова запрашивалось подтверждение.';

  @override
  String get serverResetTrustConfirmTitle => 'Сбросить доверие к хосту?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return 'Сохранённый отпечаток для $identity:$port будет удалён. При следующем подключении снова потребуется подтвердить ключ хоста.';
  }

  @override
  String get serverResetTrustConfirmAction => 'Сбросить';

  @override
  String get serverResetTrustDone =>
      'Доверие к хосту сброшено — подключитесь снова, чтобы подтвердить отпечаток.';

  @override
  String get agentErrorNoTargetServer => 'Нет доступного целевого сервера';

  @override
  String get agentErrorExecFailed => 'Не удалось выполнить команду';

  @override
  String get agentErrorConnectFailed =>
      'Не удалось автоматически подключиться к серверу';

  @override
  String get agentErrorConnectAuthRequired =>
      'Нет сохранённых учётных данных для этого сервера — автоподключение невозможно';

  @override
  String agentErrorDangerSkipped(String command) {
    return 'Пропущена опасная команда: $command';
  }

  @override
  String get agentErrorUnexpected => 'Непредвиденная ошибка';

  @override
  String get exportDocChatTitle => 'Экспорт чата Shell-Mind';

  @override
  String exportDocExportedAt(String time) {
    return 'Экспортировано: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return 'Сообщений: $count';
  }

  @override
  String get exportDocUserSection => 'Пользователь';

  @override
  String get exportDocAssistantSection => 'Ассистент';

  @override
  String get exportDocToolSection => 'Выполнение инструмента';

  @override
  String get exportDocNoContent => '_(нет содержимого)_';

  @override
  String get exportDocUnknownServer => 'Неизвестный сервер';

  @override
  String exportDocExitCode(int code) {
    return 'Код завершения $code';
  }

  @override
  String get exportDocCommand => 'Команда';

  @override
  String get exportDocOutput => 'Вывод';

  @override
  String get exportDocErrorOutput => 'Вывод ошибок';

  @override
  String get exportDocDiagTitle => 'Диагностический отчёт Shell-Mind';

  @override
  String exportDocDiagCrashCount(int count) {
    return 'Зафиксировано ошибок: $count';
  }

  @override
  String get exportDocDiagCrashesSection => 'Зафиксированные ошибки';

  @override
  String get exportDocDiagNone => '(нет)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return 'Сводка ошибки: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return 'Версия приложения: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return 'Платформа: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return 'Язык: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return 'Использование локальных данных: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'Аудит команд AI (последние $limit сводок)';
  }

  @override
  String get exportDocDiagSuccess => 'успешно';

  @override
  String get exportDocDiagFailed => 'с ошибкой';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return 'код завершения $code';
  }

  @override
  String get settingsTerminalScheme => 'Цветовая схема терминала';

  @override
  String get settingsTerminalSchemeDesc =>
      'Выберите палитру цветов ANSI для SSH-терминалов.';

  @override
  String get settingsSectionDataTransfer => 'Импорт и экспорт';

  @override
  String get transferSnippetsTitle => 'Сниппеты команд';

  @override
  String get transferServersTitle => 'Конфигурации серверов';

  @override
  String get transferExport => 'Экспорт';

  @override
  String get transferImport => 'Импорт';

  @override
  String get transferExportImport => 'Экспорт / импорт';

  @override
  String get transferExportTitle => 'Экспорт';

  @override
  String get transferCopyJson => 'Копировать JSON';

  @override
  String get transferCopied => 'Скопировано в буфер обмена';

  @override
  String get transferImportHint => 'Вставьте экспортированный JSON сюда…';

  @override
  String get transferSnippetsEmpty => 'Нет сниппетов команд для экспорта.';

  @override
  String get transferServersEmpty => 'Нет серверов для экспорта.';

  @override
  String get transferImportNothing =>
      'В импорте не найдено допустимых элементов.';

  @override
  String transferSnippetsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count сниппета',
      many: 'Импортировано $count сниппетов',
      few: 'Импортировано $count сниппета',
      one: 'Импортирован 1 сниппет',
    );
    return '$_temp0';
  }

  @override
  String transferServersImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count сервера',
      many: 'Импортировано $count серверов',
      few: 'Импортировано $count сервера',
      one: 'Импортирован 1 сервер',
    );
    return '$_temp0';
  }

  @override
  String transferImportFailed(String message) {
    return 'Не удалось импортировать: $message';
  }

  @override
  String transferExportFailed(String message) {
    return 'Не удалось экспортировать: $message';
  }

  @override
  String transferExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String get sessionsTitle => 'Диалоги';

  @override
  String get sessionsNew => 'Новый диалог';

  @override
  String get sessionsSearch => 'Поиск диалогов…';

  @override
  String get sessionsEmpty => 'Пока нет диалогов';

  @override
  String sessionsNoMatch(String query) {
    return 'Совпадений нет: \"$query\"';
  }

  @override
  String get sessionsRename => 'Переименовать';

  @override
  String get sessionsRenameHint => 'Название диалога';

  @override
  String get sessionsDelete => 'Удалить';

  @override
  String sessionsDeleteConfirm(String title) {
    return 'Удалить \"$title\"? Это действие необратимо.';
  }

  @override
  String sessionsMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения',
      many: '$count сообщений',
      few: '$count сообщения',
      one: '1 сообщение',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsNotificationsTitle => 'Фоновые оповещения';

  @override
  String get settingsNotificationsDesc =>
      'Уведомлять, когда SSH-сеанс прерывается или задача AI завершается, пока приложение работает в фоновом режиме.';

  @override
  String get sftpTitle => 'Файлы';

  @override
  String get sftpNotConnected => 'Нет подключения к этому серверу.';

  @override
  String get sftpLoading => 'Загрузка файлов…';

  @override
  String get sftpEmpty => 'Эта папка пуста.';

  @override
  String get sftpDownload => 'Скачать';

  @override
  String sftpDownloaded(String path, int size) {
    return 'Скачано $path ($size байт)';
  }

  @override
  String get sftpDownloadFailed => 'Не удалось скачать';

  @override
  String get sftpPreviewError => 'Не удалось открыть предпросмотр';

  @override
  String get sftpNewFolderName => 'Новая папка';

  @override
  String get sftpRefresh => 'Обновить';

  @override
  String get sftpDelete => 'Удалить';

  @override
  String sftpDeleteConfirm(String name) {
    return 'Удалить \"$name\"?';
  }

  @override
  String get sftpRename => 'Переименовать';

  @override
  String get sftpTooltip => 'Просмотр файлов (SFTP)';

  @override
  String get terminalMoreTooltip => 'Ещё';

  @override
  String get tunnelsTitle => 'Проброс портов';

  @override
  String get tunnelsEmpty => 'Нет активных туннелей.';

  @override
  String get tunnelsAddLocal => 'Локальный проброс';

  @override
  String get tunnelsAddRemote => 'Удалённый проброс';

  @override
  String get tunnelsLocalPort => 'Локальный порт';

  @override
  String get tunnelsRemoteHost => 'Удалённый хост';

  @override
  String get tunnelsRemotePort => 'Удалённый порт';

  @override
  String get tunnelsAdd => 'Добавить';

  @override
  String get tunnelsClose => 'Закрыть';

  @override
  String get tunnelsTooltip => 'Проброс портов (SSH-туннель)';

  @override
  String get tunnelsError => 'Не удалось создать туннель';

  @override
  String get tunnelsInvalidPort =>
      'Порт должен быть в диапазоне от 1 до 65535.';

  @override
  String get settingsLanguageTitle => 'Язык';
}
