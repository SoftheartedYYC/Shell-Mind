import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/connection_state.dart';

/// Contract for driving a single interactive SSH shell.
///
/// The presentation layer talks only to this interface; the concrete
/// implementation (`SshSessionRepository`) delegates to a `dartssh2`-backed
/// manager. That indirection keeps the transport swappable and testable and
/// stops protocol types from leaking into widgets/providers.
///
/// Lifecycle: [connect] → observe [stateStream] / [outputStream] → pump user
/// keystrokes through [sendInput] and viewport changes through [resize] →
/// [disconnect] when the terminal page goes away.
abstract interface class SshRepository {
  /// Dials the remote host, authenticates, and opens an interactive PTY shell.
  ///
  /// Exactly one of [password] / [privateKey] supplies the credential;
  /// [passphrase] unlocks an encrypted [privateKey]. Resolves to a
  /// [Failure] (never throws) on timeout, auth rejection, or network error.
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
  });

  /// Raw shell output (stdout + stderr merged) as it arrives from the remote.
  ///
  /// A broadcast stream so the terminal pump can subscribe independently of
  /// connection timing. Bytes are UTF-8 encoded by the remote PTY; the
  /// consumer is responsible for incremental decoding across chunk boundaries.
  Stream<Uint8List> get outputStream;

  /// Live connection-state transitions, ending in [SshConnectionStatus.error]
  /// or [SshConnectionStatus.disconnected] when the link drops.
  Stream<SshConnectionState> get stateStream;

  /// Writes user input (keystrokes / control sequences) to the shell's stdin.
  void sendInput(String data);

  /// Notifies the remote PTY that the local viewport changed so line-wrapping
  /// and full-screen apps (vim, top) reflow to the new cell grid.
  Future<void> resize(int width, int height);

  /// Tears down the shell, channel, and socket, releasing all resources.
  Future<void> disconnect();

  /// Current snapshot of the connection state.
  SshConnectionState get currentState;

  /// True while a live shell is usable.
  bool get isConnected;
}
