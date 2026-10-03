import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import 'ssh_command_executor.dart';

/// Outcome of probing a single server.
enum ServerProbeStatus { online, offline }

/// Health of one server at the moment it was probed.
///
/// [uptimeBrief] and [loadAverage] are parsed from the remote `uptime` /
/// `/proc/loadavg` output and are only populated for online servers.
@immutable
class ServerHealth {
  const ServerHealth({
    required this.serverId,
    required this.serverName,
    required this.status,
    this.uptimeBrief,
    this.loadAverage,
    required this.probedAt,
  });

  factory ServerHealth.online({
    required String serverId,
    required String serverName,
    String? uptimeBrief,
    String? loadAverage,
  }) {
    return ServerHealth(
      serverId: serverId,
      serverName: serverName,
      status: ServerProbeStatus.online,
      uptimeBrief: uptimeBrief,
      loadAverage: loadAverage,
      probedAt: DateTime.now(),
    );
  }

  factory ServerHealth.offline({
    required String serverId,
    required String serverName,
  }) {
    return ServerHealth(
      serverId: serverId,
      serverName: serverName,
      status: ServerProbeStatus.offline,
      probedAt: DateTime.now(),
    );
  }

  final String serverId;

  /// Display name only — never the host/IP, so the health surfaces stay
  /// privacy-safe regardless of the "hide IP" preference.
  final String serverName;

  final ServerProbeStatus status;

  /// e.g. `up 3 days, 2:14` — null when it could not be parsed.
  final String? uptimeBrief;

  /// e.g. `0.52, 0.58, 0.60` — null when it could not be parsed.
  final String? loadAverage;

  final DateTime probedAt;

  bool get isOnline => status == ServerProbeStatus.online;

  @override
  String toString() =>
      'ServerHealth($serverName: ${status.name}, '
      'uptime: $uptimeBrief, load: $loadAverage)';
}

/// How the fleet as a whole is doing — drives the summary card's colour.
enum FleetMood { allOnline, degraded, allOffline, empty }

/// Aggregated result of one probe round across the whole fleet.
@immutable
class FleetHealthSnapshot {
  const FleetHealthSnapshot({required this.servers, required this.probedAt});

  factory FleetHealthSnapshot.empty() => FleetHealthSnapshot(
        servers: const <ServerHealth>[],
        probedAt: DateTime.now(),
      );

  /// One entry per probed server, in the request order.
  final List<ServerHealth> servers;

  /// When this round finished — the basis for cache freshness.
  final DateTime probedAt;

  int get totalCount => servers.length;

  int get onlineCount => servers.where((ServerHealth s) => s.isOnline).length;

  List<ServerHealth> get onlineServers =>
      servers.where((ServerHealth s) => s.isOnline).toList();

  List<ServerHealth> get offlineServers =>
      servers.where((ServerHealth s) => !s.isOnline).toList();

  FleetMood get mood {
    if (servers.isEmpty) return FleetMood.empty;
    if (onlineCount == servers.length) return FleetMood.allOnline;
    if (onlineCount == 0) return FleetMood.allOffline;
    return FleetMood.degraded;
  }
}

/// Runs light-weight health probes over already-connected SSH sessions.
///
/// For every server the executor runs [probeCommand] (a single cheap round
/// trip that yields kernel uptime plus the canonical three load figures).
/// Servers without a live session fail fast with a `notFound` result and are
/// reported offline without touching the network. Probes fan out in
/// parallel, each bounded by [probeTimeout]; one slow or broken host never
/// affects the others.
///
/// A short-lived snapshot cache ([cacheTtl]) keeps rapid repeat requests
/// from hammering the fleet — callers can always bypass it with `force`.
class SshHealthProbe {
  SshHealthProbe(this._ref);

  final Ref _ref;

  /// One cheap command that answers both questions at once. `&&` keeps the
  /// exit code meaningful on Linux; stdout is parsed defensively so quirky
  /// platforms (busybox, BSD) still produce useful briefs when possible.
  static const String probeCommand = 'uptime && cat /proc/loadavg';

  /// Per-command budget — a healthy box answers in well under a second.
  static const Duration probeTimeout = Duration(seconds: 5);

  /// How long a snapshot stays fresh before a new probe is warranted.
  static const Duration cacheTtl = Duration(seconds: 15);

  FleetHealthSnapshot? _cache;

  /// Probes [servers] in parallel and returns the aggregated snapshot.
  ///
  /// Returns the cached snapshot when it is still fresh and covers the same
  /// server set, unless [force] is true.
  Future<FleetHealthSnapshot> probeFleet(
    List<ServerConfig> servers, {
    bool force = false,
  }) async {
    if (servers.isEmpty) return FleetHealthSnapshot.empty();

    final FleetHealthSnapshot? cached = _cache;
    if (!force && cached != null && _isFresh(cached, servers)) {
      return cached;
    }

    // Parallel fan-out; every server is probed independently.
    final List<ServerHealth> results =
        await Future.wait<ServerHealth>(servers.map(_probeOne));
    final FleetHealthSnapshot snapshot = FleetHealthSnapshot(
      servers: results,
      probedAt: DateTime.now(),
    );
    _cache = snapshot;
    return snapshot;
  }

