import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/ssh/ssh_reconnect_coordinator.dart';
import '../../../../shared/ssh/ssh_server_connect_controller.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../data/ssh_client_manager.dart';
import '../../domain/entities/connection_state.dart';
import 'terminal_providers.dart';

// ─── Cached terminal (one xterm buffer per server, app-wide) ──────────────

/// A live xterm [Terminal] wired to a server's SSH session, kept in an
/// app-wide cache so terminal tabs can be switched without losing the
/// scrollback buffer.
///
/// The cache watches [sshSessionRegistryProvider]:
///
/// * a newly registered session gets a fresh [Terminal] wired to its manager;
/// * a session whose manager was replaced (auto-reconnect success) keeps its
///   [Terminal] — only the I/O wiring is moved to the new manager;
/// * a session removed from the registry (manual disconnect / give-up legacy
///   path) has its wiring torn down and its entry dropped.
@immutable
class CachedTerminal {
  const CachedTerminal({
    required this.terminal,
    required this.wiring,
    required this.manager,
    required this.pump,
  });

  /// The persistent xterm buffer for this server.
  final Terminal terminal;

  /// Remote-output subscription feeding [terminal]. Cancelled on teardown.
  final StreamSubscription<Uint8List> wiring;

  /// The manager [terminal] is currently wired to. Used to detect manager
  /// replacement after a reconnect.
  final SshClientManager manager;

  /// Output coalescer bridging raw bytes into throttled [Terminal.write]s.
  final TabOutputPump pump;
}

/// App-wide cache of per-server xterm terminals (see [CachedTerminal]).
///
/// Deliberately **not** autoDispose: buffers must survive tab switches and
/// page navigation. Entry lifecycle mirrors the global registry, not the UI.
class TerminalTabCache extends Notifier<Map<String, CachedTerminal>> {
  /// Mirror of [state] used for teardown when the container itself dies.
  final Map<String, CachedTerminal> _live = <String, CachedTerminal>{};

  @override
  Map<String, CachedTerminal> build() {
    ref.onDispose(_disposeEverything);

    // Seed from the registry's current snapshot, then keep mirroring it.
    final Map<String, CachedTerminal> initial =
        _reconcile(ref.read(sshSessionRegistryProvider), const <String, CachedTerminal>{});

    ref.listen(sshSessionRegistryProvider,
        (_, Map<String, RegisteredSession> next) {
      state = _reconcile(next, state);
    });

    return initial;
  }

  /// Reconciles [current] against [registry]:
  /// creates entries for new sessions, rewires entries whose manager was
  /// replaced (buffer preserved), and tears down removed sessions.
  Map<String, CachedTerminal> _reconcile(
    Map<String, RegisteredSession> registry,
    Map<String, CachedTerminal> current,
  ) {
    Map<String, CachedTerminal>? next;

    // 1. Removed sessions and manager replacements.
    for (final MapEntry<String, CachedTerminal> entry in current.entries) {
      final RegisteredSession? session = registry[entry.key];
      if (session == null) {
        _teardown(entry.key, entry.value);
        (next ??= Map<String, CachedTerminal>.of(current)).remove(entry.key);
      } else if (!identical(entry.value.manager, session.manager)) {
        // Auto-reconnect replaced the manager: keep the buffer and re-wire
        // it onto the fresh manager (same Terminal — scrollback preserved).
        _teardownWiring(entry.value);
        final CachedTerminal rewired = _wire(entry.value.terminal, session);
        (next ??= Map<String, CachedTerminal>.of(current))[entry.key] = rewired;
        _live[entry.key] = rewired;
      }
    }

    // 2. Brand-new sessions.
    for (final MapEntry<String, RegisteredSession> entry in registry.entries) {
      if (!current.containsKey(entry.key)) {
        final CachedTerminal created = _create(entry.value);
        (next ??= Map<String, CachedTerminal>.of(current))[entry.key] = created;
        _live[entry.key] = created;
      }
    }

    return next ?? current;
  }

  /// Creates a brand-new buffer for [session] and wires it to the manager.
  CachedTerminal _create(RegisteredSession session) {
    return _wire(Terminal(maxLines: AppConstants.terminalScrollback), session);
  }

