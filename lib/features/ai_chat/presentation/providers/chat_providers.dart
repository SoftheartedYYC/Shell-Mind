import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/ai_service.dart';
import '../../data/chat_history_store.dart';
import '../../data/chat_repository_impl.dart';
import '../../data/custom_ai_provider_store.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../shared/ssh/ssh_command_executor.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';

// ─── Provider / model selection ─────────────────────────────────────────

/// The provider the user picked in Settings. Non-autoDispose: [PreferencesService]
/// is a silent singleton, so this is recomputed only when a settings change
/// explicitly invalidates it (see `ai_settings_provider.dart`).
///
/// Resolves against built-ins first, then user-defined custom providers. When
/// the stored id names a custom provider that was deleted, it falls back to
/// the default built-in so a stale preference never breaks the request.
final Provider<AiProvider> selectedProviderProvider = Provider<AiProvider>((Ref ref) {
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return providerFromId(
    prefs.selectedProviderId,
    ref.watch(customAiProvidersProvider),
  );
});

/// Mirrors [CustomAiProviderStore] so Riverpod consumers rebuild when a
/// custom provider is added/updated/deleted. Re-derives from the store's
/// snapshot on every read; mutations notify dependents by invalidating
/// [customAiProvidersProvider] (see `AiSettingsController`).
final Provider<List<AiProvider>> customAiProvidersProvider =
    Provider<List<AiProvider>>((Ref ref) {
  final CustomAiProviderStore store = ref.watch(customAiProviderStoreProvider);
  return store.all
      .map((CustomAiProvider c) => AiProvider(
            id: c.id,
            name: c.name,
            baseUrl: c.baseUrl,
            models: c.defaultModelId == null
                ? const <AiModel>[]
                : <AiModel>[
                    AiModel(id: c.defaultModelId!, name: c.defaultModelId!),
                  ],
            isCustom: true,
          ))
      .toList(growable: false);
});

/// Injected dependency for [customAiProvidersProvider] — overridable in tests.
final Provider<CustomAiProviderStore> customAiProviderStoreProvider =
    Provider<CustomAiProviderStore>((Ref ref) => CustomAiProviderStore.instance);

/// Resolves a provider id against built-ins and then [customProviders]
/// (user-defined, in display order). Falls back to the default built-in when
/// neither list matches — e.g. a stale preference pointing at a deleted
/// custom provider. Exposed as a pure function so settings controllers can
/// resolve ids outside a provider build (they pass in the mirrored list).
AiProvider providerFromId(String id, List<AiProvider> customProviders) {
  for (final AiProvider p in AiProviders.all) {
    if (p.id == id) return p;
  }
  for (final AiProvider p in customProviders) {
    if (p.id == id) return p;
  }
  return AiProviders.openai;
}

/// The model chosen for the current provider.
///
/// Resolved against the built-in catalogue first (for a friendly display
/// name); a stored id that isn't built-in (fetched from `/models` or manually
/// added) is kept as-is instead of falling back to the provider default.
final Provider<AiModel> selectedModelProvider = Provider<AiModel>((Ref ref) {
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  final AiProvider provider = ref.watch(selectedProviderProvider);
  final String? stored = prefs.getSelectedModel(provider.id);
  return resolveStoredModel(provider, stored);
});

/// Resolves a stored model id against [provider].
///
/// [AiProvider.modelById] falls back to [defaultModel] for unknown ids, so a
/// plain lookup would silently discard custom/fetched models (e.g.
/// `deepseek-flash`). We therefore compare the lookup result's id with the
/// stored id: a match means it's built-in (keep the friendly name), a
/// mismatch means it's custom — construct an [AiModel] from the id itself.
AiModel resolveStoredModel(AiProvider provider, String? storedId) {
  if (storedId == null || storedId.isEmpty) return provider.defaultModel;
  final AiModel builtin = provider.modelById(storedId);
  if (builtin.id == storedId) return builtin;
  return AiModel(id: storedId, name: storedId);
}

/// The API key for the current provider (async — secure storage). `null` when
/// unconfigured. Invalidated whenever a key is saved/cleared.
final FutureProvider<String?> apiKeyProvider = FutureProvider<String?>((Ref ref) async {
  final SecureStorageService secure = ref.watch(secureStorageServiceProvider);
  final AiProvider provider = ref.watch(selectedProviderProvider);
  return secure.getProviderApiKey(provider.id);
});

// ─── Service / repository wiring ────────────────────────────────────────

