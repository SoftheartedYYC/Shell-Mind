import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/data/custom_ai_provider_store.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../../../ai_chat/presentation/providers/chat_providers.dart';
import '../providers/ai_settings_provider.dart';
import 'model_picker_sheet.dart';

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
    // Built-ins first, then user-defined custom providers, in one list so
    // every tile behaves identically (select / configure / delete-if-custom).
    final List<AiProvider> providers = <AiProvider>[
      ...AiProviders.all,
      ...ref.watch(customAiProvidersProvider),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < providers.length; i++) ...<Widget>[
                  if (i > 0) const _SectionDivider(indent: 0),
                  _ProviderTile(
                    provider: providers[i],
                    selected: providers[i].id == provider.id,
                    configured: s.configuredProviderIds.contains(providers[i].id),
                    onTap: () => controller.selectProvider(providers[i].id),
                    onDelete: providers[i].isCustom
                        ? () => _confirmDeleteProvider(
                            context, controller, providers[i])
                        : null,
                  ),
                ],
                const _SectionDivider(indent: 0),
                _AddProviderTile(
                  onTap: () => _openAddProviderDialog(context, controller),
                ),
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
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the add-custom-provider dialog and persists the result.
  Future<void> _openAddProviderDialog(
    BuildContext context,
    AiSettingsController controller,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final (String, String, String)? result =
        await showDialog<(String, String, String)>(
      context: context,
      builder: (BuildContext ctx) => const _CustomProviderDialog(),
    );
    if (result == null || !context.mounted) return;

    final (String name, String baseUrl, String model) = result;
    final String? id = await controller.addCustomProvider(
      name: name,
      baseUrl: baseUrl,
      defaultModelId: model.isEmpty ? null : model,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            id == null ? l10n.aiProvidersAddFailed : l10n.aiProvidersAdded),
      ),
    );
  }

  /// Confirmation flow for deleting a user-defined provider.
  Future<void> _confirmDeleteProvider(
    BuildContext context,
    AiSettingsController controller,
    AiProvider provider,
  ) async {
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
    if (ok == true) {
      await controller.deleteCustomProvider(provider.id);
    }
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

// ─── Provider tile ──────────────────────────────────────────────────────

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.selected,
    required this.configured,
    required this.onTap,
    this.onDelete,
  });

  final AiProvider provider;
  final bool selected;
  final bool configured;
  final VoidCallback onTap;

  /// Non-null only for user-defined providers — shows the remove affordance.
  final VoidCallback? onDelete;

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
              Icon(Icons.check_circle_rounded, size: 20, color: colors.primary)
            else if (onDelete != null)
              IconButton(
                tooltip: AppLocalizations.of(context).aiProvidersDeleteTile,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(Icons.close_rounded, size: 16, color: colors.error),
              ),
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

// ─── Custom provider entry + dialog ─────────────────────────────────────

/// The "+ Add provider" row at the bottom of the provider list.
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

/// Dialog collecting name + base URL + optional default model id for a new
/// user-defined provider. Validates non-blank fields, a http(s) URL, and
/// duplicate names; pops with a `(name, baseUrl, model)` record.
class _CustomProviderDialog extends StatefulWidget {
  const _CustomProviderDialog();

  @override
  State<_CustomProviderDialog> createState() => _CustomProviderDialogState();
}

class _CustomProviderDialogState extends State<_CustomProviderDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _model = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _model.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n, Set<String> takenNames) {
    final String name = _name.text.trim();
    final String url = _url.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => _error = l10n.aiProvidersInvalidInput);
      return;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      setState(() => _error = l10n.aiProvidersInvalidUrl);
      return;
    }
    for (final String existing in takenNames) {
      if (existing.toLowerCase() == name.toLowerCase()) {
        setState(() => _error = l10n.aiProvidersDuplicateName);
        return;
      }
    }
    Navigator.of(context).pop((name, url, _model.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.add_rounded, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.aiProvidersAddTitle,
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ProviderField(
              controller: _name,
              label: l10n.aiProvidersFieldName,
              hint: l10n.aiProvidersFieldNameHint,
            ),
            const SizedBox(height: 12),
            _ProviderField(
              controller: _url,
              label: l10n.aiProvidersFieldBaseUrl,
              hint: l10n.aiProvidersFieldBaseUrlHint,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            _ProviderField(
              controller: _model,
              label: l10n.aiProvidersFieldModel,
              hint: l10n.aiProvidersFieldModelHint,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => _submit(
            l10n,
            <String>{
              for (final CustomAiProvider p
                  in CustomAiProviderStore.instance.all)
                p.name,
            },
          ),
          child: Text(l10n.aiProvidersAddConfirm),
        ),
      ],
    );
  }
}

/// A single labelled text field inside [_CustomProviderDialog].
class _ProviderField extends StatelessWidget {
  const _ProviderField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: label == AppLocalizations.of(context).aiProvidersFieldName,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
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
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
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