  /// Wires [terminal] — a fresh buffer or a preserved scrollback — onto
  /// [session]'s manager (output pump, input sink, PTY resize).
  CachedTerminal _wire(Terminal terminal, RegisteredSession session) {
    final TabOutputPump pump = TabOutputPump(terminal);
    final SshClientManager manager = session.manager;

    final StreamSubscription<Uint8List> wiring =
        manager.outputStream.listen(pump.add, onError: (Object _) {});

    terminal.onOutput = (String data) {
      // Sticky Ctrl modifier on the soft keyboard: a single letter becomes
      // its control byte (Ctrl-C → 0x03), then the modifier auto-releases.
      if (data.length == 1 && ref.read(ctrlKeyStateProvider)) {
        final int? control = controlByteFor(data.codeUnitAt(0));
        if (control != null) {
          manager.sendInput(String.fromCharCode(control));
          ref.read(ctrlKeyStateProvider.notifier).release();
          return;
        }
      }
      manager.sendInput(data);
    };

    terminal.onResize = (int width, int height, int pixelWidth, int pixelHeight) {
      unawaited(manager.resize(width, height));
    };

    return CachedTerminal(
      terminal: terminal,
      wiring: wiring,
      manager: manager,
      pump: pump,
    );
  }

  void _teardownWiring(CachedTerminal entry) {
    unawaited(entry.wiring.cancel());
    entry.pump.dispose();
    entry.terminal.onOutput = null;
    entry.terminal.onResize = null;
  }

  /// Tears the entry for [serverId] down completely (wiring + cache mirror).
  void _teardown(String serverId, CachedTerminal entry) {
    _teardownWiring(entry);
    _live.remove(serverId);
  }

  void _disposeEverything() {
    for (final CachedTerminal entry in _live.values) {
      _teardownWiring(entry);
    }
    _live.clear();
  }
}

/// Maps an ASCII letter code point to its control byte (a→1 … z→26), or null
/// when [code] has no control equivalent.
int? controlByteFor(int code) {
  final int lower = (code >= 0x41 && code <= 0x5A) ? code + 0x20 : code;
  if (lower >= 0x61 && lower <= 0x7A) return lower - 0x60;
  return null;
}


/// App-wide per-server xterm terminal cache.
final NotifierProvider<TerminalTabCache, Map<String, CachedTerminal>>
    terminalTabCacheProvider =
    NotifierProvider<TerminalTabCache, Map<String, CachedTerminal>>(
  TerminalTabCache.new,
);

/// Coalesces bursts of shell output into throttled [Terminal.write] calls and
/// decodes UTF-8 across chunk boundaries (mirrors the terminal page's pump).
class TabOutputPump {
  TabOutputPump(this._terminal);

  static const Duration _flushInterval = Duration(milliseconds: 12);

  final Terminal _terminal;
  final BytesBuilder _pending = BytesBuilder(copy: true);
  Timer? _timer;
  bool _disposed = false;

  void add(Uint8List chunk) {
    if (_disposed || chunk.isEmpty) return;
    _pending.add(chunk);
    _timer ??= Timer(_flushInterval, () {
      _timer = null;
      flush();
    });
  }

  void flush() {
    if (_disposed || _pending.isEmpty) return;

    final Uint8List bytes = _pending.takeBytes();
    final int tail = _incompleteTailLength(bytes);
    final int decodable = bytes.length - tail;

    if (decodable > 0) {
      final String text = utf8.decode(
        Uint8List.sublistView(bytes, 0, decodable),
        allowMalformed: true,
      );
      if (text.isNotEmpty) _terminal.write(text);
    }
    if (tail > 0) {
      _pending.add(Uint8List.sublistView(bytes, decodable));
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    flush(); // drain anything still buffered
  }

  static int _incompleteTailLength(Uint8List bytes) {
    final int len = bytes.length;
    for (int back = 1; back <= 3 && back <= len; back++) {
      final int b = bytes[len - back];
      if (b < 0x80) return 0; // ASCII — always complete.
      if ((b & 0xC0) != 0x80) {
        final int expected;
        if ((b & 0xE0) == 0xC0) {
          expected = 2;
        } else if ((b & 0xF0) == 0xE0) {
          expected = 3;
        } else if ((b & 0xF8) == 0xF0) {
          expected = 4;
        } else {
          return 0;
        }
        return back < expected ? back : 0;
      }
    }
    return 0;
  }
}

// ─── Per-tab status (derived) ─────────────────────────────────────────────

/// UI-facing lifecycle of one terminal tab, derived from the registry, the
/// reconnect tracker, and out-of-page connect attempts.
enum TerminalTabPhase { connected, connecting, reconnecting, gaveUp, error, closed }

@immutable
class TerminalTabStatus {
  const TerminalTabStatus({
    required this.phase,
    this.attempt = 0,
    this.maxAttempts,
    this.errorMessage,
    this.failureKind,
    this.authenticating = false,
  });

