import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/update_provider.dart';
import 'update_controls.dart';

/// "About & update" block for the Settings tab.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  static const String repoPath =
      '${UpdateService.repoOwner}/${UpdateService.repoName}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UpdateState s = ref.watch(updateProvider);
    final UpdateNotifier controller = ref.read(updateProvider.notifier);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _needsAttention(s)
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
          _Row(
            icon: Icons.info_outline_rounded,
            title: l10n.updateVersion,
            trailing: Text(
              'v${s.currentVersion} · build ${s.currentBuildNumber}',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: AppTheme.monoFallback,
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          _SectionDivider(),
          _Row(
            icon: Icons.system_update_alt_rounded,
            title: l10n.updateSoftwareUpdate,
            accent: _accentFor(context, s.status),
            trailing: _CheckControl(state: s, controller: controller),
          ),
          if (_panelVisible(s))
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    FadeTransition(
                  opacity: anim,
                  child: SizeTransition(sizeFactor: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey<String>(_panelKey(s)),
                  child: _StatusPanel(state: s, controller: controller),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _needsAttention(UpdateState s) =>
      s.status == UpdateStatus.updateAvailable ||
      s.status == UpdateStatus.downloading ||
      s.status == UpdateStatus.readyToInstall;

  static bool _panelVisible(UpdateState s) =>
      s.status != UpdateStatus.idle || s.failure != null;

  static String _panelKey(UpdateState s) =>
      '${s.status.name}-${s.updateInfo?.tagName ?? ''}';
}

Color _accentFor(BuildContext context, UpdateStatus status) {
  final sem = context.sem;
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    UpdateStatus.updateAvailable => sem.warning,
    UpdateStatus.downloading => colors.primary,
    UpdateStatus.readyToInstall => sem.success,
    UpdateStatus.upToDate => sem.success,
    UpdateStatus.error => sem.danger,
    UpdateStatus.checking => colors.primary,
    UpdateStatus.idle => colors.onSurfaceVariant,
  };
}

// ─── Row trailing control ─────────────────────────────────────────────────

class _CheckControl extends StatelessWidget {
  const _CheckControl({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    switch (state.status) {
      case UpdateStatus.checking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppSpinner(size: 14, strokeWidth: 2),
            const SizedBox(width: 8),
            Text(
              l10n.updateChecking,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        );

      case UpdateStatus.upToDate:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_rounded, size: 14, color: context.sem.success),
            const SizedBox(width: 6),
            Text(
              l10n.updateUpToDate,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: context.sem.success,
              ),
            ),
            const SizedBox(width: 6),
            _MiniRefresh(
              tooltip: l10n.updateCheckAgain,
              onPressed: state.canCheck ? controller.checkForUpdate : null,
            ),
          ],
        );

      case UpdateStatus.downloading:
        final double pct = (state.progress?.percentage ?? 0) * 100;
        return Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        );

      case UpdateStatus.updateAvailable:
      case UpdateStatus.readyToInstall:
        final bool ready = state.status == UpdateStatus.readyToInstall;
        return StatusPill(
          label: ready ? l10n.updateReady : l10n.updateNew,
          color: ready ? context.sem.success : context.sem.warning,
          size: StatusPillSize.small,
        );

      case UpdateStatus.error:
      case UpdateStatus.idle:
        return _MiniButton(
          label: l10n.updateCheck,
          glyph: Icons.sync_rounded,
          onPressed: state.canCheck ? controller.checkForUpdate : null,
        );
    }
  }
}

// ─── Status panel ─────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: switch (state.status) {
          UpdateStatus.checking => const _CheckingPanel(),
          UpdateStatus.upToDate => _UpToDatePanel(state: state),
          UpdateStatus.updateAvailable =>
            _AvailablePanel(state: state, controller: controller),
          UpdateStatus.downloading =>
            _DownloadingPanel(state: state, controller: controller),
          UpdateStatus.readyToInstall =>
            _ReadyPanel(state: state, controller: controller),
          UpdateStatus.error =>
            _ErrorPanel(state: state, controller: controller),
          UpdateStatus.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ─── Checking ─────────────────────────────────────────────────────────────

