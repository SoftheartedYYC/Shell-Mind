import 'dart:convert';

import '../../../core/utils/id_generator.dart';
import 'entities/server_config.dart';

/// Pure JSON (de)serialization for importing/exporting server *metadata*.
///
/// Security invariant: credentials (passwords / private keys / passphrases)
/// never leave the device — they live in the secure keystore keyed by server
/// id and are deliberately absent from this format. Imported configs are
/// re-issued fresh ids so they never overwrite an existing server's secrets;
/// the user re-enters credentials for imported hosts.
abstract final class ServerTransfer {
  static const String formatTag = 'shellmind-servers';

  static const int version = 1;

  static String encode(List<ServerConfig> servers, {DateTime? exportedAt}) {
    final DateTime at = exportedAt ?? DateTime.now();
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': formatTag,
      'version': version,
      'exportedAt': at.toIso8601String(),
      'items': <Map<String, dynamic>>[
        for (final ServerConfig s in servers)
          <String, dynamic>{
            'name': s.name,
            'host': s.host,
            'port': s.port,
            'username': s.username,
            'authType': s.authType.name,
            if (s.group != null && s.group!.trim().isNotEmpty) 'group': s.group,
            'createdAt': s.createdAt.toIso8601String(),
            if (s.lastConnectedAt != null)
              'lastConnectedAt': s.lastConnectedAt!.toIso8601String(),
          },
      ],
    });
  }

  /// Parses an exported server document into fresh entities (no credentials).
  ///
  /// Throws [FormatException] for a malformed/foreign document; malformed
  /// items are skipped. The caller is responsible for surfacing that imported
  /// servers still need their credentials entered.
  static List<ServerConfig> decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Invalid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Not a valid export (expected an object).');
    }
    final Map<String, dynamic> doc = Map<String, dynamic>.from(decoded);
    if (doc['format'] != formatTag) {
      throw const FormatException('Not a ShellMind server export.');
    }
    final Object? items = doc['items'];
    if (items is! List) {
      throw const FormatException('Missing server items.');
    }

    final List<ServerConfig> out = <ServerConfig>[];
    for (final Object? raw in items) {
      if (raw is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
      final Object? name = map['name'];
      final Object? host = map['host'];
      final Object? username = map['username'];
      if (name is! String || name.trim().isEmpty) continue;
      if (host is! String || host.trim().isEmpty) continue;
      if (username is! String || username.trim().isEmpty) continue;
      out.add(ServerConfig(
        id: generateId(),
        name: name.trim(),
        host: host.trim(),
        port: map['port'] is int ? (map['port'] as int) : 22,
        username: username.trim(),
        authType: AuthType.fromName(map['authType'] as String?),
        group: (map['group'] is String && (map['group'] as String).trim().isNotEmpty)
            ? (map['group'] as String).trim()
            : null,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        lastConnectedAt: map['lastConnectedAt'] is String
            ? DateTime.tryParse(map['lastConnectedAt'] as String)
            : null,
      ));
    }
    return out;
  }
}