  const TerminalTabStatus.connected() : this(phase: TerminalTabPhase.connected);

  const TerminalTabStatus.connecting({this.authenticating = false})
      : phase = TerminalTabPhase.connecting,
        attempt = 0,
        maxAttempts = null,
        errorMessage = null,
        failureKind = null;

  const TerminalTabStatus.reconnecting(int attempt, int? maxAttempts)
      : this(
          phase: TerminalTabPhase.reconnecting,
          attempt: attempt,
          maxAttempts: maxAttempts,
        );

  const TerminalTabStatus.gaveUp() : this(phase: TerminalTabPhase.gaveUp);

  const TerminalTabStatus.error(String message, {String? failureKind})
      : this(
          phase: TerminalTabPhase.error,
          errorMessage: message,
          failureKind: failureKind,
        );

  const TerminalTabStatus.closed() : this(phase: TerminalTabPhase.closed);

  final TerminalTabPhase phase;

  /// 1-based attempt number while reconnecting.
  final int attempt;

  /// Cap of the running reconnect loop (`null` = unlimited).
  final int? maxAttempts;

  /// Latest attempt failure message, when [phase] is [TerminalTabPhase.error].
  final String? errorMessage;

  /// [FailureKind] name behind [TerminalTabPhase.error], for colour-coding.
  final String? failureKind;

  /// While [phase] is [TerminalTabPhase.connecting]: the handshake already
  /// reached the authentication step (refines the chrome's status label).
  final bool authenticating;

  /// Maps the tab phase onto the [SshConnectionStatus] vocabulary shared with
  /// the terminal chrome (status pill colours and labels).
  SshConnectionStatus get connectionStatus => switch (phase) {
        TerminalTabPhase.connected => SshConnectionStatus.connected,
        TerminalTabPhase.connecting ||
        TerminalTabPhase.reconnecting =>
          SshConnectionStatus.connecting,
        TerminalTabPhase.gaveUp ||
        TerminalTabPhase.error =>
          SshConnectionStatus.error,
        TerminalTabPhase.closed => SshConnectionStatus.disconnected,
      };

  bool get isConnected => phase == TerminalTabPhase.connected;
  bool get isBusy =>
      phase == TerminalTabPhase.connecting ||
      phase == TerminalTabPhase.reconnecting;
  bool get isReconnecting => phase == TerminalTabPhase.reconnecting;
  bool get hasGivenUp => phase == TerminalTabPhase.gaveUp;
}

/// Derives the tab status for [serverId] from the shared SSH machinery.
///
/// Reconnect progress wins over everything (the registry entry is kept alive
/// during a loop); a live session means connected; otherwise the out-of-page
/// connect attempt map provides dialing/error detail; anything else reads as
/// a closed session.
final ProviderFamily<TerminalTabStatus, String> terminalTabStatusProvider =
    Provider.family<TerminalTabStatus, String>((Ref ref, String serverId) {
  final RegisteredSession? session =
      ref.watch(sshSessionRegistryProvider)[serverId];
  final SshReconnectState reconnect =
      ref.watch(sshReconnectStateProvider)[serverId] ??
          const SshReconnectState.idle();
  final SshServerConnectAttempt? attempt =
      ref.watch(sshServerConnectProvider)[serverId];

  if (reconnect.isReconnecting) {
    return TerminalTabStatus.reconnecting(
        reconnect.attempt, reconnect.maxAttempts);
  }
  if (reconnect.hasGivenUp) {
    return const TerminalTabStatus.gaveUp();
  }
  if (session != null) {
    if (session.isConnected) return const TerminalTabStatus.connected();
    final SshConnectionState current = session.manager.currentState;
    return switch (current.status) {
      SshConnectionStatus.connected => const TerminalTabStatus.connected(),
      SshConnectionStatus.connecting ||
      SshConnectionStatus.authenticating ||
      SshConnectionStatus.disconnected =>
        TerminalTabStatus.connecting(
          authenticating: current.status == SshConnectionStatus.authenticating,
        ),
      SshConnectionStatus.error => TerminalTabStatus.error(
          current.errorMessage ?? 'error',
          failureKind: current.failureKind,
        ),
    };
  }
  if (attempt != null) {
    if (attempt.connecting) return const TerminalTabStatus.connecting();
    if (attempt.error != null) {
      return TerminalTabStatus.error(attempt.error!,
          failureKind: attempt.failureKind);
    }
  }
  return const TerminalTabStatus.closed();
});

// ─── Tab strip state ──────────────────────────────────────────────────────

/// Which terminal tabs are open and which is visible.
@immutable
class TerminalTabsState {
  const TerminalTabsState({
    this.openIds = const <String>[],
    this.activeId,
  });

