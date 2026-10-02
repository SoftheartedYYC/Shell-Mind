import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ssh_session_registry.dart';

// ─── State ───────────────────────────────────────────────────────────────────

/// Immutable state for the terminal-context feature.
///
/// Tracks whether context injection is enabled, which server's output to
/// capture, and how many trailing lines to retain in the ring buffer.
@immutable
class TerminalContextState {
  const TerminalContextState({
    this.isEnabled = false,
    this.serverId,
    this.maxLines = 50,
  });

  /// Whether terminal output should be attached to AI messages.
  final bool isEnabled;

  /// The server whose output stream is being captured. `null` means "use the
  /// default (most-recently connected) session".
  final String? serverId;

  /// Maximum number of trailing lines retained in the ring buffer.
  final int maxLines;

  TerminalContextState copyWith({
    bool? isEnabled,
    String? serverId,
    int? maxLines,
    bool clearServer = false,
  }) {
    return TerminalContextState(
      isEnabled: isEnabled ?? this.isEnabled,
      serverId: clearServer ? null : (serverId ?? this.serverId),
      maxLines: maxLines ?? this.maxLines,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalContextState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          serverId == other.serverId &&
          maxLines == other.maxLines;

  @override
  int get hashCode => Object.hash(isEnabled, serverId, maxLines);

  @override
  String toString() =>
      'TerminalContextState(enabled: $isEnabled, server: $serverId, maxLines: $maxLines)';
}

// ─── Controller ──────────────────────────────────────────────────────────────

/// Manages terminal output capture for AI context injection.
///
/// When enabled, subscribes to the selected server's [SshClientManager.outputStream]
/// and retains the last [TerminalContextState.maxLines] lines in a ring buffer.
/// The captured text can then be formatted and prepended to user messages so the
/// AI model has live terminal context.
///
/// The ring buffer approach works independently of whether the terminal page is
/// mounted — as long as the SSH session is alive in the registry, output flows.
class TerminalContextController extends Notifier<TerminalContextState> {
  StreamSubscription<Uint8List>? _outputSub;
  final List<String> _ringBuffer = <String>[];
  final StringBuffer _partialLine = StringBuffer();

  @override
  TerminalContextState build() {
    ref.onDispose(_unsubscribe);
    return const TerminalContextState();
  }

  /// Toggles context attachment on/off.
  ///
  /// When turning on, immediately subscribes to the target server's output.
  /// When turning off, unsubscribes and clears the buffer.
  void toggleContext() {
    final bool next = !state.isEnabled;
    state = state.copyWith(isEnabled: next);
    if (next) {
      _subscribe();
    } else {
      _unsubscribe();
      _clearBuffer();
    }
  }

  /// Explicitly enables or disables context capture.
  void setEnabled(bool enabled) {
    if (enabled == state.isEnabled) return;
    state = state.copyWith(isEnabled: enabled);
    if (enabled) {
      _subscribe();
    } else {
      _unsubscribe();
      _clearBuffer();
    }
  }

  /// Selects which server's output to capture.
  ///
  /// Pass `null` to use the default (most-recently connected) session.
  /// Re-subscribes if context is currently enabled.
  void setServer(String? serverId) {
    state = state.copyWith(serverId: serverId, clearServer: serverId == null);
    if (state.isEnabled) {
      _unsubscribe();
      _clearBuffer();
      _subscribe();
    }
  }

  /// Returns the captured terminal output as a single string, or `null` when
  /// context is disabled or the buffer is empty.
  String? getTerminalContext() {
    if (!state.isEnabled) return null;
    if (_ringBuffer.isEmpty) return null;
    final String text = _ringBuffer.join('\n').trim();
    return text.isEmpty ? null : text;
  }

  /// Formats raw terminal context into the envelope expected by the AI model.
  ///
  /// Returns `null` when [rawContext] is null/empty.
  String? formatContext(String? rawContext, String? serverName) {
    if (rawContext == null || rawContext.isEmpty) return null;
    final String tag = serverName != null ? ' server:$serverName' : '';
    return '[terminal-context$tag]\n$rawContext\n[/terminal-context]';
  }

  /// Convenience: resolves the server name for the currently selected session.
  String? get currentServerName {
    final SshSessionRegistry registry =
        ref.read(sshSessionRegistryProvider.notifier);
    final RegisteredSession? session = state.serverId != null
        ? registry.getSession(state.serverId!)
        : registry.defaultSession;
    return session?.serverName;
  }

  // ─── Internals ───────────────────────────────────────────────────────────

  /// Subscribes to the output stream of the target session.
  void _subscribe() {
    final SshSessionRegistry registry =
        ref.read(sshSessionRegistryProvider.notifier);
    final RegisteredSession? session = state.serverId != null
        ? registry.getSession(state.serverId!)
        : registry.defaultSession;
    if (session == null) return;

    _outputSub = session.manager.outputStream.listen(
      _onOutput,
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void _unsubscribe() {
    _outputSub?.cancel();
    _outputSub = null;
  }

  void _clearBuffer() {
    _ringBuffer.clear();
    _partialLine.clear();
  }

  /// Handles raw bytes from the SSH output stream: decodes UTF-8, splits into
  /// lines, and appends to the ring buffer (evicting oldest lines when full).
  void _onOutput(Uint8List chunk) {
    final String text = utf8.decode(chunk, allowMalformed: true);
    // Prepend any incomplete line from the previous chunk.
    final String combined = _partialLine.toString() + text;
    _partialLine.clear();

    final List<String> parts = combined.split('\n');
    // The last element is either '' (if text ended with \n) or a partial line.
    final String trailing = parts.removeLast();
    if (trailing.isNotEmpty) {
      _partialLine.write(trailing);
    }

    for (final String line in parts) {
      // Strip ANSI escape sequences for cleaner context.
      final String cleaned = _stripAnsi(line);
      _ringBuffer.add(cleaned);
      if (_ringBuffer.length > state.maxLines) {
        _ringBuffer.removeAt(0);
      }
    }
  }

  /// Removes ANSI escape sequences (CSI, OSC, simple escapes) from [input].
  static final RegExp _ansiRegex = RegExp(
    r'\x1B(?:\[[0-9;]*[A-Za-z]|\][^\x07]*\x07|[()][A-Z0-9]|[=>]|\[[\?]?[0-9;]*[hlHJKGr]|\[([0-9]{1,3}(;[0-9]{1,3})*)?m)',
  );

  static String _stripAnsi(String input) => input.replaceAll(_ansiRegex, '');
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// App-wide provider for terminal context capture.
///
/// Not autoDispose — the buffer should persist across navigation so context
/// remains available when the user switches between the terminal and AI tabs.
final NotifierProvider<TerminalContextController, TerminalContextState>
    terminalContextProvider =
    NotifierProvider<TerminalContextController, TerminalContextState>(
  TerminalContextController.new,
);
