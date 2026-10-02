import 'package:flutter/foundation.dart';

/// Navigation payload handed to the AI chat page when it is opened from
/// another surface (e.g. the terminal's "Ask AI" entry point).
///
/// Carries just enough context for the chat page to pre-fill a question,
/// target a specific server, or start with the terminal context attached —
/// without coupling the caller to the chat page's internal state.
@immutable
class AiChatExtra {
  const AiChatExtra({
    this.serverId,
    this.initialQuery,
    this.attachedTerminalContext = false,
  });

  /// Id of the server the user was working with, used to scope command
  /// execution and terminal-context capture.
  final String? serverId;

  /// Text pre-filled into the composer (e.g. a terminal selection).
  final String? initialQuery;

  /// When true, the chat page should attach the live terminal context on open.
  final bool attachedTerminalContext;

  AiChatExtra copyWith({
    String? serverId,
    String? initialQuery,
    bool? attachedTerminalContext,
  }) {
    return AiChatExtra(
      serverId: serverId ?? this.serverId,
      initialQuery: initialQuery ?? this.initialQuery,
      attachedTerminalContext:
          attachedTerminalContext ?? this.attachedTerminalContext,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatExtra &&
          other.serverId == serverId &&
          other.initialQuery == initialQuery &&
          other.attachedTerminalContext == attachedTerminalContext;

  @override
  int get hashCode =>
      Object.hash(serverId, initialQuery, attachedTerminalContext);

  @override
  String toString() =>
      'AiChatExtra(serverId: $serverId, initialQuery: $initialQuery, '
      'attachedTerminalContext: $attachedTerminalContext)';
}
