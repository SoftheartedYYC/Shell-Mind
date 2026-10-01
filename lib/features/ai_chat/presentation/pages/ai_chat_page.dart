import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';

/// The AI assistant chat surface.
///
/// Three zones stacked vertically: a status header, a reversed transcript
/// (newest pinned to the bottom), and a phosphor-lit composer. Streaming
/// replies render live via [MessageBubble] → `StreamingText`, and the whole
/// screen degrades gracefully to a setup guide when no API key is present.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

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

    notifier.sendMessage(text);
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

  @override
  Widget build(BuildContext context) {
    final ChatState chat = ref.watch(chatMessagesProvider);
    final AsyncValue<bool> keyStatus = ref.watch(apiKeyConfiguredProvider);
    final bool hasKey = keyStatus.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ChatHeader(
              isStreaming: chat.isStreaming,
              hasKey: hasKey,
              canClear: chat.messages.isNotEmpty,
              onClear: _clear,
            ),
            Expanded(
              child: keyStatus.when(
                loading: () => const Center(
                  child: PhosphorLoader(label: 'checking credentials', compact: true),
                ),
                error: (Object _, StackTrace __) => _ApiKeySetupGuide(
                  onOpenSettings: _openSettings,
                ),
                data: (bool configured) {
                  if (!configured) {
                    return _ApiKeySetupGuide(onOpenSettings: _openSettings);
                  }
                  if (chat.messages.isEmpty) {
                    return _WelcomeTranscript(onSuggestion: _useSuggestion);
                  }
                  return _Transcript(
                    messages: chat.messages,
                    controller: _scroll,
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
            _Composer(
              controller: _input,
              focusNode: _focus,
              enabled: hasKey,
              isStreaming: chat.isStreaming,
              canSend: _canSend && hasKey,
              onSend: _submit,
              onStop: _stop,
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
    required this.onClear,
  });

  final bool isStreaming;
  final bool hasKey;
  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String model = ref.watch(activeModelProvider);

    final (String label, Color color, bool pulse) = !hasKey
        ? ('SETUP', AppTheme.amber, false)
        : isStreaming
            ? ('STREAMING', AppTheme.phosphorGlow, true)
            : ('READY', AppTheme.mint, false);

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
                Row(
                  children: <Widget>[
                    Text(
                      'assistant',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: const <String>[
                          'JetBrains Mono',
                          'Menlo',
                          'monospace',
                        ],
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.phosphorGlow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.phosphorGlow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '~/ai',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'AI Assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _ModelBadge(model: model),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StatusPill(label: label, color: color, pulse: pulse),
          if (canClear)
            IconButton(
              onPressed: onClear,
              tooltip: 'Clear conversation',
              icon: const Icon(Icons.delete_sweep_outlined,
                  size: 20, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  const _ModelBadge({required this.model});
  final String model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.phosphor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.phosphor.withValues(alpha: 0.28)),
      ),
      child: Text(
        model,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTheme.monoFont,
          fontFamilyFallback: const <String>[
            'JetBrains Mono',
            'Menlo',
            'monospace',
          ],
          fontSize: 9.5,
          letterSpacing: 0.4,
          color: AppTheme.phosphor,
        ),
      ),
    );
  }
}

// ─── Transcript ─────────────────────────────────────────────────────────

class _Transcript extends StatelessWidget {
  const _Transcript({required this.messages, required this.controller});

  final List<ChatMessage> messages;
  final ScrollController controller;

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
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MessageBubble(
            key: ValueKey<String>(message.id),
            message: message,
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

  static const List<String> _suggestions = <String>[
    'Explain what ls -la output means',
    'How do I find which process is using a port?',
    'Show me how to tail logs and grep for errors',
    'Write an awk one-liner to sum a CSV column',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      children: <Widget>[
        const _IntroCard(),
        const SizedBox(height: 22),
        const SectionHeader(label: 'try asking', padding: EdgeInsets.zero),
        const SizedBox(height: 4),
        for (final String s in _suggestions)
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF142038), Color(0xFF101728)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.phosphor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '> shell-mind --start',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: const <String>[
                'JetBrains Mono',
                'Menlo',
                'monospace',
              ],
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppTheme.phosphor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your second pair of eyes on the terminal.',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a command, an error, or a chunk of log output. Shell-Mind '
            'explains what happened, suggests the next move, and writes the '
            'commands so you don\'t have to.',
            style: context.text.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
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
    return Material(
      color: AppTheme.inkSurface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppTheme.inkBorderSoft),
          ),
          child: Row(
            children: <Widget>[
              const Text(
                '\$',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.phosphor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.north_east_rounded,
                  size: 14, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── API key setup guide ────────────────────────────────────────────────

class _ApiKeySetupGuide extends StatelessWidget {
  const _ApiKeySetupGuide({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.amber.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(Icons.key_rounded,
                    size: 26, color: AppTheme.amber),
              ),
              const SizedBox(height: 20),
              Text(
                'no api key found',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: const <String>[
                    'JetBrains Mono',
                    'Menlo',
                    'monospace',
                  ],
                  fontSize: 13,
                  letterSpacing: 0.4,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add your OpenAI API key to wake the assistant. It\'s stored '
                'encrypted on this device and never leaves it except to call '
                'the model.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Open AI settings'),
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

// ─── Composer ─────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isStreaming,
    required this.canSend,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isStreaming;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        border: Border(top: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: enabled ? AppTheme.inkBorder : AppTheme.inkBorderSoft,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '>',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppTheme.phosphor
                          : AppTheme.textDisabled,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      cursorColor: AppTheme.phosphorGlow,
                      cursorWidth: 1.6,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: const <String>[
                          'JetBrains Mono',
                          'Menlo',
                          'monospace',
                        ],
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        hintText: enabled
                            ? 'Ask anything…'
                            : 'Set an API key to begin',
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 12.5,
                          color: AppTheme.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          isStreaming
              ? _StopButton(onTap: onStop)
              : _SendButton(enabled: canSend, onTap: onSend),
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
    final Color bg = enabled ? AppTheme.phosphor : AppTheme.inkElevated;
    final Color fg = enabled ? AppTheme.inkVoid : AppTheme.textDisabled;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: enabled
            ? <BoxShadow>[
                BoxShadow(
                  color: AppTheme.phosphor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Icon(Icons.arrow_upward_rounded, size: 20, color: fg),
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: const Center(
            child: Icon(Icons.stop_rounded, size: 20, color: AppTheme.coral),
          ),
        ),
      ),
    );
  }
}