class _CheckingPanel extends StatelessWidget {
  const _CheckingPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UpdateCommandLine(
          text: 'curl -s api.github.com/repos/${UpdateSection.repoPath}'
              '/releases/latest',
        ),
        const SizedBox(height: 12),
        AppLoader(
            height: 4,
            label: AppLocalizations.of(context).updateAwaitingResponse,
            compact: true),
      ],
    );
  }
}

// ─── Up to date ───────────────────────────────────────────────────────────

class _UpToDatePanel extends StatelessWidget {
  const _UpToDatePanel({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? latest = state.latestKnownVersion;
    final DateTime? checked = state.lastCheckedAt;

    return UpdatePanelHeading(
      icon: Icons.verified_rounded,
      color: context.sem.success,
      title: l10n.updateAlreadyLatest,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          latest == null
              ? l10n.updateCurrentVersionLatest(state.currentVersion)
              : l10n.updateRunningVersion(state.currentVersion, latest),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
        ),
        if (checked != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            l10n.updateCheckedAgo(formatTimeAgo(checked)),
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 10,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Update available ─────────────────────────────────────────────────────

class _AvailablePanel extends StatelessWidget {
  const _AvailablePanel({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final UpdateInfo? info = state.updateInfo;
    if (info == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UpdatePanelHeading(
          icon: Icons.arrow_upward_rounded,
          color: context.sem.warning,
          title: l10n.updateAvailable,
          trailing: info.isPrerelease
              ? StatusPill(
                  label: l10n.updatePre,
                  color: context.sem.warning,
                  size: StatusPillSize.small,
                )
              : null,
          children: <Widget>[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: UpdateVersionArrow(
                from: state.currentVersion,
                to: info.version,
              ),
            ),
          ],
        ),
        if (info.releaseNotes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          UpdateNotesPanel(notes: info.releaseNotes, tag: info.tagName),
        ],
        const SizedBox(height: 12),
        UpdateMetaStrip(
          items: <UpdateMeta>[
            UpdateMeta(Icons.sd_storage_outlined, formatBytes(info.fileSize)),
            UpdateMeta(Icons.schedule_rounded, formatTimeAgo(info.publishedAt)),
            UpdateMeta(
              Icons.description_outlined,
              info.assetName.isEmpty ? 'apk' : info.assetName,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: TerminalActionButton(
                label: l10n.updateDownloadInstall,
                glyph: Icons.download_rounded,
                filled: true,
                onPressed: controller.downloadUpdate,
              ),
            ),
            const SizedBox(width: 8),
            TerminalActionButton(
              label: l10n.updateLater,
              expand: false,
              onPressed: controller.dismiss,
            ),
          ],
        ),
        if (!controller.canInstallApk) ...<Widget>[
          const SizedBox(height: 10),
          UpdateInlineHint(
            icon: Icons.phonelink_erase_outlined,
            color: context.sem.warning,
            text: l10n.updateApkHint,
          ),
        ],
      ],
    );
  }
}

// ─── Downloading ──────────────────────────────────────────────────────────

class _DownloadingPanel extends StatelessWidget {
  const _DownloadingPanel({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DownloadProgress p = state.progress ?? const DownloadProgress();
    final UpdateInfo? info = state.updateInfo;
    final int total = p.total > 0 ? p.total : (info?.fileSize ?? 0);
    final double fraction =
        total > 0 ? (p.downloaded / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            UpdateStatusGlyph(
              icon: Icons.arrow_downward_rounded,
              color: colors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.updateDownloading(info?.tagName ?? 'update'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                    ),
              ),
            ),
            Text(
              total > 0 ? '${(fraction * 100).toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlockProgressBar(progress: total > 0 ? fraction : null),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: <Widget>[
            UpdateReadout(
              label: l10n.updateSize,
              value: '${formatBytes(p.downloaded)} / '
                  '${total > 0 ? formatBytes(total) : '?'}',
            ),
            UpdateReadout(
              label: l10n.updateRate,
              value: p.speedBytesPerSecond > 0
                  ? '${formatBytes(p.speedBytesPerSecond)}/s'
                  : '—',
            ),
            UpdateReadout(
              label: l10n.updateEta,
              value: p.remaining == null ? '—' : formatDuration(p.remaining!),
            ),
            UpdateReadout(
              label: l10n.updateElapsed,
              value: formatDuration(p.elapsed),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            TerminalActionButton(
              label: l10n.updateCancel,
              glyph: Icons.close_rounded,
              accent: colors.error,
              expand: false,
              onPressed: controller.cancelDownload,
            ),
            const Spacer(),
            Text(
              l10n.updateKeepForeground,
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Ready to install ─────────────────────────────────────────────────────

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final UpdateInfo? info = state.updateInfo;
    final int size = state.progress?.downloaded ?? info?.fileSize ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UpdatePanelHeading(
          icon: Icons.check_rounded,
          color: context.sem.success,
          title: l10n.updateDownloadComplete,
          children: <Widget>[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                '${info?.assetName ?? 'update.apk'} · ${formatBytes(size)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 10,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        UpdateInlineHint(
          icon: Icons.warning_amber_rounded,
          color: context.sem.warning,
          text: l10n.updateInstallHint,
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: TerminalActionButton(
                label: state.isInstalling
                    ? l10n.updateLaunching
                    : l10n.updateInstallNow,
                glyph: Icons.install_mobile_rounded,
                accent: context.sem.success,
                filled: true,
                busy: state.isInstalling,
                onPressed: state.isInstalling
                    ? null
                    : () => confirmAndInstall(context, controller, state),
              ),
            ),
            const SizedBox(width: 8),
            TerminalActionButton(
              label: l10n.updateDelete,
              glyph: Icons.delete_outline_rounded,
              expand: false,
              onPressed: controller.discardDownload,
            ),
          ],
        ),
      ],
    );
  }
}

/// Asks for confirmation, then launches the system installer.
Future<void> confirmAndInstall(
  BuildContext context,
  UpdateNotifier controller,
  UpdateState state,
) async {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? go = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.install_mobile_rounded, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.updateInstallTitle(state.updateInfo?.tagName ?? 'update'),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Text(
        l10n.updateInstallMessage,
        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.updateNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.updateInstall),
        ),
      ],
    ),
  );
  if (go != true) return;
  await controller.installUpdate();
}

