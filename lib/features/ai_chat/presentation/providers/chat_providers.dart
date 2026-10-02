import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/ai_service.dart';
import '../../data/chat_repository_impl.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../shared/ssh/ssh_command_executor.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';

// ─── Provider / model selection ─────────────────────────────────────────

/// The provider the user picked in Settings. Non-autoDispose: [PreferencesService]
/// is a silent singleton, so this is recomputed only when a settings change
/// explicitly invalidates it (see `ai_settings_provider.dart`).
final Provider<AiProvider> selectedProviderProvider = Provider<AiProvider>((Ref ref) {
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return AiProviders.getById(prefs.selectedProviderId);
});

/// The model chosen for the current provider, resolved against its catalogue
/// (falls back to the provider default when the stored id is stale).
final Provider<AiModel> selectedModelProvider = Provider<AiModel>((Ref ref) {
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  final AiProvider provider = ref.watch(selectedProviderProvider);
  final String? stored = prefs.getSelectedModel(provider.id);
  return stored == null ? provider.defaultModel : provider.modelById(stored);
});

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
  final String apiKey = ref.watch(apiKeyProvider).valueOrNull ?? '';
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

  @override
  ChatState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const ChatState();
  }

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

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

    final StringBuffer buffer = StringBuffer();

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
  }

  void _onStreamDone(String assistantId, String content) {
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
      return;
    }
    _patchMessage(assistantId, (ChatMessage m) => m.finish());
    state = state.copyWith(isStreaming: false, isConnecting: false);
  }

  void _onStreamError(
    String assistantId,
    String partial,
    Object error,
    StackTrace stack,
  ) {
    _subscription = null;
    final AppFailure failure = _toFailure(error, stack);

    // Cancellation is a normal "stop" — don't treat it as an error banner.
    if (failure.kind == FailureKind.cancelled) {
      _patchMessage(assistantId, (ChatMessage m) => m.finish());
      state = state.copyWith(isStreaming: false, isConnecting: false);
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

    _subscription = ref
        .read(chatRepositoryProvider)
        .sendMessageStream(
          history: messages,
          userMessage: '', // Empty user message triggers continuation based on tool results
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
  }

  /// Wipes the conversation and any error state.
  void clearChat() {
    _subscription?.cancel();
    _subscription = null;
    state = const ChatState();
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
