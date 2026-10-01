import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/server_config.dart';

/// Hive-persistable mirror of [ServerConfig].
///
/// The domain entity stays storage-agnostic; this model owns the wire format
/// (primitives only, timestamps as epoch-millis, auth type as its ordinal) so
/// the two can evolve independently. Convert with [toEntity] /
/// [ServerConfigModel.fromEntity].
@immutable
class ServerConfigModel {
  const ServerConfigModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.authTypeIndex,
    required this.group,
    required this.createdAtMillis,
    required this.lastConnectedAtMillis,
  });

  /// Builds the persisted form of a domain [ServerConfig].
  factory ServerConfigModel.fromEntity(ServerConfig entity) {
    return ServerConfigModel(
      id: entity.id,
      name: entity.name,
      host: entity.host,
      port: entity.port,
      username: entity.username,
      authTypeIndex: entity.authType.index,
      group: entity.group,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      lastConnectedAtMillis: entity.lastConnectedAt?.millisecondsSinceEpoch,
    );
  }

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;

  /// Ordinal of [AuthType] — persisted as an int to keep the frame compact.
  final int authTypeIndex;

  final String? group;
  final int createdAtMillis;
  final int? lastConnectedAtMillis;

  /// Rehydrates the domain entity from this persisted model.
  ServerConfig toEntity() {
    final int? lastMillis = lastConnectedAtMillis;
    return ServerConfig(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      authType: AuthType.fromIndex(authTypeIndex),
      group: group,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      lastConnectedAt: lastMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMillis),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfigModel &&
          other.id == id &&
          other.name == name &&
          other.host == host &&
          other.port == port &&
          other.username == username &&
          other.authTypeIndex == authTypeIndex &&
          other.group == group &&
          other.createdAtMillis == createdAtMillis &&
          other.lastConnectedAtMillis == lastConnectedAtMillis;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        host,
        port,
        username,
        authTypeIndex,
        group,
        createdAtMillis,
        lastConnectedAtMillis,
      );

  @override
  String toString() => 'ServerConfigModel($id, $name, $host:$port)';
}

/// Hand-written [TypeAdapter] for [ServerConfigModel].
///
/// Authored manually (rather than via `hive_ce_generator`) to keep the build
/// free of code-generation steps. Field ordinals are fixed — never reuse or
/// reorder them once shipped; append new fields with fresh indices and bump
/// [AppConstants.hiveSchemaVersion] so migrations can reason about versions.
class ServerConfigModelAdapter extends TypeAdapter<ServerConfigModel> {
  /// Unique within the app's Hive registry. Reserve one id per adapter.
  static const int kTypeId = 1;

  @override
  final int typeId = kTypeId;

  /// Number of fields written to each frame (kept in sync with [write]).
  static const int _fieldCount = 9;

  @override
  ServerConfigModel read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServerConfigModel(
      id: fields[0] as String,
      name: fields[1] as String,
      host: fields[2] as String,
      port: fields[3] as int,
      username: fields[4] as String,
      authTypeIndex: fields[5] as int,
      group: fields[6] as String?,
      createdAtMillis: fields[7] as int,
      lastConnectedAtMillis: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ServerConfigModel obj) {
    writer
      ..writeByte(_fieldCount)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.host)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(5)
      ..write(obj.authTypeIndex)
      ..writeByte(6)
      ..write(obj.group)
      ..writeByte(7)
      ..write(obj.createdAtMillis)
      ..writeByte(8)
      ..write(obj.lastConnectedAtMillis);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
