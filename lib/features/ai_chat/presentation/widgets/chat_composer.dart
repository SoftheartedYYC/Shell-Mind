import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/terminal_context_provider.dart';

// ─── Composer ─────────────────────────────────────────────────────────────

/// Bottom composer: terminal-context toggle, snippet picker chip, the input
/// field and the send/stop button.
class ChatComposer extends ConsumerWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isStreaming,
    required this.canSend,
    required this.onSend,
    required this.onStop,
    this.onPickSnippet,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isStreaming;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  /// When non-null, a snippet-picker chip is shown to the left of the input;
  /// tapping it opens the saved-command sheet.
  final VoidCallback? onPickSnippet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TerminalContextState ctxState = ref.watch(terminalContextProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Input row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // Terminal context toggle.
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: IconButton(
                  onPressed: enabled
                      ? () => ref
                          .read(terminalContextProvider.notifier)
                          .toggleContext()
                      : null,
                  tooltip: ctxState.isEnabled
                      ? AppLocalizations.of(context).aiContextToggleDetach
                      : AppLocalizations.of(context).aiContextToggleAttach,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    ctxState.isEnabled ? Icons.link : Icons.link_off,
                    size: 20,
                    color: ctxState.isEnabled
                        ? colors.primary
                        : colors.outline,
                  ),
                ),
              ),
              // Saved command snippets (chat composer entry).
              if (onPickSnippet != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 4),
                  child: IconButton(
                    onPressed: enabled ? onPickSnippet : null,
                    tooltip: AppLocalizations.of(context).snippetsTitle,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 44, maxHeight: 140),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: enabled
                          ? AppLocalizations.of(context).aiChatInputHint
                          : AppLocalizations.of(context).aiChatInputDisabled,
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              isStreaming
                  ? _StopButton(onTap: onStop)
                  : _SendButton(enabled: canSend, onTap: onSend),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: enabled ? colors.primary : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 20,
              color: enabled ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(Icons.stop_rounded, size: 20, color: colors.error),
          ),
        ),
      ),
    );
  }
}
