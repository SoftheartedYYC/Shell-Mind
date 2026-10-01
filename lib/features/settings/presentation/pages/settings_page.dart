import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../widgets/ai_settings_section.dart';

/// Settings tab — a placeholder that establishes the section-based layout
/// the real settings feature will fill in.
///
/// Sections are grouped by concern (Provider, Terminal, Storage, About) and
/// rendered as monospace-labelled rows with hairline dividers, following
/// the same visual grammar as the rest of the app.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: <Widget>[
            const _SettingsHeader(),
            const _IdentityCard(),
            const SizedBox(height: 16),
            const _AiProviderSection(),
            const _Section(
              label: 'terminal',
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Font size',
                  value: '13.5',
                ),
                _SettingsTile(
                  icon: Icons.font_download_outlined,
                  title: 'Font family',
                  value: 'Roboto Mono',
                ),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Colour scheme',
                  value: 'Phosphor',
                ),
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic feedback',
                  value: 'on',
                  trailing: _MockSwitch(value: true),
                ),
              ],
            ),
            const _Section(
              label: 'storage & privacy',
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Secrets',
                  value: 'encrypted',
                  valueColor: AppTheme.mint,
                ),
                _SettingsTile(
                  icon: Icons.storage_rounded,
                  title: 'Local cache',
                  value: '4.2 MB',
                ),
                _SettingsTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear all data',
                  value: '',
                  destructive: true,
                ),
              ],
            ),
            const _Section(
              label: 'about',
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  value: AppConstants.appVersion,
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'Open-source licences',
                  value: '',
                ),
                _SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report an issue',
                  value: '',
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'config',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: const <String>[
                          'JetBrains Mono',
                          'Menlo',
                          'monospace',
                        ],
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.phosphor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.phosphor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '~/config',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Settings.',
                  style: context.text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded,
                size: 20, color: AppTheme.textSecondary),
            tooltip: 'Search settings',
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1322),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.phosphor.withValues(alpha: 0.35)),
            ),
            child: const Center(
              child: Text(
                '>_',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.phosphor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppConstants.appName,
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${AppConstants.appVersion} · build ${AppConstants.appBuildNumber}',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 10.5,
                    letterSpacing: 0.4,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const StatusPill(
            label: 'STABLE',
            color: AppTheme.mint,
          ),
        ],
      ),
    );
  }
}

// ─── AI provider section ──────────────────────────────────────────────────

/// Wraps the live [AiSettingsSection] in the same header + spacing rhythm the
/// static [_Section]s use, so it sits flush with the rest of the page.
class _AiProviderSection extends StatelessWidget {
  const _AiProviderSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: 'ai provider'),
          AiSettingsSection(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(label: label),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.inkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.inkBorderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.inkBorderSoft,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        destructive ? AppTheme.coral : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
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
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (value.isNotEmpty)
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
                    color: valueColor ?? AppTheme.textSecondary,
                  ),
                ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (value.isNotEmpty || trailing == null)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppTheme.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mock switch (placeholder until the real settings land) ───────────────

class _MockSwitch extends StatelessWidget {
  const _MockSwitch({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 20,
      decoration: BoxDecoration(
        color: value ? AppTheme.phosphor : AppTheme.inkElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? AppTheme.phosphor : AppTheme.inkBorder,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: value ? AppTheme.inkVoid : AppTheme.textTertiary,
            shape: BoxShape.circle,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          const Divider(color: AppTheme.inkBorderSoft),
          const SizedBox(height: 14),
          Text(
            'made for people who live in the terminal',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 10,
              letterSpacing: 0.6,
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _FooterDot(color: AppTheme.coral),
              const SizedBox(width: 4),
              const _FooterDot(color: AppTheme.amber),
              const SizedBox(width: 4),
              const _FooterDot(color: AppTheme.mint),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}
