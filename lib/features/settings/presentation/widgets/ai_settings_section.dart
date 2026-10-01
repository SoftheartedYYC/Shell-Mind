import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../providers/ai_settings_provider.dart';

/// Settings block for the AI backend: pick a provider, configure its API key,
/// choose a model, and tune temperature. Clean Material 3 style.
class AiSettingsSection extends ConsumerWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiSettingsState s = ref.watch(aiSettingsProvider);
    final AiSettingsController controller = ref.read(aiSettingsProvider.notifier);
    final AiProvider provider = s.effectiveProvider;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < AiProviders.all.length; i++) ...<Widget>[
                  if (i > 0) const _SectionDivider(indent: 0),
                  _ProviderTile(
                    provider: AiProviders.all[i],
                    selected: AiProviders.all[i].id == provider.id,
                    configured: s.configuredProviderIds.contains(AiProviders.all[i].id),
                    onTap: () => controller.selectProvider(AiProviders.all[i].id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              children: <Widget>[
                _Row(
                  icon: Icons.key_rounded,
                  title: l10n.aiSettingsApiKeyTitle(provider.name),
                  trailing: s.isLoading
                      ? const _Spinner()
                      : GestureDetector(
                          onTap: () => _openKeyDialog(context, controller, s),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                s.hasKey
                                    ? (s.maskedKey ?? l10n.aiSettingsKeySet)
                                    : l10n.aiSettingsKeyNotConfigured,
                                style: TextStyle(
                                  fontFamily: AppTheme.monoFont,
                                  fontFamilyFallback: AppTheme.monoFallback,
                                  fontSize: 12,
                                  color: s.hasKey
                                      ? context.sem.success
                                      : context.sem.warning,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded,
                                  size: 16, color: context.colors.onSurfaceVariant),
                            ],
                          ),
                        ),
                ),
                if (provider.websiteUrl != null) ...<Widget>[
                  const _SectionDivider(),
                  _Row(
                    icon: Icons.open_in_new_rounded,
                    title: l10n.aiSettingsGetApiKey,
                    trailing: GestureDetector(
                      onTap: () => _showWebsite(context, provider),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 16, color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
                const _SectionDivider(),
                _ModelList(
                  provider: provider,
                  selectedModelId: s.model ?? provider.defaultModel.id,
                  onSelected: controller.setModel,
                ),
                const _SectionDivider(),
                _Row(
                  icon: Icons.thermostat_rounded,
                  title: l10n.aiSettingsTemperature,
                  trailing: Text(
                    s.temperature.toStringAsFixed(2),
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Slider(
                    value: s.temperature.clamp(0.0, 2.0),
                    min: 0,
                    max: 2,
                    divisions: 20,
                    onChanged: controller.setTemperature,
                  ),
                ),
                if (s.hasKey) ...<Widget>[
                  const _SectionDivider(),
                  _Row(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.aiSettingsRemoveKey,
                    destructive: true,
                    trailing: GestureDetector(
                      onTap: () => _confirmClear(context, controller, provider),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: context.colors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openKeyDialog(
    BuildContext context,
    AiSettingsController controller,
    AiSettingsState state,
  ) async {
    final String providerName = state.effectiveProvider.name;
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _ApiKeyDialog(
        providerName: providerName,
        existing: state.hasKey,
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await controller.saveKey(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).aiSettingsKeySaved(providerName))),
        );
      }
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    AiSettingsController controller,
    AiProvider provider,
  ) async {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.aiSettingsRemoveKeyTitle(provider.name)),
        content: Text(l10n.aiSettingsRemoveKeyMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.aiSettingsRemoveKeyConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.clearKey();
    }
  }

  void _showWebsite(BuildContext context, AiProvider provider) {
    final String url = provider.websiteUrl ?? '';
    final AppLocalizations l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.aiSettingsGetKeyTitle(provider.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.aiSettingsGetKeyMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              url,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: AppTheme.monoFallback,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.aiSettingsClose),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.aiSettingsLinkCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l10n.aiSettingsCopyLink),
          ),
        ],
      ),
    );
  }
}

// ─── Provider tile ──────────────────────────────────────────────────────

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.selected,
    required this.configured,
    required this.onTap,
  });

  final AiProvider provider;
  final bool selected;
  final bool configured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: Text(
                provider.initials,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: AppTheme.monoFallback,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    provider.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: colors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(
                        configured
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 12,
                        color: configured ? context.sem.success : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        configured
                            ? AppLocalizations.of(context).aiSettingsKeyConfigured
                            : AppLocalizations.of(context).aiSettingsNotConfigured,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            if (selected)
              Icon(Icons.check_circle_rounded, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Model list ─────────────────────────────────────────────────────────

class _ModelList extends StatelessWidget {
  const _ModelList({
    required this.provider,
    required this.selectedModelId,
    required this.onSelected,
  });

  final AiProvider provider;
  final String selectedModelId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        for (int i = 0; i < provider.models.length; i++) ...<Widget>[
          if (i > 0) const _SectionDivider(indent: 52),
          Builder(
            builder: (BuildContext context) {
              final AiModel m = provider.models[i];
              final bool active = m.id == selectedModelId;
              return InkWell(
                onTap: () => onSelected(m.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        active
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: active ? colors.primary : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              m.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: active ? colors.primary : colors.onSurface,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                  ),
                            ),
                            if (m.description != null) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                _localizedModelDesc(l10n, m.description!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ─── API key dialog ─────────────────────────────────────────────────────

/// Maps a model's raw (English) description to its localized string.
String _localizedModelDesc(AppLocalizations l10n, String raw) => switch (raw) {
      'Fast & affordable' => l10n.modelDescFastAffordable,
      'Most capable' => l10n.modelDescMostCapable,
      'Legacy fast' => l10n.modelDescLegacyFast,
      'General conversation' => l10n.modelDescGeneralConversation,
      'Advanced reasoning' => l10n.modelDescAdvancedReasoning,
      'Fast response' => l10n.modelDescFastResponse,
      'Balanced' => l10n.modelDescBalanced,
      'Free & fast' => l10n.modelDescFreeFast,
      'Enhanced' => l10n.modelDescEnhanced,
      'Standard' => l10n.modelDescStandard,
      'Lightweight' => l10n.modelDescLightweight,
      'RL enhanced' => l10n.modelDescRlEnhanced,
      _ => raw,
    };

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.providerName, required this.existing});
  final String providerName;
  final bool existing;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final bool next = v.trim().isNotEmpty;
    if (next != _valid) setState(() => _valid = next);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.key_rounded, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.existing
                  ? l10n.aiSettingsUpdateKeyTitle(widget.providerName)
                  : l10n.aiSettingsAddKeyTitle(widget.providerName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.aiSettingsKeyStorageNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            obscureText: _obscure,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.singleLineFormatter,
            ],
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: AppTheme.monoFallback,
              fontSize: 13,
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.aiSettingsApiKeyHint,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            onSubmitted: (_) {
              if (_valid) Navigator.of(context).pop(_controller.text);
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed:
              _valid ? () => Navigator.of(context).pop(_controller.text) : null,
          child: Text(l10n.aiSettingsSave),
        ),
      ],
    );
  }
}

// ─── Shared chrome ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color fg = destructive ? colors.error : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: destructive ? colors.error : colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({this.indent = 52});
  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
        indent: indent,
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
