import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/auth_lock.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/supported_languages.dart';
import '../../../../core/services/storage_inspector.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/hide_ip_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/ai_settings_section.dart';
import '../widgets/data_transfer_section.dart';
import '../widgets/ssh_reconnect_section.dart';
import '../widgets/storage_dialogs.dart';
import '../widgets/terminal_scheme_section.dart';
import '../widgets/update_section.dart';

/// Settings page — clean Material 3 design with theme switching.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Top inset mirrors the 16px breathing room other tabs give their
          // headers (SafeArea already clears the status bar).
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: <Widget>[
            _Section(
              label: l10n.settingsSectionAiProvider,
              children: <Widget>[
                const AiSettingsSection(),
              ],
            ),
            _Section(
              label: l10n.settingsSectionAiAgent,
              children: <Widget>[
                const _AiAgentSection(),
              ],
            ),
            _Section(
              label: l10n.settingsSectionSsh,
              children: <Widget>[
                const SshReconnectSection(),
                const TerminalSchemeTile(),
              ],
            ),
            _Section(
              label: l10n.settingsSectionServers,
              children: <Widget>[
                _HideIpTile(),
              ],
            ),
            _Section(
              label: l10n.settingsSectionNotifications,
              children: <Widget>[
                const _NotificationsTile(),
              ],
            ),
            const _AppearanceSection(),
            _Section(
              label: l10n.settingsSectionDataTransfer,
              children: <Widget>[
                const SnippetTransferTile(),
                const ServerTransferTile(),
              ],
            ),
            _Section(
              label: l10n.settingsSectionStoragePrivacy,
              children: <Widget>[
                const _AuthLockTile(),
                _SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.auditTitle,
                  value: l10n.auditTileDesc,
                  onTap: () => context.pushNamed(RouteNames.auditLog),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: l10n.settingsTileSecrets,
                  value: l10n.settingsTileEncrypted,
                  onTap: () => showSecretsInfoDialog(context),
                ),
                const _LocalCacheTile(),
                _SettingsTile(
                  icon: Icons.delete_sweep_outlined,
                  title: l10n.settingsTileClearData,
                  value: '',
                  destructive: true,
                  onTap: () => confirmClearAllData(context, ref),
                ),
              ],
            ),
            _Section(
              label: l10n.settingsSectionResources,
              highlight: UpdateSection.needsAttention(ref.watch(updateProvider)),
              children: <Widget>[
                const UpdateSection(),
                _SettingsTile(
                  icon: Icons.monitor_heart_outlined,
                  title: l10n.diagTitle,
                  value: l10n.diagTileDesc,
                  onTap: () => context.pushNamed(RouteNames.diagnostics),
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: l10n.settingsTileLicenses,
                  value: '',
                  onTap: () => showOpenSourceLicences(context),
                ),
                _SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: l10n.settingsTileReportIssue,
                  value: '',
                  onTap: () => openIssueTracker(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _FooterSignature(),
          ],
        ),
      ),
    );
  }
}

// ─── Appearance & language section ────────────────────────────────────────

/// Appearance (theme mode) and language pickers merged into one visual
/// group so both "how the app looks" controls live side by side.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final ThemeModeNotifier themeNotifier =
        ref.read(themeModeProvider.notifier);
    final locale = ref.watch(localeProvider);
    final LocaleNotifier localeNotifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final String currentLanguage = locale?.languageCode ?? 'system';

    return _Section(
      label: l10n.settingsSectionAppearance,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SegmentedButton<ThemeMode>(
            segments: <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_rounded),
                label: Text(l10n.settingsThemeSystem),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_rounded),
                label: Text(l10n.settingsThemeLight),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_rounded),
                label: Text(l10n.settingsThemeDark),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              themeNotifier.setThemeMode(selection.first);
            },
            showSelectedIcon: false,
          ),
        ),
        _LanguageTile(
          currentLanguage: currentLanguage,
          onChanged: localeNotifier.setLocale,
        ),
      ],
    );
  }
}

