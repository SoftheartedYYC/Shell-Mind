import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';

/// The AI assistant chat surface.
///
/// Three zones stacked vertically: a status header, a reversed transcript
/// (newest pinned to the bottom), and a composer. Streaming replies render
/// live via [MessageBubble] → `StreamingText`, and the whole screen degrades
/// gracefully to a setup guide when no API key is present.
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
    final AiProvider provider = ref.watch(selectedProviderProvider);

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
              onClear: _clear,
            ),
            Expanded(
              child: keyStatus.when(
                loading: () => Center(
                  child: AppLoader(
                      label: AppLocalizations.of(context)
                          .aiChatCheckingCredentials),
                ),
                error: (Object _, StackTrace __) => _ApiKeySetupGuide(
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 140),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
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
