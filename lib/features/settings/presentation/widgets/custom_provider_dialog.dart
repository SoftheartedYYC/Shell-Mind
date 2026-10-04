import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/data/custom_ai_provider_store.dart';

/// Shows the add-custom-provider dialog; resolves with a
/// `(name, baseUrl, model)` record, or `null` when dismissed.
Future<(String, String, String)?> showCustomProviderDialog(
  BuildContext context,
) {
  return showDialog<(String, String, String)>(
    context: context,
    builder: (BuildContext ctx) => const CustomProviderDialog(),
  );
}

/// Dialog collecting name + base URL + optional default model id for a new
/// user-defined provider. Validates non-blank fields, a http(s) URL, and
/// duplicate names; pops with a `(name, baseUrl, model)` record.
class CustomProviderDialog extends StatefulWidget {
  const CustomProviderDialog({super.key});

  @override
  State<CustomProviderDialog> createState() => _CustomProviderDialogState();
}

class _CustomProviderDialogState extends State<CustomProviderDialog> {
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

/// A single labelled text field inside [CustomProviderDialog].
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
