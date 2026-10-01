import '../../../../core/utils/result.dart';
import '../entities/chat_message.dart';

/// Contract between the presentation layer and the AI backend.
///
/// The repository hides the transport (OpenAI SSE vs. a future local model)
/// and the prompt-assembly policy, exposing only "send these messages, get
/// text back" — streamed for the live typing effect, or as a single
/// [Result] for headless/backup use.
abstract class ChatRepository {
  /// Sends [userMessage] with the given [history] and streams the assistant
  /// reply token-by-token.
  ///
  /// The stream emits content deltas only; the caller accumulates them. It
  /// closes normally on `[DONE]` and may emit an error (`addError`) which the
  /// presentation layer surfaces as a failure banner. Callers should cancel
  /// their subscription to abort an in-flight response.
  Stream<String> sendMessageStream({
    required List<ChatMessage> history,
    required String userMessage,
  });

  /// Non-streaming variant — waits for the full completion. Kept as a
  /// fallback for contexts where incremental rendering isn't possible.
  Future<Result<String>> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
  });
}
