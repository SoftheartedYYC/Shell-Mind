/// Global application constants.
///
/// Kept in one place so environment/build variations (e.g. dev vs prod API
/// endpoints) can be swapped centrally without touching feature code.
abstract final class AppConstants {
  // ─── Identity ───────────────────────────────────────────────────────────
  static const String appName = 'ShellMind';
  static const String appTagline = 'SSH · AI · Command';
  static const String appVersion = '1.5.1';
  static const int appBuildNumber = 10;

  /// Emitted at the top of exported terminal transcripts.
  static const String userAgent = '$appName/$appVersion';

  // ─── Debug / diagnostics ────────────────────────────────────────────────
  /// When true, GoRouter logs every navigation event.
  static const bool debugRouter = false;

  /// When true, network requests and responses are logged to console.
  static const bool debugNetwork = false;

  /// When true, verbose SSH traffic is dumped to console.
  static const bool debugSsh = false;

  // ─── SSH defaults ───────────────────────────────────────────────────────
  static const int defaultSshPort = 22;
  static const Duration sshConnectTimeout = Duration(seconds: 15);
  static const Duration sshKeepAliveInterval = Duration(seconds: 30);

  /// Terminal scrollback (lines) held in memory per session.
  static const int terminalScrollback = 5000;

  /// Default terminal type sent to the remote host.
  static const String defaultTermType = 'xterm-256color';

  // ─── AI / LLM defaults ──────────────────────────────────────────────────
  /// Chat Completions path appended to every provider's base URL. All built-in
  /// providers (OpenAI, DeepSeek, Qwen, GLM, MiMo) are OpenAI-compatible and
  /// share this endpoint shape.
  static const String aiChatCompletionsPath = '/chat/completions';

  /// Model catalogue path appended to a provider's base URL for the
  /// OpenAI-compatible `GET /models` listing endpoint.
  static const String aiModelsPath = '/models';

  /// Timeout for the (non-streaming) model catalogue request.
  static const Duration modelsRequestTimeout = Duration(seconds: 10);

  /// Provider used before the user makes an explicit choice.
  static const String defaultAiProviderId = 'openai';

  static const Duration chatRequestTimeout = Duration(seconds: 60);
  static const Duration sseIdleTimeout = Duration(seconds: 120);

  /// Hard cap on persisted chat-history turns. Older messages are dropped
  /// when the transcript exceeds this bound.
  static const int kMaxChatHistoryMessages = 200;

  /// SSE stream termination marker emitted by OpenAI-compatible servers.
  static const String sseDoneMarker = '[DONE]';

  // ─── Network ────────────────────────────────────────────────────────────
  static const Duration httpConnectTimeout = Duration(seconds: 15);
  static const Duration httpReceiveTimeout = Duration(seconds: 60);
  static const Duration httpSendTimeout = Duration(seconds: 30);
  static const int httpMaxRetries = 2;

  // ─── Hive boxes ─────────────────────────────────────────────────────────
  static const String hiveBoxServers = 'servers';
  static const String hiveBoxSessions = 'ssh_sessions';
  static const String hiveBoxChatHistory = 'chat_history';
  static const String hiveBoxSnippets = 'command_snippets';
  static const String hiveBoxMeta = 'app_meta';

  /// Version stamped into Hive adapters when they change.
  static const int hiveSchemaVersion = 1;

  // ─── Secure storage keys ────────────────────────────────────────────────
  /// Prefix for per-server password entries: `ssh_pw::<serverId>`.
  static const String secureKeyPasswordPrefix = 'ssh_pw::';

  /// Prefix for per-server private-key blobs: `ssh_key::<serverId>`.
  static const String secureKeyPrivateKeyPrefix = 'ssh_key::';

  /// Prefix for per-server key passphrases: `ssh_pass::<serverId>`.
  static const String secureKeyPassphrasePrefix = 'ssh_pass::';

  /// Legacy single-provider AI API key (pre multi-provider). Retained so keys
  /// saved by earlier builds keep working; migrated to the OpenAI namespace.
  static const String secureKeyApiKey = 'ai_api_key';

  /// Optional custom base URL for OpenAI-compatible providers (legacy).
  static const String secureKeyApiBaseUrl = 'ai_api_base_url';

  /// Per-provider API key namespace: `ai_api_key_<providerId>`.
  static String aiApiKey(String providerId) => 'ai_api_key_$providerId';

  static String passwordKey(String serverId) =>
      '$secureKeyPasswordPrefix$serverId';
  static String privateKeyKey(String serverId) =>
      '$secureKeyPrivateKeyPrefix$serverId';
  static String passphraseKey(String serverId) =>
      '$secureKeyPassphrasePrefix$serverId';

  // ─── SharedPreferences keys ─────────────────────────────────────────────
  static const String prefKeyThemeMode = 'pref.theme_mode';
  static const String prefKeyTerminalFontSize = 'pref.terminal_font_size';
  static const String prefKeyTerminalFontFamily = 'pref.terminal_font_family';
  static const String prefKeyHapticFeedback = 'pref.haptic_feedback';
  /// Legacy provider/model keys — kept for backward-compatible migration.
  static const String prefKeyAiProvider = 'pref.ai_provider';
  static const String prefKeyAiModel = 'pref.ai_model';
  static const String prefKeyAiTemperature = 'pref.ai_temperature';

