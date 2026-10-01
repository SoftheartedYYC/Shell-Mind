import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/id_generator.dart';

/// How a server authenticates during the SSH handshake.
///
/// The secret material itself (password / private key / passphrase) is never
/// stored on this entity — it lives in the platform keystore via
/// `SecureStorageService`, keyed by [ServerConfig.id].
enum AuthType {
  password,
  privateKey;

  /// Title-cased, human-readable label for pickers and cards.
  String get label => switch (this) {
        AuthType.password => 'Password',
        AuthType.privateKey => 'Private key',
      };

  /// Lowercase monospace token used in dense terminal chrome.
  String get token => switch (this) {
        AuthType.password => 'pw',
        AuthType.privateKey => 'key',
      };

  /// Reverses [index] safely, falling back to [AuthType.password] when the
  /// persisted value predates a schema change or is otherwise out of range.
  static AuthType fromIndex(int index) {
    if (index < 0 || index >= AuthType.values.length) return AuthType.password;
    return AuthType.values[index];
  }

  /// Parses the [name] produced by a form/JSON, defaulting to password.
  static AuthType fromName(String? name) => AuthType.values.firstWhere(
        (AuthType t) => t.name == name,
        orElse: () => AuthType.password,
      );
}

/// Immutable value object describing a saved SSH endpoint.
///
/// Credentials are deliberately excluded — this is the shareable, listable
/// metadata. Combine with `SecureStorageService` to obtain the secret needed
/// to actually connect.
@immutable
class ServerConfig {
  const ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port = AppConstants.defaultSshPort,
    required this.username,
    this.authType = AuthType.password,
    this.group,
    required this.createdAt,
    this.lastConnectedAt,
  });

  /// Creates a brand-new config with a freshly minted UUID and `createdAt`
  /// stamp. Used by the add-server form.
  factory ServerConfig.create({
    required String name,
    required String host,
    int port = AppConstants.defaultSshPort,
    required String username,
    AuthType authType = AuthType.password,
    String? group,
  }) {
    return ServerConfig(
      id: generateId(),
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      group: group,
      createdAt: DateTime.now(),
    );
  }

  /// Stable UUID primary key. Also the namespace for this server's secrets
  /// inside the secure keystore.
  final String id;

  /// User-defined label ("prod-web-01", "home lab", …).
  final String name;

  /// IP address or DNS hostname.
  final String host;

  /// SSH port, defaults to 22.
  final int port;

  /// Login user on the remote host.
  final String username;

  /// Authentication strategy.
  final AuthType authType;

  /// Optional user-defined grouping label for sectioning the fleet list.
  final String? group;

  final DateTime createdAt;

  /// Timestamp of the most recent successful (or attempted) connection.
  final DateTime? lastConnectedAt;

  /// `host:port` — the canonical address shown in monospace across the UI.
  String get address => '$host:$port';

  /// `user@host` — the classic SSH identity string.
  String get identity => '$username@$host';

  /// True when this config has ever been connected to.
  bool get hasConnected => lastConnectedAt != null;

  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? group,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      group: group ?? this.group,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfig &&
          other.id == id &&
          other.name == name &&
          other.host == host &&
          other.port == port &&
          other.username == username &&
          other.authType == authType &&
          other.group == group &&
          other.createdAt == createdAt &&
          other.lastConnectedAt == lastConnectedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        host,
        port,
        username,
        authType,
        group,
        createdAt,
        lastConnectedAt,
      );

  @override
  String toString() =>
      'ServerConfig(id: $id, name: "$name", address: $address, '
      'user: $username, auth: ${authType.name}, group: $group)';
}
