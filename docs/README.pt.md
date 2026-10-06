# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Aplicativo Android de terminal SSH + assistente de IA baseado em Flutter. Conecte-se aos seus servidores via SSH, execute um agente de IA que executa comandos nos hosts conectados (com modos de confirmação e registro de auditoria), gerencie frotas de servidores e monitore a saúde do cluster.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Recursos

| Módulo | Recursos |
| --- | --- |
| **Terminal SSH** | Autenticação por senha / chave privada ([dartssh2](https://pub.dev/packages/dartssh2)); emulação de terminal com uma barra de teclado auxiliar ([xterm](https://pub.dev/packages/xterm)); reconexão automática com backoff exponencial; registro global de múltiplas sessões — as sessões continuam em execução quando você navega para outra tela; **6 esquemas de cores de terminal selecionáveis** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **Navegador SFTP** | Navegação por diretórios com navegação nível a nível; visualização de arquivos de texto; download para o armazenamento local; mkdir / renomear / excluir |
| **Encaminhamento de porta** | Túneis locais (`ssh -L`) e remotos (`ssh -R`); lista de túneis em tempo real com fechamento com um toque |
| **Agente de IA** | Executa comandos no modo de confirmação ou totalmente automático; interceptação de comandos perigosos; número máximo configurável de rodadas de execução; coordenação de múltiplos servidores a partir de uma única conversa; linha do tempo visual de execução; registro completo de auditoria de comandos |
| **Chat de IA** | **Realce de sintaxe em blocos de código** (shell / python / json / yaml / dockerfile / sql); **gerenciamento de múltiplas sessões** (nova / alternar / renomear / excluir); **busca no histórico de conversas** (títulos + corpo das mensagens); exportação em Markdown; anexar contexto do terminal |
| **Provedores de IA** | DeepSeek / Qwen / GLM / MiMo / OpenAI integrados (compatível com OpenAI); provedores personalizados (nome + URL base + modelos); respostas em streaming SSE; seletor de modelos com filtro de busca |
| **Gerenciamento de servidores** | CRUD com agrupamento e busca; selos de status de conexão em tempo real nos cartões de servidor; cartões de agregação de saúde do cluster (tempo de atividade / sondagem de carga) com diagnóstico de IA com um clique |
| **Importar e Exportar** | Exportação/importação em JSON de trechos de comandos e configurações de servidor (as credenciais nunca são exportadas; as entradas importadas recebem IDs novos) |
| **Notificações** | Alertas locais quando uma sessão SSH é interrompida ou uma tarefa de IA termina enquanto o aplicativo está em segundo plano (ativável) |
| **Segurança e Privacidade** | Credenciais criptografadas via `flutter_secure_storage`; bloqueio biométrico do aplicativo; modo de ocultar IP; registro de auditoria de comandos; exportação de diagnóstico de erros |
| **Produtividade** | Histórico persistente de chat de IA; trechos de comandos (entrada dupla: chat de IA / terminal); exportação de conversa em Markdown; anexar contexto do terminal às conversas de IA |
| **Localização e Temas** | Interface em vários idiomas (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); temas claro / escuro / seguir o sistema |
| **Plataformas** | Android (APKs divididos por ABI); iOS (o Info.plist documenta o uso de rede local e Face ID; a permissão de notificação é solicitada pelo plugin) |

## Capturas de tela

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Começando

### Instalar a partir dos Releases

1. Acesse a página de [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases).
2. Baixe o APK correspondente à ABI do seu dispositivo e instale-o (`arm64-v8a` para celulares modernos, `armeabi-v7a` para dispositivos legados de 32 bits, `x86_64` somente para emuladores).
3. O aplicativo também verifica atualizações dentro do app (via GitHub Releases, selecionando automaticamente o artefato correspondente à ABI do dispositivo).

### Compilar a partir do código-fonte

Requisitos: Flutter 3.47+ (requer Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Compilar APKs de release (divididos por ABI, correspondendo aos artefatos de release do CI):

```bash
flutter build apk --release --split-per-abi
```

Os artefatos são gerados em `build/app/outputs/flutter-apk/` como `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` e `app-x86_64-release.apk`. Somente para testes em dispositivo local, o comando simples `flutter build apk --release` também funciona (um APK "fat" de ~63 MB para instalação local).

> **Assinatura**: um build de release assinado requer dois arquivos (ambos excluídos pelo `.gitignore` e nunca commitados):
>
> - `android/key.properties` — copie de `android/key.properties.example` e preencha com credenciais reais;
> - `android/app/shellmind-release-key.jks` — o keystore de release.
>
> Se algum deles estiver ausente, o build recorre à configuração de assinatura de debug (somente para depuração local, não para distribuição). Builds oficiais foram verificados com JDK 17 e JDK 25.

## Desenvolvimento

```bash
# Análise estática
flutter analyze

# Testes de unidade e de widget (suíte completa)
flutter test
```

## Release de CI/CD

Enviar uma tag `v*` (por exemplo, `v1.4.1`) aciona o [GitHub Actions](.github/workflows/release.yml):

1. Verifica se a tag corresponde à versão em `pubspec.yaml` (caso contrário, falha);
2. Executa o gate de testes (`flutter pub get` / `flutter analyze` / `flutter test`, qualquer falha aborta o release);
3. Compila APKs de release assinados (`--split-per-abi`, nomeados como `Shell-Mind-v{version}-{abi}.apk` para arm64-v8a / armeabi-v7a / x86_64);
4. Extrai as notas de release em chinês da versão correspondente do [CHANGELOG.md](../CHANGELOG.md), cria um GitHub Release e faz upload de todos os APKs por ABI e dos checksums automaticamente.

Dois Secrets do repositório devem ser configurados em **Settings → Secrets and variables → Actions** (ambos são Base64 do conteúdo dos arquivos):

| Secret | Conteúdo |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 do keystore de release `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 de `android/key.properties` |

Gere com o PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Se os Secrets estiverem ausentes, o workflow falha imediatamente — ele nunca publica um APK assinado com debug.

## Stack de Tecnologias

| Camada | Biblioteca |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| Gerenciamento de estado | flutter_riverpod |
| Roteamento | go_router |
| SSH | dartssh2 |
| Emulação de terminal | xterm |
| Transporte de IA | dio (streaming SSE) |
| Armazenamento local | hive_ce |
| Armazenamento seguro | flutter_secure_storage |
| Biometria | local_auth |
| Atualização no app | package_info_plus / open_filex / permission_handler |

## Aviso legal

Este aplicativo permite que um agente de IA execute comandos em servidores reais, e o modo totalmente automático executa sem confirmação por comando. A interceptação de comandos perigosos é uma salvaguarda, não uma garantia. Não ative o modo automático sem supervisão em hosts de produção ou críticos. Use por sua própria conta e risco.

## Licença

Este projeto é distribuído sob a [Licença MIT](LICENSE).