  /// Open tabs in opening order (entry server first).
  final List<String> openIds;

  /// The visible tab; `null` only when no tabs are open.
  final String? activeId;

  bool contains(String serverId) => openIds.contains(serverId);
  bool get isEmpty => openIds.isEmpty;

  TerminalTabsState copyWith({
    List<String>? openIds,
    String? activeId,
  }) {
    return TerminalTabsState(
      openIds: openIds ?? this.openIds,
      activeId: activeId ?? this.activeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalTabsState &&
          other.runtimeType == runtimeType &&
          other.openIds.length == openIds.length &&
          other.activeId == activeId &&
          _listsEqual(other.openIds, openIds);

  static bool _listsEqual(List<String> a, List<String> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(openIds), activeId);
}

/// Owns the open-tabs list and the active selection for the terminal page.
///
/// Pure UI state — connections live in the global registry, so opening,
/// switching, and closing tabs never tears down a session unless explicitly
/// requested via [closeTab]'s [TerminalTabsController.closeTab] disconnect
/// flag.
class TerminalTabsController extends Notifier<TerminalTabsState> {
  @override
  TerminalTabsState build() => const TerminalTabsState();

  /// Seeds the entry server as the focused tab when the page mounts. Tabs
  /// opened previously survive (a later navigation back must not lose
  /// history); the freshly entered server is always brought to front.
  void seed(String serverId) {
    if (state.openIds.isEmpty) {
      state = TerminalTabsState(openIds: <String>[serverId], activeId: serverId);
      return;
    }
    if (state.contains(serverId)) {
      state = state.copyWith(activeId: serverId);
      return;
    }
    state = state.copyWith(
        openIds: <String>[serverId, ...state.openIds], activeId: serverId);
  }

  /// Opens (and focuses) a tab for [serverId].
  void openTab(String serverId) {
    if (state.contains(serverId)) {
      state = state.copyWith(activeId: serverId);
      return;
    }
    state = state.copyWith(
      openIds: <String>[...state.openIds, serverId],
      activeId: serverId,
    );
  }

  /// Focuses an existing tab (opens it first when missing).
  void activate(String serverId) {
    openTab(serverId);
  }

  /// Closes a tab. When [disconnectSession] is set the underlying SSH session
  /// is torn down through the registry first; otherwise the connection stays
  /// live in the background. A neighbouring tab becomes active; the last tab
  /// closing leaves the page without tabs (the caller pops).
  void closeTab(String serverId, {bool disconnectSession = false}) {
    if (disconnectSession) {
      unawaited(
          ref.read(sshSessionRegistryProvider.notifier).disconnect(serverId));
    }
    final int index = state.openIds.indexOf(serverId);
    if (index < 0) return;

    final List<String> remaining = List<String>.of(state.openIds)
      ..remove(serverId);

    if (state.activeId != serverId) {
      state = state.copyWith(openIds: remaining);
      return;
    }

    final String? nextActive = remaining.isEmpty
        ? null
        : remaining[(index - 1).clamp(0, remaining.length - 1)];
    state = TerminalTabsState(openIds: remaining, activeId: nextActive);
  }
}

/// Terminal page tab state.
final NotifierProvider<TerminalTabsController, TerminalTabsState>
    terminalTabsProvider =
    NotifierProvider<TerminalTabsController, TerminalTabsState>(
  TerminalTabsController.new,
);
