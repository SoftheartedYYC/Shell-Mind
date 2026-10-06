import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/services/notification_service.dart';

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockNotificationsPlugin plugin;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    registerFallbackValue(NotificationDetails(
      android: const AndroidNotificationDetails('c', 'n'),
      iOS: const DarwinNotificationDetails(),
    ));
  });

  setUp(() {
    plugin = MockNotificationsPlugin();
    when(() => plugin.initialize(any())).thenAnswer((_) async => true);
    when(() => plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);
    when(() => plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()).thenReturn(null);
    when(() => plugin.show(any(), any(), any(), any()))
        .thenAnswer((_) async {});
  });

  test('notifications are a no-op before init()', () async {
    final NotificationService service = NotificationService(
      plugin: plugin,
      enabled: () => true,
      isBackground: () => true,
    );
    await service.notifySessionDisconnected('web-01');
    verifyNever(() => plugin.show(any(), any(), any(), any()));
  });

  test('posts a notification in the background when enabled', () async {
    final NotificationService service = NotificationService(
      plugin: plugin,
      enabled: () => true,
      isBackground: () => true,
    );
    await service.init();
    await service.notifySessionDisconnected('web-01');
    await service.notifyAiTaskComplete();
    verify(() => plugin.show(any(), any(), any(), any())).called(2);
  });

  test('stays silent in the foreground', () async {
    final NotificationService service = NotificationService(
      plugin: plugin,
      enabled: () => true,
      isBackground: () => false,
    );
    await service.init();
    await service.notifySessionDisconnected('web-01');
    verifyNever(() => plugin.show(any(), any(), any(), any()));
  });

  test('stays silent when notifications are disabled', () async {
    final NotificationService service = NotificationService(
      plugin: plugin,
      enabled: () => false,
      isBackground: () => true,
    );
    await service.init();
    await service.notifyAiTaskComplete();
    verifyNever(() => plugin.show(any(), any(), any(), any()));
  });
}
