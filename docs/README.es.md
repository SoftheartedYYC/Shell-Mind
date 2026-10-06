# ShellMind

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

Aplicación para Android de terminal SSH basada en Flutter + asistente de IA. Conecte con sus servidores mediante SSH, ejecute un agente de IA que ejecuta comandos en los hosts conectados (con modos de confirmación y registro de auditoría), gestione flotas de servidores y supervise el estado del clúster.

![Flutter](https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white)
![Release](https://img.shields.io/github/v/release/SoftheartedYYC/Shell-Mind?include_prereleases&logo=github)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Características

| Módulo | Características |
| --- | --- |
| **Terminal SSH** | Autenticación por contraseña / clave privada ([dartssh2](https://pub.dev/packages/dartssh2)); emulación de terminal con una barra de teclado auxiliar ([xterm](https://pub.dev/packages/xterm)); reconexión automática con retroceso exponencial; registro global de múltiples sesiones — las sesiones siguen ejecutándose cuando se abandona la pantalla; **6 esquemas de colores de terminal seleccionables** (Tokyo Night / One Dark / Dracula / Monokai / Solarized Dark / Classic) |
| **Explorador SFTP** | Navegación de directorios nivel por nivel; vista previa de archivos de texto; descarga al almacenamiento local; mkdir / renombrar / eliminar |
| **Reenvío de puertos** | Túneles locales (`ssh -L`) y remotos (`ssh -R`); lista de túneles en vivo con cierre con un solo toque |
| **Agente de IA** | Ejecuta comandos en modo de confirmación o totalmente automático; interceptación de comandos peligrosos; número máximo configurable de rondas de ejecución; coordinación de múltiples servidores desde una sola conversación; línea de tiempo visual de ejecución; registro de auditoría completo de comandos |
| **Chat de IA** | **Resaltado de sintaxis en bloques de código** (shell / python / json / yaml / dockerfile / sql); **gestión de múltiples sesiones** (nueva / cambiar / renombrar / eliminar); **búsqueda en el historial de conversaciones** (títulos + cuerpos de mensajes); exportación a Markdown; adjuntar contexto de la terminal |
| **Proveedores de IA** | DeepSeek / Qwen / GLM / MiMo / OpenAI integrados (compatibles con OpenAI); proveedores personalizados (nombre + URL base + modelos); respuestas en streaming SSE; hoja de selección de modelos con filtrado por búsqueda |
| **Gestión de servidores** | CRUD con agrupación y búsqueda; insignias de estado de conexión en vivo en las tarjetas de servidor; tarjetas de agregación del estado del clúster (sondeo de tiempo de actividad / carga) con diagnóstico de IA con un clic |
| **Importación y exportación** | Exportación/importación en JSON de fragmentos de comandos y configuraciones de servidor (las credenciales nunca se exportan; las entradas importadas reciben ID nuevos) |
| **Notificaciones** | Alertas locales cuando se interrumpe una sesión SSH o finaliza una tarea de IA mientras la aplicación está en segundo plano (desactivable) |
| **Seguridad y privacidad** | Credenciales cifradas mediante `flutter_secure_storage`; bloqueo biométrico de la aplicación; modo de ocultar IP; registro de auditoría de comandos; exportación de diagnóstico de errores |
| **Productividad** | Historial persistente del chat de IA; fragmentos de comandos (entrada dual chat de IA / terminal); exportación de conversaciones a Markdown; adjuntar contexto de la terminal a las conversaciones de IA |
| **Localización y temas** | Interfaz multilingüe (English / 简体中文 / 日本語 / 한국어 / Deutsch / Français / Español / Português / Русский / Italiano); temas claro / oscuro / según el sistema |
| **Plataformas** | Android (APK divididos por ABI); iOS (Info.plist documenta el uso de red local y Face ID; el permiso de notificación lo solicita el complemento) |

## Capturas de pantalla

<!-- TODO: Add screenshots once captured. Expected location: docs/screenshots/. -->

## Primeros pasos

### Instalación desde Releases

1. Vaya a la página de [Releases](https://github.com/SoftheartedYYC/Shell-Mind/releases).
2. Descargue el APK que coincida con la ABI de su dispositivo e instálelo (`arm64-v8a` para teléfonos modernos, `armeabi-v7a` para dispositivos heredados de 32 bits, `x86_64` solo para emuladores).
3. La aplicación también busca actualizaciones dentro de la propia aplicación (a través de GitHub Releases, seleccionando automáticamente el activo que coincide con la ABI del dispositivo).

### Compilar desde el código fuente

Requisitos: Flutter 3.47+ (requiere Dart SDK ^3.13.4), Java 17+, Android SDK 36.

```bash
git clone https://github.com/SoftheartedYYC/Shell-Mind.git
cd Shell-Mind
flutter pub get
flutter run
```

Compile los APK de lanzamiento (división por ABI, coincidiendo con los artefactos de lanzamiento de CI):

```bash
flutter build apk --release --split-per-abi
```

Los artefactos se generan en `build/app/outputs/flutter-apk/` como `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` y `app-x86_64-release.apk`. Solo para pruebas en dispositivos locales, `flutter build apk --release` a secas también funciona (un APK «fat» de ~63 MB para instalación local).

> **Firma**: una compilación de lanzamiento firmada requiere dos archivos (ambos excluidos por `.gitignore` y nunca confirmados):
>
> - `android/key.properties` — cópielo desde `android/key.properties.example` y rellene credenciales reales;
> - `android/app/shellmind-release-key.jks` — el almacén de claves de lanzamiento.
>
> Si falta alguno, la compilación recurre a la configuración de firma de depuración (solo para depuración local, no para distribución). Las compilaciones oficiales se han verificado con JDK 17 y JDK 25.

## Desarrollo

```bash
# Análisis estático
flutter analyze

# Pruebas unitarias y de widgets (suite completa)
flutter test
```

## Lanzamiento CI/CD

Al enviar una etiqueta `v*` (p. ej., `v1.4.1`) se activa [GitHub Actions](.github/workflows/release.yml):

1. Verifica que la etiqueta coincida con la versión en `pubspec.yaml` (de lo contrario, falla);
2. Ejecuta la puerta de pruebas (`flutter pub get` / `flutter analyze` / `flutter test`; cualquier fallo aborta el lanzamiento);
3. Compila APK de lanzamiento firmados (`--split-per-abi`, con el nombre `Shell-Mind-v{version}-{abi}.apk` para arm64-v8a / armeabi-v7a / x86_64);
4. Extrae las notas de lanzamiento en chino de la versión correspondiente desde [CHANGELOG.md](CHANGELOG.md), crea una publicación en GitHub Release y sube automáticamente todos los APK por ABI y las sumas de comprobación.

Deben configurarse dos Secrets del repositorio en **Settings → Secrets and variables → Actions** (ambos son Base64 del contenido de los archivos):

| Secret | Contenido |
| --- | --- |
| `KEYSTORE_BASE64` | Base64 del almacén de claves de lanzamiento `android/app/shellmind-release-key.jks` |
| `KEY_PROPERTIES_BASE64` | Base64 de `android/key.properties` |

Generar con PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('<path>'))`

> Si faltan los Secrets, el flujo de trabajo falla de inmediato — nunca publica un APK firmado para depuración.

## Pila tecnológica

| Capa | Biblioteca |
| --- | --- |
| Framework | Flutter 3.47+ / Dart ^3.13.4 |
| Gestión de estado | flutter_riverpod |
| Enrutamiento | go_router |
| SSH | dartssh2 |
| Emulación de terminal | xterm |
| Transporte de IA | dio (streaming SSE) |
| Almacenamiento local | hive_ce |
| Almacenamiento seguro | flutter_secure_storage |
| Biometría | local_auth |
| Actualización dentro de la aplicación | package_info_plus / open_filex / permission_handler |

## Aviso legal

Esta aplicación permite que un agente de IA ejecute comandos en servidores reales, y el modo totalmente automático los ejecuta sin confirmación por comando. La interceptación de comandos peligrosos es una salvaguarda, no una garantía. No active el modo automático sin supervisión en hosts de producción o críticos. Úselo bajo su propia responsabilidad.

## Licencia

Este proyecto se publica bajo la [Licencia MIT](LICENSE).
