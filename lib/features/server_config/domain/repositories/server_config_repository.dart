import '../entities/server_config.dart';

/// Persistence contract for the saved server fleet.
///
/// Implementations back onto Hive (metadata) plus the secure keystore
/// (credentials, managed separately). The presentation layer talks only to
/// this interface so storage details stay swappable and testable.
abstract interface class ServerConfigRepository {
  /// One-shot snapshot of every saved config, ordered for display.
  Future<List<ServerConfig>> getAll();

  /// Live view of the fleet — emits the current list immediately, then again
  /// on every underlying box mutation. Drives the reactive server list UI.
  Stream<List<ServerConfig>> watchAll();

  /// Looks up a single config, or `null` when [id] is unknown.
  Future<ServerConfig?> getById(String id);

  /// Inserts or replaces the config keyed by [ServerConfig.id].
  Future<void> save(ServerConfig config);

  /// Removes the config and purges any secrets tied to its id.
  Future<void> delete(String id);

  /// Stamps `lastConnectedAt = now` on the given server, preserving the rest.
  Future<void> updateLastConnected(String id);
}
