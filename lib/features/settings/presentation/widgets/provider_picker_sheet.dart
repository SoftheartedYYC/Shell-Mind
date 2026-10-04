import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../../../ai_chat/presentation/providers/chat_providers.dart';
import '../providers/ai_settings_provider.dart';
import 'custom_provider_dialog.dart';

/// Modal bottom sheet for picking the active AI provider.
///
/// Lists every provider (built-ins first, then user-defined customs) with
/// its key-configuration status, keeps the delete affordance for custom rows
/// and the add-custom entry at the bottom 鈥?the management affordances that
/// previously lived inline on the settings page. Selecting a row pops the
/// sheet with the picked id ([show]); the caller applies it through
/// [AiSettingsController.selectProvider]. Add/delete flows resolve inside
/// the sheet through the controller directly.
///
/// Presentation mirrors [ModelPickerSheet]: a rounded top container with a
/// title row and a lazily-built list.
class ProviderPickerSheet extends ConsumerStatefulWidget {
  const ProviderPickerSheet({super.key});

  /// Shows the sheet; returns the picked provider id (`null` when dismissed
  /// or after in-sheet add/delete flows 鈥?those apply through the controller
  /// without popping a result).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => const ProviderPickerSheet(),
    );
  }

  @override
  ConsumerState<ProviderPickerSheet> createState() =>
      _ProviderPickerSheetState();
}

class _ProviderPickerSheetState extends ConsumerState<ProviderPickerSheet> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AiSettingsState s = ref.watch(aiSettingsProvider);
    // Built-ins first, then user-defined custom providers 鈥?same ordering
    // the previous inline tiles used.
    final List<AiProvider> providers = <AiProvider>[
      ...AiProviders.all,
      ...ref.watch(customAiProvidersProvider),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // 鈹€鈹€ Title row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              l10n.aiProvidersPickerTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // 鈹€鈹€ Provider list 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: providers.length,
              itemBuilder: (BuildContext context, int index) {
                final AiProvider provider = providers[index];
                final bool active = provider.id == s.effectiveProvider.id;
                return _ProviderOptionTile(
                  provider: provider,
                  active: active,
                  configured: s.configuredProviderIds.contains(provider.id),
                  onSelect: () =>
                      Navigator.of(context).pop<String>(provider.id),
                  onDelete: provider.isCustom
                      ? () => _confirmDeleteProvider(provider)
                      : null,
                );
              },
            ),
          ),

          // 鈹€鈹€ Add-custom entry 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          SafeArea(
            top: false,
            child: _AddProviderTile(onTap: _openAddProviderDialog),
          ),
        ],
      ),
    );
  }

  /// Opens the add-custom-provider dialog and persists the result. The sheet
  /// stays open so the freshly added (auto-selected) provider is visible.
  Future<void> _openAddProviderDialog() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final (String, String, String)? result =
        await showCustomProviderDialog(context);
    if (result == null || !mounted) return;

    final (String name, String baseUrl, String model) = result;
    final String? id = await ref
        .read(aiSettingsProvider.notifier)
        .addCustomProvider(
          name: name,
          baseUrl: baseUrl,
          defaultModelId: model.isEmpty ? null : model,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            id == null ? l10n.aiProvidersAddFailed : l10n.aiProvidersAdded),
      ),
    );
  }

  /// Confirmation flow for deleting a user-defined provider 鈥?the same
  /// dialog and controller call the inline tiles used, now hosted inside
  /// the sheet (the list refreshes in place via [customAiProvidersProvider]).
  Future<void> _confirmDeleteProvider(AiProvider provider) async {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.aiProvidersDeleteTitle(provider.name)),
        content: Text(l10n.aiProvidersDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.aiProvidersDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(aiSettingsProvider.notifier)
        .deleteCustomProvider(provider.id);
  }
}

// 鈹€鈹€鈹€ Provider row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// A single selectable provider row: radio state, initials badge, name,
/// key-configuration status, custom badge and remove action. Carries over
/// the visual treatment of the previous inline `_ProviderTile`.
class _ProviderOptionTile extends StatelessWidget {
  const _ProviderOptionTile({
    required this.provider,
    required this.active,
    required this.configured,
    required this.onSelect,
    this.onDelete,
  });

  final AiProvider provider;
  final bool active;
  final bool configured;
  final VoidCallback onSelect;

  /// Non-null only for user-defined providers 鈥?shows the remove affordance.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: onDelete != null ? 10 : 20,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: active ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            // Initials badge 鈥?carried over from the inline provider tile.
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: Text(
                provider.initials,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: AppTheme.monoFallback,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          provider.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: active
                                        ? colors.primary
                                        : colors.onSurface,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                        ),
                      ),
                      if (provider.isCustom) ...<Widget>[
                        const SizedBox(width: 8),
                        // Custom badge 鈥?same pill as the model picker's.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.aiModelsCustomBadge,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.onTertiaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(
                        configured
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 12,
                        color: configured
                            ? context.sem.success
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        configured
                            ? l10n.aiSettingsKeyConfigured
                            : l10n.aiSettingsNotConfigured,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: configured
                                  ? context.sem.success
                                  : colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: l10n.aiProvidersDeleteTile,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(Icons.close_rounded, size: 16, color: colors.error),
              ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child:
                    Icon(Icons.check_rounded, size: 18, color: colors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// 鈹€鈹€鈹€ Custom provider entry + dialog 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

/// The "+ Add provider" row at the bottom of the sheet.
class _AddProviderTile extends StatelessWidget {
  const _AddProviderTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(Icons.add_rounded, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Text(
              l10n.aiProvidersAddTile,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
