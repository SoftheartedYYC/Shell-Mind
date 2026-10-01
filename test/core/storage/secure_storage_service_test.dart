import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('Generic primitives', () {
    test('write delegates to storage.write', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.write('test_key', 'test_value');

      verify(() => mockStorage.write(key: 'test_key', value: 'test_value'))
          .called(1);
    });

    test('read delegates to storage.read', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'stored_value');

      final result = await service.read('test_key');

      expect(result, 'stored_value');
      verify(() => mockStorage.read(key: 'test_key')).called(1);
    });

    test('read returns null when key not found', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await service.read('missing_key');
      expect(result, isNull);
    });

    test('delete delegates to storage.delete', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.delete('test_key');

      verify(() => mockStorage.delete(key: 'test_key')).called(1);
    });

    test('contains delegates to storage.containsKey', () async {
      when(() => mockStorage.containsKey(key: any(named: 'key')))
          .thenAnswer((_) async => true);

      final result = await service.contains('test_key');
      expect(result, isTrue);
    });
  });

  group('SSH secrets - password', () {
    test('savePassword uses correct key format', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.savePassword('server-123', 'my-password');

      verify(() => mockStorage.write(
            key: AppConstants.passwordKey('server-123'),
            value: 'my-password',
          )).called(1);
    });

    test('getPassword uses correct key format', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'stored-pw');

      final result = await service.getPassword('server-456');

      expect(result, 'stored-pw');
      verify(() => mockStorage.read(
            key: AppConstants.passwordKey('server-456'),
          )).called(1);
    });

    test('deletePassword uses correct key format', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deletePassword('server-789');

      verify(() => mockStorage.delete(
            key: AppConstants.passwordKey('server-789'),
          )).called(1);
    });
  });

  group('SSH secrets - private key', () {
    test('savePrivateKey uses correct key format', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.savePrivateKey('srv-1', '-----BEGIN RSA KEY-----');

      verify(() => mockStorage.write(
            key: AppConstants.privateKeyKey('srv-1'),
            value: '-----BEGIN RSA KEY-----',
          )).called(1);
    });

    test('getPrivateKey returns stored key', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'pem-content');

      final result = await service.getPrivateKey('srv-2');
      expect(result, 'pem-content');
    });
  });

  group('SSH secrets - passphrase', () {
    test('savePassphrase uses correct key format', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.savePassphrase('srv-3', 'secret-pass');

      verify(() => mockStorage.write(
            key: AppConstants.passphraseKey('srv-3'),
            value: 'secret-pass',
          )).called(1);
    });

    test('getPassphrase returns stored passphrase', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'my-pass');

      final result = await service.getPassphrase('srv-4');
      expect(result, 'my-pass');
    });
  });

  group('purgeServer', () {
    test('deletes password, private key, and passphrase', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.purgeServer('server-abc');

      verify(() => mockStorage.delete(
            key: AppConstants.passwordKey('server-abc'),
          )).called(1);
      verify(() => mockStorage.delete(
            key: AppConstants.privateKeyKey('server-abc'),
          )).called(1);
      verify(() => mockStorage.delete(
            key: AppConstants.passphraseKey('server-abc'),
          )).called(1);
    });
  });

  group('AI provider secrets', () {
    test('saveApiKey uses correct key', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveApiKey('sk-test123');

      verify(() => mockStorage.write(
            key: AppConstants.secureKeyApiKey,
            value: 'sk-test123',
          )).called(1);
    });

    test('getApiKey returns stored key', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'sk-stored');

      final result = await service.getApiKey();
      expect(result, 'sk-stored');
      verify(() => mockStorage.read(key: AppConstants.secureKeyApiKey))
          .called(1);
    });

    test('deleteApiKey removes key', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deleteApiKey();

      verify(() => mockStorage.delete(key: AppConstants.secureKeyApiKey))
          .called(1);
    });

    test('saveApiBaseUrl uses correct key', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveApiBaseUrl('https://custom.api.com/v1');

      verify(() => mockStorage.write(
            key: AppConstants.secureKeyApiBaseUrl,
            value: 'https://custom.api.com/v1',
          )).called(1);
    });

    test('getApiBaseUrl returns stored URL', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'https://my-proxy.com');

      final result = await service.getApiBaseUrl();
      expect(result, 'https://my-proxy.com');
    });

    test('deleteApiBaseUrl removes URL', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deleteApiBaseUrl();

      verify(() => mockStorage.delete(key: AppConstants.secureKeyApiBaseUrl))
          .called(1);
    });
  });

  group('AppConstants key format', () {
    test('passwordKey produces correct format', () {
      expect(AppConstants.passwordKey('abc'), 'ssh_pw::abc');
    });

    test('privateKeyKey produces correct format', () {
      expect(AppConstants.privateKeyKey('abc'), 'ssh_key::abc');
    });

    test('passphraseKey produces correct format', () {
      expect(AppConstants.passphraseKey('abc'), 'ssh_pass::abc');
    });
  });
}
