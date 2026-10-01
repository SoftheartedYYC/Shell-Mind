/// Global application constants.
///
/// Kept in one place so environment/build variations (e.g. dev vs prod API
/// endpoints) can be swapped centrally without touching feature code.
abstract final class AppConstants {
  // ─── Identity ───────────────────────────────────────────────────────────
  static const String appName = 'Shell-Mind';
  static const String appTagline = 'SSH · AI · Command';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

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

  /// Provider used before the user makes an explicit choice.
  static const String defaultAiProviderId = 'openai';

  static const Duration chatRequestTimeout = Duration(seconds: 60);
  static const Duration sseIdleTimeout = Duration(seconds: 120);

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

  /// Per-provider remembered model: `pref.ai_model_<providerId>`.
  static String aiModelKey(String providerId) => 'pref.ai_model_$providerId';
  static const String prefKeyLastOpenedServerId = 'pref.last_server_id';
  static const String prefKeyOnboardingComplete = 'pref.onboarding_complete';
  static const String prefKeyLocale = 'pref.locale';

  // ─── Defaults (used as fallbacks when prefs are absent) ─────────────────
  static const double defaultTerminalFontSize = 13.5;
  static const double minTerminalFontSize = 9.0;
  static const double maxTerminalFontSize = 22.0;
  static const double defaultAiTemperature = 0.4;

  // ─── Layout ─────────────────────────────────────────────────────────────
  static const double gutterSm = 12;
  static const double gutterMd = 16;
  static const double gutterLg = 24;
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
}