/// Row that shows the active language and opens a bottom sheet listing every
/// supported language (each in its own script) so the app can switch among
/// many locales instead of the old three-way segmented control.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.currentLanguage,
    required this.onChanged,
  });

  final String currentLanguage;
  final Future<void> Function(Locale? locale) onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LanguageOption current = languageOptionFor(currentLanguage);
    final String label = current.code == 'system'
        ? l10n.settingsLanguageSystem
        : current.nativeName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageSheet(context, l10n),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(Icons.language_rounded,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.settingsLanguageTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                l10n.settingsLanguageTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kSupportedLanguages.length,
                itemBuilder: (BuildContext ctx, int index) {
                  final LanguageOption option = kSupportedLanguages[index];
                  final bool selected = option.code == currentLanguage;
                  final String label = option.code == 'system'
                      ? l10n.settingsLanguageSystem
                      : option.nativeName;
                  return ListTile(
                    title: Text(label),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onChanged(
                        option.code == 'system'
                            ? null
                            : Locale(option.code),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── AI Agent section ─────────────────────────────────────────────────────

/// Agent autonomy controls: the auto-execute toggle plus the cap on
/// automatic command loops. Lives outside [AiSettingsSection] so the
/// "AI provider" and "AI agent" concerns get their own labelled groups.
class _AiAgentSection extends ConsumerWidget {
  const _AiAgentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiSettingsState s = ref.watch(aiSettingsProvider);
    final AiSettingsController controller =
        ref.read(aiSettingsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: <Widget>[
              Icon(Icons.smart_toy_rounded,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.settingsAiAutoExecuteTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      l10n.settingsAiAutoExecuteSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: s.aiAutoExecute,
                onChanged: controller.setAiAutoExecute,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: <Widget>[
              Icon(Icons.lan_rounded, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.settingsAiAutoConnectTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      l10n.settingsAiAutoConnectSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: s.aiAutoConnect,
                onChanged: controller.setAiAutoConnect,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _showMaxLoopsSheet(context, ref, s.aiMaxAutoLoops),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(Icons.repeat_rounded,
                    size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.settingsAiMaxAutoLoopsTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        l10n.settingsAiMaxAutoLoopsTileDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${s.aiMaxAutoLoops}',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: AppTheme.monoFallback,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.settingsAiMaxAutoLoopsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Stepper dialog for the max automatic loop count per AI task
  /// ([AppConstants.kMinMaxAutoLoops]–[AppConstants.kMaxMaxAutoLoops]).
  void _showMaxLoopsSheet(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    int selected = current;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
          title: Text(l10n.settingsAiMaxAutoLoopsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.settingsAiMaxAutoLoopsSub),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton.filledTonal(
                    onPressed: selected > AppConstants.kMinMaxAutoLoops
                        ? () => setState(() => selected--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$selected',
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                            fontFamily: AppTheme.monoFont,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: selected < AppConstants.kMaxMaxAutoLoops
                        ? () => setState(() => selected++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                ref.read(aiSettingsProvider.notifier).setMaxAutoLoops(selected);
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children, this.highlight = false});

  final String label;
  final List<Widget> children;

  /// Draws an accent border instead of the default outline. Used by the
  /// "Resources" section so the update block keeps its attention cue that
  /// previously lived on the update card's own border.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: label),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight
                    ? colors.primary.withValues(alpha: 0.4)
                    : colors.outlineVariant,
              ),
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
            child: Column(
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant,
                      indent: 52,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────

/// "Local cache" tile that reports the real on-disk footprint. The size is
/// resolved asynchronously (Hive files + cached update APKs) and refreshed
/// after the cache dialog closes, so a cleanup is reflected immediately.
class _LocalCacheTile extends ConsumerStatefulWidget {
  const _LocalCacheTile();

  @override
  ConsumerState<_LocalCacheTile> createState() => _LocalCacheTileState();
}

class _LocalCacheTileState extends ConsumerState<_LocalCacheTile> {
  String _size = '';

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    final CacheBreakdown breakdown =
        await ref.read(storageInspectorProvider).inspect();
    if (!mounted) return;
    setState(() => _size = formatBytes(breakdown.totalBytes));
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.storage_rounded,
      title: AppLocalizations.of(context).settingsTileLocalCache,
      value: _size,
      onTap: () async {
        await showStorageCacheDialog(context);
        await _measure();
      },
    );
  }
}

// ─── Hide-IP privacy tile ─────────────────────────────────────────────────

/// Switch tile for the "hide IP addresses" privacy toggle.
class _HideIpTile extends ConsumerWidget {
  const _HideIpTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool hideIp = ref.watch(hideIpAddressesProvider);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(Icons.visibility_off_outlined,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.settingsHideIp,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    l10n.settingsHideIpDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: hideIp,
              onChanged: (bool value) => ref
                  .read(hideIpAddressesProvider.notifier)
                  .setHideIpAddresses(value),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notifications tile ────────────────────────────────────────────────────

/// Switch tile for background-alert notifications.
class _NotificationsTile extends ConsumerStatefulWidget {
  const _NotificationsTile();

  @override
  ConsumerState<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends ConsumerState<_NotificationsTile> {
  bool? _value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool value = _value ??
        ref.read(preferencesServiceProvider).notificationsEnabled;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(Icons.notifications_outlined,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.settingsNotificationsTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    l10n.settingsNotificationsDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (bool next) async {
                setState(() => _value = next);
                await ref
                    .read(preferencesServiceProvider)
                    .setNotificationsEnabled(next);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Biometric app-lock tile ──────────────────────────────────────────────

/// Switch tile for the biometric app lock ("Storage & Privacy" section).
///
/// Enabling runs a verification round-trip first — see
/// [AuthLockController.setEnabled]. When the device cannot verify (no
/// hardware / nothing enrolled) or the user cancels, the switch snaps back
/// and a hint explains why the lock stays off.
class _AuthLockTile extends ConsumerStatefulWidget {
  const _AuthLockTile();

  @override
  ConsumerState<_AuthLockTile> createState() => _AuthLockTileState();
}

class _AuthLockTileState extends ConsumerState<_AuthLockTile> {
  /// Whether the enable round-trip is in flight (disables the switch).
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AuthLockState lock = ref.watch(authLockProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(Icons.fingerprint_rounded,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.authLockToggleTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    _subtitle(l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: lock.enabled,
                onChanged: (bool value) async {
                  // Captured before the async gap so the snackbar never uses
                  // a BuildContext across the verification round-trip.
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  setState(() => _busy = true);
                  final AuthLockToggleResult result = await ref
                      .read(authLockProvider.notifier)
                      .setEnabled(value);
                  if (!mounted) return;
                  setState(() => _busy = false);
                  final String? message = switch (result) {
                    AuthLockToggleResult.applied => null,
                    AuthLockToggleResult.unavailable =>
                      l10n.authLockUnavailableDesc,
                    AuthLockToggleResult.failed => l10n.authLockEnableFailed,
                  };
                  if (message != null) {
                    messenger.showSnackBar(SnackBar(content: Text(message)));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Explanatory copy under the title: the setting description when the lock
  /// is on, the device-capability hint when the device cannot verify.
  String _subtitle(AppLocalizations l10n) {
    final bool deviceCapable =
        ref.watch(biometricCapabilityProvider).value ?? false;
    if (!deviceCapable) return l10n.authLockUnavailableDesc;
    return l10n.authLockToggleDesc;
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color titleColor = destructive ? colors.error : colors.onSurface;
    final Color iconColor =
        destructive ? colors.error : colors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────

class _FooterSignature extends StatelessWidget {
  const _FooterSignature();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Divider(color: colors.outlineVariant),
          const SizedBox(height: 14),
          Text(
            l10n.settingsFooter,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
