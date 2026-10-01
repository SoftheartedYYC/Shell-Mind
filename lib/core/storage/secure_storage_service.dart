import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Thin async wrapper around [FlutterSecureStorage] for secrets that must
/// never touch disk in plain text: SSH passwords, private keys, passphrases,
/// and the AI provider API key.
///
/// The service is intentionally stateless — a single instance is shared via
/// [SecureStorageService.instance] and a Riverpod provider is exposed at
/// the bottom of this file.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Process-wide default instance.
  static final SecureStorageService instance = SecureStorageService();

  final FlutterSecureStorage _storage;

  // ─── Generic primitives ─────────────────────────────────────────────────

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<bool> contains(String key) => _storage.containsKey(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<Map<String, String>> readAll() => _storage.readAll();

  // ─── SSH secrets ────────────────────────────────────────────────────────

  Future<void> savePassword(String serverId, String password) =>
      write(AppConstants.passwordKey(serverId), password);

  Future<String?> getPassword(String serverId) =>
      read(AppConstants.passwordKey(serverId));

  Future<void> deletePassword(String serverId) =>
      delete(AppConstants.passwordKey(serverId));

  Future<void> savePrivateKey(String serverId, String pem) =>
      write(AppConstants.privateKeyKey(serverId), pem);

  Future<String?> getPrivateKey(String serverId) =>
      read(AppConstants.privateKeyKey(serverId));

  Future<void> deletePrivateKey(String serverId) =>
      delete(AppConstants.privateKeyKey(serverId));

  Future<void> savePassphrase(String serverId, String passphrase) =>
      write(AppConstants.passphraseKey(serverId), passphrase);

  Future<String?> getPassphrase(String serverId) =>
      read(AppConstants.passphraseKey(serverId));

  Future<void> deletePassphrase(String serverId) =>
      delete(AppConstants.passphraseKey(serverId));

  /// Wipes every secret tied to a single server (used on server delete).
  Future<void> purgeServer(String serverId) async {
    await deletePassword(serverId);
    await deletePrivateKey(serverId);
    await deletePassphrase(serverId);
  }

  // ─── AI provider secrets ────────────────────────────────────────────────

  Future<void> saveApiKey(String apiKey) =>
      write(AppConstants.secureKeyApiKey, apiKey);

  Future<String?> getApiKey() => read(AppConstants.secureKeyApiKey);

  Future<void> deleteApiKey() => delete(AppConstants.secureKeyApiKey);

  Future<void> saveApiBaseUrl(String url) =>
      write(AppConstants.secureKeyApiBaseUrl, url);

  Future<String?> getApiBaseUrl() => read(AppConstants.secureKeyApiBaseUrl);

  Future<void> deleteApiBaseUrl() => delete(AppConstants.secureKeyApiBaseUrl);
}

/// Riverpod provider for the process-wide [SecureStorageService].
final Provider<SecureStorageService> secureStorageServiceProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService.instance);