  /// Currently selected AI provider id.
  static const String prefKeyAiSelectedProvider = 'pref.ai_selected_provider';

  /// When true, the AI agent may run parsed commands autonomously.
  static const String prefKeyAiAutoExecute = 'pref.ai_auto_execute';

  /// Upper bound on automatic command-execution loops per assistant response.
  static const String prefKeyAiMaxAutoLoops = 'pref.ai_max_auto_loops';

  /// Per-provider remembered model: `pref.ai_model_<providerId>`.
  static String aiModelKey(String providerId) => 'pref.ai_model_$providerId';

  /// Per-provider user-added custom model ids: `ai_custom_models_<providerId>`.
  static String aiCustomModelsKey(String providerId) =>
      'ai_custom_models_$providerId';

  /// Hive key inside [hiveBoxMeta] holding the JSON list of user-defined AI
  /// providers (name + base URL + optional default model id).
  static const String hiveKeyAiCustomProviders = 'ai_custom_providers';

  /// Hive key inside [hiveBoxMeta] holding the JSON array of AI command
  /// audit entries (most recent last). See [CommandAuditLog].
  static const String hiveKeyCommandAuditLog = 'command_audit_log';

  /// Maximum number of audit entries retained; older entries are evicted
  /// first-in-first-out when the list exceeds this bound.
  static const int kMaxCommandAuditEntries = 500;

  /// Hive key inside [hiveBoxMeta] holding the JSON array of captured
  /// crash/uncaught-error entries (most recent first). See
  /// `CrashReportService`.
  static const String hiveKeyCrashReports = 'crash_reports';

  /// Maximum number of crash report entries retained in the ring buffer;
  /// older entries are evicted when the list exceeds this bound.
  static const int kMaxCrashReportEntries = 50;

  /// Maximum characters of a crash report stack trace kept per entry.
  static const int kCrashReportStackMaxChars = 2000;

  /// Prefix for the stable ids generated for user-defined AI providers:
  /// `custom_<uuid>`.
  static const String customAiProviderIdPrefix = 'custom_';
  static const String prefKeyLastOpenedServerId = 'pref.last_server_id';
  static const String prefKeyOnboardingComplete = 'pref.onboarding_complete';
  static const String prefKeyLocale = 'pref.locale';

  /// When true, user-facing surfaces display masked host/IP addresses.
  static const String prefKeyHideIpAddresses = 'pref.hide_ip_addresses';

  /// When true, dropped SSH sessions auto-reconnect with exponential backoff.
  static const String prefKeySshAutoReconnect = 'pref.ssh_auto_reconnect';

  /// Maximum reconnect attempts per dropped session before giving up.
  /// `0` means retry forever (until the user disconnects manually).
  static const String prefKeySshReconnectMaxAttempts = 'pref.ssh_reconnect_max_attempts';

  /// When true, the app requires fingerprint/face verification at launch and
  /// whenever it returns to the foreground (biometric app lock).
  static const String prefKeyAuthLockEnabled = 'pref.auth_lock_enabled';

  // ─── Defaults (used as fallbacks when prefs are absent) ─────────────────
  static const double defaultTerminalFontSize = 13.5;
  static const double minTerminalFontSize = 9.0;
  static const double maxTerminalFontSize = 22.0;
  static const double defaultAiTemperature = 0.4;

  // ─── AI agent auto-execution defaults ───────────────────────────────────
  /// Auto-execute is opt-in and therefore defaults to off.
  static const bool defaultAiAutoExecute = false;

  /// Default cap on automatic command-execution loops.
  static const int kDefaultMaxAutoLoops = 10;
  static const int kMinMaxAutoLoops = 1;
  static const int kMaxMaxAutoLoops = 20;

  /// Default per-command execution timeout.
  static const int kDefaultCommandTimeoutSeconds = 30;

  // ─── SSH auto-reconnect defaults ────────────────────────────────────────
  /// Auto-reconnect defaults to on: a dropped session transparently retries.
  static const bool defaultSshAutoReconnect = true;

  /// Default cap on reconnect attempts per dropped session (`0` = unlimited).
  static const int kDefaultSshReconnectMaxAttempts = 5;

  /// Lower bound for the configurable max-attempts setting.
  static const int kMinSshReconnectMaxAttempts = 1;

  /// Upper bound for the configurable max-attempts setting.
  static const int kMaxSshReconnectMaxAttempts = 10;

  /// Base delay of the exponential backoff schedule: 2s, 4s, 8s, 16s, 30s…
  static const Duration sshReconnectBaseDelay = Duration(seconds: 2);

  /// Ceiling of the exponential backoff schedule.
  static const Duration sshReconnectMaxDelay = Duration(seconds: 30);

  // ─── Layout ─────────────────────────────────────────────────────────────
  static const double gutterSm = 12;
  static const double gutterMd = 16;
  static const double gutterLg = 24;
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
}
