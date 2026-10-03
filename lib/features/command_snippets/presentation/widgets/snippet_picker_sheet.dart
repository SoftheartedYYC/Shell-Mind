import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/command_snippet.dart';
import '../providers/command_snippet_providers.dart';

/// Bottom sheet listing saved command snippets.
///
/// Shared by two entry points with different consume semantics:
///
/// * **AI chat composer** — tapping a row pops the sheet and hands the
///   [CommandSnippet] back so the caller can insert its command into the
///   composer input.
/// * **Terminal keyboard toolbar** — tapping a row pops the sheet and the
///   caller immediately pipes the command (plus a newline) into the live
///   shell.
///
/// The sheet itself is consume-agnostic: it always resolves with the tapped
/// snippet (or `null` when dismissed) and owns the add/delete affordances,
/// including an inline empty state when nothing is saved yet.
class SnippetPickerSheet extends ConsumerStatefulWidget {
  const SnippetPickerSheet({super.key});

  /// Shows the picker. Resolves with the selected snippet, or `null` when
  /// the sheet was dismissed without a selection.
  static Future<CommandSnippet?> show(BuildContext context) {
    return showModalBottomSheet<CommandSnippet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => const SnippetPickerSheet(),
    );
  }

  @override
  ConsumerState<SnippetPickerSheet> createState() =>
      _SnippetPickerSheetState();
}

class _SnippetPickerSheetState extends ConsumerState<SnippetPickerSheet> {
  Future<void> _openAddForm() async {
    final bool? added = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => const _AddSnippetDialog(),
    );
    if (added == true && mounted) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _remove(CommandSnippet snippet) async {
    HapticFeedback.lightImpact();
    await ref
        .read(commandSnippetsProvider.notifier)
        .removeSnippet(snippet.id);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<CommandSnippet>> snippets =
        ref.watch(commandSnippetsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.heightOf(context) * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.snippetsTitle,
                        style: context.text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.snippetsSubtitle,
                        style: context.text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openAddForm,
                  tooltip: l10n.snippetsAddTooltip,
                  icon: Icon(Icons.add_circle_outline_rounded,
                      size: 24, color: colors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: snippets.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (Object _, StackTrace __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    l10n.snippetsLoadFailed,
                    style: context.text.bodyMedium
                        ?.copyWith(color: colors.error),
                  ),
                ),
              ),
              data: (List<CommandSnippet> list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.bookmark_border_rounded,
                            size: 40, color: colors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          l10n.snippetsEmptyTitle,
                          style: context.text.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.snippetsEmptyMessage,
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: list.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final CommandSnippet snippet = list[index];
                    return _SnippetTile(
                      snippet: snippet,
                      onTap: () => Navigator.of(context).pop(snippet),
                      onDelete: () => _remove(snippet),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: SizedBox(height: 4),
          ),
        ],
      ),
    );
  }
}

/// A single snippet row: label (name or command) over the raw command, with
/// a trailing delete action.
class _SnippetTile extends StatelessWidget {
  const _SnippetTile({
    required this.snippet,
    required this.onTap,
    required this.onDelete,
  });

  final CommandSnippet snippet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool hasName = snippet.name != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    snippet.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: hasName ? null : AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallback,
                    ),
                  ),
                  if (hasName) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      snippet.command,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: AppTheme.monoFallback,
                        fontSize: 11.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: l10n.snippetsDeleteTooltip,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add-snippet dialog: command (required, multi-line) + optional name.
/// Validates non-empty command client-side and reports success via `pop(true)`.
class _AddSnippetDialog extends ConsumerStatefulWidget {
  const _AddSnippetDialog();

  @override
  ConsumerState<_AddSnippetDialog> createState() => _AddSnippetDialogState();
}

class _AddSnippetDialogState extends ConsumerState<_AddSnippetDialog> {
  final TextEditingController _command = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _command.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String command = _command.text.trim();
    if (command.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snippetsCommandRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(commandSnippetsProvider.notifier).addSnippet(
          command: command,
          name: _name.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.bookmark_add_outlined, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.snippetsAddTitle,
                style: context.text.titleLarge),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _command,
              autofocus: true,
              autocorrect: false,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: AppTheme.monoFallback,
                fontSize: 13,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l10n.snippetsCommandHint,
                labelText: l10n.snippetsCommandLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l10n.snippetsNameHint,
                labelText: l10n.snippetsNameLabel,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(l10n.snippetsSave),
        ),
      ],
    );
  }
}
