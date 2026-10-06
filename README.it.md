# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

App Android basata su Flutter che combina un terminale SSH e un assistente AI. Si connetta ai Suoi server tramite SSH, esegua un agente AI che lancia comandi sugli host connessi (con modalità di conferma e registrazione di audit), gestisca flotte di server e monitori lo stato di salute dei cluster.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Funzionalità

| Modulo | Funzionalità |
| --- | --- |
| **Terminale SSH** | Autenticazione tramite password / chiave privata ([dartssh2](https://pub.dev/packages/dartssh2)); emulazione del terminale con barra tastiera ausiliaria ([xterm](https://pub.dev/packages/xterm)); riconnessione automatica con backoff esponenziale; registro globale multi-sessione — le sessioni continuano a essere eseguite quando Lei si sposta su un'altra schermata; **6 schemi di colori del terminale selezionabili** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **Browser SFTP** | Esplorazione delle cartelle con navigazione livello per livello; anteprima dei file di testo; scarica nella memoria locale; mkdir / rinomina / eliminazione |
| **Port Forwarding** | Tunnel locali (`ssh -L`) e remoti (`ssh -R`); elenco dei tunnel in tempo reale con chiusura con un solo tocco |
| **Agente AI** | Esegue i comandi in modalità di conferma o completamente automatica; intercettazione dei comandi pericolosi; numero massimo di round di esecuzione configurabile; coordinamento multi-server da una singola conversazione; timeline visiva dell'esecuzione; registro di audit completo dei comandi |
| **Chat AI** | **Evidenziazione della sintassi nei blocchi di codice** (shell / python / json / yaml / dockerfile / sql); **gestione multi-sessione** (nuova / cambia / rinomina / elimina); **ricerca nella cronologia delle conversazioni** (titoli + corpo dei messaggi); esportazione Markdown; allegare il contesto del terminale |
| **Provider AI** | Provider integrati DeepSeek / Qwen / GLM / MiMo / OpenAI (compatibili con OpenAI); provider personalizzati (nome + Base URL + modelli); risposte in streaming SSE; pannello di selezione dei modelli con filtro di ricerca |
| **Gestione dei server** | CRUD con raggruppamento e ricerca; badge dello stato di connessione in tempo reale sulle schede dei server; schede aggregate sullo stato di salute del cluster (uptime / rilevamento del carico) con diagnosi AI in un clic |
| **Importazione ed esportazione** | Esportazione/importazione JSON di frammenti di comando e configurazioni dei server (le credenziali non vengono mai esportate; le voci importate ricevono ID nuovi) |
| **Notifiche** | Avvisi locali quando una sessione SSH si interrompe o un'attività AI termina mentre l'app è in background (disattivabili) |
| **Sicurezza e privacy** | Credenziali crittografate tramite `flutter_secure_storage`; blocco biometrico dell'app; modalità nascondi-IP; registro di audit dei comandi; esportazione della diagnosi degli errori |
| **Produttività** | Cronologia persistente delle chat AI; frammenti di comando (doppia immissione chat AI / terminale); esportazione Markdown delle conversazioni; allegare il contesto del terminale alle conversazioni AI |
| **Localizzazione e temi** | Interfaccia multilingue (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); temi chiaro / scuro / segui il sistema |
| **Piattaforme** | Android (APK suddivisi per ABI); iOS (Info.plist documenta l'uso della rete locale e del Face ID; l'autorizzazione per le notifiche è richiesta dal plugin) |

## Screenshot

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Per iniziare

### Installazione dalle Release

1. Vada alla pagina [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases).
2. Scarichi l'APK corrispondente all'ABI del Suo dispositivo e lo installi (`arm64-v8a` per i telefoni moderni, `armeabi-v7a` per i dispositivi legacy a 32 bit, `x86_64` solo per gli emulatori).
3. L'app verifica inoltre gli aggiornamenti direttamente al suo interno (tramite GitHub Releases, selezionando automaticamente l'asset corrispondente all'ABI del dispositivo).

### Compilazione dai sorgenti

Requisiti: Flutter 3.47+ (richiede Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Compili gli APK di release (suddivisi per ABI, corrispondenti agli artifact della release CI):

```bash
flutter build apk --release --split-per-abi
```

Gli artifact vengono generati in `build/app/outputs/flutter-apk/` come `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` e `app-x86_64-release.apk`. Solo per i test su dispositivo locale, funziona anche il semplice `flutter build apk --release` (un APK "fat" di circa 63 MB per l'installazione locale).

> **Firma**: una build di release firmata richiede due file (entrambi esclusi da `.gitignore` e mai sottoposti a commit):
>
> - `android/key.properties` — copi da `android/key.properties.example` e inserisca le credenziali reali;
> - `android/app/shellmind-release-key.jks` — il keystore di release.
>
> Se uno dei due è assente, la build ripiega sulla configurazione di firma di debug (solo per il debug locale, non per la distribuzione). Le build ufficiali sono state verificate con JDK 17 e JDK 25.

## Sviluppo

```bash
# Static analysis
flutter analyze

# Unit & widget tests (full suite)
flutter test
```

## CI/CD Release

L'invio di un tag `v*` (ad es. `v1.4.1`) attiva [GitHub Actions](.github/workflows/release.yml):

1. Verifica che il tag corrisponda alla versione in `pubspec.yaml` (in caso contrario fallisce);
2. Esegue il gate dei test (`flutter pub get` / `flutter analyze` / `flutter test`; qualsiasi errore interrompe la release);
3. Compila gli APK di release firmati (`--split-per-abi`, denominati `Shell-Mind-v{version}-{abi}.apk` per arm64-v8a / armeabi-v7a / x86_64);
4. Estrae le note di release in cinese della versione corrispondente da [CHANGELOG.md](CHANGELOG.md), crea una GitHub Release e carica automaticamente tutti gli APK per ABI e i relativi checksum.

Devono essere configurati due Secrets del repository in **Settings → Secrets and variables → Actions** (entrambi sono il Base64 del contenuto dei file):

| Secret | Contenuto |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 del keystore di release `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 di `android/key.properties` |

Si genera con PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Se i Secrets sono assenti, il workflow fallisce immediatamente — non pubblica mai un APK firmato in modalità debug.

## Stack tecnologico

| Livello | Libreria |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| Gestione dello stato | flutter_riverpod |
| Routing | go_router |
| SSH | dartssh2 |
| Emulazione del terminale | xterm |
| Trasporto AI | dio (streaming SSE) |
| Archiviazione locale | hive_ce |
| Archiviazione sicura | flutter_secure_storage |
| Biometria | local_auth |
| Aggiornamento in-app | package_info_plus / open_filex / permission_handler |

## Dichiarazione di non responsabilità

Questa app consente a un agente AI di eseguire comandi su server reali e la modalità completamente automatica esegue senza conferma per ogni comando. L'intercettazione dei comandi pericolosi è una salvaguardia, non una garanzia. Non abiliti la modalità automatica senza supervisione su host di produzione o critici. L'uso è a Suo rischio e pericolo.

## Licenza

Questo progetto è rilasciato sotto la [Licenza MIT](LICENSE).
