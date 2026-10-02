import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/data_maintenance.dart';
import '../../../../core/services/storage_inspector.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_chat/presentation/providers/chat_providers.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/update_provider.dart';

// ─── Secrets / encryption ─────────────────────────────────────────────────

/// Explains that credentials are always encrypted at rest by the platform
/// keystore, and that this protection is by design and cannot be disabled.
Future<void> showSecretsInfoDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ColorScheme colors = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      icon: Icon(Icons.shield_outlined, color: colors.primary, size: 28),
      title: Text(l10n.settingsSecretsDialogTitle),
      content: Text(
        l10n.settingsSecretsDialogBody,
        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.settingsDialogOk),
        ),
      ],
    ),
  );
}

// ─── Storage / cache ──────────────────────────────────────────────────────

/// Opens the cache-detail dialog: Hive data size, downloaded update size, and
/// a button to reclaim the download cache (Hive data is preserved).
Future<void> showStorageCacheDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const _CacheDialog(),
  );
}

class _CacheDialog extends ConsumerStatefulWidget {
  const _CacheDialog();

  @override
  ConsumerState<_CacheDialog> createState() => _CacheDialogState();
}

class _CacheDialogState extends ConsumerState<_CacheDialog> {
  late Future<CacheBreakdown> _future;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(storageInspectorProvider).inspect();
  }

  void _reload() {
    setState(() {
      _future = ref.read(storageInspectorProvider).inspect();
    });
  }

  Future<void> _clearDownloads() async {
    setState(() => _clearing = true);
    final StorageInspector inspector = ref.read(storageInspectorProvider);
    final int freed = await inspector.clearDownloadCache();
    // The downloaded APK may back an active update panel — drop that state so
    // it does not point at a file we just deleted.
    ref.read(updateProvider.notifier).dismiss();
    if (!mounted) return;
    setState(() => _clearing = false);
    _reload();
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsCacheCleared(formatBytes(freed)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.storage_rounded, color: colors.primary, size: 28),
      title: Text(l10n.settingsCacheDialogTitle),
      content: SizedBox(
        width: 320,
        child: FutureBuilder<CacheBreakdown>(
          future: _future,
          builder: (BuildContext ctx, AsyncSnapshot<CacheBreakdown> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final CacheBreakdown data = snap.data ?? const CacheBreakdown();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _CacheRow(
                  label: l10n.settingsCacheHiveData,
                  value: formatBytes(data.hiveBytes),
                ),
                _CacheRow(
                  label: l10n.settingsCacheDownloads,
                  value: formatBytes(data.downloadBytes),
                ),
                Divider(color: colors.outlineVariant),
                _CacheRow(
                  label: l10n.settingsCacheTotal,
                  value: formatBytes(data.totalBytes),
                  emphasis: true,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsCacheDialogHint,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.settingsDialogClose),
        ),
        FilledButton.tonalIcon(
          onPressed: _clearing ? null : _clearDownloads,
          icon: _clearing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cleaning_services_outlined, size: 16),
          label: Text(l10n.settingsCacheClearDownloads),
        ),
      ],
    );
  }
}

class _CacheRow extends StatelessWidget {
  const _CacheRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: emphasis ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: emphasis ? colors.primary : colors.onSurface,
                  fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Clear all data ───────────────────────────────────────────────────────

/// Asks for confirmation, then wipes Hive, the keystore and preferences, and
/// invalidates every dependent provider so the UI reflects the reset.
Future<void> confirmClearAllData(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ColorScheme colors = Theme.of(context).colorScheme;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colors.error, size: 28),
      title: Text(l10n.settingsClearDataTitle),
      content: Text(
        l10n.settingsClearDataMessage,
        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.settingsClearDataConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final DataMaintenance maintenance = ref.read(dataMaintenanceProvider);
  final Result<void> result = await maintenance.clearAll();

  result.when(
    success: (_) {
      // Reset every provider that caches storage-derived state.
      ref.invalidate(serverConfigListProvider);
      ref.invalidate(serverConfigListStreamProvider);
      ref.invalidate(chatMessagesProvider);
      ref.invalidate(aiSettingsProvider);
      ref.invalidate(themeModeProvider);
      ref.invalidate(localeProvider);
      ref.invalidate(updateProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsDataCleared)),
      );
    },
    failure: (AppFailure f) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsClearDataFailed(f.message))),
      );
    },
  );
}

// ─── Resources ────────────────────────────────────────────────────────────

/// Opens Flutter's built-in licence page listing every package's licence.
void showOpenSourceLicences(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  showLicensePage(
    context: context,
    applicationName: l10n.appTitle,
    applicationLegalese: l10n.settingsFooter,
  );
}

/// Opens the GitHub issue tracker. Falls back to copying the URL to the
/// clipboard (with a SnackBar) when no browser can handle it.
Future<void> openIssueTracker(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String url =
      'https://github.com/${UpdateService.repoOwner}/${UpdateService.repoName}'
      '/issues/new';
  final Uri uri = Uri.parse(url);

  bool launched = false;
  try {
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    launched = false;
  }

  if (!launched) {
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsIssueLinkCopied)),
    );
  }
}
