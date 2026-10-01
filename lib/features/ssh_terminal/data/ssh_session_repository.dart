import 'dart:typed_data';

import '../../../core/utils/result.dart';
import '../domain/entities/connection_state.dart';
import '../domain/repositories/ssh_repository.dart';
import 'ssh_client_manager.dart';

/// [SshRepository] implementation backed by [SshClientManager].
///
/// Thin adapter: it converts the manager's throwing [SshClientManager.connect]
/// into a [Result], reuses the manager's error mapping, and forwards the
/// stream/input/resize/disconnect calls. Kept separate from the manager so the
/// domain contract stays free of `dartssh2` types and can be faked in tests.
class SshSessionRepository implements SshRepository {
  SshSessionRepository(this._manager);

  final SshClientManager _manager;

  @override
  Future<Result<void>> connect({
    required String host,
    required int port,
    required String username,
    String? serverName,
    String? password,
    String? privateKey,
    String? passphrase,
    int width = 80,
    int height = 24,
  }) {
    return Result.guard<void>(
      () => _manager.connect(
        host: host,
        port: port,
        username: username,
        serverName: serverName,
        password: password,
        privateKey: privateKey,
        passphrase: passphrase,
        width: width,
        height: height,
      ),
      onError: (Object error, StackTrace stack) =>
          SshClientManager.mapError(error).copyWith(stackTrace: stack),
    );
  }

  @override
  Stream<Uint8List> get outputStream => _manager.outputStream;

  @override
  Stream<SshConnectionState> get stateStream => _manager.stateStream;

  @override
  void sendInput(String data) => _manager.sendInput(data);

  @override
  Future<void> resize(int width, int height) =>
      _manager.resize(width, height);

  @override
  Future<void> disconnect() => _manager.disconnect();

  @override
  SshConnectionState get currentState => _manager.currentState;

  @override
  bool get isConnected => _manager.isConnected;
}
