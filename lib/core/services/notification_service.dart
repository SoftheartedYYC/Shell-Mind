import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../storage/preferences_service.dart';

/// Local-notification façade for background alerts.
///
/// Two app events are surfaced while the app is not in the foreground:
/// an SSH session dropping unexpectedly, and an AI task finishing. The plugin
/// is initialised once and permission is requested at [init]; every [show]
/// call is fire-and-forget and never throws (a notification hiccup must not
/// break a conversation or a reconnect loop).
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    bool Function()? enabled,
    bool Function()? isBackground,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _enabled = enabled ?? _defaultEnabled,
        _isBackground = isBackground ?? _defaultIsBackground;

  static final NotificationService instance = NotificationService();

  static const String _channelId = 'shellmind_alerts';
  static const String _channelName = 'ShellMind alerts';
  static const String _channelDescription =
      'Session disconnects and AI task completion';

  final FlutterLocalNotificationsPlugin _plugin;
  final bool Function() _enabled;
  final bool Function() _isBackground;

  bool _initialised = false;
  int _idCounter = 0;

  /// Initialises the plugin and requests notification permission. Safe to call
  /// more than once; failures are logged and swallowed.
  Future<void> init() async {
    if (_initialised) return;
    try {
      const InitializationSettings settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _initialised = true;
    } catch (error) {
      debugPrint('[NotificationService] init failed: $error');
    }
  }

  /// Notifies that an SSH session dropped. No-op in the foreground (the user
  /// can see the terminal), when notifications are disabled, or before [init].
  Future<void> notifySessionDisconnected(String serverName) {
    return _show(
      'Session disconnected',
      'SSH session to "$serverName" was lost.',
    );
  }

  /// Notifies that an AI task finished. No-op in the foreground / disabled.
  Future<void> notifyAiTaskComplete() {
    return _show('AI task complete', 'ShellMind finished running commands.');
  }

  Future<void> _show(String title, String body) async {
    if (!_initialised || !_enabled() || !_isBackground()) return;
    try {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
      await _plugin.show(_idCounter++, title, body, details);
    } catch (error) {
      debugPrint('[NotificationService] show failed: $error');
    }
  }

  static bool _defaultEnabled() {
    try {
      return PreferencesService.instance.notificationsEnabled;
    } catch (_) {
      return true;
    }
  }

  static bool _defaultIsBackground() {
    try {
      return WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
    } catch (_) {
      return false;
    }
  }
}
