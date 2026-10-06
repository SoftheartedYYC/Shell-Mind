import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/agent_controller.dart';
import '../../../../shared/ssh/ssh_command_executor.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../../shared/ssh/terminal_context_provider.dart';
import '../../domain/chat_exporter.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/ai_chat_extra.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../../../settings/presentation/providers/ai_settings_provider.dart';
import '../widgets/command_confirm_dialog.dart';
import '../widgets/message_bubble.dart';
import '../widgets/server_selector_sheet.dart';
import '../../../command_snippets/domain/entities/command_snippet.dart';
import '../../../command_snippets/presentation/widgets/snippet_picker_sheet.dart';
import '../widgets/agent_timeline_sheet.dart';

/// The AI assistant chat surface.
///
/// Three zones stacked vertically: a status header, a reversed transcript
/// (newest pinned to the bottom), and a composer. Streaming replies render
/// live via [MessageBubble] → `StreamingText`, and the whole screen degrades
/// gracefully to a setup guide when no API key is present.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key, this.extra});

  /// Optional navigation payload (e.g. from the terminal's "Ask AI" entry).
  final AiChatExtra? extra;

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    _applyExtra(widget.extra);
    // Restore the persisted transcript on first entry (idempotent — the
    // notifier guards against duplicate restores and skips while streaming).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(chatMessagesProvider.notifier)
          .restoreFromHistory(ref.read(chatHistoryStoreProvider));
    });
  }

  /// Consumes an inbound [AiChatExtra]: pre-fills the composer with a terminal
  /// selection and, when requested, attaches the live terminal context for the
  /// originating server.
  void _applyExtra(AiChatExtra? extra) {
    if (extra == null) return;
    final String? query = extra.initialQuery;
    if (query != null && query.trim().isNotEmpty) {
      _input.text = query;
      _canSend = true;
    }
    if (extra.serverId != null || extra.attachedTerminalContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final TerminalContextController ctx =
            ref.read(terminalContextProvider.notifier);
        if (extra.serverId != null) ctx.setServer(extra.serverId);
        if (extra.attachedTerminalContext) ctx.setEnabled(true);
      });
    }
  }

  void _onInputChanged() {
    final bool next = _input.text.trim().isNotEmpty;
    if (next != _canSend) setState(() => _canSend = next);
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    final ChatNotifier notifier = ref.read(chatMessagesProvider.notifier);
    if (ref.read(chatMessagesProvider).isStreaming) return;

    // Attach terminal context when enabled.
    final TerminalContextController ctxCtrl =
        ref.read(terminalContextProvider.notifier);
    final TerminalContextState ctxState = ref.read(terminalContextProvider);
    String messageToSend = text;
    if (ctxState.isEnabled) {
      final String? raw = ctxCtrl.getTerminalContext();
      final String? formatted = ctxCtrl.formatContext(raw, ctxCtrl.currentServerName);
      if (formatted != null) {
        messageToSend = '$formatted\n\n$text';
      }
    }

    notifier.sendMessage(messageToSend);
    _input.clear();
    _scrollToBottom();
  }

  void _stop() {
    ref.read(chatMessagesProvider.notifier).stopStreaming();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clear() {
    ref.read(chatMessagesProvider.notifier).clearChat();
    setState(() => _canSend = _input.text.trim().isNotEmpty);
  }

  void _useSuggestion(String prompt) {
    _input.text = prompt;
    _onInputChanged();
    _focus.unfocus();
    _submit();
  }

  /// Opens the snippet picker; the chosen command is inserted into the
  /// composer (appended on a new line when the input already holds text).
  Future<void> _openSnippetPicker() async {
    _focus.unfocus();
    final CommandSnippet? snippet = await SnippetPickerSheet.show(context);
    if (!mounted || snippet == null) return;
    final String current = _input.text;
    _input.text = current.isEmpty
        ? snippet.command
        : '$current\n${snippet.command}';
    _input.selection = TextSelection.collapsed(
      offset: _input.text.length,
    );
    _onInputChanged();
    _focus.requestFocus();
  }

  /// Opens the in-chat connection manager so the user can bring servers
  /// online (or drop them) without leaving the assistant.
  Future<void> _openServerManager() async {
    _focus.unfocus();
    await ServerSelectorSheet.show(context, manage: true);
  }

  /// Opens the agent execution timeline sheet (live-updating).
  Future<void> _openTimeline() async {
    _focus.unfocus();
    await AgentTimelineSheet.show(context);
  }

  /// Exports the transcript to Markdown.
  ///
  /// Renders via the pure [ChatExporter], writes to the app documents
  /// directory (`exports/`), and surfaces the absolute path in a SnackBar.
  /// Guarded against empty transcripts and streaming turns (a half-received
  /// reply would freeze a truncated snapshot into the file).
  Future<void> _exportChat() async {
    final ChatState chat = ref.read(chatMessagesProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (chat.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportChatEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (chat.isStreaming) {
      ref.read(chatMessagesProvider.notifier).stopStreaming();
    }

    final DateTime now = DateTime.now();
    final String markdown = ChatExporter.export(chat.messages, exportedAt: now);
    final String fileName = 'shell-mind-chat-${ChatExporter.fileStamp(now)}.md';

    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final Directory exportDir = Directory(
        '${dir.path}${Platform.pathSeparator}exports',
      );
      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }
      final File file = File(
        '${exportDir.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsString(markdown, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportChatSuccess(file.path)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportChatFailed(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handles the "run on server" action for an executable code block.
  ///
  /// Flow: pick target server(s) → confirm → hand off to [AgentController].
  Future<void> _handleExecuteCode(String code, String language) async {
    final Map<String, RegisteredSession> registry =
        ref.read(sshSessionRegistryProvider);
    if (registry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).aiChatNoConnection),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Choose target server(s).
    List<String> serverIds;
    if (registry.length > 1) {
      final List<String>? selected =
          await ServerSelectorSheet.show(context, multiSelect: true);
      if (selected == null || selected.isEmpty) return;
      serverIds = selected;
    } else {
      serverIds = <String>[registry.keys.first];
    }
    if (!mounted) return;

    // 2. Confirm (with a danger warning when applicable).
    final bool isDangerous = SshCommandExecutor.isDangerous(code);
    final List<String> serverNames = serverIds
        .map((String id) => registry[id]?.serverName ?? id)
        .toList();
    final bool confirmed = await CommandConfirmDialog.show(
      context,
      command: code,
      serverNames: serverNames,
      isDangerous: isDangerous,
    );
    if (!confirmed || !mounted) return;

    // 3. Execute via the agent controller (also feeds results back to the AI).
    _focus.unfocus();
    await ref
        .read(agentControllerProvider.notifier)
        .executeConfirmed(command: code, serverIds: serverIds);
    _scrollToBottom();
  }

  /// Asks the AI to analyze the most recent tool output.
  void _handleAnalyzeTool() {
    final ChatNotifier notifier = ref.read(chatMessagesProvider.notifier);
    if (ref.read(chatMessagesProvider).isStreaming) return;
    notifier.sendMessage(AppLocalizations.of(context).aiChatAnalyzePrompt);
    _scrollToBottom();
  }

  /// Toggles the hands-off auto-execution loop.
  ///
  /// The controller may reject the start request when the settings master
  /// switch is off — the returned flag is ignored here because the agent bar
  /// keeps the toggle disabled/hidden in that situation anyway.
  void _toggleAutoMode() {
    final AgentController controller = ref.read(agentControllerProvider.notifier);
    if (ref.read(agentControllerProvider).isAutoMode) {
      controller.stopAutoMode();
    } else {
      controller.startAutoMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatState chat = ref.watch(chatMessagesProvider);
    final AsyncValue<bool> keyStatus = ref.watch(apiKeyConfiguredProvider);
    final bool hasKey = keyStatus.value ?? false;
    final AiProvider provider = ref.watch(selectedProviderProvider);
    final AgentState agent = ref.watch(agentControllerProvider);
    // Master gate: the settings "auto-execute commands" switch. The bar is a
    // pure renderer — the state flows in, no decisions are made here.
    final bool autoExecuteEnabled = ref.watch(aiSettingsProvider).aiAutoExecute;

    // When a streamed assistant reply finishes, hand its content to the agent
    // so the auto-loop can pick up any command blocks it contains.
    ref.listen<ChatState>(chatMessagesProvider, (ChatState? prev, ChatState next) {
      if (prev != null && prev.isStreaming && !next.isStreaming) {
        String lastAssistant = '';
        for (final ChatMessage m in next.messages.reversed) {
          if (m.role == MessageRole.assistant && m.content.trim().isNotEmpty) {
            lastAssistant = m.content;
            break;
          }
        }
        if (lastAssistant.isNotEmpty) {
          ref
              .read(agentControllerProvider.notifier)
              .onAssistantResponseComplete(lastAssistant);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ChatHeader(
              isStreaming: chat.isStreaming,
              hasKey: hasKey,
              canClear: chat.messages.isNotEmpty,
              canExport: chat.messages.isNotEmpty,
              onClear: _clear,
              onExport: _exportChat,
              onManageServers: _openServerManager,
            ),
            Expanded(
              child: keyStatus.when(
                loading: () => Center(
                  child: AppLoader(
                      label: AppLocalizations.of(context)
                          .aiChatCheckingCredentials),
                ),
                error: (Object _, StackTrace _) => _ApiKeySetupGuide(
                  providerName: provider.name,
                  onOpenSettings: _openSettings,
                ),
                data: (bool configured) {
                  if (!configured) {
                    return _ApiKeySetupGuide(
                      providerName: provider.name,
                      onOpenSettings: _openSettings,
                    );
                  }
                  if (chat.messages.isEmpty) {
                    return _WelcomeTranscript(onSuggestion: _useSuggestion);
                  }
                  return _Transcript(
                    messages: chat.messages,
                    controller: _scroll,
                    onExecuteCode: _handleExecuteCode,
                    onAnalyzeTool: _handleAnalyzeTool,
                  );
                },
              ),
            ),
            if (chat.failure != null)
              _ErrorStrip(
                failure: chat.failure!,
                onDismiss: () =>
                    ref.read(chatMessagesProvider.notifier).dismissError(),
              ),
            _AgentBar(
              state: agent,
              autoExecuteEnabled: autoExecuteEnabled,
              onToggleAutoMode: _toggleAutoMode,
              onOpenTimeline: _openTimeline,
            ),
            _Composer(
              controller: _input,
              focusNode: _focus,
              enabled: hasKey,
              isStreaming: chat.isStreaming,
              canSend: _canSend && hasKey,
              onSend: _submit,
              onStop: _stop,
              onPickSnippet: _openSnippetPicker,
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    _focus.unfocus();
    context.goNamed(RouteNames.settings);
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends ConsumerWidget {
  const _ChatHeader({
    required this.isStreaming,
    required this.hasKey,
    required this.canClear,
    required this.canExport,
    required this.onClear,
    required this.onExport,
    required this.onManageServers,
  });

  final bool isStreaming;
  final bool hasKey;
  final bool canClear;

  /// True when the transcript is non-empty — the export action is disabled
  /// for an empty conversation (nothing to write).
  final bool canExport;
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback onManageServers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AiProvider provider = ref.watch(selectedProviderProvider);
    final AiModel model = ref.watch(selectedModelProvider);

    final (String label, Color color, bool pulse) = !hasKey
        ? (l10n.aiChatStatusSetup, context.sem.warning, false)
        : isStreaming
            ? (l10n.aiChatStatusStreaming, colors.primary, true)
            : (l10n.aiChatStatusReady, context.sem.success, false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.aiChatTitle,
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    _ProviderBadge(name: provider.name),
                    const SizedBox(width: 6),
                    Flexible(child: _ModelBadge(model: model.name)),
                  ],
                ),
              ],
            ),
          ),
          StatusPill(label: label, color: color, pulse: pulse),
          // Export transcript to Markdown (disabled on an empty transcript).
          IconButton(
            onPressed: canExport ? onExport : null,
            tooltip: l10n.exportChatAction,
            icon: Icon(
              Icons.ios_share_rounded,
              size: 22,
              color: canExport ? colors.onSurfaceVariant : colors.outline,
            ),
          ),
          IconButton(
            onPressed: onManageServers,
            tooltip: l10n.aiServerManageTitle,
            icon: Icon(Icons.dns_outlined,
                size: 22, color: colors.onSurfaceVariant),
          ),
          if (canClear)
            IconButton(
              onPressed: onClear,
              tooltip: l10n.aiChatClearConversation,
              icon: Icon(Icons.delete_sweep_outlined,
                  size: 22, color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.2,
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  const _ModelBadge({required this.model});
  final String model;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        model,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTheme.monoFont,
          fontFamilyFallback: AppTheme.monoFallback,
          fontSize: 11,
          letterSpacing: 0.3,
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Transcript ─────────────────────────────────────────────────────────

class _Transcript extends StatelessWidget {
  const _Transcript({
    required this.messages,
    required this.controller,
    this.onExecuteCode,
    this.onAnalyzeTool,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final void Function(String code, String language)? onExecuteCode;
  final VoidCallback? onAnalyzeTool;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        // reverse: index 0 is the newest (bottom-most) message.
        final ChatMessage message = messages[messages.length - 1 - index];
        // Only offer code execution on finished assistant turns.
        final bool canExecute = message.role == MessageRole.assistant &&
            !message.isStreaming;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MessageBubble(
            key: ValueKey<String>(message.id),
            message: message,
            onExecuteCode: canExecute ? onExecuteCode : null,
            onAnalyzeTool: onAnalyzeTool,
          ),
        );
      },
    );
  }
}

// ─── Welcome / empty transcript ─────────────────────────────────────────

class _WelcomeTranscript extends StatelessWidget {
  const _WelcomeTranscript({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> suggestions = <String>[
      l10n.aiChatSuggestion1,
      l10n.aiChatSuggestion2,
      l10n.aiChatSuggestion3,
      l10n.aiChatSuggestion4,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      children: <Widget>[
        const _IntroCard(),
        const SizedBox(height: 24),
        SectionHeader(
            label: l10n.aiChatTryAsking, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        for (final String s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SuggestionTile(
              label: s,
              onTap: () => onSuggestion(s),
            ),
          ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.smart_toy_outlined,
                  size: 22, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiChatIntroTitle,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiChatIntroBody,
              style: context.text.bodyMedium?.copyWith(
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

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(Icons.arrow_outward_rounded,
                  size: 16, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── API key setup guide ────────────────────────────────────────────────

class _ApiKeySetupGuide extends StatelessWidget {
  const _ApiKeySetupGuide({required this.onOpenSettings, this.providerName});

  final VoidCallback onOpenSettings;
  final String? providerName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.sem.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.key_rounded,
                    size: 28, color: context.sem.warning),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.aiChatNoKeyTitle,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.aiChatNoKeyMessage(
                    providerName ?? l10n.settingsSectionAiProvider),
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(l10n.aiChatOpenSettings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error strip ────────────────────────────────────────────────────────

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.failure, required this.onDismiss});

  final AppFailure failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ErrorBanner(failure: failure, onDismiss: onDismiss, dense: true),
    );
  }
}

// ─── Agent status bar ─────────────────────────────────────────────────────

/// Slim bar above the composer surfacing the [AgentController] state: an
/// auto-mode toggle, a live execution indicator, and loop progress.
class _AgentBar extends StatelessWidget {
  const _AgentBar({
    required this.state,
    required this.autoExecuteEnabled,
    required this.onToggleAutoMode,
    required this.onOpenTimeline,
  });

  final AgentState state;

  /// Settings master switch ("auto-execute commands"). When off the session
  /// toggle is rendered as an inert, dimmed chip with an explanatory hint —
  /// and the running-mode affordances are hidden entirely, since the gate
  /// rejects any start request at the controller level.
  final bool autoExecuteEnabled;
  final VoidCallback onToggleAutoMode;
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
          // Auto-mode toggle. Master switch off → disabled + hint tooltip.
          Tooltip(
            message: autoExecuteEnabled ? '' : l10n.aiAgentAutoModeDisabledHint,
            triggerMode: TooltipTriggerMode.longPress,
            child: InkWell(
              onTap: autoExecuteEnabled ? onToggleAutoMode : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      state.isAutoMode
                          ? Icons.autorenew_rounded
                          : Icons.bolt_outlined,
                      size: 16,
                      color: !autoExecuteEnabled
                          ? colors.onSurfaceVariant.withValues(alpha: 0.4)
                          : state.isAutoMode
                              ? colors.primary
                              : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !autoExecuteEnabled
                          ? l10n.aiAgentAutoModeDisabledHint
                          : state.isAutoMode
                              ? l10n.aiAgentAutoModeOn
                              : l10n.aiAgentAutoModeOff,
                      style: context.text.labelMedium?.copyWith(
                        color: !autoExecuteEnabled
                            ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                            : state.isAutoMode
                                ? colors.primary
                                : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                          state.errorMessage!,
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
          // Loop progress + stop button while auto mode is on. Stopping is
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
              onPressed: onToggleAutoMode,
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

// ─── Composer ─────────────────────────────────────────────────────────────

class _Composer extends ConsumerWidget {
  const _Composer({
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
