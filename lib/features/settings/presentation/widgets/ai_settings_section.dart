import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../providers/ai_settings_provider.dart';

/// Settings block for the AI provider: API key (masked), model picker, and
/// temperature. Matches the hairline-row grammar of the rest of Settings.
class AiSettingsSection extends ConsumerWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiSettingsState s = ref.watch(aiSettingsProvider);
    final AiSettingsController controller =
        ref.read(aiSettingsProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          _Row(
            icon: Icons.key_rounded,
            title: 'API key',
            trailing: s.isLoading
                ? const _Spinner()
                : GestureDetector(
                    onTap: () => _openKeyDialog(context, controller, s),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          s.hasKey ? (s.maskedKey ?? 'set') : 'not configured',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: const <String>[
                              'JetBrains Mono',
                              'Menlo',
                              'monospace',
                            ],
                            fontSize: 11.5,
                            letterSpacing: 0.3,
                            color: s.hasKey ? AppTheme.mint : AppTheme.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppTheme.textTertiary),
                      ],
                    ),
                  ),
          ),
          const _Divider(),
          _Row(
            icon: Icons.memory_rounded,
            title: 'Model',
            trailing: _ModelPicker(
              value: s.model,
              onChanged: controller.setModel,
            ),
          ),
          const _Divider(),
          _Row(
            icon: Icons.thermostat_rounded,
            title: 'Temperature',
            trailing: Text(
              s.temperature.toStringAsFixed(2),
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Slider(
              value: s.temperature.clamp(0.0, 2.0),
              min: 0,
              max: 2,
              divisions: 20,
              onChanged: controller.setTemperature,
            ),
          ),
          if (s.hasKey) ...<Widget>[
            const _Divider(),
            _Row(
              icon: Icons.delete_outline_rounded,
              title: 'Remove key',
              destructive: true,
              trailing: GestureDetector(
                onTap: () => _confirmClear(context, controller),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppTheme.coral),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openKeyDialog(
    BuildContext context,
    AiSettingsController controller,
    AiSettingsState state,
  ) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _ApiKeyDialog(existing: state.hasKey),
    );
    if (result != null && result.trim().isNotEmpty) {
      await controller.saveKey(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved securely.')),
        );
      }
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    AiSettingsController controller,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove API key?'),
        content: const Text(
          'The assistant will stop working until a new key is added.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.coral),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.clearKey();
    }
  }
}

// ─── API key dialog ─────────────────────────────────────────────────────

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.existing});
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
    return AlertDialog(
      title: Row(
        children: <Widget>[
          const Icon(Icons.key_rounded, size: 18, color: AppTheme.phosphor),
          const SizedBox(width: 10),
          Text(
            widget.existing ? 'Update API key' : 'Add API key',
            style: context.text.titleLarge,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Stored encrypted on this device. Used only to call OpenAI.',
            style: context.text.bodySmall
                ?.copyWith(color: AppTheme.textTertiary, height: 1.5),
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
            cursorColor: AppTheme.phosphorGlow,
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: const <String>[
                'JetBrains Mono',
                'Menlo',
                'monospace',
              ],
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'sk-…',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? () => Navigator.of(context).pop(_controller.text) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Model picker ───────────────────────────────────────────────────────

class _ModelPicker extends StatelessWidget {
  const _ModelPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Select model',
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final String m in kAvailableChatModels)
          PopupMenuItem<String>(
            value: m,
            child: Row(
              children: <Widget>[
                Icon(
                  m == value
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: m == value ? AppTheme.phosphor : AppTheme.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(
                  m,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 12,
                    color: m == value ? AppTheme.phosphor : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: const <String>[
                  'JetBrains Mono',
                  'Menlo',
                  'monospace',
                ],
                fontSize: 11.5,
                letterSpacing: 0.3,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── Shared row chrome ──────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: destructive
                  ? AppTheme.coral.withValues(alpha: 0.08)
                  : const Color(0xFF0E1322),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: destructive
                    ? AppTheme.coral.withValues(alpha: 0.35)
                    : AppTheme.inkBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 13,
              color: destructive ? AppTheme.coral : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: context.text.bodyMedium?.copyWith(
                color: destructive ? AppTheme.coral : AppTheme.textPrimary,
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.inkBorderSoft,
        indent: 52,
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.phosphor),
        ),
      );
}
