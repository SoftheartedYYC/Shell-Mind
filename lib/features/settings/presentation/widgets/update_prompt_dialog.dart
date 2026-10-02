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
import 'update_section.dart' show confirmAndInstall;

/// Mounts [child] and raises the "new release" prompt exactly once per session
/// when the background check finds a newer build.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _presented = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateState>(updateProvider, (_, UpdateState next) {
      if (!next.pendingPrompt || _presented) return;
      _presented = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        ref.read(updateProvider.notifier).consumePrompt();
        await showUpdatePrompt(context);
        _presented = false;
      });
    });
    return widget.child;
  }
}

/// Presents the modal release announcement.
Future<void> showUpdatePrompt(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const _UpdatePromptDialog(),
  );
}

class _UpdatePromptDialog extends ConsumerStatefulWidget {
  const _UpdatePromptDialog();

  @override
  ConsumerState<_UpdatePromptDialog> createState() =>
      _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends ConsumerState<_UpdatePromptDialog> {
  @override
  Widget build(BuildContext context) {
    final UpdateState s = ref.watch(updateProvider);
    final UpdateNotifier controller = ref.read(updateProvider.notifier);
    final UpdateInfo? info = s.updateInfo;

    if (info == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _Body(state: s, controller: controller, info: info),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.controller,
    required this.info,
  });

  final UpdateState state;
  final UpdateNotifier controller;
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      UpdateStatus.downloading => _downloading(context),
      UpdateStatus.readyToInstall => _ready(context),
      UpdateStatus.error => _error(context),
      _ => _available(context),
    };
  }

  Widget _available(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_upward_rounded,
                  size: 20, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.updateNewVersionAvailable,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: UpdateVersionArrow(
            from: state.currentVersion,
            to: info.version,
            fontSize: 15,
          ),
        ),
        if (info.releaseNotes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          UpdateNotesPanel(
            notes: info.releaseNotes,
            tag: info.tagName,
            maxHeight: 190,
          ),
        ],
        const SizedBox(height: 14),
        UpdateMetaStrip(
          maxTextWidth: 130,
          items: <UpdateMeta>[
            UpdateMeta(Icons.sd_storage_outlined, formatBytes(info.fileSize)),
            UpdateMeta(Icons.schedule_rounded, formatTimeAgo(info.publishedAt)),
          ],
        ),
        const SizedBox(height: 20),
        TerminalActionButton(
          label: l10n.updateDownloadInstall,
          glyph: Icons.download_rounded,
          filled: true,
          height: 44,
          onPressed: controller.downloadUpdate,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _close(context, controller),
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              minimumSize: const Size(0, 36),
            ),
            child: Text(l10n.updateRemindLater),
          ),
        ),
      ],
    );
  }

  Widget _downloading(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DownloadProgress p = state.progress ?? const DownloadProgress();
    final int total = p.total > 0 ? p.total : info.fileSize;
    final double fraction =
        total > 0 ? (p.downloaded / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.updateDownloading(info.tagName),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
              ),
            ),
            Text(
              total > 0 ? '${(fraction * 100).toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        BlockProgressBar(progress: total > 0 ? fraction : null, height: 10),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
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
          ],
        ),
        const SizedBox(height: 20),
        TerminalActionButton(
          label: l10n.updateCancelDownload,
          glyph: Icons.close_rounded,
          accent: colors.error,
          onPressed: () async {
            await controller.cancelDownload();
            if (context.mounted) Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }

  Widget _ready(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int size = state.progress?.downloaded ?? info.fileSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UpdatePanelHeading(
          icon: Icons.check_rounded,
          color: context.sem.success,
          title: l10n.updateDownloadComplete,
          children: <Widget>[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                '${info.assetName.isEmpty ? '${info.tagName}.apk' : info.assetName}'
                ' · ${formatBytes(size)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        UpdateInlineHint(
          icon: Icons.warning_amber_rounded,
          color: context.sem.warning,
          text: l10n.updatePromptInstallHint,
        ),
        const SizedBox(height: 20),
        TerminalActionButton(
          label: state.isInstalling
              ? l10n.updateLaunching
              : l10n.updateInstallTag(info.tagName),
          glyph: Icons.install_mobile_rounded,
          accent: context.sem.success,
          filled: true,
          height: 44,
          busy: state.isInstalling,
          onPressed: state.isInstalling
              ? null
              : () => confirmAndInstall(context, controller, state),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              minimumSize: const Size(0, 36),
            ),
            child: Text(l10n.updateInstallLaterFromSettings),
          ),
        ),
      ],
    );
  }

  Widget _error(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppFailure failure = state.failure ??
        AppFailure(
          kind: FailureKind.unexpected,
          message: l10n.updateCouldNotComplete,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ErrorBanner(
          failure: failure,
          dense: true,
          showCode: false,
          title: updateFailureTitle(context, failure),
          message: describeUpdateFailure(context, failure),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TerminalActionButton(
                label: l10n.updateRetry,
                glyph: Icons.refresh_rounded,
                onPressed: state.hasDownloadedFile
                    ? controller.restoreDownload
                    : controller.downloadUpdate,
              ),
            ),
            const SizedBox(width: 8),
            TerminalActionButton(
              label: l10n.updateClose,
              expand: false,
              onPressed: () => _close(context, controller),
            ),
          ],
        ),
      ],
    );
  }

  void _close(BuildContext context, UpdateNotifier controller) {
    controller.dismiss();
    Navigator.of(context).maybePop();
  }
}
