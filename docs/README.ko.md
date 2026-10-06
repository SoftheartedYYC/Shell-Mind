# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Flutter 기반 Android SSH 터미널 + AI 어시스턴트 앱입니다. SSH로 서버에 연결하고, 연결된 호스트에서 명령을 실행하는 AI 에이전트를 구동하며(확인 모드 및 감사 로깅 지원), 서버 집단을 관리하고 클러스터 상태를 모니터링합니다.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 기능

| 모듈 | 기능 |
| --- | --- |
| **SSH 터미널** | 비밀번호 / 개인 키 인증([dartssh2](https://pub.dev/packages/dartssh2)); 보조 키보드 바가 있는 터미널 에뮬레이션([xterm](https://pub.dev/packages/xterm)); 지수 백오프 방식 자동 재연결; 전역 멀티 세션 레지스트리 — 화면을 벗어나도 세션이 계속 실행됩니다; **선택 가능한 터미널 색상 구성 6종**(Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **SFTP 브라우저** | 단계별 탐색이 가능한 디렉터리 탐색; 텍스트 파일 미리보기; 로컬 저장소로 다운로드; mkdir / 이름 변경 / 삭제 |
| **포트 포워딩** | 로컬(`ssh -L`) 및 원격(`ssh -R`) 터널; 한 번 탭으로 닫을 수 있는 실시간 터널 목록 |
| **AI 에이전트** | 확인 모드 또는 완전 자동 모드로 명령 실행; 위험 명령 차단; 설정 가능한 최대 실행 라운드; 단일 대화에서의 다중 서버 협업; 시각적 실행 타임라인; 전체 명령 감사 로그 |
| **AI 채팅** | **코드 블록 구문 강조**(shell / python / json / yaml / dockerfile / sql); **멀티 세션 관리**(새로 만들기 / 전환 / 이름 변경 / 삭제); **대화 기록 검색**(제목 + 메시지 본문); Markdown 내보내기; 터미널 컨텍스트 첨부 |
| **AI 제공자** | 내장 DeepSeek / Qwen / GLM / MiMo / OpenAI(OpenAI 호환); 사용자 지정 제공자(이름 + Base URL + 모델); SSE 스트리밍 응답; 검색 필터링이 있는 모델 선택 시트 |
| **서버 관리** | 그룹화 및 검색이 포함된 CRUD; 서버 카드의 실시간 연결 상태 배지; 원클릭 AI 진단이 포함된 클러스터 상태 집계 카드(업타임 / 부하 프로빙) |
| **가져오기 및 내보내기** | 명령 스니펫과 서버 설정의 JSON 내보내기/가져오기(자격 증명은 절대 내보내지 않으며, 가져온 항목에는 새 ID가 부여됩니다) |
| **알림** | 앱이 백그라운드에 있을 때 SSH 세션이 끊기거나 AI 작업이 완료되면 로컬 알림(토글 가능) |
| **보안 및 개인정보** | `flutter_secure_storage`를 통한 자격 증명 암호화; 생체 인식 앱 잠금; IP 숨김 모드; 명령 감사 로그; 오류 진단 내보내기 |
| **생산성** | 영구 AI 채팅 기록; 명령 스니펫(AI 채팅 / 터미널 이중 입력); Markdown 대화 내보내기; AI 대화에 터미널 컨텍스트 첨부 |
| **로컬라이제이션 및 테마** | 다국어 인터페이스(English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); 라이트 / 다크 / 시스템 설정 따름 테마 |
| **플랫폼** | Android(ABI별 분할 APK); iOS(Info.plist에 로컬 네트워크 및 Face ID 사용 명시; 알림 권한은 플러그인에서 요청) |

## 스크린샷

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## 시작하기

### 릴리스에서 설치

1. [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases) 페이지로 이동합니다.
2. 기기의 ABI에 맞는 APK를 다운로드하여 설치합니다(최신 휴대폰은 `arm64-v8a`, 레거시 32비트 기기는 `armeabi-v7a`, 에뮬레이터 전용은 `x86_64`).
3. 앱은 앱 내에서도 업데이트를 확인합니다(GitHub Releases를 통해 기기 ABI에 맞는 에셋을 자동 선택).

### 소스에서 빌드

요구 사항: Flutter 3.47+ (Dart SDK ^3.13.4 필요), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

릴리스 APK 빌드(CI 릴리스 아티팩트와 일치하는 ABI별 분할):

```bash
flutter build apk --release --split-per-abi
```

아티팩트는 `build/app/outputs/flutter-apk/`에 `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`로 저장됩니다. 로컬 기기 테스트 전용으로는 일반 `flutter build apk --release`도 작동합니다(로컬 설치용 약 63 MB 통합 APK).

> **서명**: 서명된 릴리스 빌드에는 두 개의 파일이 필요합니다(둘 다 `.gitignore`로 제외되며 절대 커밋되지 않습니다):
>
> - `android/key.properties` — `android/key.properties.example`에서 복사하고 실제 자격 증명을 입력하세요;
> - `android/app/shellmind-release-key.jks` — 릴리스 키스토어.
>
> 둘 중 하나라도 없으면 빌드는 디버그 서명 설정으로 대체됩니다(로컬 디버깅 전용이며 배포용이 아님). 공식 빌드는 JDK 17 및 JDK 25에서 검증되었습니다.

## 개발

```bash
# Static analysis
flutter analyze

# Unit & widget tests (full suite)
flutter test
```

## CI/CD 릴리스

`v*` 태그(예: `v1.4.1`)를 푸시하면 [GitHub Actions](.github/workflows/release.yml)가 트리거됩니다:

1. 태그가 `pubspec.yaml`의 버전과 일치하는지 확인합니다(일치하지 않으면 실패);
2. 테스트 게이트를 실행합니다(`flutter pub get` / `flutter analyze` / `flutter test`, 실패 시 릴리스가 중단됨);
3. 서명된 릴리스 APK를 빌드합니다(`--split-per-abi`, arm64-v8a / armeabi-v7a / x86_64용 `Shell-Mind-v{version}-{abi}.apk` 이름);
4. [CHANGELOG.md](../CHANGELOG.md)에서 해당 버전의 중국어 릴리스 노트를 추출하고, GitHub Release를 생성한 뒤 모든 ABI별 APK와 체크섬을 자동으로 업로드합니다.

**Settings → Secrets and variables → Actions**에서 두 개의 저장소 Secret을 설정해야 합니다(둘 다 파일 내용의 Base64):

| Secret | 내용 |
| --- | --- |
| `KEYSTORE_BASE64` | 릴리스 키스토어 `android/app/shellmind-release-key.jks`의 Base64 |
| `KEY_PROPERTIES_BASE64` | `android/key.properties`의 Base64 |

PowerShell로 생성: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Secret이 없으면 워크플로가 즉시 실패합니다 — 디버그 서명 APK는 절대 게시하지 않습니다.

## 기술 스택

| 계층 | 라이브러리 |
| --- | --- |
| 프레임워크 | Flutter 3.47+ / Dart ^3.13.4 |
| 상태 관리 | flutter_riverpod |
| 라우팅 | go_router |
| SSH | dartssh2 |
| 터미널 에뮬레이션 | xterm |
| AI 전송 | dio (SSE 스트리밍) |
| 로컬 저장소 | hive_ce |
| 보안 저장소 | flutter_secure_storage |
| 생체 인식 | local_auth |
| 앱 내 업데이트 | package_info_plus / open_filex / permission_handler |

## 면책 조항

이 앱은 AI 에이전트가 실제 서버에서 명령을 실행하도록 하며, 완전 자동 모드는 명령별 확인 없이 실행됩니다. 위험 명령 차단은 안전장치일 뿐 보장이 아닙니다. 프로덕션 또는 중요 호스트에서는 자동 모드를 무인으로 활성화하지 마십시오. 사용에 따른 책임은 본인에게 있습니다.

## 라이선스

이 프로젝트는 [MIT License](LICENSE)에 따라 배포됩니다.
