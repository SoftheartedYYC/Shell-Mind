// Smoke test: the app should boot, mount the shell, and land on the
// Servers tab without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shell_mind/app/app.dart';
import 'package:shell_mind/app/router.dart';
import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/domain/repositories/server_config_repository.dart';
import 'package:shell_mind/features/server_config/presentation/providers/server_config_providers.dart';

class _MockServerConfigRepository extends Mock
    implements ServerConfigRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  testWidgets('Shell-Mind boots into the servers tab',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();

    // Stub the data layer so the servers page resolves to a deterministic
    // empty state without touching Hive / the platform keystore.
    final _MockServerConfigRepository mockRepo = _MockServerConfigRepository();
    when(() => mockRepo.getAll()).thenAnswer((_) async => <ServerConfig>[]);
    when(() => mockRepo.watchAll())
        .thenAnswer((_) => Stream<List<ServerConfig>>.value(<ServerConfig>[]));
    final _MockSecureStorageService mockSecure = _MockSecureStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          serverConfigRepositoryProvider.overrideWithValue(mockRepo),
          secureStorageServiceProvider.overrideWithValue(mockSecure),
        ],
        child: const ShellMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The bottom navigation should always be present in the shell.
    // `Servers` appears both in the nav bar and the page header.
    expect(find.text('Servers'), findsAtLeastNWidgets(1));
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // The shell should render the initial route's landing content.
    expect(find.text('No servers yet'), findsOneWidget);

    // The initial route resolves to Servers.
    expect(
      find.byType(ProviderScope),
      findsOneWidget,
      reason: 'ProviderScope should wrap the root app',
    );
  });

  testWidgets('Route paths resolve to distinct routes',
      (WidgetTester tester) async {
    expect(RoutePaths.servers, '/servers');
    expect(RoutePaths.aiChat, '/ai');
    expect(RoutePaths.settings, '/settings');
    expect(RoutePaths.terminalFor('abc'), '/terminal/abc');
  });
}
