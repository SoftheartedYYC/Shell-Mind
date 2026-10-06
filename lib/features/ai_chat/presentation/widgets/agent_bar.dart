import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/agent_controller.dart';

// ─── Agent status bar ─────────────────────────────────────────────────────

/// Slim bar above the composer surfacing the [AgentController] state: a live
/// execution indicator and loop progress with a stop affordance.
///
/// The auto mode is armed by the settings master switch ("auto-execute
/// commands") at the controller level — the bar never toggles it, it only
/// renders the loop's live state and lets the user stop it.
class AgentBar extends StatelessWidget {
  const AgentBar({
    super.key,
    required this.state,
    required this.onStopAutoMode,
    required this.onOpenTimeline,
  });

  final AgentState state;
  final VoidCallback onStopAutoMode;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool executing = state.status == AgentStatus.executing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: state.isAutoMode
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          // Live execution indicator.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: executing
                  ? Row(
                      key: const ValueKey<String>('executing'),
                      children: <Widget>[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${state.executingServerName ?? l10n.aiAgentDefaultServer} · '
                            '${state.executingCommand ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: AppTheme.monoFont,
                              fontFamilyFallback: AppTheme.monoFallback,
                            ),
                          ),
                        ),
                      ],
                    )
                  : (state.errorMessage != null
                      ? Text(
                          // Map the machine-readable kind to a localised
                          // message; genuinely unpredictable exceptions
                          // (AgentErrorKind.unexpected) keep the raw text.
                          state.errorKind == AgentErrorKind.unexpected
                              ? state.errorMessage!
                              : switch (state.errorKind) {
                                  AgentErrorKind.noTargetServer =>
                                    l10n.agentErrorNoTargetServer,
                                  AgentErrorKind.execFailed =>
                                    l10n.agentErrorExecFailed,
                                  AgentErrorKind.dangerSkipped =>
                                    l10n.agentErrorDangerSkipped(
                                      state.errorArg ?? state.errorMessage!,
                                    ),
                                  AgentErrorKind.connectAuthRequired =>
                                    l10n.agentErrorConnectAuthRequired,
                                  AgentErrorKind.connectFailed =>
                                    l10n.agentErrorConnectFailed,
                                  AgentErrorKind.unexpected ||
                                  null =>
                                    state.errorMessage!,
                                },
                          key: const ValueKey<String>('error'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey<String>('idle'))),
            ),
          ),
          // Timeline entry — appears once at least one command has run.
          if (state.results.isNotEmpty) ...<Widget>[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onOpenTimeline,
              tooltip: l10n.aiTimelineOpen,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.timeline_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          // Loop progress + stop button while the auto loop runs. Stopping is
          // never gated: turning the master switch off mid-run must still
          // leave the user in control of the loop that already started.
          if (state.isAutoMode) ...<Widget>[
            const SizedBox(width: 8),
            Text(
              '${state.autoLoopCount}/${state.maxAutoLoops}',
              style: context.text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: AppTheme.monoFallback,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onStopAutoMode,
              tooltip: l10n.aiAgentStop,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.stop_circle_outlined, size: 20, color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
