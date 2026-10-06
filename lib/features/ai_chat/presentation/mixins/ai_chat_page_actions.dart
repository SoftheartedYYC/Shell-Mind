import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/agent_controller.dart';
import '../../../../shared/ssh/ssh_command_executor.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../../shared/ssh/terminal_context_provider.dart';
import '../../../command_snippets/domain/entities/command_snippet.dart';
import '../../../command_snippets/presentation/widgets/snippet_picker_sheet.dart';
import '../../domain/chat_exporter.dart';
import '../../domain/entities/ai_chat_extra.dart';
import '../providers/chat_providers.dart';
import '../widgets/agent_timeline_sheet.dart';
import '../widgets/command_confirm_dialog.dart';
import '../widgets/server_selector_sheet.dart';
import '../widgets/sessions_sheet.dart';

/// Mixin carrying all imperative actions of the AI chat page: composer
/// wiring, sheet/dialog launching, transcript export, and the code-block
/// execution flow.
///
/// The host [State] implements the accessors so the mixin stays decoupled
/// from the concrete widget (no `on<AiChatPage>` bound, keeps `mixin` usable
/// both by the page and by tests that stub the accessors).
mixin AiChatPageActions<T extends StatefulWidget> on State<T> {
  /// Composer text controller (owned by the page state).
  TextEditingController get inputController;

  /// Composer focus node (owned by the page state).
  FocusNode get composerFocus;

  /// Bottom-repinning scroll controller (owned by the page state).
  ScrollController get scrollController;

  /// Container read access — resolves providers for the actions.
  WidgetRef get actionsRef;

  /// Marks the composer sendability from the raw input text.
  void setCanSend(bool value);

  /// Current sendability flag (mirrored by the page state).
  bool get canSendNow;

  /// Schedules the reversed-list re-pin animation to the newest message.
  void scrollToBottom();

  // ─── Composer wiring ────────────────────────────────────────────────────

  /// Consumes an inbound [AiChatExtra]: pre-fills the composer with a terminal
  /// selection and, when requested, attaches the live terminal context for the
  /// originating server.
  void applyExtra(AiChatExtra? extra) {
    if (extra == null) return;
    final String? query = extra.initialQuery;
    if (query != null && query.trim().isNotEmpty) {
      inputController.text = query;
      setCanSend(true);
    }
    if (extra.serverId != null || extra.attachedTerminalContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final TerminalContextController ctx =
            actionsRef.read(terminalContextProvider.notifier);
        if (extra.serverId != null) ctx.setServer(extra.serverId);
        if (extra.attachedTerminalContext) ctx.setEnabled(true);
      });
    }
  }

  void onInputChanged() {
    final bool next = inputController.text.trim().isNotEmpty;
    if (next != canSendNow) setCanSend(next);
  }

  // ─── Sending / clearing ────────────────────────────────────────────────

  void submit() {
    final String text = inputController.text.trim();
    if (text.isEmpty) return;
    final ChatNotifier notifier = actionsRef.read(chatMessagesProvider.notifier);
    if (actionsRef.read(chatMessagesProvider).isStreaming) return;

    // Attach terminal context when enabled.
    final TerminalContextController ctxCtrl =
        actionsRef.read(terminalContextProvider.notifier);
    final TerminalContextState ctxState =
        actionsRef.read(terminalContextProvider);
    String messageToSend = text;
    if (ctxState.isEnabled) {
      final String? raw = ctxCtrl.getTerminalContext();
      final String? formatted =
          ctxCtrl.formatContext(raw, ctxCtrl.currentServerName);
      if (formatted != null) {
        messageToSend = '$formatted\n\n$text';
      }
    }

    notifier.sendMessage(messageToSend);
    inputController.clear();
    scrollToBottom();
  }

  void stopStreaming() {
    actionsRef.read(chatMessagesProvider.notifier).stopStreaming();
  }

  void clearChat() {
    actionsRef.read(chatMessagesProvider.notifier).clearChat();
    setCanSend(inputController.text.trim().isNotEmpty);
  }

  void useSuggestion(String prompt) {
    inputController.text = prompt;
    onInputChanged();
    composerFocus.unfocus();
    submit();
  }

  // ─── Sheets & dialogs ──────────────────────────────────────────────────

  /// Opens the snippet picker; the chosen command is inserted into the
  /// composer (appended on a new line when the input already holds text).
  Future<void> openSnippetPicker() async {
    composerFocus.unfocus();
    final CommandSnippet? snippet = await SnippetPickerSheet.show(context);
    if (!mounted || snippet == null) return;
    final String current = inputController.text;
    inputController.text = current.isEmpty
        ? snippet.command
        : '$current\n${snippet.command}';
    inputController.selection = TextSelection.collapsed(
      offset: inputController.text.length,
    );
    onInputChanged();
    composerFocus.requestFocus();
  }

  /// Opens the in-chat connection manager so the user can bring servers
  /// online (or drop them) without leaving the assistant.
  Future<void> openServerManager() async {
    composerFocus.unfocus();
    await ServerSelectorSheet.show(context, manage: true);
  }

  /// Opens the agent execution timeline sheet (live-updating).
  Future<void> openTimeline() async {
    composerFocus.unfocus();
    await AgentTimelineSheet.show(context);
  }

  /// Opens the multi-session manager (search / switch / rename / delete).
  Future<void> openSessions() async {
    composerFocus.unfocus();
    await SessionsSheet.show(context);
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Exports the transcript to Markdown.
  ///
  /// Renders via the pure [ChatExporter], writes to the app documents
  /// directory (`exports/`), and surfaces the absolute path in a SnackBar.
  /// Guarded against empty transcripts and streaming turns (a half-received
  /// reply would freeze a truncated snapshot into the file).
  Future<void> exportChat() async {
    final ChatState chat = actionsRef.read(chatMessagesProvider);
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
      actionsRef.read(chatMessagesProvider.notifier).stopStreaming();
    }

    final DateTime now = DateTime.now();
    final String markdown = ChatExporter.export(
      chat.messages,
      l10n: l10n,
      exportedAt: now,
    );
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

  // ─── Code-block execution flow ─────────────────────────────────────────

  /// Handles the "run on server" action for an executable code block.
  ///
  /// Flow: pick target server(s) → confirm → hand off to [AgentController].
  Future<void> handleExecuteCode(String code, String language) async {
    final Map<String, RegisteredSession> registry =
        actionsRef.read(sshSessionRegistryProvider);
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
    composerFocus.unfocus();
    await actionsRef
        .read(agentControllerProvider.notifier)
        .executeConfirmed(command: code, serverIds: serverIds);
    scrollToBottom();
  }

  /// Asks the AI to analyze the most recent tool output.
  void handleAnalyzeTool() {
    final ChatNotifier notifier = actionsRef.read(chatMessagesProvider.notifier);
    if (actionsRef.read(chatMessagesProvider).isStreaming) return;
    notifier.sendMessage(AppLocalizations.of(context).aiChatAnalyzePrompt);
    scrollToBottom();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────

  void openSettings() {
    composerFocus.unfocus();
    context.goNamed(RouteNames.settings);
  }
}
