# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Auf Flutter basierende Android-App mit SSH-Terminal und KI-Assistent. Verbinden Sie sich per SSH mit Ihren Servern, lassen Sie einen KI-Agenten Befehle auf verbundenen Hosts ausführen (mit Bestätigungsmodi und Audit-Protokollierung), verwalten Sie Serverflotten und überwachen Sie den Cluster-Zustand.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Funktionen

| Modul | Funktionen |
| --- | --- |
| **SSH Terminal** | Passwort- / Authentifizierung mit privatem Schlüssel ([dartssh2](https://pub.dev/packages/dartssh2)); Terminal-Emulation mit einer zusätzlichen Tastaturleiste ([xterm](https://pub.dev/packages/xterm)); automatische Wiederverbindung mit exponentiellem Backoff; globale Registrierung mehrerer Sitzungen — Sitzungen laufen weiter, wenn Sie die Ansicht wechseln; **6 wählbare Terminal-Farbschemata** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **SFTP Browser** | Ordner-Durchsuchen mit Navigation Ebene für Ebene; Vorschau von Textdateien; Herunterladen in den lokalen Speicher; mkdir / Umbenennen / Löschen |
| **Portweiterleitung** | Lokale (`ssh -L`) und entfernte (`ssh -R`) Tunnel; Live-Tunnelliste mit Schließen per Fingertipp |
| **KI-Agent** | Führt Befehle im Bestätigungs- oder vollautomatischen Modus aus; Abfangen gefährlicher Befehle; konfigurierbare maximale Ausführungsrunden; Koordination mehrerer Server aus einer einzigen Konversation; visuelle Ausführungszeitleiste; vollständiges Befehls-Audit-Protokoll |
| **KI-Chat** | **Syntaxhervorhebung für Codeblöcke** (shell / python / json / yaml / dockerfile / sql); **Verwaltung mehrerer Sitzungen** (neu / wechseln / umbenennen / löschen); **Suche im Konversationsverlauf** (Titel + Nachrichtentexte); Markdown-Export; Terminalkontext anhängen |
| **KI-Anbieter** | Integriert: DeepSeek / Qwen / GLM / MiMo / OpenAI (OpenAI-kompatibel); benutzerdefinierte Anbieter (Name + Basis-URL + Modelle); SSE-Streaming-Antworten; Modellauswahl mit Suchfilter |
| **Serververwaltung** | CRUD mit Gruppierung und Suche; Live-Statusanzeigen zur Verbindung auf Serverkarten; aggregierte Karten zum Cluster-Zustand (Uptime / Lastabfrage) mit KI-Diagnose per Klick |
| **Import & Export** | JSON-Export/-Import von Befehlsschnipseln und Serverkonfigurationen (Zugangsdaten werden niemals exportiert; importierte Einträge erhalten neue IDs) |
| **Benachrichtigungen** | Lokale Benachrichtigungen, wenn eine SSH-Sitzung abbricht oder eine KI-Aufgabe endet, während die App im Hintergrund läuft (abschaltbar) |
| **Sicherheit & Datenschutz** | Zugangsdaten verschlüsselt über `flutter_secure_storage`; biometrische App-Sperre; IP-Ausblendmodus; Befehls-Audit-Protokoll; Export zur Fehlerdiagnose |
| **Produktivität** | Dauerhafter KI-Chat-Verlauf; Befehlsschnipsel (doppelter Eintrag über KI-Chat / Terminal); Markdown-Export von Konversationen; Terminalkontext an KI-Konversationen anhängen |
| **Lokalisierung & Designs** | Mehrsprachige Oberfläche (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); helle / dunkle / systemabhängige Designs |
| **Plattformen** | Android (nach ABI aufgeteilte APKs); iOS (Info.plist dokumentiert lokale Netzwerk- und Face-ID-Nutzung; die Benachrichtigungsberechtigung wird vom Plugin angefordert) |

## Screenshots

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Erste Schritte

### Installation aus Releases

1. Öffnen Sie die Seite [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases).
2. Laden Sie die zum ABI Ihres Geräts passende APK herunter und installieren Sie sie (`arm64-v8a` für moderne Smartphones, `armeabi-v7a` für ältere 32-Bit-Geräte, `x86_64` nur für Emulatoren).
3. Die App prüft außerdem in der App auf Updates (über GitHub Releases, wobei automatisch das zum Geräte-ABI passende Asset ausgewählt wird).

### Aus dem Quellcode bauen

Voraussetzungen: Flutter 3.47+ (erfordert Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Release-APKs bauen (nach ABI aufgeteilt, entsprechend den CI-Release-Artefakten):

```bash
flutter build apk --release --split-per-abi
```

Die Artefakte landen in `build/app/outputs/flutter-apk/` als `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` und `app-x86_64-release.apk`. Nur für lokale Gerätetests funktioniert auch einfaches `flutter build apk --release` (eine ~63 MB große Fat-APK für die lokale Installation).

> **Signierung**: Ein signierter Release-Build erfordert zwei Dateien (beide über `.gitignore` ausgeschlossen und niemals committet):
>
> - `android/key.properties` — von `android/key.properties.example` kopieren und echte Zugangsdaten eintragen;
> - `android/app/shellmind-release-key.jks` — der Release-Keystore.
>
> Fehlt eine der beiden Dateien, fällt der Build auf die Debug-Signierkonfiguration zurück (nur lokales Debugging, nicht für die Verteilung). Offizielle Builds wurden mit JDK 17 und JDK 25 verifiziert.

## Entwicklung

```bash
# Statische Analyse
flutter analyze

# Unit- & Widget-Tests (vollständige Suite)
flutter test
```

## CI/CD Release

Das Pushen eines `v*`-Tags (z. B. `v1.4.1`) löst [GitHub Actions](.github/workflows/release.yml) aus:

1. Prüft, ob der Tag mit der Version in `pubspec.yaml` übereinstimmt (andernfalls Fehlschlag);
2. Führt den Test-Gate aus (`flutter pub get` / `flutter analyze` / `flutter test`, jeder Fehler bricht den Release ab);
3. Baut signierte Release-APKs (`--split-per-abi`, benannt als `Shell-Mind-v{version}-{abi}.apk` für arm64-v8a / armeabi-v7a / x86_64);
4. Extrahiert die chinesischen Release-Notizen der passenden Version aus [CHANGELOG.md](../CHANGELOG.md), erstellt ein GitHub Release und lädt alle nach ABI aufgeteilten APKs und Prüfsummen automatisch hoch.

Zwei Repository-Secrets müssen unter **Settings → Secrets and variables → Actions** konfiguriert werden (beide sind Base64 der Dateiinhalte):

| Secret | Inhalt |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 des Release-Keystore `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 von `android/key.properties` |

Erzeugen mit PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Fehlen die Secrets, schlägt der Workflow sofort fehl — er veröffentlicht niemals eine debug-signierte APK.

## Technologie-Stack

| Ebene | Bibliothek |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| State-Management | flutter_riverpod |
| Routing | go_router |
| SSH | dartssh2 |
| Terminal-Emulation | xterm |
| KI-Transport | dio (SSE-Streaming) |
| Lokaler Speicher | hive_ce |
| Sicherer Speicher | flutter_secure_storage |
| Biometrie | local_auth |
| In-App-Update | package_info_plus / open_filex / permission_handler |

## Haftungsausschluss

Diese App ermöglicht es einem KI-Agenten, Befehle auf echten Servern auszuführen, und der vollautomatische Modus führt Befehle ohne Bestätigung pro Befehl aus. Das Abfangen gefährlicher Befehle ist eine Schutzmaßnahme, keine Garantie. Aktivieren Sie den Automatikmodus nicht unbeaufsichtigt auf Produktions- oder kritischen Hosts. Die Nutzung erfolgt auf eigenes Risiko.

## Lizenz

Dieses Projekt wird unter der [MIT-Lizenz](LICENSE) veröffentlicht.
