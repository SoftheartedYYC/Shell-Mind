import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/terminal_providers.dart';

/// A key on the auxiliary toolbar.
///
/// Either a text [label] (rendered monospaced) or an [icon] (arrows), and the
/// raw [data] sequence it emits — which may be an escape sequence rather than a
/// single printable character. [isCtrl] marks the modifier toggle, which drives
/// [ctrlKeyStateProvider] instead of sending anything.
class _Key {
  const _Key({this.label, this.data, this.icon}) : isCtrl = false;

  const _Key.ctrl()
      : label = 'ctrl',
        data = null,
        icon = null,
        isCtrl = true;

  final String? label;
  final String? data;
  final IconData? icon;
  final bool isCtrl;
}

/// Escape / control sequences used by the arrow cluster and special keys.
abstract final class _Seq {
  static const String esc = '\x1b';
  static const String tab = '\t';
  static const String up = '\x1b[A';
  static const String down = '\x1b[B';
  static const String right = '\x1b[C';
  static const String left = '\x1b[D';
  static const String home = '\x1b[H';
  static const String end = '\x1b[F';
}

/// Bottom auxiliary keyboard for the terminal.
///
/// Supplies the special keys a mobile soft keyboard hides — Esc, Tab, Ctrl,
/// pipes/slashes, cursor arrows — as a horizontally scrollable strip. A leading
/// toggle flips between the *common* set and an *extended* symbol set.
///
/// The Ctrl key is a sticky modifier: it arms [ctrlKeyStateProvider], which the
/// terminal's `onOutput` consumes to translate the next typed letter into its
/// control byte (Ctrl-C → interrupt), then auto-releases.
class KeyboardToolbar extends ConsumerStatefulWidget {
  const KeyboardToolbar({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.onAskAi,
  });

  /// Emits a raw sequence (character or escape code) to the remote shell.
  final void Function(String data) onSend;

  /// When false (e.g. not yet connected) every key is dimmed and inert.
  final bool enabled;

  /// When non-null, an "Ask AI" chip is pinned to the trailing edge; tapping it
  /// hands the current terminal context off to the AI assistant.
  final VoidCallback? onAskAi;

  @override
  ConsumerState<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends ConsumerState<KeyboardToolbar> {
  /// Whether the extended symbol set is showing.
  bool _extended = false;

  // Common: the everyday shell metacharacters.
  static const List<_Key> _commonKeys = <_Key>[
    _Key(label: 'esc', data: _Seq.esc),
    _Key(label: 'tab', data: _Seq.tab),
    _Key.ctrl(),
    _Key(label: '/', data: '/'),
    _Key(label: '-', data: '-'),
    _Key(label: '.', data: '.'),
    _Key(label: '~', data: '~'),
    _Key(label: '|', data: '|'),
  ];

  // Extended: symbols the soft keyboard buries behind sub-menus.
  static const List<_Key> _extendedKeys = <_Key>[
    _Key.ctrl(),
    _Key(label: r'$', data: r'$'),
    _Key(label: '&', data: '&'),
    _Key(label: ';', data: ';'),
    _Key(label: '(', data: '('),
    _Key(label: ')', data: ')'),
    _Key(label: '{', data: '{'),
    _Key(label: '}', data: '}'),
    _Key(label: '[', data: '['),
    _Key(label: ']', data: ']'),
    _Key(label: '<', data: '<'),
    _Key(label: '>', data: '>'),
    _Key(label: '!', data: '!'),
    _Key(label: '@', data: '@'),
    _Key(label: '#', data: '#'),
  ];

  // Always trailing the set: cursor movement + line editing.
  static const List<_Key> _navKeys = <_Key>[
    _Key(icon: Icons.keyboard_arrow_up_rounded, data: _Seq.up),
    _Key(icon: Icons.keyboard_arrow_down_rounded, data: _Seq.down),
    _Key(icon: Icons.keyboard_arrow_left_rounded, data: _Seq.left),
    _Key(icon: Icons.keyboard_arrow_right_rounded, data: _Seq.right),
    _Key(label: 'home', data: _Seq.home),
    _Key(label: 'end', data: _Seq.end),
  ];

  void _onKeyTap(_Key key) {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();

    if (key.isCtrl) {
      ref.read(ctrlKeyStateProvider.notifier).toggle();
      return;
    }

    final String? data = key.data;
    if (data == null) return;

    // When Ctrl is armed, a single typed letter becomes its control byte and
    // the modifier releases — mirroring a hardware terminal's sticky Ctrl.
    if (data.length == 1 && ref.read(ctrlKeyStateProvider)) {
      final int? control = _controlByteFor(data.codeUnitAt(0));
      if (control != null) {
        widget.onSend(String.fromCharCode(control));
        ref.read(ctrlKeyStateProvider.notifier).release();
        return;
      }
    }

    widget.onSend(data);
  }

  /// Maps an ASCII letter code point to its control byte (a→1 … z→26), or null.
  static int? _controlByteFor(int code) {
    final int lower = (code >= 0x41 && code <= 0x5A) ? code + 0x20 : code;
    if (lower >= 0x61 && lower <= 0x7A) return lower - 0x60;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool ctrlArmed = ref.watch(ctrlKeyStateProvider);
    final List<_Key> keys = <_Key>[
      ...(_extended ? _extendedKeys : _commonKeys),
      ..._navKeys,
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Row(
          children: <Widget>[
            // Set-switch toggle, pinned so it never scrolls away.
            _KeyChip(
              active: _extended,
              enabled: widget.enabled,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _extended = !_extended);
              },
              child: Text(
                _extended ? '#+=' : 'abc',
                style: _labelStyle(
                  _extended ? colors.onPrimary : colors.onSurfaceVariant,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 1,
              height: 24,
              color: colors.outlineVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: <Widget>[
                    for (final _Key key in keys) ...<Widget>[
                      _KeyChip(
                        active: key.isCtrl && ctrlArmed,
                        enabled: widget.enabled,
                        onTap: () => _onKeyTap(key),
                        child: key.icon != null
                            ? Icon(
                                key.icon,
                                size: 18,
                                color: widget.enabled
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface.withValues(alpha: 0.3),
                              )
                            : Text(
                                key.label!,
                                style: _labelStyle(
                                  _fgFor(context, key.isCtrl && ctrlArmed,
                                      widget.enabled),
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
            // "Ask AI" chip, pinned to the trailing edge so it never scrolls away.
            if (widget.onAskAi != null) ...<Widget>[
              Container(
                width: 1,
                height: 24,
                color: colors.outlineVariant,
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: AppLocalizations.of(context).terminalTooltipAskAi,
                child: _KeyChip(
                  enabled: widget.enabled,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onAskAi!();
                  },
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 18,
                    color: widget.enabled
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _fgFor(BuildContext context, bool active, bool enabled) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (active) return colors.onPrimary;
    return enabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.3);
  }

  static TextStyle _labelStyle(
    Color color, {
    double size = 12.5,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: AppTheme.monoFont,
      fontFamilyFallback: AppTheme.monoFallback,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.4,
      color: color,
    );
  }
}

/// A single toolbar key: a rounded chip that highlights when [active]
/// (used for the sticky Ctrl modifier).
class _KeyChip extends StatelessWidget {
  const _KeyChip({
    required this.child,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = active
        ? colors.primary
        : colors.surfaceContainerHigh;
    final Color border = active
        ? colors.primary
        : colors.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 34,
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
