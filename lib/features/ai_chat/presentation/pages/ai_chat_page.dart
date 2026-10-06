import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/agent_controller.dart';
import '../../domain/entities/ai_chat_extra.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../mixins/ai_chat_page_actions.dart';
import '../providers/chat_providers.dart';
import '../widgets/agent_bar.dart';
import '../widgets/api_key_setup_guide.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_error_strip.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_transcript.dart';
import '../widgets/welcome_transcript.dart';

/// The AI assistant chat surface.
///
/// Three zones stacked vertically: a status header, a reversed transcript
/// (newest pinned to the bottom), and a composer. Streaming replies render
/// live via `MessageBubble` → `StreamingText`, and the whole screen degrades
/// gracefully to a setup guide when no API key is present.
///
/// Structure: this file keeps only widget lifecycle + composition; all
/// imperative actions live in [AiChatPageActions] and every visual zone is a
/// widget under `presentation/widgets/`.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key, this.extra});

  /// Optional navigation payload (e.g. from the terminal's "Ask AI" entry).
  final AiChatExtra? extra;

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage>
    with AiChatPageActions {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  bool _canSend = false;

  // ─── AiChatPageActions accessors ─────────────────────────────────────────

  @override
  TextEditingController get inputController => _input;

  @override
  FocusNode get composerFocus => _focus;

  @override
  ScrollController get scrollController => _scroll;

  @override
  WidgetRef get actionsRef => ref;

  @override
  bool get canSendNow => _canSend;

  @override
  void setCanSend(bool value) {
    if (mounted) setState(() => _canSend = value);
  }

  @override
  void scrollToBottom() {
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

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _input.addListener(onInputChanged);
    applyExtra(widget.extra);
    // Restore the persisted transcript on first entry (idempotent — the
    // notifier guards against duplicate restores and skips while streaming).
    // Once history lands, the reversed ListView must be re-pinned to offset 0
    // (the newest message) — restoring rows below the viewport otherwise
    // leaves the list scrolled into a blank stretch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(chatMessagesProvider.notifier)
          .restoreFromHistory(ref.read(chatHistoryStoreProvider))
          .whenComplete(() {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
        });
      });
    });
  }

  @override
  void dispose() {
    _input.removeListener(onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Narrow reads: header / composer / agent-bar watch only the scalar flags
    // they consume, so a streamed token — which mutates `messages` alone — no
    // longer rebuilds them. The transcript body watches `messages` itself via
    // `_ChatBody`, so only that subtree re-lays out per token.
    final bool isStreaming =
        ref.watch(chatMessagesProvider.select((ChatState s) => s.isStreaming));
    final bool hasMessages = ref.watch(
        chatMessagesProvider.select((ChatState s) => s.messages.isNotEmpty));
    final AppFailure? failure =
        ref.watch(chatMessagesProvider.select((ChatState s) => s.failure));
    final AsyncValue<bool> keyStatus = ref.watch(apiKeyConfiguredProvider);
    final bool hasKey = keyStatus.value ?? false;
    final AiProvider provider = ref.watch(selectedProviderProvider);
    final AgentState agent = ref.watch(agentControllerProvider);

    // When a streamed assistant reply finishes, hand its content to the agent
    // so the auto-loop can pick up any command blocks it contains. A reply
    // that immediately follows tool results is a *continuation* — it must
    // never re-arm the loop, so a user stop survives in-flight continuations
    // and confirmed-execution follow-ups stay non-automatic.
    ref.listen<ChatState>(chatMessagesProvider, (ChatState? prev, ChatState next) {
      if (prev != null && prev.isStreaming && !next.isStreaming) {
        String lastAssistant = '';
        bool isContinuation = false;
        final List<ChatMessage> reversed = next.messages.reversed.toList();
        for (int i = 0; i < reversed.length; i++) {
          final ChatMessage m = reversed[i];
          if (m.role == MessageRole.assistant && m.content.trim().isNotEmpty) {
            lastAssistant = m.content;
            isContinuation = i + 1 < reversed.length &&
                reversed[i + 1].role == MessageRole.tool;
            break;
          }
        }
        if (lastAssistant.isNotEmpty) {
          ref
              .read(agentControllerProvider.notifier)
              .onAssistantResponseComplete(lastAssistant, isContinuation: isContinuation);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChatHeader(
              isStreaming: isStreaming,
              hasKey: hasKey,
              canClear: hasMessages,
              canExport: hasMessages,
              onClear: clearChat,
              onExport: exportChat,
              onManageServers: openServerManager,
            ),
            Expanded(
              child: _ChatBody(
                scrollController: _scroll,
                provider: provider,
                onExecuteCode: handleExecuteCode,
                onAnalyzeTool: handleAnalyzeTool,
                onSuggestion: useSuggestion,
                onOpenSettings: openSettings,
              ),
            ),
            if (failure != null)
              ChatErrorStrip(
                failure: failure,
                onDismiss: () =>
                    ref.read(chatMessagesProvider.notifier).dismissError(),
              ),
            AgentBar(
              state: agent,
              onStopAutoMode: () =>
                  ref.read(agentControllerProvider.notifier).stopAutoMode(),
              onOpenTimeline: openTimeline,
            ),
            ChatComposer(
              controller: _input,
              focusNode: _focus,
              enabled: hasKey,
              isStreaming: isStreaming,
              canSend: _canSend && hasKey,
              onSend: submit,
              onStop: stopStreaming,
              onPickSnippet: openSnippetPicker,
            ),
          ],
        ),
      ),
    );
  }
}

/// The chat body zone: setup guide, welcome transcript, or live transcript.
///
/// A standalone [ConsumerWidget] so it watches [apiKeyConfiguredProvider] and
/// the message list itself. During streaming, only this subtree rebuilds per
/// token — the header, agent bar, and composer above/below stay untouched.
class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.scrollController,
    required this.provider,
    required this.onExecuteCode,
    required this.onAnalyzeTool,
    required this.onSuggestion,
    required this.onOpenSettings,
  });

  final ScrollController scrollController;
  final AiProvider provider;
  final void Function(String code, String language) onExecuteCode;
  final VoidCallback onAnalyzeTool;
  final void Function(String prompt) onSuggestion;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> keyStatus = ref.watch(apiKeyConfiguredProvider);
    final List<ChatMessage> messages = ref.watch(
        chatMessagesProvider.select((ChatState s) => s.messages));

    return keyStatus.when(
      loading: () => Center(
        child: AppLoader(
            label: AppLocalizations.of(context).aiChatCheckingCredentials),
      ),
      error: (Object _, StackTrace _) => ApiKeySetupGuide(
        providerName: provider.name,
        onOpenSettings: onOpenSettings,
      ),
      data: (bool configured) {
        if (!configured) {
          return ApiKeySetupGuide(
            providerName: provider.name,
            onOpenSettings: onOpenSettings,
          );
        }
        if (messages.isEmpty) {
          return WelcomeTranscript(onSuggestion: onSuggestion);
        }
        return ChatTranscript(
          messages: messages,
          controller: scrollController,
          onExecuteCode: onExecuteCode,
          onAnalyzeTool: onAnalyzeTool,
        );
      },
    );
  }
}