/// Builds the [AiService] for the currently selected provider + credential.
/// Rebuilds whenever the provider, model, key, or temperature changes.
final Provider<AiService> aiServiceProvider = Provider<AiService>((Ref ref) {
  final DioClient client = ref.watch(dioClientProvider);
  final AiProvider provider = ref.watch(selectedProviderProvider);
  final AiModel model = ref.watch(selectedModelProvider);
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  final String apiKey = ref.watch(apiKeyProvider).value ?? '';
  return AiService(
    client: client,
    provider: provider,
    apiKey: apiKey,
    model: model.id,
    temperature: prefs.aiTemperature,
  );
});

/// Concrete [ChatRepository] used across the feature.
///
/// Injects a live callback that resolves the currently connected servers from
/// [sshSessionRegistryProvider], so every AI request carries an up-to-date
/// server roster in its system prompt.
final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((Ref ref) {
  return ChatRepositoryImpl(
    ref.watch(aiServiceProvider),
    activeServersGetter: () {
      final Map<String, RegisteredSession> sessions =
          ref.read(sshSessionRegistryProvider);
      return sessions.values
          .map((RegisteredSession s) =>
              '${s.config.name} (${s.config.username}@${s.config.host}:${s.config.port})')
          .toList();
    },
  );
});

/// True when a non-empty API key is present for the current provider.
///
/// Watched by the chat page to decide between the setup guide and the
/// transcript. Invalidate after saving/clearing a key in Settings.
final FutureProvider<bool> apiKeyConfiguredProvider =
    FutureProvider<bool>((Ref ref) async {
  final String? key = await ref.watch(apiKeyProvider.future);
  return key != null && key.trim().isNotEmpty;
});

// ─── Chat state ─────────────────────────────────────────────────────────

/// Immutable UI state for the active conversation.
class ChatState {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isStreaming = false,
    this.isConnecting = false,
    this.failure,
  });

  final List<ChatMessage> messages;

  /// True from the moment a request is sent until the stream closes.
  final bool isStreaming;

  /// True after send, before the first token arrives — drives the
  /// "thinking" indicator distinct from the typing cursor.
  final bool isConnecting;

  /// Last surfaced error, if any.
  final AppFailure? failure;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    bool? isConnecting,
    AppFailure? failure,
    bool clearFailure = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        isConnecting: isConnecting ?? this.isConnecting,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  bool operator ==(Object other) =>
      other is ChatState &&
      other.isStreaming == isStreaming &&
      other.isConnecting == isConnecting &&
      other.failure == failure &&
      _sameMessages(other.messages, messages);

  @override
  int get hashCode =>
      Object.hash(messages.length, isStreaming, isConnecting, failure);

  static bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Notifier driving the conversation: send, stream, stop, clear.
class ChatNotifier extends Notifier<ChatState> {
  StreamSubscription<String>? _subscription;
  int _idCounter = 0;

  /// Set once the persisted transcript has been merged into state, so a
  /// later re-entry never duplicates history.
  bool _historyRestored = false;

  /// Marks a persistence snapshot as scheduled-but-not-yet-flushed so the
  /// notifier can distinguish "writing" from "cleared" state transitions.
  bool _restoreInFlight = false;

