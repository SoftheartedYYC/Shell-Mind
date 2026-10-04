import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../providers/ai_settings_provider.dart';
import 'model_picker_sheet.dart';
import 'provider_picker_sheet.dart';

/// Settings block for the AI backend: pick a provider, configure its API key,
/// choose a model, and tune temperature.
///
/// Renders as a flat group of rows (no card of its own) so it can sit inside
/// the section card built by [SettingsPage] without a double-border look.
class AiSettingsSection extends ConsumerWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiSettingsState s = ref.watch(aiSettingsProvider);
    final AiSettingsController controller = ref.read(aiSettingsProvider.notifier);
    final AiProvider provider = s.effectiveProvider;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Flat group of rows (no card of its own) so it sits inside the section
    // card drawn by SettingsPage without a double-border look. The provider
    // catalogue lives in [ProviderPickerSheet] — the tile only mirrors the
    // active provider, mirroring the model row's interaction pattern.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProviderPickerTile(
          provider: provider,
          configured: s.configuredProviderIds.contains(provider.id),
          onOpen: () => _openProviderPicker(context, controller),
        ),
        const _SectionDivider(),
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
        _ModelPickerTile(
          provider: provider,
          selectedModelId: s.model ?? provider.defaultModel.id,
          onOpen: () => _openModelPicker(context, controller),
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
    );
  }

  /// Opens the provider picker sheet. The picked id is applied through the
  /// controller (`selectProvider`) so the selection persists and propagates
  /// to the chat surface immediately. Add/delete flows resolve inside the
  /// sheet; deleting the active provider falls back via the controller.
  Future<void> _openProviderPicker(
    BuildContext context,
    AiSettingsController controller,
  ) async {
    final String? picked = await ProviderPickerSheet.show(context);
    if (picked == null || picked.isEmpty || !context.mounted) return;
    await controller.selectProvider(picked);
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

  /// Opens the model picker sheet. The picked id is applied through the
  /// controller (`setModel`) so the selection persists and propagates to the
  /// chat surface immediately.
  Future<void> _openModelPicker(
    BuildContext context,
    AiSettingsController controller,
  ) async {
    final String? picked = await ModelPickerSheet.show(context);
    if (picked == null || picked.isEmpty || !context.mounted) return;
    await controller.setModel(picked);
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

// ─── Provider picker entry ──────────────────────────────────────────────

/// Single settings row for provider selection: shows the active provider's
/// initials badge, name and key-configuration status, and opens the
/// [ProviderPickerSheet] on tap. The full catalogue, custom-provider
/// management and delete flows live inside the sheet — mirroring the model
/// row's "single tile opens a picker sheet" interaction pattern.
class _ProviderPickerTile extends StatelessWidget {
  const _ProviderPickerTile({
    required this.provider,
    required this.configured,
    required this.onOpen,
  });

  final AiProvider provider;
  final bool configured;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            // Initials badge — same treatment the inline provider tiles used.
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary),
              ),
              child: Text(
                provider.initials,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: AppTheme.monoFallback,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
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
                        color: configured
                            ? context.sem.success
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        configured
                            ? l10n.aiSettingsKeyConfigured
                            : l10n.aiSettingsNotConfigured,
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
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Model picker entry ─────────────────────────────────────────────────

/// Single settings row for model selection: shows the active model name and
/// opens the [ModelPickerSheet] on tap. The full catalogue, search filtering
/// and custom-model management live inside the sheet.
class _ModelPickerTile extends StatelessWidget {
  const _ModelPickerTile({
    required this.provider,
    required this.selectedModelId,
    required this.onOpen,
  });

  final AiProvider provider;
  final String selectedModelId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Built-in matches keep their friendly display name; custom/fetched ids
    // fall back to the raw id itself.
    final AiModel builtin = provider.modelById(selectedModelId);
    final String modelName =
        builtin.id == selectedModelId ? builtin.name : selectedModelId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(Icons.memory_rounded,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.aiModelsTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            // Expanded (not Flexible) so the value hugs the trailing edge —
            // same right-aligned treatment as the temperature readout above.
            Expanded(
              child: Text(
                modelName.isEmpty ? l10n.aiModelsEmpty : modelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: AppTheme.monoFallback,
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── API key dialog ─────────────────────────────────────────────────────

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
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
        indent: 52,
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
