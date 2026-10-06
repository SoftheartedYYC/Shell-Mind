// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'ShellMind';

  @override
  String get navServers => '서버';

  @override
  String get navAiChat => 'AI 채팅';

  @override
  String get navSettings => '설정';

  @override
  String get pageNotFound => '페이지를 찾을 수 없습니다';

  @override
  String get backToServers => '서버로 돌아가기';

  @override
  String get serversTitle => '서버';

  @override
  String serversHostCount(int count) {
    return '호스트 $count개';
  }

  @override
  String get serversSearch => '서버 검색…';

  @override
  String get serversAdd => '서버 추가';

  @override
  String get serversEmpty => '아직 서버가 없습니다';

  @override
  String get serversEmptyHint => '첫 번째 SSH 서버를 추가하여 시작하세요.';

  @override
  String get serversDeleteConfirmTitle => '서버 삭제';

  @override
  String serversDeleteConfirmMessage(String name, String identity, int port) {
    return '\"$name\"을(를) 삭제하시겠습니까?\n\n$identity:$port 및 저장된 자격 증명이 영구적으로 제거됩니다.';
  }

  @override
  String serversDeleted(String identity) {
    return '$identity 제거됨';
  }

  @override
  String serversDeleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String get serversLoading => '서버 불러오는 중';

  @override
  String get serversUngrouped => '그룹 없음';

  @override
  String get serversSortName => 'a–z';

  @override
  String get serversSortRecent => '최근';

  @override
  String get serversQuickStart => '빠른 시작';

  @override
  String get serversQuickStep1Title => '호스트 추가';

  @override
  String get serversQuickStep1Desc => '비밀번호 또는 키 인증으로 SSH 엔드포인트를 등록하세요.';

  @override
  String get serversQuickStep2Title => '연결 테스트';

  @override
  String get serversQuickStep2Desc => '저장하기 전에 포트를 확인하여 오타를 빠르게 잡아냅니다.';

  @override
  String get serversQuickStep3Title => '연결';

  @override
  String get serversQuickStep3Desc => '터미널 세션을 엽니다 — 전체 PTY, 색상, vim을 지원합니다.';

  @override
  String serversNoMatch(String query) {
    return '일치하는 항목 없음: \"$query\"';
  }

  @override
  String get serversClearFilter => '필터 지우기';

  @override
  String get serversReadError => '서버 목록을 읽을 수 없습니다.';

  @override
  String get serverEditTitle => '서버 추가';

  @override
  String get serverEditTitleEdit => '서버 편집';

  @override
  String get serverNotFound => '서버를 찾을 수 없습니다';

  @override
  String get serverValidationNameRequired => '이름이 필요합니다';

  @override
  String get serverValidationHostRequired => '호스트가 필요합니다';

  @override
  String get serverValidationNoSpaces => '공백은 허용되지 않습니다';

  @override
  String get serverValidationRequired => '필수 항목';

  @override
  String get serverValidationNumeric => '숫자';

  @override
  String get serverValidationPortRange => '1–65535';

  @override
  String get serverValidationUsernameRequired => '사용자 이름이 필요합니다';

  @override
  String get serverValidationPasswordRequired => '비밀번호가 필요합니다';

  @override
  String get serverValidationPrivateKeyRequired => '개인 키가 필요합니다';

  @override
  String serverAdded(String identity, int port) {
    return '서버 추가됨: $identity:$port';
  }

  @override
  String serverSaved(String identity, int port) {
    return '저장됨: $identity:$port';
  }

  @override
  String serverSaveFailed(String message) {
    return '저장 실패: $message';
  }

  @override
  String get serverTestEnterHost => '먼저 호스트 주소를 입력하세요';

  @override
  String serverTestProbing(String host, int port) {
    return '$host:$port 확인 중…';
  }

  @override
  String serverTestReachable(String host, int port) {
    return '$host:$port — 연결 가능';
  }

  @override
  String serverTestTimedOut(String host, int port) {
    return '$host:$port — 시간 초과';
  }

  @override
  String serverTestRefused(String host, int port) {
    return '$host:$port — 거부됨 / 연결 불가';
  }

  @override
  String serverTestProbeFailed(String host, int port) {
    return '$host:$port — 확인 실패';
  }

  @override
  String serverTestHandshakeFailed(String host, int port) {
    return '$host:$port SSH 핸드셰이크 실패';
  }

  @override
  String serverTestAuthFailed(String host, int port) {
    return '$host:$port 인증 실패 - 사용자 이름과 자격 증명을 확인하세요';
  }

  @override
  String get serverLoading => '불러오는 중';

  @override
  String get serverSaveChanges => '변경 사항 저장';

  @override
  String get serverSectionIdentity => '신원';

  @override
  String get serverSectionConnection => '연결';

  @override
  String get serverSectionAuthentication => '인증';

  @override
  String get serverFieldLabel => '라벨';

  @override
  String get serverFieldLabelHint => 'prod-web-01';

  @override
  String get serverFieldGroup => '그룹 (선택 사항)';

  @override
  String get serverFieldGroupHint => 'production';

  @override
  String get serverFieldHost => '호스트';

  @override
  String get serverFieldHostHint => '10.0.0.5';

  @override
  String get serverFieldPort => '포트';

  @override
  String get serverFieldUsername => '사용자 이름';

  @override
  String get serverFieldUsernameHint => 'root';

  @override
  String get serverFieldPassword => '비밀번호';

  @override
  String get serverFieldPasswordStored => '저장됨 — 유지하려면 비워 두세요';

  @override
  String get serverFieldPrivateKey => '개인 키 (PEM)';

  @override
  String get serverFieldPassphrase => '키 암호 (선택 사항)';

  @override
  String get serverAuthPassword => '비밀번호';

  @override
  String get serverAuthPrivateKey => '개인 키';

  @override
  String get serverTestIdle => '\"테스트\"를 눌러 연결을 확인하세요';

  @override
  String get serverSecurityNote =>
      '자격 증명은 기기 키스토어에 암호화되어 저장되며 Hive 메타데이터 저장소에 접근하거나 이 기기를 벗어나지 않습니다.';

  @override
  String get serverTesting => '테스트 중…';

  @override
  String get serverTest => '테스트';

  @override
  String get serverSaving => '저장 중…';

  @override
  String serverCopiedAddress(String address) {
    return '$address 복사됨';
  }

  @override
  String get serverActions => '서버 작업';

  @override
  String get serverActionConnect => '연결';

  @override
  String get serverActionEdit => '편집';

  @override
  String get serverActionEditDetails => '세부 정보 편집';

  @override
  String get serverActionCopySsh => 'SSH 명령 복사';

  @override
  String get serverActionDelete => '삭제';

  @override
  String get serverActionDeleteServer => '서버 삭제';

  @override
  String get serverOnline => '온라인';

  @override
  String get serverNeverConnected => '연결된 적 없음';

  @override
  String get serverJustNow => '방금 전';

  @override
  String serverMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String serverHoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String serverDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get terminalHostNotFound => '호스트를 찾을 수 없습니다';

  @override
  String terminalHostNotFoundMessage(String id) {
    return 'id \"$id\"에 해당하는 저장된 서버가 없습니다. 삭제되었을 수 있습니다.';
  }

  @override
  String get terminalBackToServers => '서버로 돌아가기';

  @override
  String get terminalConnectionFailed => '연결에 실패했습니다.';

  @override
  String get terminalSessionClosed => '세션 종료됨';

  @override
  String terminalSessionClosedMessage(String name) {
    return '$name 연결이 종료되었습니다.';
  }

  @override
  String get terminalReconnect => '다시 연결';

  @override
  String get terminalAuthenticating => '인증 중';

  @override
  String get terminalConnecting => '연결 중';

  @override
  String get terminalResolvingHost => '호스트 확인 중…';

  @override
  String get terminalTooltipDisconnectBack => '연결 해제 및 뒤로';

  @override
  String get terminalTooltipSmallerText => '텍스트 축소';

  @override
  String get terminalTooltipLargerText => '텍스트 확대';

  @override
  String get terminalTooltipDisconnect => '연결 해제';

  @override
  String get terminalRetryAvailable => '재시도 가능';

  @override
  String get terminalStatusConnected => '연결됨';

  @override
  String get terminalStatusOffline => '오프라인';

  @override
  String get terminalStatusError => '오류';

  @override
  String get aiChatTitle => 'AI 어시스턴트';

  @override
  String get aiChatStatusSetup => '설정';

  @override
  String get aiChatStatusStreaming => '스트리밍 중';

  @override
  String get aiChatStatusReady => '준비됨';

  @override
  String get aiChatClearConversation => '대화 지우기';

  @override
  String get aiChatSuggestion1 => 'ls -la 출력의 의미를 설명해 줘';

  @override
  String get aiChatSuggestion2 => '어떤 프로세스가 포트를 사용 중인지 어떻게 확인하나요?';

  @override
  String get aiChatSuggestion3 => '로그를 tail 하고 오류를 grep 하는 방법을 알려줘';

  @override
  String get aiChatSuggestion4 => 'CSV 열을 합산하는 awk 한 줄 명령을 작성해 줘';

  @override
  String get aiChatTryAsking => '물어보세요';

  @override
  String get aiChatIntroTitle => '당신의 터미널 동반자';

  @override
  String get aiChatIntroBody =>
      '명령, 오류 또는 로그 출력 일부를 붙여넣으세요. ShellMind가 무슨 일이 있었는지 설명하고, 다음 단계를 제안하며, 직접 명령을 작성해 줍니다.';

  @override
  String get aiChatNoKeyTitle => 'API 키가 구성되지 않았습니다';

  @override
  String aiChatNoKeyMessage(String provider) {
    return '어시스턴트를 사용하려면 $provider API 키를 추가하세요. 키는 이 기기에 암호화되어 저장되며, 모델 호출 외에는 기기를 벗어나지 않습니다.';
  }

  @override
  String get aiChatOpenSettings => 'AI 설정 열기';

  @override
  String get aiChatCheckingCredentials => '자격 증명 확인 중';

  @override
  String get aiChatInputHint => '무엇이든 물어보세요…';

  @override
  String get aiChatInputDisabled => '시작하려면 API 키를 설정하세요';

  @override
  String get aiChatError => '오류';

  @override
  String get aiChatAssistantName => 'ShellMind';

  @override
  String get aiChatCopied => '복사됨';

  @override
  String get aiChatCopy => '복사';

  @override
  String get aiChatThinking => '생각 중…';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSearchTooltip => '설정 검색';

  @override
  String get settingsStable => '안정';

  @override
  String get settingsSectionAppearance => '모양 및 언어';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSectionAiProvider => 'AI 제공자';

  @override
  String get settingsSectionAiAgent => 'AI 에이전트';

  @override
  String get settingsSectionSsh => 'SSH';

  @override
  String get settingsSectionServers => '서버';

  @override
  String get settingsSectionAboutUpdate => '정보 및 업데이트';

  @override
  String get settingsSectionStoragePrivacy => '저장소 및 개인정보';

  @override
  String get settingsSectionResources => '리소스';

  @override
  String get settingsTileSecrets => '비밀 정보';

  @override
  String get settingsTileEncrypted => '암호화됨';

  @override
  String get settingsTileLocalCache => '로컬 캐시';

  @override
  String get settingsTileClearData => '모든 데이터 지우기';

  @override
  String get settingsTileLicenses => '오픈소스 라이선스';

  @override
  String get settingsTileReportIssue => '문제 신고';

  @override
  String get settingsFooter => '현대적인 워크플로우를 위한 SSH + AI 어시스턴트';

  @override
  String get settingsSecretsDialogTitle => '비밀 정보 및 암호화';

  @override
  String get settingsSecretsDialogBody =>
      '자격 증명(서버 비밀번호, 개인 키, AI API 키)은 항상 플랫폼 키스토어(Android Keystore / iOS Keychain)를 사용해 저장 시 암호화됩니다. 이 보호는 설계상의 기능이며 끌 수 없습니다. 자격 증명을 변경하려면 서버 편집 페이지 또는 AI 설정에서 편집하거나 제거하세요.';

  @override
  String get settingsDialogOk => '확인';

  @override
  String get settingsDialogClose => '닫기';

  @override
  String get settingsCacheDialogTitle => '로컬 캐시';

  @override
  String get settingsCacheHiveData => '앱 데이터';

  @override
  String get settingsCacheDownloads => '다운로드된 업데이트';

  @override
  String get settingsCacheTotal => '합계';

  @override
  String get settingsCacheDialogHint =>
      '다운로드 캐시를 지우면 다운로드된 업데이트 패키지(APK)가 제거됩니다. 서버, 키 및 채팅 기록은 유지됩니다.';

  @override
  String get settingsCacheClearDownloads => '다운로드 캐시 지우기';

  @override
  String settingsCacheCleared(String freed) {
    return '$freed 확보됨';
  }

  @override
  String get settingsClearDataTitle => '모든 데이터를 지우시겠습니까?';

  @override
  String get settingsClearDataMessage =>
      '이 기기의 모든 서버, 저장된 자격 증명, AI 키, 채팅 기록 및 환경설정이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get settingsClearDataConfirm => '모두 지우기';

  @override
  String get settingsDataCleared => '모든 데이터가 지워졌습니다';

  @override
  String settingsClearDataFailed(String message) {
    return '데이터를 지울 수 없습니다: $message';
  }

  @override
  String get settingsIssueLinkCopied => '문제 링크가 클립보드에 복사되었습니다.';

  @override
  String get settingsAboutGithub => 'GitHub 저장소';

  @override
  String get settingsHideIp => 'IP 주소 숨기기';

  @override
  String get settingsHideIpDesc => '서버 목록 및 AI 페이지에서 IP 주소를 가립니다';

  @override
  String get serverMaskedAddress => '주소 숨김';

  @override
  String aiSettingsApiKeyTitle(String provider) {
    return '$provider API 키';
  }

  @override
  String get aiSettingsKeySet => '설정됨';

  @override
  String get aiSettingsKeyNotConfigured => '구성되지 않음';

  @override
  String get aiSettingsGetApiKey => 'API 키 받기';

  @override
  String get aiSettingsTemperature => 'Temperature';

  @override
  String get aiSettingsRemoveKey => '키 제거';

  @override
  String aiSettingsKeySaved(String provider) {
    return '$provider API 키가 안전하게 저장되었습니다.';
  }

  @override
  String aiSettingsRemoveKeyTitle(String provider) {
    return '$provider 키를 제거하시겠습니까?';
  }

  @override
  String get aiSettingsRemoveKeyMessage =>
      '새 키가 추가될 때까지 이 제공자의 어시스턴트가 작동하지 않습니다.';

  @override
  String get aiSettingsRemoveKeyConfirm => '제거';

  @override
  String aiSettingsGetKeyTitle(String provider) {
    return '$provider 키 받기';
  }

  @override
  String get aiSettingsGetKeyMessage =>
      '브라우저에서 제공자 콘솔을 열어 API 키를 생성한 다음 여기에 붙여넣으세요.';

  @override
  String get aiSettingsClose => '닫기';

  @override
  String get aiSettingsLinkCopied => '링크가 클립보드에 복사되었습니다.';

  @override
  String get aiSettingsCopyLink => '링크 복사';

  @override
  String get aiSettingsKeyConfigured => '키 구성됨';

  @override
  String get aiSettingsNotConfigured => '구성되지 않음';

  @override
  String aiSettingsUpdateKeyTitle(String provider) {
    return '$provider 키 업데이트';
  }

  @override
  String aiSettingsAddKeyTitle(String provider) {
    return '$provider 키 추가';
  }

  @override
  String get aiSettingsKeyStorageNote =>
      '이 기기에 암호화되어 저장됩니다. AI 제공자 호출에만 사용됩니다.';

  @override
  String get aiSettingsApiKeyHint => 'API 키…';

  @override
  String get aiSettingsSave => '저장';

  @override
  String get modelDescFastAffordable => '빠르고 저렴함';

  @override
  String get modelDescMostCapable => '가장 뛰어남';

  @override
  String get modelDescLegacyFast => '레거시 빠름';

  @override
  String get modelDescGeneralConversation => '일반 대화';

  @override
  String get modelDescAdvancedReasoning => '고급 추론';

  @override
  String get modelDescFastResponse => '빠른 응답';

  @override
  String get modelDescBalanced => '균형 잡힘';

  @override
  String get modelDescFreeFast => '무료 및 빠름';

  @override
  String get modelDescEnhanced => '향상됨';

  @override
  String get modelDescStandard => '표준';

  @override
  String get modelDescLightweight => '경량';

  @override
  String get modelDescRlEnhanced => 'RL 강화';

  @override
  String get aiModelsTitle => '모델';

  @override
  String get aiModelsRefresh => '모델 목록 새로고침';

  @override
  String get aiModelsAddCustom => '사용자 정의 모델 추가';

  @override
  String get aiModelsAddCustomHint => '모델 ID, 예: deepseek-chat';

  @override
  String get aiModelsAdd => '추가';

  @override
  String get aiModelsCustomBadge => '사용자 정의';

  @override
  String get aiModelsFetchFailed => '모델을 가져올 수 없습니다 — 내장 목록을 표시합니다.';

  @override
  String get aiModelsRemoveCustom => '사용자 정의 모델 제거';

  @override
  String get aiModelsEmpty => '모델 없음';

  @override
  String get aiModelsInvalidId => '모델 ID를 입력하세요.';

  @override
  String get aiModelsDuplicate => '이 모델은 이미 목록에 있습니다.';

  @override
  String get aiModelsPickerTitle => '모델 선택';

  @override
  String get aiModelsSearchHint => '모델 검색';

  @override
  String get aiModelsSearchEmpty => '검색과 일치하는 모델이 없습니다.';

  @override
  String get aiProvidersAddTile => '사용자 정의 제공자 추가';

  @override
  String get aiProvidersAddTitle => '사용자 정의 제공자 추가';

  @override
  String get aiProvidersFieldName => '이름';

  @override
  String get aiProvidersFieldNameHint => '예: SiliconFlow';

  @override
  String get aiProvidersFieldBaseUrl => '기본 URL';

  @override
  String get aiProvidersFieldBaseUrlHint => 'https://api.example.com/v1';

  @override
  String get aiProvidersFieldModel => '기본 모델 (선택 사항)';

  @override
  String get aiProvidersFieldModelHint => '모델 ID, 예: deepseek-chat';

  @override
  String get aiProvidersAddConfirm => '추가';

  @override
  String get aiProvidersInvalidInput => '이름과 기본 URL을 입력하세요.';

  @override
  String get aiProvidersInvalidUrl => '기본 URL은 http:// 또는 https://로 시작해야 합니다';

  @override
  String get aiProvidersDuplicateName => '이 이름을 가진 제공자가 이미 존재합니다.';

  @override
  String get aiProvidersAdded => '사용자 정의 제공자가 추가되었습니다.';

  @override
  String get aiProvidersAddFailed => '제공자를 추가할 수 없습니다 — 입력값을 확인하세요.';

  @override
  String get aiProvidersDeleteTile => '사용자 정의 제공자 제거';

  @override
  String aiProvidersDeleteTitle(String provider) {
    return '$provider을(를) 제거하시겠습니까?';
  }

  @override
  String get aiProvidersDeleteMessage =>
      '저장된 API 키, 기억된 모델 및 사용자 정의 모델도 함께 제거됩니다. 내장 제공자는 삭제할 수 없습니다.';

  @override
  String get aiProvidersDeleteConfirm => '제거';

  @override
  String get aiProvidersPickerTitle => '제공자 선택';

  @override
  String get updateVersion => '버전';

  @override
  String get updateSoftwareUpdate => '소프트웨어 업데이트';

  @override
  String get updateChecking => '확인 중';

  @override
  String get updateUpToDate => '최신 상태';

  @override
  String get updateCheckAgain => '다시 확인';

  @override
  String get updateReady => '준비됨';

  @override
  String get updateNew => '신규';

  @override
  String get updateCheck => '확인';

  @override
  String get updateAwaitingResponse => '응답 대기 중';

  @override
  String get updateAlreadyLatest => '이미 최신 빌드입니다';

  @override
  String updateCurrentVersionLatest(String version) {
    return 'v$version은(는) GitHub에 게시된 최신 릴리스입니다.';
  }

  @override
  String updateRunningVersion(String current, String latest) {
    return 'v$current 실행 중 — 원격 최신 버전은 v$latest입니다.';
  }

  @override
  String updateCheckedAgo(String timeAgo) {
    return '$timeAgo에 확인됨';
  }

  @override
  String get updateAvailable => '업데이트 사용 가능';

  @override
  String get updatePre => '프리';

  @override
  String get updateDownloadInstall => '다운로드 및 설치';

  @override
  String get updateLater => '나중에';

  @override
  String get updateApkHint =>
      'APK 설치는 Android에서만 지원됩니다. 파일은 여기에서 다운로드할 수 있습니다.';

  @override
  String updateDownloading(String tag) {
    return '$tag 다운로드 중';
  }

  @override
  String get updateSize => '크기';

  @override
  String get updateRate => '속도';

  @override
  String get updateEta => '예상 시간';

  @override
  String get updateElapsed => '경과 시간';

  @override
  String get updateCancel => '취소';

  @override
  String get updateKeepForeground => '앱을 전면에 유지하세요';

  @override
  String get updateDownloadComplete => '다운로드 완료';

  @override
  String get updateInstallHint =>
      'Android에서 확인을 요청합니다. 설치 프로그램이 실행되는 동안 ShellMind가 종료되며, 서버와 기록은 유지됩니다.';

  @override
  String get updateLaunching => '실행 중...';

  @override
  String get updateInstallNow => '지금 설치';

  @override
  String get updateDelete => '삭제';

  @override
  String updateInstallTitle(String tag) {
    return '$tag을(를) 설치하시겠습니까?';
  }

  @override
  String get updateInstallMessage =>
      '시스템 패키지 설치 프로그램이 열립니다. 설치 중 ShellMind가 종료되고 새 버전에서 다시 열립니다.';

  @override
  String get updateNotNow => '지금은 아님';

  @override
  String get updateInstall => '설치';

  @override
  String get updateCheckFailed => '업데이트 확인에 실패했습니다.';

  @override
  String get updateErrorTitleNoReleases => '릴리스 없음';

  @override
  String get updateErrorTitleGeneric => '업데이트 확인 실패';

  @override
  String get updateErrNoReleases => '아직 ShellMind에 게시된 릴리스가 없습니다.';

  @override
  String get updateErrRateLimit => 'GitHub의 API 속도 제한에 도달했습니다. 나중에 다시 시도하세요.';

  @override
  String get updateErrTimeout => 'GitHub 요청이 시간 초과되었습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get updateErrNetwork => 'GitHub에 연결할 수 없습니다. 네트워크 연결을 확인하세요.';

  @override
  String get updateErrAuth => 'GitHub가 업데이트 요청을 거부했습니다.';

  @override
  String get updateErrPermission => '업데이트 요청이 거부되었습니다.';

  @override
  String get updateErrStorage => '업데이트를 완료할 저장 공간이 부족합니다.';

  @override
  String get updateErrDigestMismatch =>
      '다운로드한 업데이트가 SHA-256 무결성 검사에 실패하여 삭제되었습니다. 다운로드를 다시 시도하세요.';

  @override
  String get updateErrDigestMissing =>
      '업데이트 패키지에 게시된 무결성 다이제스트가 없어 업데이트가 거부되었습니다. 나중에 다시 시도하세요.';

  @override
  String get updateRetry => '재시도';

  @override
  String get updateDismiss => '닫기';

  @override
  String updateReleaseNotes(String tag) {
    return '릴리스 $tag';
  }

  @override
  String get updateNotesLabel => '메모';

  @override
  String get updateNewVersionAvailable => '새 버전 사용 가능';

  @override
  String get updateRemindLater => '나중에 알림';

  @override
  String get updateCancelDownload => '다운로드 취소';

  @override
  String updateInstallTag(String tag) {
    return '$tag 설치';
  }

  @override
  String get updateInstallLaterFromSettings => '나중에 설정에서 설치';

  @override
  String get updateCouldNotComplete => '업데이트를 완료할 수 없습니다.';

  @override
  String get updateClose => '닫기';

  @override
  String get updatePromptInstallHint =>
      '설치 프로그램이 실행되는 동안 Android가 ShellMind를 종료합니다. 서버, 키 및 채팅 기록은 유지됩니다.';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonRetry => '재시도';

  @override
  String get commonLoading => '불러오는 중...';

  @override
  String get commonNoData => '데이터 없음';

  @override
  String get commonNothingToShow => '아직 표시할 내용이 없습니다.';

  @override
  String get commonOk => '확인';

  @override
  String get settingsAiAutoExecuteTitle => '명령 자동 실행';

  @override
  String get settingsAiAutoExecuteSubtitle =>
      'AI 에이전트가 매번 묻지 않고 파싱된 명령을 실행하도록 허용합니다';

  @override
  String get settingsAiAutoConnectTitle => 'AI 서버 자동 연결';

  @override
  String get settingsAiAutoConnectSubtitle =>
      'AI 어시스턴트가 구성되었지만 오프라인인 서버에 자동으로 연결하여 명령을 실행하도록 허용합니다(저장된 자격 증명이 사용됩니다)';

  @override
  String get settingsAiMaxAutoLoopsTitle => '최대 자동 루프 반복 횟수';

  @override
  String get settingsAiMaxAutoLoopsSub => '응답당 자동 명령 실행 횟수를 제한합니다';

  @override
  String get settingsAiMaxAutoLoopsTileDesc => 'AI가 작업당 실행할 수 있는 최대 명령 라운드';

  @override
  String get settingsAiMaxAutoLoopsHint =>
      'AI 작업당 실행 라운드의 상한입니다 — SSH 재연결 시도 횟수가 아닙니다(이는 SSH 항목에 있습니다).';

  @override
  String get terminalAskAi => 'AI에게 묻기';

  @override
  String get terminalAskAiSubtitle => '선택한 텍스트를 AI 어시스턴트에게 보냅니다';

  @override
  String get terminalTooltipAskAi => 'AI에게 묻기';

  @override
  String get aiChatNoConnection => '먼저 서버 터미널에 연결하세요';

  @override
  String get aiChatAnalyzePrompt =>
      '위 명령 출력을 분석하여 결과의 의미를 설명하고 필요한 경우 후속 제안을 해 주세요.';

  @override
  String get aiExecuteButton => '서버에서 실행';

  @override
  String get aiExecuteTitle => '명령 실행 확인';

  @override
  String get aiExecuteConfirmButton => '실행';

  @override
  String get aiExecuteConfirmAnyway => '그래도 실행';

  @override
  String get aiExecuteDangerWarning => '⚠ 위험한 명령';

  @override
  String get aiExecuteDangerText =>
      '이 명령은 파괴적일 수 있으며 데이터 손실이나 시스템 손상을 일으킬 수 있습니다.';

  @override
  String get aiExecuteCommandLabel => '실행할 명령:';

  @override
  String get aiExecuteTargetServer => '대상 서버:';

  @override
  String get aiExecuteSelectServer => '대상 서버 선택';

  @override
  String get aiExecuteNoServer => '먼저 서버에 연결하세요';

  @override
  String get aiExecuteAtLeastOne => '서버를 하나 이상 선택하세요';

  @override
  String get aiExecuteSelectHint => '이 명령을 실행할 서버를 선택하세요';

  @override
  String aiExecuteRunCount(int count) {
    return '실행 ($count)';
  }

  @override
  String get aiExecuteSelectAll => '전체 선택';

  @override
  String get aiExecuteClearSelection => '지우기';

  @override
  String aiExecuteUptime(int hours, int minutes) {
    return '$hours시간 $minutes분 온라인';
  }

  @override
  String get aiExecuteSuccess => '명령이 성공적으로 실행되었습니다';

  @override
  String get aiExecuteFailed => '명령 실행 실패';

  @override
  String get aiServerManageTitle => '서버';

  @override
  String get aiServerManageSubtitle => 'AI 어시스턴트가 작동할 서버를 연결하세요';

  @override
  String aiServerOnlineCount(int count) {
    return '$count개 온라인';
  }

  @override
  String get aiServerDone => '완료';

  @override
  String get aiServerConnecting => '연결 중…';

  @override
  String get aiServerOffline => '오프라인';

  @override
  String get aiServerNoCredential =>
      '저장된 자격 증명 없음 — 먼저 서버 페이지에서 비밀번호 또는 키를 저장하세요';

  @override
  String get aiServerConnectFailed => '연결 실패';

  @override
  String get aiToolResultCommand => '명령';

  @override
  String get aiToolResultOutput => '명령 출력';

  @override
  String aiToolResultExitCode(int code) {
    return '종료 코드: $code';
  }

  @override
  String get aiToolResultElapsed => '경과 시간';

  @override
  String get aiToolResultAnalyzeButton => 'AI가 출력 분석';

  @override
  String aiToolResultCollapsedShow(int total) {
    return '$total줄 더 보기';
  }

  @override
  String get aiToolResultExpandedHide => '출력 숨기기';

  @override
  String get aiToolResultStderrLabel => '오류 출력:';

  @override
  String get aiContextToggleAttach => '터미널 컨텍스트 첨부';

  @override
  String get aiContextToggleDetach => '터미널 컨텍스트 첨부됨';

  @override
  String get aiContextBadge => '컨텍스트';

  @override
  String aiContextLines(int lines) {
    return '터미널에서 $lines줄';
  }

  @override
  String get aiAgentStop => '자동 모드 중지';

  @override
  String get aiAgentExecuting => '실행 중…';

  @override
  String get aiAgentDefaultServer => '서버';

  @override
  String get aiTimelineTitle => '실행 타임라인';

  @override
  String get aiTimelineOpen => '실행 타임라인';

  @override
  String get aiTimelineEmpty => '아직 실행된 명령이 없습니다';

  @override
  String get aiTimelineEmptyHint => '채팅 또는 자동 모드로 명령을 실행하면 전체 체인이 여기에 표시됩니다.';

  @override
  String aiTimelineStatRounds(int count) {
    return '$count 라운드';
  }

  @override
  String aiTimelineStatCommands(int count) {
    return '명령 $count개';
  }

  @override
  String aiTimelineStatSuccess(int count) {
    return '$count개 성공';
  }

  @override
  String aiTimelineStatFailed(int count) {
    return '$count개 실패';
  }

  @override
  String aiTimelineStarted(String time) {
    return '$time 시작됨';
  }

  @override
  String aiTimelineEnded(String time) {
    return '$time 종료됨';
  }

  @override
  String aiTimelineExitCode(int code) {
    return '종료 코드: $code';
  }

  @override
  String get aiTimelineNoExitCode => '종료 코드 없음';

  @override
  String get aiTimelineOutput => '출력';

  @override
  String get aiTimelineOutputEmpty => '출력 없음';

  @override
  String get aiTimelineErrorOutput => '오류 출력';

  @override
  String get aiTimelineRunning => '실행 중…';

  @override
  String get aiTimelineClose => '닫기';

  @override
  String get sshReconnectToggle => '연결 해제 시 자동 재연결';

  @override
  String get sshReconnectToggleDesc => '지수 백오프로 끊어진 SSH 세션을 재시도합니다';

  @override
  String get sshReconnectMaxAttempts => '최대 재연결 시도 횟수';

  @override
  String get sshReconnectMaxAttemptsDesc =>
      '연결 해제 후 최대 자동 재연결 시도 횟수 — 0은 성공할 때까지 재시도함을 의미합니다';

  @override
  String sshReconnectMaxAttemptsValue(int count) {
    return '$count';
  }

  @override
  String get sshReconnectMaxAttemptsUnlimited => '무제한';

  @override
  String sshReconnectStatusReconnecting(int attempt) {
    return '재연결 중 (시도 $attempt)';
  }

  @override
  String sshReconnectStatusReconnectingOf(int attempt, int max) {
    return '재연결 중 (시도 $attempt/$max)';
  }

  @override
  String get sshReconnectGaveUp => '자동 재연결 포기';

  @override
  String sshReconnectGaveUpMessage(String name, int max) {
    return '$max회 시도 후에도 $name에 연결할 수 없습니다.';
  }

  @override
  String sshReconnectGaveUpMessageUnlimited(String name) {
    return '$name에 연결할 수 없습니다.';
  }

  @override
  String get sshReconnectRetryNow => '지금 재시도';

  @override
  String get sshReconnectStopAuto => '중지';

  @override
  String sshReconnectReconnectedSnack(String name) {
    return '$name에 다시 연결됨';
  }

  @override
  String get snippetsTitle => '명령 스니펫';

  @override
  String get snippetsSubtitle => '빠른 재사용을 위해 명령을 저장하세요';

  @override
  String get snippetsAddTooltip => '스니펫 추가';

  @override
  String get snippetsAddTitle => '새 스니펫';

  @override
  String get snippetsSave => '저장';

  @override
  String get snippetsCommandLabel => '명령';

  @override
  String get snippetsCommandHint => '예: docker ps -a';

  @override
  String get snippetsNameLabel => '이름 (선택 사항)';

  @override
  String get snippetsNameHint => '예: 모든 컨테이너 나열';

  @override
  String get snippetsCommandRequired => '명령 텍스트가 필요합니다';

  @override
  String get snippetsDeleteTooltip => '스니펫 삭제';

  @override
  String get snippetsEmptyTitle => '아직 스니펫이 없습니다';

  @override
  String get snippetsEmptyMessage => '자주 사용하는 명령을 저장하고 한 번의 탭으로 삽입하거나 실행하세요.';

  @override
  String get snippetsLoadFailed => '스니펫을 불러올 수 없습니다';

  @override
  String get healthTitle => '서버 그룹 상태';

  @override
  String healthOnlineRatio(int online, int total) {
    return '$online/$total 온라인';
  }

  @override
  String get healthProbing => '확인 중…';

  @override
  String get healthProbeTooltip => '상태 점검 실행';

  @override
  String healthProbedAt(String time) {
    return '$time에 확인됨';
  }

  @override
  String get healthMoodAllOnline => '모든 시스템 정상';

  @override
  String get healthMoodDegraded => '일부 서버에 연결할 수 없습니다';

  @override
  String get healthMoodAllOffline => '모든 서버에 연결할 수 없습니다';

  @override
  String healthOfflineServers(String names) {
    return '오프라인: $names';
  }

  @override
  String get healthNoData => '새로고침을 눌러 모든 서버를 확인하세요';

  @override
  String healthUptime(String brief) {
    return '$brief 가동';
  }

  @override
  String healthLoad(String value) {
    return '부하 $value';
  }

  @override
  String get healthDiagIntro => '내 서버 그룹의 상태 보고서입니다:';

  @override
  String healthDiagStats(int online, int total) {
    return '$total개 서버 중 $online개 온라인.';
  }

  @override
  String healthDiagOfflineItem(String name) {
    return '- $name: 오프라인';
  }

  @override
  String healthDiagOnlineItem(String name, String details) {
    return '- $name: 온라인 ($details)';
  }

  @override
  String get healthDiagOutro =>
      '상태 데이터를 분석하고 비정상적인 항목(높은 부하, 최근 재부팅)을 표시한 후 다음에 확인할 사항을 제안해 주세요.';

  @override
  String get healthDiagnose => 'AI 진단';

  @override
  String get healthStaleNote => '마지막 점검 이후 일부 서버가 오프라인 상태가 되었습니다.';

  @override
  String get auditTitle => '명령 감사 로그';

  @override
  String get auditTileDesc => 'AI 에이전트가 실행한 명령';

  @override
  String get auditEmptyTitle => '아직 감사 항목이 없습니다';

  @override
  String get auditEmptyMessage => 'AI 에이전트가 실행한 명령이 여기에 기록됩니다.';

  @override
  String get auditFilteredEmpty => '현재 필터와 일치하는 항목이 없습니다';

  @override
  String get auditFilterAllServers => '모든 서버';

  @override
  String get auditFilterAllModes => '모든 모드';

  @override
  String get auditFilterAllResults => '모든 결과';

  @override
  String get auditFilterConfirmed => '확인됨';

  @override
  String get auditFilterAuto => '자동';

  @override
  String get auditFilterSuccess => '성공';

  @override
  String get auditFilterFailed => '실패';

  @override
  String get auditModeConfirmed => '확인됨';

  @override
  String get auditModeAuto => '자동';

  @override
  String get auditStatusSuccess => '성공';

  @override
  String get auditStatusFailed => '실패';

  @override
  String get auditDangerousBadge => '위험';

  @override
  String auditExitCode(int code) {
    return '종료 코드 $code';
  }

  @override
  String get auditOutputSummary => '출력 요약';

  @override
  String get auditNoOutput => '출력 없음';

  @override
  String get auditClearTooltip => '감사 로그 지우기';

  @override
  String get auditClearConfirmTitle => '감사 로그 지우기';

  @override
  String auditClearConfirmMessage(int count) {
    return '$count개의 감사 항목이 모두 영구적으로 제거됩니다.';
  }

  @override
  String get auditClearAction => '지우기';

  @override
  String get auditCleared => '감사 로그가 지워졌습니다';

  @override
  String auditEntriesCount(int count) {
    return '항목 $count개';
  }

  @override
  String get serverActionDisconnect => '연결 해제';

  @override
  String get exportChatAction => 'Markdown으로 내보내기';

  @override
  String get exportChatEmpty => '아직 내보낼 내용이 없습니다';

  @override
  String exportChatSuccess(String path) {
    return '대화가 $path에 내보내졌습니다';
  }

  @override
  String exportChatFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get diagTitle => '진단';

  @override
  String get diagTileDesc => '앱 오류 및 진단 내보내기';

  @override
  String get diagEmptyTitle => '캡처된 오류 없음';

  @override
  String get diagEmptyMessage => '처리되지 않은 예외가 문제 보고에 도움이 되도록 여기에 기록됩니다.';

  @override
  String diagEntriesCount(int count) {
    return '오류 $count개';
  }

  @override
  String get diagSourceFlutter => 'UI 오류';

  @override
  String get diagSourcePlatform => '런타임 오류';

  @override
  String get diagSourceZone => '비동기 작업';

  @override
  String get diagStackTrace => '스택 추적';

  @override
  String get diagNoStackTrace => '스택 추적 없음';

  @override
  String get diagExportAction => '진단 보고서 내보내기';

  @override
  String get diagExportEmpty => '보고할 내용 없음 — 기본 정보 내보내기';

  @override
  String diagExportSuccess(String path) {
    return '진단 보고서가 $path에 내보내졌습니다';
  }

  @override
  String diagExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get diagPrivacyNote =>
      '진단 내용은 마스킹 처리됩니다 — 비밀번호, 개인 키 또는 API 키는 포함되지 않습니다.';

  @override
  String get diagClearTooltip => '오류 기록 지우기';

  @override
  String get diagClearConfirmTitle => '오류 기록 지우기';

  @override
  String diagClearConfirmMessage(int count) {
    return '$count개의 오류 기록이 모두 영구적으로 제거됩니다.';
  }

  @override
  String get diagClearAction => '지우기';

  @override
  String get diagCleared => '오류 기록이 지워졌습니다';

  @override
  String get diagAppInfoTitle => '앱 정보';

  @override
  String get diagAppInfoVersion => '버전';

  @override
  String get diagAppInfoPlatform => '플랫폼';

  @override
  String get diagAppInfoLocale => '언어';

  @override
  String get diagAppInfoStorage => '로컬 데이터 크기';

  @override
  String get authLockToggleTitle => '생체 인식 잠금';

  @override
  String get authLockToggleDesc => '앱을 열 때 지문 또는 얼굴 잠금 해제를 요구합니다';

  @override
  String get authLockEnableFailed => '인증 실패 — 잠금이 꺼진 상태로 유지됩니다';

  @override
  String get authLockUnavailableDesc => '이 기기에 등록된 생체 인식이 없습니다';

  @override
  String get authLockScreenTitle => 'ShellMind가 잠겨 있습니다';

  @override
  String get authLockScreenSubtitle => '계속하려면 인증하세요';

  @override
  String get authLockUnlockAction => '잠금 해제';

  @override
  String get authLockUnlockFailed => '인증 실패 — 다시 시도하세요';

  @override
  String get terminalTabPickerTitle => '터미널 전환';

  @override
  String get terminalTabPickerSubtitle =>
      '터미널 탭으로 열 서버를 선택하세요 — 온라인 서버는 즉시 연결되고, 오프라인 서버는 먼저 전화를 겁니다';

  @override
  String get terminalTabPickerEmpty => '아직 구성된 서버가 없습니다';

  @override
  String get terminalTabNewTooltip => '새 터미널 탭';

  @override
  String get terminalTabCloseTooltip => '탭 닫기';

  @override
  String get hostKeyConfirmTitle => '이 호스트를 신뢰하시겠습니까?';

  @override
  String get hostKeyConfirmMessage =>
      '이 서버에 대한 첫 연결입니다. 신뢰하기 전에 지문을 확인하세요 — 중간자 공격으로부터 보호합니다.';

  @override
  String get hostKeyEndpointLabel => '서버';

  @override
  String get hostKeyFingerprintLabel => 'SHA-256 지문';

  @override
  String get hostKeySecurityNote =>
      '서버 운영자로부터 대역 외로 받은 값과 지문을 비교하세요. 잘못된 지문을 신뢰하면 자격 증명이 노출됩니다.';

  @override
  String get hostKeyTrustAndConnect => '신뢰 및 연결';

  @override
  String get hostKeyReject => '거부';

  @override
  String hostKeyAutoRejectCountdown(int seconds) {
    return '$seconds초 후 자동 거부 — 신뢰는 확인할 때만 기록됩니다.';
  }

  @override
  String get hostKeyMismatchTitle => '호스트 키 변경됨';

  @override
  String hostKeyMismatchMessage(String host, int port) {
    return '$host:$port이(가) 제시한 키가 이전에 신뢰한 키와 다릅니다. 연결이 차단되었습니다 — 중간자 공격이거나 서버가 다시 설치되었을 수 있습니다. 새 키를 확인했다면 서버 편집 페이지에서 호스트 신뢰를 초기화하고 다시 연결하세요.';
  }

  @override
  String get hostKeyRejectedMessage =>
      '연결 취소됨 — 호스트 키가 신뢰되지 않았습니다. 지문을 검토하려면 다시 연결할 수 있습니다.';

  @override
  String get serverResetTrustAction => '호스트 신뢰 초기화';

  @override
  String get serverResetTrustDesc => '이 서버의 저장된 지문을 잊어 다음 연결에서 다시 확인을 요청합니다.';

  @override
  String get serverResetTrustConfirmTitle => '호스트 신뢰를 초기화하시겠습니까?';

  @override
  String serverResetTrustConfirmMessage(String identity, int port) {
    return '$identity:$port의 저장된 지문이 제거됩니다. 다음 연결에서 호스트 키를 다시 확인하라는 요청을 받게 됩니다.';
  }

  @override
  String get serverResetTrustConfirmAction => '초기화';

  @override
  String get serverResetTrustDone => '호스트 신뢰 초기화됨 — 지문을 다시 확인하려면 다시 연결하세요.';

  @override
  String get agentErrorNoTargetServer => '대상 서버를 사용할 수 없습니다';

  @override
  String get agentErrorExecFailed => '명령 실행 실패';

  @override
  String get agentErrorConnectFailed => '서버에 자동으로 연결하지 못했습니다';

  @override
  String get agentErrorConnectAuthRequired =>
      '이 서버에 저장된 자격 증명이 없습니다 — 자동 연결이 불가능합니다';

  @override
  String agentErrorDangerSkipped(String command) {
    return '위험한 명령 건너뜀: $command';
  }

  @override
  String get agentErrorUnexpected => '예기치 않은 오류';

  @override
  String get exportDocChatTitle => 'Shell-Mind 채팅 내보내기';

  @override
  String exportDocExportedAt(String time) {
    return '내보낸 시각: $time';
  }

  @override
  String exportDocMessageCount(int count) {
    return '메시지: $count';
  }

  @override
  String get exportDocUserSection => '사용자';

  @override
  String get exportDocAssistantSection => '어시스턴트';

  @override
  String get exportDocToolSection => '도구 실행';

  @override
  String get exportDocNoContent => '_(내용 없음)_';

  @override
  String get exportDocUnknownServer => '알 수 없는 서버';

  @override
  String exportDocExitCode(int code) {
    return '종료 코드 $code';
  }

  @override
  String get exportDocCommand => '명령';

  @override
  String get exportDocOutput => '출력';

  @override
  String get exportDocErrorOutput => '오류 출력';

  @override
  String get exportDocDiagTitle => 'Shell-Mind 진단 보고서';

  @override
  String exportDocDiagCrashCount(int count) {
    return '캡처된 오류: $count';
  }

  @override
  String get exportDocDiagCrashesSection => '캡처된 오류';

  @override
  String get exportDocDiagNone => '(없음)';

  @override
  String exportDocDiagErrorMessage(String message) {
    return '오류 요약: $message';
  }

  @override
  String exportDocDiagAppVersion(String version) {
    return '앱 버전: $version';
  }

  @override
  String exportDocDiagPlatform(String platform) {
    return '플랫폼: $platform';
  }

  @override
  String exportDocDiagLocale(String locale) {
    return '언어: $locale';
  }

  @override
  String exportDocDiagStorage(String value) {
    return '로컬 데이터 사용량: $value';
  }

  @override
  String exportDocDiagAuditSection(int limit) {
    return 'AI 명령 감사 (최근 $limit개 요약)';
  }

  @override
  String get exportDocDiagSuccess => '성공';

  @override
  String get exportDocDiagFailed => '실패';

  @override
  String exportDocDiagExitCodeOf(int code) {
    return '종료 코드 $code';
  }

  @override
  String get settingsTerminalScheme => '터미널 색상 구성';

  @override
  String get settingsTerminalSchemeDesc => 'SSH 터미널의 ANSI 색상 팔레트를 선택하세요.';

  @override
  String get settingsSectionDataTransfer => '가져오기 및 내보내기';

  @override
  String get transferSnippetsTitle => '명령 스니펫';

  @override
  String get transferServersTitle => '서버 구성';

  @override
  String get transferExport => '내보내기';

  @override
  String get transferImport => '가져오기';

  @override
  String get transferExportImport => '내보내기 / 가져오기';

  @override
  String get transferExportTitle => '내보내기';

  @override
  String get transferCopyJson => 'JSON 복사';

  @override
  String get transferCopied => '클립보드에 복사됨';

  @override
  String get transferImportHint => '내보낸 JSON을 여기에 붙여넣으세요…';

  @override
  String get transferSnippetsEmpty => '내보낼 명령 스니펫이 없습니다.';

  @override
  String get transferServersEmpty => '내보낼 서버가 없습니다.';

  @override
  String get transferImportNothing => '가져오기에서 유효한 항목을 찾지 못했습니다.';

  @override
  String transferSnippetsImported(int count) {
    return '명령 스니펫 $count개 가져옴';
  }

  @override
  String transferServersImported(int count) {
    return '서버 $count개 가져옴';
  }

  @override
  String transferImportFailed(String message) {
    return '가져오기 실패: $message';
  }

  @override
  String transferExportFailed(String message) {
    return '내보내기 실패: $message';
  }

  @override
  String get sessionsTitle => '대화';

  @override
  String get sessionsNew => '새 대화';

  @override
  String get sessionsSearch => '대화 검색…';

  @override
  String get sessionsEmpty => '아직 대화가 없습니다';

  @override
  String sessionsNoMatch(String query) {
    return '일치하는 항목 없음: \"$query\"';
  }

  @override
  String get sessionsRename => '이름 바꾸기';

  @override
  String get sessionsRenameHint => '대화 제목';

  @override
  String get sessionsDelete => '삭제';

  @override
  String sessionsDeleteConfirm(String title) {
    return '\"$title\"을(를) 삭제하시겠습니까? 되돌릴 수 없습니다.';
  }

  @override
  String sessionsMessageCount(int count) {
    return '메시지 $count개';
  }

  @override
  String get settingsSectionNotifications => '알림';

  @override
  String get settingsNotificationsTitle => '백그라운드 알림';

  @override
  String get settingsNotificationsDesc =>
      '앱이 백그라운드에 있는 동안 SSH 세션이 끊기거나 AI 작업이 완료되면 알립니다.';

  @override
  String get sftpTitle => '파일';

  @override
  String get sftpNotConnected => '이 서버에 연결되어 있지 않습니다.';

  @override
  String get sftpLoading => '파일 불러오는 중…';

  @override
  String get sftpEmpty => '이 폴더는 비어 있습니다.';

  @override
  String get sftpDownload => '다운로드';

  @override
  String sftpDownloaded(String path, int size) {
    return '$path 다운로드됨 ($size바이트)';
  }

  @override
  String get sftpDownloadFailed => '다운로드 실패';

  @override
  String get sftpPreviewError => '미리보기 실패';

  @override
  String get sftpNewFolderName => '새 폴더';

  @override
  String get sftpRefresh => '새로고침';

  @override
  String get sftpDelete => '삭제';

  @override
  String sftpDeleteConfirm(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get sftpRename => '이름 바꾸기';

  @override
  String get sftpTooltip => '파일 탐색 (SFTP)';

  @override
  String get terminalMoreTooltip => '더 보기';

  @override
  String get tunnelsTitle => '포트 포워딩';

  @override
  String get tunnelsEmpty => '활성 터널이 없습니다.';

  @override
  String get tunnelsAddLocal => '로컬 포워딩';

  @override
  String get tunnelsAddRemote => '원격 포워딩';

  @override
  String get tunnelsLocalPort => '로컬 포트';

  @override
  String get tunnelsRemoteHost => '원격 호스트';

  @override
  String get tunnelsRemotePort => '원격 포트';

  @override
  String get tunnelsAdd => '추가';

  @override
  String get tunnelsClose => '닫기';

  @override
  String get tunnelsTooltip => '포트 포워딩 (SSH 터널)';

  @override
  String get tunnelsError => '터널 실패';

  @override
  String get tunnelsInvalidPort => '포트는 1에서 65535 사이여야 합니다.';

  @override
  String get settingsLanguageTitle => '언어';
}