// ─── Error ────────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.state, required this.controller});

  final UpdateState state;
  final UpdateNotifier controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppFailure failure = state.failure ??
        AppFailure(
          kind: FailureKind.unexpected,
          message: l10n.updateCheckFailed,
        );

    final bool retryDownload = state.updateInfo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ErrorBanner(failure: failure, dense: true),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            TerminalActionButton(
              label: l10n.updateRetry,
              glyph: Icons.refresh_rounded,
              expand: false,
              onPressed: retryDownload
                  ? controller.downloadUpdate
                  : controller.checkForUpdate,
            ),
            const SizedBox(width: 8),
            TerminalActionButton(
              label: l10n.updateDismiss,
              expand: false,
              onPressed: controller.dismiss,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Row chrome ───────────────────────────────────────────────────────────

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, this.glyph, this.onPressed});

  final String label;
  final IconData? glyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null;
    final Color tint = enabled ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: enabled ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (glyph != null) Icon(glyph, size: 12, color: tint),
            if (glyph != null) const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRefresh extends StatelessWidget {
  const _MiniRefresh({this.onPressed, this.tooltip});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget icon = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          Icons.refresh_rounded,
          size: 14,
          color: onPressed == null
              ? colors.onSurfaceVariant.withValues(alpha: 0.4)
              : colors.onSurfaceVariant,
        ),
      ),
    );
    return tooltip == null ? icon : Tooltip(message: tooltip!, child: icon);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    this.accent,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color tint = accent ?? colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
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
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
        indent: 52,
      );
}
