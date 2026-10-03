import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/domain/entities/ai_provider.dart';
import '../../../ai_chat/presentation/providers/models_provider.dart';
import '../providers/ai_settings_provider.dart';

/// Modal bottom sheet for picking the active AI model.
///
/// Reads the merged catalogue (built-in ∪ fetched ∪ custom) from
/// [availableModelsProvider], offers a live filter by model id/name, and
/// keeps the refresh / add-custom / remove-custom affordances that used to
/// live inline on the settings page. Selecting a row applies it immediately
/// through [AiSettingsController.setModel] and closes the sheet.
///
/// Presentation mirrors [ServerSelectorSheet]: a rounded top container with a
/// title row, a search field, and a lazily-built list.
class ModelPickerSheet extends ConsumerStatefulWidget {
  const ModelPickerSheet({super.key});

  /// Shows the sheet; returns the picked model id (`null` when dismissed).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => const ModelPickerSheet(),
    );
  }

  @override
  ConsumerState<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<ModelPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Filtered view of the catalogue: case-insensitive match against the
  /// model id or friendly name. An empty query shows everything.
  List<AiModel> _filter(List<AiModel> models, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return models;
    return models
        .where((AiModel m) =>
            m.id.toLowerCase().contains(q) ||
            m.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AvailableModelsState> async =
        ref.watch(availableModelsProvider);
    final AvailableModelsState? current = async.valueOrNull;
    final String selectedId =
        ref.watch(aiSettingsProvider.select((AiSettingsState s) => s.model)) ??
            ref.read(aiSettingsProvider).effectiveProvider.defaultModel.id;

    final List<AiModel> models =
        _filter(current?.models ?? const <AiModel>[], _query);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: <Widget>[
          // ── Title row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.aiModelsPickerTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Refresh the live `/models` fetch.
                IconButton(
                  tooltip: l10n.aiModelsRefresh,
                  visualDensity: VisualDensity.compact,
                  onPressed: async.isLoading
                      ? null
                      : () =>
                          ref.read(availableModelsProvider.notifier).refresh(),
                  icon: async.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 20, color: colors.onSurfaceVariant),
                ),
                // Add a custom model id (dedup + persist).
                IconButton(
                  tooltip: l10n.aiModelsAddCustom,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openAddCustomDialog(context),
                  icon: Icon(Icons.add_rounded,
                      size: 20, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // ── Search field ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _search,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (String v) => setState(() => _query = v),
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: AppTheme.monoFallback,
                fontSize: 13,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l10n.aiModelsSearchHint,
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: colors.onSurfaceVariant),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: colors.onSurfaceVariant),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // ── Fetch-error hint (retry keeps the sheet open) ────────────────
          if (current?.fetchError != null)
            _FetchErrorHint(
              onRetry: () =>
                  ref.read(availableModelsProvider.notifier).refresh(),
            ),

          // ── Model list ───────────────────────────────────────────────────
          Expanded(
            child: current == null
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : models.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            current.models.isEmpty
                                ? l10n.aiModelsEmpty
                                : l10n.aiModelsSearchEmpty,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: models.length,
                        itemBuilder: (BuildContext context, int index) {
                          final AiModel model = models[index];
                          final bool active = model.id == selectedId;
                          final bool isCustom = current.isCustom(model.id);
                          return _ModelOptionTile(
                            model: model,
                            active: active,
                            isCustom: isCustom,
                            onSelect: () =>
                                Navigator.of(context).pop<String>(model.id),
                            onRemove: isCustom
                                ? () => ref
                                    .read(customModelsProvider.notifier)
                                    .removeCustomModel(
                                        ref
                                            .read(aiSettingsProvider)
                                            .effectiveProvider
                                            .id,
                                        model.id)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddCustomDialog(BuildContext context) async {
    final String providerId =
        ref.read(aiSettingsProvider).effectiveProvider.id;
    final Set<String> existing = <String>{
      for (final AiModel m
          in ref.read(availableModelsProvider).valueOrNull?.models ??
              const <AiModel>[])
        m.id,
    };
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) =>
          _CustomModelDialog(existingIds: existing),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref
          .read(customModelsProvider.notifier)
          .addCustomModel(providerId, result);
    }
  }
}

// ─── Model row ────────────────────────────────────────────────────────────

/// A single selectable model row: radio state, name, optional description,
/// custom badge and remove action. Mirrors the previous inline `_ModelTile`.
class _ModelOptionTile extends StatelessWidget {
  const _ModelOptionTile({
    required this.model,
    required this.active,
    required this.isCustom,
    required this.onSelect,
    this.onRemove,
  });

  final AiModel model;
  final bool active;
  final bool isCustom;
  final VoidCallback onSelect;

  /// Non-null only for user-added models — shows the remove affordance.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: isCustom ? 10 : 20,
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          model.name,
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
                      if (isCustom) ...<Widget>[
                        const SizedBox(width: 8),
                        _CustomBadge(label: l10n.aiModelsCustomBadge),
                      ],
                    ],
                  ),
                  if (model.description != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      _localizedModelDesc(l10n, model.description!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCustom && onRemove != null)
              IconButton(
                tooltip: l10n.aiModelsRemoveCustom,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
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

/// Small pill labelling a user-added model.
class _CustomBadge extends StatelessWidget {
  const _CustomBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onTertiaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// One-line warning shown when the live model fetch failed, offering a retry.
class _FetchErrorHint extends StatelessWidget {
  const _FetchErrorHint({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 16, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiModelsFetchFailed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.error,
                    fontSize: 11,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a custom model id, with non-empty + duplicate validation.
class _CustomModelDialog extends StatefulWidget {
  const _CustomModelDialog({required this.existingIds});
  final Set<String> existingIds;

  @override
  State<_CustomModelDialog> createState() => _CustomModelDialogState();
}

class _CustomModelDialogState extends State<_CustomModelDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final String id = _controller.text.trim();
    if (id.isEmpty) {
      setState(() => _error = l10n.aiModelsInvalidId);
      return;
    }
    if (widget.existingIds.contains(id)) {
      setState(() => _error = l10n.aiModelsDuplicate);
      return;
    }
    Navigator.of(context).pop(id);
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
            child: Text(l10n.aiModelsAddCustom,
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
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
          hintText: l10n.aiModelsAddCustomHint,
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(l10n),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.aiModelsAdd),
        ),
      ],
    );
  }
}

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