  /// True when [snapshot] is young enough and covers exactly [servers].
  bool _isFresh(FleetHealthSnapshot snapshot, List<ServerConfig> servers) {
    if (DateTime.now().difference(snapshot.probedAt) >= cacheTtl) return false;
    if (snapshot.servers.length != servers.length) return false;
    final Set<String> requested = servers.map((ServerConfig s) => s.id).toSet();
    return snapshot.servers
        .every((ServerHealth s) => requested.contains(s.serverId));
  }

  /// Probes a single server. Never throws — every failure mode degrades to
  /// an offline entry so one bad host cannot abort the batch.
  Future<ServerHealth> _probeOne(ServerConfig config) async {
    ServerHealth health;
    try {
      final Result<CommandResult> result =
          await _ref.read(sshCommandExecutorProvider).execute(
                serverId: config.id,
                command: probeCommand,
                timeout: probeTimeout,
              );
      health = _healthFromResult(config, result);
    } catch (_) {
      health = ServerHealth.offline(serverId: config.id, serverName: config.name);
    }
    return health;
  }

  /// Maps an executed (or failed) command into a [ServerHealth] entry.
  ServerHealth _healthFromResult(
    ServerConfig config,
    Result<CommandResult> result,
  ) {
    return result.when(
      success: (CommandResult cmd) {
        // Exit 0 is the happy path; a non-zero exit with recognisable
        // uptime output (e.g. `cat /proc/loadavg` missing on BSD) still
        // counts as a live, healthy box.
        if (!cmd.success && !_hasUptimeSignature(cmd.stdout)) {
          return ServerHealth.offline(
              serverId: config.id, serverName: config.name);
        }
        return ServerHealth.online(
          serverId: config.id,
          serverName: config.name,
          uptimeBrief: parseUptimeBrief(cmd.stdout),
          loadAverage: parseLoadAverage(cmd.stdout),
        );
      },
      failure: (_) =>
          ServerHealth.offline(serverId: config.id, serverName: config.name),
    );
  }

  // ─── Output parsing ─────────────────────────────────────────────────────

  static final RegExp _uptimeWithUsers = RegExp(r'up\s+(.+?),\s+\d+\s+users?');
  static final RegExp _uptimeBeforeLoad = RegExp(r'up\s+(.+?),\s*load average');
  static final RegExp _uptimeSimple = RegExp(r'up\s+([^,\r\n]+)');
  static final RegExp _loadTriple = RegExp(
    r'(\d+(?:\.\d+)?)[,\s]+(\d+(?:\.\d+)?)[,\s]+(\d+(?:\.\d+)?)',
  );
  static final RegExp _uptimeSignature = RegExp(r'\bup\s+\d');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Extracts the uptime segment (e.g. `up 3 days, 2:14`) from `uptime`
  /// output. Tolerates procps, busybox (no user count) and BSD layouts.
  static String? parseUptimeBrief(String stdout) {
    if (!stdout.contains('up')) return null;
    final String? segment = _firstGroup(_uptimeWithUsers, stdout) ??
        _firstGroup(_uptimeBeforeLoad, stdout) ??
        _firstGroup(_uptimeSimple, stdout);
    if (segment == null || segment.trim().isEmpty) return null;
    return 'up ${segment.trim().replaceAll(_whitespace, ' ')}';
  }

  /// Extracts the three load figures, accepting both the `uptime` wording
  /// (`load average: 0.52, 0.58, 0.60`) and raw `/proc/loadavg` content.
  static String? parseLoadAverage(String stdout) {
    final RegExpMatch? match = _loadTriple.firstMatch(stdout);
    if (match == null) return null;
    return '${match.group(1)}, ${match.group(2)}, ${match.group(3)}';
  }

  static String? _firstGroup(RegExp pattern, String input) =>
      pattern.firstMatch(input)?.group(1);

  /// Cheap sanity check that the stdout really looks like `uptime` output.
  static bool _hasUptimeSignature(String stdout) =>
      _uptimeSignature.hasMatch(stdout);
}

/// Provider for the fleet health probe.
final Provider<SshHealthProbe> sshHealthProbeProvider =
    Provider<SshHealthProbe>(SshHealthProbe.new);

/// UI-facing state of the fleet health card.
@immutable
class FleetHealthState {
  const FleetHealthState({this.isProbing = false, this.snapshot});

  /// True while a probe round is in flight (drives the progress bar).
  final bool isProbing;

  /// Last completed snapshot; null until the first probe finishes.
  final FleetHealthSnapshot? snapshot;
}

/// Keeps the latest [FleetHealthSnapshot] for the summary card.
///
/// Probes are strictly user-initiated — nothing here polls on a timer.
class FleetHealthNotifier extends Notifier<FleetHealthState> {
  @override
  FleetHealthState build() => const FleetHealthState();

  /// Runs one probe round over [servers]. Re-entrant calls while a probe is
  /// already running are ignored.
  Future<void> probe(List<ServerConfig> servers, {bool force = false}) async {
    if (state.isProbing) return;
    final FleetHealthSnapshot? previous = state.snapshot;
    state = FleetHealthState(isProbing: true, snapshot: previous);
    try {
      final FleetHealthSnapshot snapshot = await ref
          .read(sshHealthProbeProvider)
          .probeFleet(servers, force: force);
      state = FleetHealthState(isProbing: false, snapshot: snapshot);
    } catch (_) {
      state = FleetHealthState(isProbing: false, snapshot: previous);
    }
  }
}

final NotifierProvider<FleetHealthNotifier, FleetHealthState>
    fleetHealthProvider =
    NotifierProvider<FleetHealthNotifier, FleetHealthState>(
  FleetHealthNotifier.new,
);
