import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/storage_inspector.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/hide_ip_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/ai_settings_section.dart';
import '../widgets/ssh_reconnect_section.dart';
import '../widgets/storage_dialogs.dart';
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
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: <Widget>[
            const _SettingsHeader(),
            const _IdentityCard(),
            const SizedBox(height: 8),
            const _AiProviderSection(),
            const _ThemeSection(),
            const _LanguageSection(),
            const _AboutSection(),
            _Section(
              label: l10n.settingsSectionStoragePrivacy,
              children: <Widget>[
                _HideIpTile(),
                _SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.auditTitle,
                  value: l10n.auditTileDesc,
                  onTap: () => context.pushNamed(RouteNames.auditLog),
                ),
                const SshReconnectSection(),
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
              children: <Widget>[
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

// ─── Header ───────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
            tooltip: l10n.settingsSearchTooltip,
          ),
        ],
      ),
    );
  }
}

// ─── Identity card ────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.terminal_rounded,
                  size: 22, color: colors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${AppConstants.appVersion} · build ${AppConstants.appBuildNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: AppLocalizations.of(context).settingsStable,
            color: context.sem.success,
          ),
        ],
      ),
    );
  }
}

// ─── Theme section ────────────────────────────────────────────────────────

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: l10n.settingsSectionAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                notifier.setThemeMode(selection.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language section ──────────────────────────────────────────────────────

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final String currentValue = locale?.languageCode ?? 'system';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: l10n.settingsSectionLanguage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'system',
                  icon: const Icon(Icons.language_rounded),
                  label: Text(l10n.settingsLanguageSystem),
                ),
                ButtonSegment<String>(
                  value: 'zh',
                  label: Text(l10n.settingsLanguageZh),
                ),
                ButtonSegment<String>(
                  value: 'en',
                  label: Text(l10n.settingsLanguageEn),
                ),
              ],
              selected: <String>{currentValue},
              onSelectionChanged: (Set<String> selection) {
                final String code = selection.first;
                notifier.setLocale(code == 'system' ? null : Locale(code));
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI provider section ──────────────────────────────────────────────────

class _AiProviderSection extends StatelessWidget {
  const _AiProviderSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: l10n.settingsSectionAiProvider),
          const AiSettingsSection(),
        ],
      ),
    );
  }
}

// ─── About & update section ───────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: l10n.settingsSectionAboutUpdate),
          const UpdateSection(),
        ],
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

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
