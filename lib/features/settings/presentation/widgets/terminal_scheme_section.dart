import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ssh_terminal/presentation/providers/terminal_providers.dart';
import '../../../ssh_terminal/presentation/terminal_schemes.dart';

/// Settings tile + picker for the SSH terminal colour scheme.
///
/// Shows the currently selected scheme and opens a bottom sheet where every
/// built-in palette is listed with a live colour preview. Choosing one updates
/// [terminalColorSchemeProvider], which the terminal page watches to re-theme
/// the xterm viewport immediately.
class TerminalSchemeTile extends ConsumerWidget {
  const TerminalSchemeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TerminalColorScheme scheme = ref.watch(terminalColorSchemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(Icons.palette_outlined,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.settingsTerminalScheme,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      l10n.settingsTerminalSchemeDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _SchemePreview(scheme: scheme),
              const SizedBox(width: 8),
              Text(
                scheme.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    final TerminalColorScheme current =
        ref.read(terminalColorSchemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                l10n.settingsTerminalScheme,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: TerminalColorScheme.all.length,
                itemBuilder: (BuildContext ctx, int index) {
                  final TerminalColorScheme scheme =
                      TerminalColorScheme.all[index];
                  final bool selected = scheme.id == current.id;
                  return ListTile(
                    leading: _SchemePreview(scheme: scheme),
                    title: Text(scheme.name),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(terminalColorSchemeProvider.notifier)
                          .setScheme(scheme);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A compact terminal preview: background with a row of ANSI swatches.
class _SchemePreview extends StatelessWidget {
  const _SchemePreview({required this.scheme});

  final TerminalColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = scheme.theme;
    final List<Color> swatches = <Color>[
      t.red, t.green, t.yellow, t.blue, t.magenta, t.cyan, t.white,
    ];
    return Container(
      width: 56,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          for (final Color c in swatches)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
