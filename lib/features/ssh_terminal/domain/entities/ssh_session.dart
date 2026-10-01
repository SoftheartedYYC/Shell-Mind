import 'package:flutter/foundation.dart';

import 'connection_state.dart';

/// A logical interactive shell session bound to a saved server.
///
/// This is a lightweight value object describing *what* is connected and *how
/// it is doing* — it deliberately holds no socket/channel handles. The actual
/// `dartssh2` transport lives in the data layer (`SshClientManager`). Keeping
/// the two apart means the domain/UI can reason about sessions without
/// importing protocol types.
@immutable
class SshSession {
  const SshSession({
    required this.id,
    required this.serverConfigId,
    required this.connectionState,
    required this.startedAt,
    this.columns = 80,
    this.rows = 24,
  });

  /// Unique id for this session instance (not the server id).
  final String id;

  /// The [ServerConfig.id] this session was opened against.
  final String serverConfigId;

  /// Live connection snapshot — status, error, connect time.
  final SshConnectionState connectionState;

  /// When the session object was created (page opened), which may precede a
  /// successful connection.
  final DateTime startedAt;

  /// Last known PTY dimensions, in character cells.
  final int columns;
  final int rows;

  bool get isConnected => connectionState.isConnected;

  SshSession copyWith({
    String? id,
    String? serverConfigId,
    SshConnectionState? connectionState,
    DateTime? startedAt,
    int? columns,
    int? rows,
  }) {
    return SshSession(
      id: id ?? this.id,
      serverConfigId: serverConfigId ?? this.serverConfigId,
      connectionState: connectionState ?? this.connectionState,
      startedAt: startedAt ?? this.startedAt,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SshSession &&
          other.id == id &&
          other.serverConfigId == serverConfigId &&
          other.connectionState == connectionState &&
          other.startedAt == startedAt &&
          other.columns == columns &&
          other.rows == rows;

  @override
  int get hashCode =>
      Object.hash(id, serverConfigId, connectionState, startedAt, columns, rows);

  @override
  String toString() =>
      'SshSession(id: $id, server: $serverConfigId, '
      'status: ${connectionState.status.name}, ${columns}x$rows)';
}
