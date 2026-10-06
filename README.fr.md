# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Application Android basée sur Flutter : terminal SSH + assistant IA. Connectez-vous à vos serveurs via SSH, exécutez un agent IA qui lance des commandes sur les hôtes connectés (avec modes de confirmation et journalisation d'audit), gérez vos parcs de serveurs et surveillez la santé de vos clusters.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Fonctionnalités

| Module | Fonctionnalités |
| --- | --- |
| **Terminal SSH** | Authentification par mot de passe / clé privée ([dartssh2](https://pub.dev/packages/dartssh2)) ; émulation de terminal avec barre de clavier auxiliaire ([xterm](https://pub.dev/packages/xterm)) ; reconnexion automatique avec backoff exponentiel ; registre global multi-session — les sessions continuent de tourner lorsque vous quittez l'écran ; **6 palettes de couleurs de terminal sélectionnables** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **Explorateur SFTP** | Navigation dans les dossiers niveau par niveau ; aperçu des fichiers texte ; téléchargement vers le stockage local ; mkdir / renommer / supprimer |
| **Redirection de port** | Tunnels locaux (`ssh -L`) et distants (`ssh -R`) ; liste des tunnels en temps réel avec fermeture en un seul geste |
| **Agent IA** | Exécute des commandes en mode confirmation ou entièrement automatique ; interception des commandes dangereuses ; nombre maximal de tours d'exécution configurable ; coordination multi-serveur depuis une seule conversation ; chronologie visuelle des exécutions ; journal d'audit complet des commandes |
| **Chat IA** | **Coloration syntaxique des blocs de code** (shell / python / json / yaml / dockerfile / sql) ; **gestion multi-session** (nouvelle / basculer / renommer / supprimer) ; **recherche dans l'historique des conversations** (titres + corps des messages) ; export Markdown ; joindre le contexte du terminal |
| **Fournisseurs IA** | DeepSeek / Qwen / GLM / MiMo / OpenAI intégrés (compatibles OpenAI) ; fournisseurs personnalisés (nom + URL de base + modèles) ; réponses en streaming SSE ; sélecteur de modèle avec filtrage par recherche |
| **Gestion des serveurs** | CRUD avec regroupement et recherche ; badges d'état de connexion en temps réel sur les cartes des serveurs ; cartes d'agrégation de la santé du cluster (sondage de la disponibilité / de la charge) avec diagnostic IA en un clic |
| **Import & Export** | Export/import JSON des extraits de commandes et des configurations de serveurs (les identifiants ne sont jamais exportés ; les entrées importées reçoivent de nouveaux identifiants) |
| **Notifications** | Alertes locales lorsqu'une session SSH est interrompue ou qu'une tâche IA se termine alors que l'application est en arrière-plan (désactivable) |
| **Sécurité & Confidentialité** | Identifiants chiffrés via `flutter_secure_storage` ; verrouillage biométrique de l'application ; mode masquage d'IP ; journal d'audit des commandes ; export du diagnostic d'erreur |
| **Productivité** | Historique persistant des conversations IA ; extraits de commandes (double saisie chat IA / terminal) ; export Markdown des conversations ; joindre le contexte du terminal aux conversations IA |
| **Localisation & Thèmes** | Interface multilingue (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano) ; thèmes clair / sombre / suivant le système |
| **Plateformes** | Android (APK divisés par ABI) ; iOS (Info.plist documente l'utilisation du réseau local et de Face ID ; l'autorisation de notification est demandée par le plugin) |

## Captures d'écran

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Démarrage

### Installer depuis les Releases

1. Accédez à la page [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases).
2. Téléchargez l'APK correspondant à l'ABI de votre appareil et installez-le (`arm64-v8a` pour les téléphones récents, `armeabi-v7a` pour les appareils 32 bits anciens, `x86_64` pour les émulateurs uniquement).
3. L'application vérifie également les mises à jour directement dans l'application (via GitHub Releases, en sélectionnant automatiquement l'élément correspondant à l'ABI de l'appareil).

### Compiler depuis les sources

Prérequis : Flutter 3.47+ (nécessite Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Compiler les APK de release (division par ABI, conformes aux artefacts de release de la CI) :

```bash
flutter build apk --release --split-per-abi
```

Les artefacts sont générés dans `build/app/outputs/flutter-apk/` sous les noms `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` et `app-x86_64-release.apk`. Pour un test sur un appareil local uniquement, la simple commande `flutter build apk --release` fonctionne également (un APK « fat » d'environ 63 Mo pour une installation locale).

> **Signature** : une compilation de release signée nécessite deux fichiers (tous deux exclus par `.gitignore` et jamais validés) :
>
> - `android/key.properties` — copiez depuis `android/key.properties.example` et renseignez les identifiants réels ;
> - `android/app/shellmind-release-key.jks` — le keystore de release.
>
> Si l'un des deux manque, la compilation retombe sur la configuration de signature de débogage (débogage local uniquement, pas pour la distribution). Les compilations officielles ont été vérifiées avec JDK 17 et JDK 25.

## Développement

```bash
# Static analysis
flutter analyze

# Unit & widget tests (full suite)
flutter test
```

## Publication CI/CD

Le push d'un tag `v*` (par ex. `v1.4.1`) déclenche [GitHub Actions](.github/workflows/release.yml) :

1. Vérifie que le tag correspond à la version dans `pubspec.yaml` (échec sinon) ;
2. Exécute la porte de tests (`flutter pub get` / `flutter analyze` / `flutter test`, tout échec interrompt la publication) ;
3. Compile les APK de release signés (`--split-per-abi`, nommés `Shell-Mind-v{version}-{abi}.apk` pour arm64-v8a / armeabi-v7a / x86_64) ;
4. Extrait les notes de version en chinois de la version correspondante depuis [CHANGELOG.md](CHANGELOG.md), crée une GitHub Release et téléverse automatiquement tous les APK par ABI ainsi que les sommes de contrôle.

Deux Secrets du dépôt doivent être configurés sous **Settings → Secrets and variables → Actions** (tous deux sont le Base64 du contenu des fichiers) :

| Secret | Contenu |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 du keystore de release `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 de `android/key.properties` |

Générez avec PowerShell : `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Si les Secrets sont manquants, le workflow échoue immédiatement — il ne publie jamais un APK signé en débogage.

## Pile technologique

| Couche | Bibliothèque |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| Gestion d'état | flutter_riverpod |
| Routage | go_router |
| SSH | dartssh2 |
| Émulation de terminal | xterm |
| Transport IA | dio (streaming SSE) |
| Stockage local | hive_ce |
| Stockage sécurisé | flutter_secure_storage |
| Biométrie | local_auth |
| Mise à jour dans l'application | package_info_plus / open_filex / permission_handler |

## Avertissement

Cette application permet à un agent IA d'exécuter des commandes sur de vrais serveurs, et le mode entièrement automatique exécute sans confirmation par commande. L'interception des commandes dangereuses est une protection, pas une garantie. N'activez pas le mode automatique sans surveillance sur des hôtes de production ou critiques. Utilisez à vos propres risques.

## Licence

Ce projet est publié sous la [licence MIT](LICENSE).
