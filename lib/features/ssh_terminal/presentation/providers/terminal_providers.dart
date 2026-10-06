import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../data/ssh_client_manager.dart';
import '../terminal_schemes.dart';

// ─── Terminal instance (per server, autoDispose with page) ────────────────

/// The xterm [Terminal] instance for a given server, wired bidirectionally to
/// the SSH session from the global registry:
///
/// * remote bytes → incrementally UTF-8 decoded → batched into [Terminal.write]
/// * user keystrokes ([Terminal.onOutput]) → [SshClientManager.sendInput]
/// * viewport changes ([Terminal.onResize]) → [SshClientManager.resize] (PTY)
///
/// Watches [sshSessionRegistryProvider] so wiring is established as soon as a
/// session appears (after connect) and torn down when it disappears.
/// Auto-disposed alongside the terminal page; all subscriptions and timers are
/// released in [Ref.onDispose].
final terminalForServerProvider =
    Provider.autoDispose.family<Terminal, String>((Ref ref, String serverId) {
  final Terminal terminal = Terminal(maxLines: AppConstants.terminalScrollback);
  final _TerminalOutputPump pump = _TerminalOutputPump(terminal);

  // Watch the registry — rebuilds when a session appears or disappears.
  final Map<String, RegisteredSession> sessions =
      ref.watch(sshSessionRegistryProvider);
  final RegisteredSession? session = sessions[serverId];

  StreamSubscription<Uint8List>? outputSub;

  if (session != null) {
    final SshClientManager manager = session.manager;

    // Remote output → terminal. Broadcast stream survives across (re)connects.
    outputSub = manager.outputStream.listen(
      pump.add,
      onError: (Object _) {},
      cancelOnError: false,
    );

    // Terminal input → remote stdin. When the Ctrl modifier is armed, a single
    // typed letter is translated into its control byte (Ctrl-C → 0x03) and the
    // modifier auto-releases, matching a hardware terminal's behaviour.
    terminal.onOutput = (String data) {
      if (data.length == 1 && ref.read(ctrlKeyStateProvider)) {
        final int? control = _controlByte(data.codeUnitAt(0));
        if (control != null) {
          manager.sendInput(String.fromCharCode(control));
          ref.read(ctrlKeyStateProvider.notifier).release();
          return;
        }
      }
      manager.sendInput(data);
    };

    // Viewport resize → remote PTY window-change.
    terminal.onResize =
        (int width, int height, int pixelWidth, int pixelHeight) {
      unawaited(manager.resize(width, height));
    };
  }

  ref.onDispose(() {
    unawaited(outputSub?.cancel());
    pump.dispose();
    terminal.onOutput = null;
    terminal.onResize = null;
  });

  return terminal;
});

/// Selection controller shared with the [TerminalView] so the toolbar can
/// copy the current selection and clear it after pasting.
final Provider<TerminalController> terminalControllerProvider =
    Provider.autoDispose<TerminalController>((ref) => TerminalController());

/// Whether the Ctrl modifier is currently armed by the keyboard toolbar.
///
/// Consumed by [terminalForServerProvider]'s `onOutput` handler so the modifier
/// applies to the *next* character typed on the system soft keyboard, then
/// releases.
final NotifierProvider<CtrlKeyController, bool>
    ctrlKeyStateProvider =
    NotifierProvider.autoDispose<CtrlKeyController, bool>(
  CtrlKeyController.new,
);

class CtrlKeyController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void arm() => state = true;
  void release() => state = false;
}

/// The currently selected terminal colour scheme, persisted in preferences.
///
/// The terminal page watches this to swap the xterm palette live; the settings
/// page exposes a picker bound to [TerminalColorSchemeController.setScheme].
final NotifierProvider<TerminalColorSchemeController, TerminalColorScheme>
    terminalColorSchemeProvider = NotifierProvider<
        TerminalColorSchemeController, TerminalColorScheme>(
  TerminalColorSchemeController.new,
);

class TerminalColorSchemeController extends Notifier<TerminalColorScheme> {
  @override
  TerminalColorScheme build() => TerminalColorScheme.byId(
        ref.read(preferencesServiceProvider).terminalColorSchemeId,
      );

  Future<void> setScheme(TerminalColorScheme scheme) async {
    state = scheme;
    await ref.read(preferencesServiceProvider).setTerminalColorSchemeId(scheme.id);
  }
}

/// Maps an ASCII letter code point to its control byte (a→1 … z→26), or null
/// when [code] has no control equivalent.
int? _controlByte(int code) {
  final int lower = (code >= 0x41 && code <= 0x5A) ? code + 0x20 : code;
  if (lower >= 0x61 && lower <= 0x7A) return lower - 0x60;
  return null;
}

/// Coalesces bursts of shell output into throttled [Terminal.write] calls and
/// decodes UTF-8 across chunk boundaries.
///
/// A remote `cat bigfile` or `yes` can deliver thousands of small packets per
/// second; writing each one synchronously would thrash the terminal's repaint.
/// Instead bytes accumulate in a buffer that flushes at most once per
/// [_flushInterval], keeping the UI smooth. Multi-byte UTF-8 sequences split
/// across packets are held back until complete, avoiding mojibake.
class _TerminalOutputPump {
  _TerminalOutputPump(this._terminal);

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

  /// Decodes as much complete UTF-8 as possible and writes it to the terminal,
  /// retaining any trailing incomplete sequence for the next flush.
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

  /// Returns how many trailing bytes of [bytes] form an incomplete UTF-8
  /// sequence (0 when the buffer ends on a character boundary).
  static int _incompleteTailLength(Uint8List bytes) {
    final int len = bytes.length;
    // Walk back at most 3 bytes looking for a leading byte.
    for (int back = 1; back <= 3 && back <= len; back++) {
      final int b = bytes[len - back];
      if (b < 0x80) {
        return 0; // ASCII — always complete.
      }
      if ((b & 0xC0) != 0x80) {
        // Leading byte: work out the expected sequence length.
        final int expected;
        if ((b & 0xE0) == 0xC0) {
          expected = 2;
        } else if ((b & 0xF0) == 0xE0) {
          expected = 3;
        } else if ((b & 0xF8) == 0xF0) {
          expected = 4;
        } else {
          return 0; // Invalid lead — let the decoder replace it.
        }
        // `back` bytes present so far; incomplete when fewer than expected.
        return back < expected ? back : 0;
      }
      // Otherwise a continuation byte — keep scanning backwards.
    }
    return 0;
  }
}
