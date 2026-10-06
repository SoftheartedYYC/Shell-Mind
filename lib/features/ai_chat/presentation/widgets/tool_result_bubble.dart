import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/chat_message.dart';

/// Displays SSH command execution result in a specialized message bubble.
///
/// Features:
/// - Left border color based on success (green) or failure (red)
/// - Header with server name chip, exit code badge, and elapsed time
/// - Collapsible stdout area (show first 10 lines by default); hidden
///   entirely when both stdout and stderr are blank
/// - Separate stderr section if present (always expanded)
/// - "Analyze with AI" button at bottom
class ToolResultBubble extends StatefulWidget {
  const ToolResultBubble({
    super.key,
    required this.payload,
    this.onAnalyze,
  });

  final ToolPayload payload;
  final VoidCallback? onAnalyze;

  @override
  State<ToolResultBubble> createState() => _ToolResultBubbleState();
}

class _ToolResultBubbleState extends State<ToolResultBubble> {
  static const int _visibleLines = 10;

  /// Whether the full stdout is shown (only relevant when output exceeds
  /// [_visibleLines]).
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ToolPayload payload = widget.payload;
    final bool isSuccess = payload.exitCode == 0;
    final Color borderColor = isSuccess ? context.sem.success : colors.error;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Whitespace-only output (e.g. silent `curl -s -o /dev/null`) is treated
    // as empty so the whole output section collapses away.
    final String stdout = payload.stdout.trim();
    final String stderr = payload.stderr.trim();
    final List<String> stdoutLines =
        stdout.isNotEmpty ? stdout.split('\n') : <String>[];
    final bool hasMoreOutput = stdoutLines.length > _visibleLines;
    final List<String> displayedLines =
        hasMoreOutput && !_expanded
            ? stdoutLines.sublist(0, _visibleLines)
            : stdoutLines;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50)
            .withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header with left border accent
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Colored left border
                Container(
                  width: 3,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Server name + Exit code + Time
                      Row(
                        children: <Widget>[
                          Chip(
                            label: Text(payload.serverName),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? context.sem.success.withValues(alpha: 0.12)
                                  : colors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSuccess
                                    ? context.sem.success.withValues(alpha: 0.3)
                                    : colors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isSuccess ? Icons.check_circle_rounded :
                                      Icons.error_rounded,
                                  size: 12,
                                  color: isSuccess ? context.sem.success : colors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.aiToolResultExitCode(payload.exitCode),
                                  style: TextStyle(
                                    fontFamily: AppTheme.monoFont,
                                    fontFamilyFallback: AppTheme.monoFallback,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSuccess ? context.sem.success : colors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${payload.elapsed.inMilliseconds}ms',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontFamily: AppTheme.monoFont,
                                  fontFamilyFallback: AppTheme.monoFallback,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Output section — collapsed entirely when both streams are blank.
          if (stdoutLines.isNotEmpty || stderr.isNotEmpty) ...<Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF282C34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Output header — tapping toggles expand/collapse when there
                  // is more output than the collapsed preview.
                  InkWell(
                    onTap: hasMoreOutput
                        ? () => setState(() => _expanded = !_expanded)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.code_rounded,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.aiToolResultOutput,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (hasMoreOutput) ...<Widget>[
                            const Spacer(),
                            Icon(
                              _expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Stdout content
                  LimitedBox(
                    maxHeight: 200,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: SelectableText(
                        displayedLines.join('\n'),
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

                  if (hasMoreOutput)
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 14,
                        ),
                        label: Text(
                          _expanded
                              ? l10n.aiToolResultExpandedHide
                              : l10n.aiToolResultCollapsedShow(
                                  stdoutLines.length - _visibleLines,
                                ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          minimumSize: const Size(0, 28),
                        ),
                      ),
                    ),

                  // Stderr section
                  if (payload.stderr.isNotEmpty) ...<Widget>[
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: colors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.aiToolResultStderrLabel,
                                style: TextStyle(
                                  color: colors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            stderr,
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontFamilyFallback: AppTheme.monoFallback,
                              fontSize: 12.5,
                              height: 1.55,
                              color: colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Footer with analyze button
          if (widget.onAnalyze != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: widget.onAnalyze,
                icon: Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(l10n.aiToolResultAnalyzeButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