  @override
  ChatState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const ChatState();
  }

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  // ─── History persistence ────────────────────────────────────────────────

  /// Restores the persisted transcript from [store] into state. No-op when
  /// already restored, while streaming, or when the box holds nothing.
  ///
  /// Streaming placeholders that never completed are restored as finished
  /// turns by the store itself.
  Future<void> restoreFromHistory(ChatHistoryStore store) async {
    if (_historyRestored || state.isStreaming || _restoreInFlight) return;
    _restoreInFlight = true;
    try {
      final List<ChatMessage> messages = await store.load();
      if (messages.isEmpty) return;
      _historyRestored = true;
      state = ChatState(messages: List<ChatMessage>.unmodifiable(messages));
    } finally {
      _restoreInFlight = false;
    }
  }

  /// Schedules a debounced persistence write of the current transcript.
  /// Called after every message-list mutation; the store coalesces bursts
  /// (a streaming reply) into a single disk write.
  void _persistMessages() {
    ref.read(chatHistoryStoreProvider).saveMessages(state.messages);
  }

  /// Persists the transcript immediately (flushing any pending debounced
  /// write). Used at stream completion where the transcript is final.
  Future<void> _flushMessages() {
    return ref.read(chatHistoryStoreProvider).flush(state.messages);
  }

  /// Sends [text] as a user turn and begins streaming the assistant reply.
  Future<void> sendMessage(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    // History captured before we append the new turns.
    final List<ChatMessage> history = state.messages;

    final ChatMessage userMsg =
        ChatMessage.user(id: _nextId('u'), content: trimmed);
    final String assistantId = _nextId('a');
    final ChatMessage assistant =
        ChatMessage.assistantStreaming(id: assistantId);

    state = state.copyWith(
      messages: <ChatMessage>[...history, userMsg, assistant],
      isStreaming: true,
      isConnecting: true,
      clearFailure: true,
    );
    // Persist the user turn right away (debounced); the assistant
    // placeholder is stored as a finished turn if the app dies mid-stream.
    _persistMessages();

    final StringBuffer buffer = StringBuffer();

    try {
      _subscription = ref
          .read(chatRepositoryProvider)
          .sendMessageStream(history: history, userMessage: trimmed)
          .listen(
        (String delta) {
          buffer.write(delta);
          if (state.isConnecting) {
            state = state.copyWith(isConnecting: false);
          }
          _patchMessage(
            assistantId,
            (ChatMessage m) => m.copyWith(content: buffer.toString()),
          );
        },
        onError: (Object error, StackTrace stack) => _onStreamError(
          assistantId,
          buffer.toString(),
          error,
          stack,
        ),
        onDone: () => _onStreamDone(assistantId, buffer.toString()),
        cancelOnError: true,
      );
    } catch (error, stack) {
      // Synchronous failure while wiring the stream (provider/repository
      // construction). Reset the flags and surface the failure exactly like
      // a stream error with no tokens received.
      _onStreamError(assistantId, buffer.toString(), error, stack);
    }
  }

  Future<void> _onStreamDone(String assistantId, String content) async {
    _subscription = null;
    if (content.trim().isEmpty) {
      // No tokens arrived — drop the empty placeholder rather than show a
      // blank bubble.
      state = state.copyWith(
        messages: state.messages
            .where((ChatMessage m) => m.id != assistantId)
            .toList(growable: false),
        isStreaming: false,
        isConnecting: false,
      );
      // Still persist: the user turn must survive an app restart.
      await _flushMessages();
      return;
    }
    _patchMessage(assistantId, (ChatMessage m) => m.finish());
    state = state.copyWith(isStreaming: false, isConnecting: false);
    // Stream settled — write the final transcript immediately.
    await _flushMessages();
  }

  Future<void> _onStreamError(
    String assistantId,
    String partial,
    Object error,
    StackTrace stack,
  ) async {
    _subscription = null;
    final AppFailure failure = _toFailure(error, stack);

    // Cancellation is a normal "stop" — don't treat it as an error banner.
    if (failure.kind == FailureKind.cancelled) {
      _patchMessage(assistantId, (ChatMessage m) => m.finish());
      state = state.copyWith(isStreaming: false, isConnecting: false);
      await _flushMessages();
      return;
    }

    // Keep any partial text but mark the message as an error turn, then
    // surface the failure for the banner.
    if (partial.trim().isEmpty) {
      state = state.copyWith(
        messages: state.messages
            .where((ChatMessage m) => m.id != assistantId)
            .toList(growable: false),
        isStreaming: false,
        isConnecting: false,
        failure: failure,
      );
    } else {
      _patchMessage(
        assistantId,
        (ChatMessage m) => m.copyWith(isStreaming: false, error: true),
      );
      state = state.copyWith(
        isStreaming: false,
        isConnecting: false,
        failure: failure,
      );
    }
    // Persist either way so the surviving transcript is stable on restart.
    await _flushMessages();
  }

  /// Aborts an in-flight stream, keeping whatever text arrived so far.
  void stopStreaming() {
    ChatMessage? streaming;
    for (final ChatMessage m in state.messages) {
      if (m.isStreaming) {
        streaming = m;
        break;
      }
    }

    _subscription?.cancel();
    _subscription = null;

    if (streaming != null) {
      _patchMessage(streaming.id, (ChatMessage m) => m.finish());
    }
    state = state.copyWith(isStreaming: false, isConnecting: false);
    // The stopped partial reply is a final transcript — flush immediately so
    // an app kill right after "stop" never loses the surviving turn.
    _flushMessages();
  }

  /// Sends a tool execution result to the conversation and triggers AI follow-up.
  Future<void> sendToolResult(CommandResult result) async {
    final ToolPayload payload = ToolPayload(
      toolType: 'ssh_exec',
      command: result.command,
      serverId: result.serverId,
      serverName: result.serverName,
      stdout: result.stdout,
      stderr: result.stderr,
      exitCode: result.exitCode,
      elapsed: result.elapsed,
    );

    final ChatMessage toolMessage = ChatMessage.toolResult(
      id: _nextId('t'),
      payload: payload,
    );

    // Append tool message
    final List<ChatMessage> updatedMessages = [...state.messages, toolMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: true,
      isConnecting: true,
      clearFailure: true,
    );
    // Schedule the debounced write so the tool turn survives an app kill
    // before the follow-up stream settles.
    _persistMessages();

    // Trigger AI response
    await _continueAfterToolResult(updatedMessages);
  }

  /// Batch send multiple tool results (for parallel execution).
  Future<void> sendToolResults(List<CommandResult> results) async {
    final List<ChatMessage> toolMessages = [];
    for (final CommandResult result in results) {
      final ToolPayload payload = ToolPayload(
        toolType: 'ssh_exec',
        command: result.command,
        serverId: result.serverId,
        serverName: result.serverName,
        stdout: result.stdout,
        stderr: result.stderr,
        exitCode: result.exitCode,
        elapsed: result.elapsed,
      );
      toolMessages.add(ChatMessage.toolResult(
        id: _nextId('t'),
        payload: payload,
      ));
    }

    // Append all tool messages
    final List<ChatMessage> updatedMessages = [
      ...state.messages,
      ...toolMessages,
    ];
    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: true,
      isConnecting: true,
      clearFailure: true,
    );
    // Schedule the debounced write so the tool turns survive an app kill
    // before the follow-up stream settles.
    _persistMessages();

    // Trigger AI response once
    await _continueAfterToolResult(updatedMessages);
  }

  /// Internal: continue conversation after tool results.
  Future<void> _continueAfterToolResult(List<ChatMessage> messages) async {
    final ChatMessage assistantMsg = ChatMessage.assistantStreaming(
      id: _nextId('a'),
    );

    state = state.copyWith(
      messages: [...messages, assistantMsg],
    );

    final StringBuffer buffer = StringBuffer();

    try {
      _subscription = ref
          .read(chatRepositoryProvider)
          .sendMessageStream(
            history: messages,
            // Empty user message: continuation is driven by the tool-result
            // turns already present in [messages]; _buildMessages skips the
            // empty trailing user turn.
            userMessage: '',
          )
          .listen(
        (String delta) {
          buffer.write(delta);
          if (state.isConnecting) {
            state = state.copyWith(isConnecting: false);
          }
          _patchMessage(
            assistantMsg.id,
            (ChatMessage m) => m.copyWith(content: buffer.toString()),
          );
        },
        onError: (Object error, StackTrace stack) => _onStreamError(
          assistantMsg.id,
          buffer.toString(),
          error,
          stack,
        ),
        onDone: () => _onStreamDone(assistantMsg.id, buffer.toString()),
        cancelOnError: true,
      );
    } catch (error, stack) {
      // Same synchronous-failure guard as sendMessage.
      _onStreamError(assistantMsg.id, buffer.toString(), error, stack);
    }
  }

  /// Wipes the conversation and any error state, and removes the persisted
  /// transcript so a restart cannot resurrect the cleared history.
  void clearChat() {
    _subscription?.cancel();
    _subscription = null;
    state = const ChatState();
    _historyRestored = false;
    unawaited(ref.read(chatHistoryStoreProvider).clear());
  }

  void dismissError() {
    if (state.failure != null) {
      state = state.copyWith(clearFailure: true);
    }
  }

  void _patchMessage(String id, ChatMessage Function(ChatMessage) transform) {
    state = state.copyWith(
      messages: state.messages
          .map((ChatMessage m) => m.id == id ? transform(m) : m)
          .toList(growable: false),
    );
  }

  AppFailure _toFailure(Object error, StackTrace stack) {
    if (error is AiServiceException) return error.failure;
    if (error is AppFailureException) return error.failure;
    if (error is AppFailure) return error;
    return AppFailure.unexpected(error, stackTrace: stack);
  }
}

/// The conversation notifier — the single source of truth for the chat UI.
final NotifierProvider<ChatNotifier, ChatState> chatMessagesProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

// ─── Chat history persistence ────────────────────────────────────────────

/// Hive-backed transcript store, overridable in tests.
final Provider<ChatHistoryStore> chatHistoryStoreProvider =
    Provider<ChatHistoryStore>((Ref ref) => ChatHistoryStore.instance);

/// Loads the persisted transcript into [chatMessagesProvider], restoring the
/// conversation after an app restart. Streaming placeholders that never
/// finished are restored as completed turns (handled by the store).
///
/// Safe to call more than once; subsequent calls are no-ops so navigating
/// back to the chat page never duplicates history.
Future<void> restoreChatHistory(Ref ref) async {
  final ChatNotifier notifier = ref.read(chatMessagesProvider.notifier);
  await notifier.restoreFromHistory(ref.read(chatHistoryStoreProvider));
}
