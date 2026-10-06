import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';

// ─── API key setup guide ────────────────────────────────────────────────

/// Full-body guide shown when no API key is configured (or the credentials
/// check failed). Directs the user to the provider settings screen.
class ApiKeySetupGuide extends StatelessWidget {
  const ApiKeySetupGuide({super.key, required this.onOpenSettings, this.providerName});

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
