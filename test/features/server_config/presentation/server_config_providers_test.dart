import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/domain/repositories/server_config_repository.dart';
import 'package:shell_mind/features/server_config/presentation/providers/server_config_providers.dart';

class MockServerConfigRepository extends Mock implements ServerConfigRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockServerConfigRepository mockRepo;
  late MockSecureStorageService mockSecure;

  ServerConfig makeConfig({
    String id = 'srv-1',
    String name = 'Server 1',
    String host = '10.0.0.1',
    int port = 22,
    String username = 'root',
    AuthType authType = AuthType.password,
  }) {
    return ServerConfig(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  setUpAll(() {
    registerFallbackValue(makeConfig());
  });

  setUp(() {
    mockRepo = MockServerConfigRepository();
    mockSecure = MockSecureStorageService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        serverConfigRepositoryProvider.overrideWithValue(mockRepo),
        secureStorageServiceProvider.overrideWithValue(mockSecure),
      ],
    );
  }

  group('serverConfigListProvider', () {
    test('build() seeds from repository.getAll()', () async {
      final configs = [makeConfig(id: '1'), makeConfig(id: '2', name: 'Server 2')];
      when(() => mockRepo.getAll()).thenAnswer((_) async => configs);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(configs));

      final container = createContainer();
      addTearDown(container.dispose);

      // Initially loading
      expect(container.read(serverConfigListProvider), isLoading());

      // Wait for build to complete
      await container.read(serverConfigListProvider.future);

      final state = container.read(serverConfigListProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.length, 2);
      expect(state.value![0].id, '1');
    });

    test('saveServer calls repo.save and secure storage', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockRepo.getById(any())).thenAnswer((_) async => null);
      when(() => mockRepo.save(any())).thenAnswer((_) async {});
      when(() => mockSecure.savePassword(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final config = makeConfig(id: 'new-srv');
      final result = await container
          .read(serverConfigListProvider.notifier)
          .saveServer(config: config, password: 'secret123');

      expect(result.isSuccess, isTrue);
      verify(() => mockSecure.savePassword('new-srv', 'secret123')).called(1);
      verify(() => mockRepo.save(config)).called(1);
    });

    test('saveServer with privateKey auth stores key', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockRepo.getById(any())).thenAnswer((_) async => null);
      when(() => mockRepo.save(any())).thenAnswer((_) async {});
      when(() => mockSecure.savePrivateKey(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockSecure.savePassphrase(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final config = makeConfig(id: 'key-srv', authType: AuthType.privateKey);
      final result = await container
          .read(serverConfigListProvider.notifier)
          .saveServer(
            config: config,
            privateKey: '-----BEGIN KEY-----',
            passphrase: 'my-pass',
          );

      expect(result.isSuccess, isTrue);
      verify(() => mockSecure.savePrivateKey('key-srv', '-----BEGIN KEY-----'))
          .called(1);
      verify(() => mockSecure.savePassphrase('key-srv', 'my-pass')).called(1);
    });

    test('deleteServer calls repo.delete', () async {
      final configs = [makeConfig(id: 'del-1')];
      when(() => mockRepo.getAll()).thenAnswer((_) async => configs);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(configs));
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      // After getAll returns configs, delete should trigger repo.delete
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      final result = await container
          .read(serverConfigListProvider.notifier)
          .deleteServer('del-1');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.delete('del-1')).called(1);
    });

    test('markConnected calls repo.updateLastConnected', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockRepo.updateLastConnected(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final result = await container
          .read(serverConfigListProvider.notifier)
          .markConnected('srv-1');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.updateLastConnected('srv-1')).called(1);
    });

    test('byId returns config from loaded state', () async {
      final configs = [makeConfig(id: 'find-me', name: 'Found')];
      when(() => mockRepo.getAll()).thenAnswer((_) async => configs);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(configs));

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final found = container.read(serverConfigListProvider.notifier).byId('find-me');
      expect(found, isNotNull);
      expect(found!.name, 'Found');
    });

    test('byId returns null for unknown id', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final found = container.read(serverConfigListProvider.notifier).byId('nope');
      expect(found, isNull);
    });

    test('hasStoredCredential returns true when secret exists', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockSecure.getPassword('srv-x'))
          .thenAnswer((_) async => 'stored-password');

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final has = await container
          .read(serverConfigListProvider.notifier)
          .hasStoredCredential('srv-x', AuthType.password);
      expect(has, isTrue);
    });

    test('hasStoredCredential returns false when no secret', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockSecure.getPassword('srv-y'))
          .thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final has = await container
          .read(serverConfigListProvider.notifier)
          .hasStoredCredential('srv-y', AuthType.password);
      expect(has, isFalse);
    });

    test('saveServer returns failure when repo throws', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockRepo.getById(any())).thenAnswer((_) async => null);
      when(() => mockRepo.save(any())).thenThrow(Exception('disk error'));
      when(() => mockSecure.savePassword(any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(serverConfigListProvider.future);

      final result = await container
          .read(serverConfigListProvider.notifier)
          .saveServer(config: makeConfig(), password: 'pw');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.failure.kind, FailureKind.unexpected);
    });
  });
}

/// Helper matcher for AsyncLoading state.
isLoading() => const AsyncValueMatcher(isLoading: true);

class AsyncValueMatcher extends Matcher {
  const AsyncValueMatcher({this.isLoading = false});
  final bool isLoading;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! AsyncValue) return false;
    if (isLoading) return item.isLoading;
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('AsyncValue(isLoading: $isLoading)');
}
