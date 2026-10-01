import 'package:flutter/foundation.dart';

/// Lifecycle phases of a single SSH connection attempt.
///
/// The order mirrors the SSH handshake: a TCP+transport dial ([connecting]),
/// followed by user authentication ([authenticating]), then a live interactive
/// shell ([connected]). [error] is terminal until a fresh [connect] is issued;
/// [disconnected] is the idle/closed state.
enum SshConnectionStatus {
  disconnected,
  connecting,
  authenticating,
  connected,
  error;

  /// True while a dial or handshake is in flight (not yet live, not failed).
  bool get isBusy =>
      this == SshConnectionStatus.connecting ||
      this == SshConnectionStatus.authenticating;

  /// Short uppercase token used in the terminal status strip.
  String get token => switch (this) {
        SshConnectionStatus.disconnected => 'OFFLINE',
        SshConnectionStatus.connecting => 'CONNECTING',
        SshConnectionStatus.authenticating => 'AUTH',
        SshConnectionStatus.connected => 'CONNECTED',
        SshConnectionStatus.error => 'ERROR',
      };
}

/// Immutable snapshot of an SSH connection's status.
///
/// Carried by the presentation-layer state notifier and emitted by the data
/// layer's state stream. Equality is value-based so Riverpod only rebuilds on
/// meaningful transitions.
@immutable
class SshConnectionState {
  const SshConnectionState({
    required this.status,
    this.errorMessage,
    this.serverName,
    this.connectedAt,
    this.failureKind,
  });

  /// Idle, closed connection.
  const SshConnectionState.disconnected({this.serverName})
      : status = SshConnectionStatus.disconnected,
        errorMessage = null,
        connectedAt = null,
        failureKind = null;

  /// Dialing / handshaking.
  const SshConnectionState.connecting({this.serverName})
      : status = SshConnectionStatus.connecting,
        errorMessage = null,
        connectedAt = null,
        failureKind = null;

  /// Transport ready, user authentication in progress.
  const SshConnectionState.authenticating({this.serverName})
      : status = SshConnectionStatus.authenticating,
        errorMessage = null,
        connectedAt = null,
        failureKind = null;

  /// Live interactive shell.
  SshConnectionState.connected({
    this.serverName,
    DateTime? connectedAt,
  })  : status = SshConnectionStatus.connected,
        errorMessage = null,
        failureKind = null,
        connectedAt = connectedAt ?? DateTime.now();

  /// Failed attempt carrying a human-readable reason.
  const SshConnectionState.error({
    required String message,
    this.serverName,
    this.failureKind,
  })  : status = SshConnectionStatus.error,
        errorMessage = message,
        connectedAt = null;

  final SshConnectionStatus status;

  /// Populated only when [status] is [SshConnectionStatus.error].
  final String? errorMessage;

  /// User-facing server label threaded through every state so the UI can keep
  /// showing the target name even before/after a connection succeeds.
  final String? serverName;

  /// Timestamp when the shell went live, for session uptime display.
  final DateTime? connectedAt;

  /// Optional [FailureKind] name, letting the UI colour-code the error.
  final String? failureKind;

  bool get isConnected => status == SshConnectionStatus.connected;
  bool get isError => status == SshConnectionStatus.error;
  bool get isBusy => status.isBusy;
  bool get isDisconnected => status == SshConnectionStatus.disconnected;

  SshConnectionState copyWith({
    SshConnectionStatus? status,
    String? errorMessage,
    String? serverName,
    DateTime? connectedAt,
    String? failureKind,
  }) {
    return SshConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      serverName: serverName ?? this.serverName,
      connectedAt: connectedAt ?? this.connectedAt,
      failureKind: failureKind ?? this.failureKind,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SshConnectionState &&
          other.status == status &&
          other.errorMessage == errorMessage &&
          other.serverName == serverName &&
          other.connectedAt == connectedAt &&
          other.failureKind == failureKind;

  @override
  int get hashCode =>
      Object.hash(status, errorMessage, serverName, connectedAt, failureKind);

  @override
  String toString() =>
      'SshConnectionState(${status.name}, server: $serverName'
      '${errorMessage != null ? ', error: "$errorMessage"' : ''})';
}
