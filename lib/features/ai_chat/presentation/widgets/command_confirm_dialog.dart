import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Pre-execution confirmation dialog for SSH commands.
///
/// Displays the exact command text, target server names, and warns about
/// potentially destructive operations. Users must explicitly confirm before
/// execution proceeds.
class CommandConfirmDialog extends StatelessWidget {
  const CommandConfirmDialog({
    super.key,
    required this.command,
    required this.serverNames,
    this.isDangerous = false,
  });

  final String command;
  final List<String> serverNames;
  final bool isDangerous;

  /// Shows the dialog and returns true if user confirms execution.
  static Future<bool> show(
    BuildContext context, {
    required String command,
    required List<String> serverNames,
    bool isDangerous = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) => CommandConfirmDialog(
            command: command,
            serverNames: serverNames,
            isDangerous: isDangerous,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: <Widget>[
          Icon(
            isDangerous ? Icons.warning_rounded : Icons.confirmation_num_rounded,
            color: isDangerous ? colors.error : colors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDangerous ? l10n.aiExecuteDangerWarning : l10n.aiExecuteTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Warning for dangerous commands
            if (isDangerous) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      color: colors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.aiExecuteDangerText,
                        style: TextStyle(
                          color: colors.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Command label
            Text(
              l10n.aiExecuteCommandLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Code block
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF282C34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  command,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: AppTheme.monoFallback,
                    fontSize: 12.5,
                    height: 1.55,
                    color: const Color(0xFFD4D4D4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Server list
            Text(
              l10n.aiExecuteTargetServer,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: serverNames.map((String name) {
                return Chip(
                  label: Text(name),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
                  ),
                  backgroundColor: colors.primary.withValues(alpha: 0.08),
                  labelStyle: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDangerous ? colors.error : colors.primary,
          ),
          child: Text(
              isDangerous ? l10n.aiExecuteConfirmAnyway : l10n.aiExecuteConfirmButton),
        ),
      ],
    );
  }
}
