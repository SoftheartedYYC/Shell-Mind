import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ai_provider.dart';
import '../providers/chat_providers.dart';

// ─── Header ───────────────────────────────────────────────────────────────

/// Status header of the AI chat screen: title, provider/model badges, a live
/// status pill and the trailing actions (export, manage servers, clear).
class ChatHeader extends ConsumerWidget {
  const ChatHeader({
    super.key,
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
