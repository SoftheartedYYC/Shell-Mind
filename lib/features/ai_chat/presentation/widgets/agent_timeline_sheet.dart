import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/agent_controller.dart';
import '../../../../shared/ssh/ssh_command_executor.dart';

/// Modal bottom sheet presenting the full agent execution chain as a
/// vertical timeline.
///
/// One node per [CommandResult] — sequence number, target-server badge,
/// command text, success/failure colouring, exit code, elapsed time and a
/// collapsible output block — preceded by a summary header (rounds, command
/// counts, success/failure tallies and the start–end time range). The sheet
/// watches [agentControllerProvider], so nodes stream in live while a round
/// is still running.
class AgentTimelineSheet extends ConsumerWidget {
  const AgentTimelineSheet({super.key});

  /// Opens the timeline as a tall modal sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AgentTimelineSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AgentState agent = ref.watch(agentControllerProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          // Title row with a close affordance (drag-down also dismisses).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.aiTimelineTitle,
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n.aiTimelineClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AgentTimelineView(
              results: agent.results,
              taskRounds: agent.taskRounds,
              taskStartedAt: agent.taskStartedAt,
              isExecuting: agent.status == AgentStatus.executing,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure display widget rendering the timeline body.
///
/// Deliberately provider-free so it can be exercised in widget tests with
/// plain data and reused inside [AgentTimelineSheet].
class AgentTimelineView extends StatelessWidget {
  const AgentTimelineView({
    super.key,
    required this.results,
    required this.taskRounds,
    required this.taskStartedAt,
    this.isExecuting = false,
  });

  /// Execution chain in order (oldest first).
  final List<CommandResult> results;

  /// Completed rounds (confirmed batches + auto loops) in the session.
  final int taskRounds;

  /// When the session's first command was dispatched.
  final DateTime? taskStartedAt;

  /// Whether the agent is mid-round (a live "running" node is appended).
  final bool isExecuting;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _TimelineEmpty();
    }

    final int successCount = results.where((CommandResult r) => r.success).length;
    final int failedCount = results.length - successCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TimelineSummary(
          results: results,
          taskRounds: taskRounds,
          taskStartedAt: taskStartedAt,
          successCount: successCount,
          failedCount: failedCount,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: results.length + (isExecuting ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              // Live node while the agent is still executing.
              if (isExecuting && index == results.length) {
                return const _RunningNode();
              }
              final CommandResult result = results[index];
              return _TimelineNode(
                key: ValueKey<CommandResult>(result),
                index: index,
                result: result,
                isFirst: index == 0,
                isLast: index == results.length - 1 && !isExecuting,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Summary header ──────────────────────────────────────────────────────

class _TimelineSummary extends StatelessWidget {
  const _TimelineSummary({
    required this.results,
    required this.taskRounds,
    required this.taskStartedAt,
    required this.successCount,
    required this.failedCount,
  });

  final List<CommandResult> results;
  final int taskRounds;
  final DateTime? taskStartedAt;
  final int successCount;
  final int failedCount;

  String _formatTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final DateTime? endedAt = results.isEmpty ? null : results.last.executedAt;
    final String range = taskStartedAt == null
        ? ''
        : endedAt == null
            ? l10n.aiTimelineStarted(_formatTime(taskStartedAt!))
            : '${l10n.aiTimelineStarted(_formatTime(taskStartedAt!))}'
                ' · ${l10n.aiTimelineEnded(_formatTime(endedAt))}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _SummaryChip(
                icon: Icons.autorenew_rounded,
                label: l10n.aiTimelineStatRounds(taskRounds),
                color: colors.primary,
              ),
              _SummaryChip(
                icon: Icons.terminal_rounded,
                label: l10n.aiTimelineStatCommands(results.length),
                color: colors.onSurfaceVariant,
              ),
              _SummaryChip(
                icon: Icons.check_circle_rounded,
                label: l10n.aiTimelineStatSuccess(successCount),
                color: context.sem.success,
              ),
              _SummaryChip(
                icon: Icons.error_rounded,
                label: l10n.aiTimelineStatFailed(failedCount),
                color: colors.error,
              ),
            ],
          ),
          if (range.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    range,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallback,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline nodes ──────────────────────────────────────────────────────

/// Vertical rail segment shared by all nodes.
class _RailLine extends StatelessWidget {
  const _RailLine({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 2,
      color: visible ? colors.outlineVariant : Colors.transparent,
    );
  }
}

/// One finished command on the timeline.
class _TimelineNode extends StatefulWidget {
  const _TimelineNode({
    super.key,
    required this.index,
    required this.result,
    required this.isFirst,
    required this.isLast,
  });

  final int index;
  final CommandResult result;
  final bool isFirst;
  final bool isLast;

  @override
  State<_TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<_TimelineNode> {
  bool _expanded = false;

  String _formatElapsed(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final CommandResult result = widget.result;
    final bool isSuccess = result.success;
    final Color statusColor = isSuccess ? context.sem.success : colors.error;

    final String stdout = result.stdout.trim();
    final String stderr = result.stderr.trim();
    final bool hasOutput = stdout.isNotEmpty || stderr.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Timeline rail: connecting segments + status dot.
          SizedBox(
            width: 32,
            child: Column(
              children: <Widget>[
                _RailLine(visible: !widget.isFirst),
                const SizedBox(height: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: context.text.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: _RailLine(visible: !widget.isLast)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Server badge + status / exit code + elapsed time.
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          result.serverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess
                            ? l10n.aiTimelineExitCode(result.exitCode)
                            : (result.exitCode >= 0
                                ? l10n.aiTimelineExitCode(result.exitCode)
                                : l10n.aiTimelineNoExitCode),
                        style: context.text.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.monoFont,
                          fontFamilyFallback: AppTheme.monoFallback,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatElapsed(result.elapsed),
                        style: context.text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: AppTheme.monoFont,
                          fontFamilyFallback: AppTheme.monoFallback,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Command text.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.colors.surfaceContainerLow
                          : context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: SelectableText(
                      result.command,
                      style: context.text.bodySmall?.copyWith(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: AppTheme.monoFallback,
                        height: 1.5,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  // Collapsible output block.
                  if (hasOutput)
                    _OutputBlock(
                      stdout: stdout,
                      stderr: stderr,
                      expanded: _expanded,
                      isDark: isDark,
                      onToggle: () => setState(() => _expanded = !_expanded),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible stdout/stderr viewer inside a timeline node.
class _OutputBlock extends StatelessWidget {
  const _OutputBlock({
    required this.stdout,
    required this.stderr,
    required this.expanded,
    required this.isDark,
    required this.onToggle,
  });

  final String stdout;
  final String stderr;
  final bool expanded;
  final bool isDark;
  final VoidCallback onToggle;

  static const int _collapsedLines = 4;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<String> stdoutLines =
        stdout.isEmpty ? <String>[] : stdout.split('\n');
    final bool truncated = !expanded && stdoutLines.length > _collapsedLines;
    final List<String> visibleLines = truncated
        ? stdoutLines.sublist(0, _collapsedLines)
        : stdoutLines;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Toggle header.
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.data_object_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.aiTimelineOutput,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (visibleLines.isEmpty)
                        Text(
                          l10n.aiTimelineOutputEmpty,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.55,
                            color: Color(0xFF9DA3B4),
                          ),
                        )
                      else
                        SelectableText(
                          visibleLines.join('\n'),
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: AppTheme.monoFallback,
                            fontSize: 12,
                            height: 1.55,
                            color: Color(0xFFD4D4D4),
                          ),
                        ),
                      if (truncated)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '… +${stdoutLines.length - _collapsedLines}',
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontFamilyFallback: AppTheme.monoFallback,
                              fontSize: 11,
                              color: Color(0xFF9DA3B4),
                            ),
                          ),
                        ),
                      if (stderr.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline_rounded,
                              size: 12,
                              color: colors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.aiTimelineErrorOutput,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          stderr,
                          maxLines: expanded ? null : 4,
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: AppTheme.monoFallback,
                            fontSize: 12,
                            height: 1.55,
                            color: colors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Live placeholder appended while the agent is executing a new command.
class _RunningNode extends StatelessWidget {
  const _RunningNode();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Column(
              children: <Widget>[
                const _RailLine(visible: true),
                const SizedBox(height: 6),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Expanded(child: _RailLine(visible: false)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.aiTimelineRunning,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────

class _TimelineEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.timeline_rounded,
                size: 26,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiTimelineEmpty,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aiTimelineEmptyHint,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
