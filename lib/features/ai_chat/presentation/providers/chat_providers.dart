import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/chat_repository_impl.dart';
import '../../data/openai_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

// ─── Service / repository wiring ────────────────────────────────────────

/// Builds the [OpenAiService] from the shared Dio client + storage services.
final Provider<OpenAiService> openaiServiceProvider =
    Provider<OpenAiService>((Ref ref) {
  final DioClient client = ref.watch(dioClientProvider);
  final SecureStorageService secure = ref.watch(secureStorageServiceProvider);
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return OpenAiService(
    client: client,
    secureStorage: secure,
    preferences: prefs,
  );
});

/// Concrete [ChatRepository] used across the feature.
final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((Ref ref) {
  return ChatRepositoryImpl(ref.watch(openaiServiceProvider));
});

/// True when a non-empty API key is present in secure storage.
///
/// Watched by the chat page to decide between the setup guide and the
/// transcript. Invalidate after saving/clearing a key in Settings.
final FutureProvider<bool> apiKeyConfiguredProvider =
    FutureProvider<bool>((Ref ref) async {
  final SecureStorageService secure = ref.watch(secureStorageServiceProvider);
  final String? key = await secure.getApiKey();
  return key != null && key.trim().isNotEmpty;
});

/// Currently selected model name (from preferences) — surfaced in the header.
final Provider<String> activeModelProvider = Provider<String>((Ref ref) {
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return prefs.aiModel;
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
