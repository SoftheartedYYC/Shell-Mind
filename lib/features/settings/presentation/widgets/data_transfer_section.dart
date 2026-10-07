import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/export_saver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../command_snippets/domain/entities/command_snippet.dart';
import '../../../command_snippets/domain/snippet_transfer.dart';
import '../../../command_snippets/presentation/providers/command_snippet_providers.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/domain/server_transfer.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';

/// Export / import tiles for command snippets and server metadata.
///
/// Export writes a versioned JSON document to the app documents `exports/`
/// directory and offers a one-tap copy of the JSON; import accepts pasted JSON
/// (no file picker dependency). Server export is credentials-free by design —
/// secrets never leave the device.
class SnippetTransferTile extends ConsumerWidget {
  const SnippetTransferTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TransferTile(
      icon: Icons.terminal_rounded,
      title: AppLocalizations.of(context).transferSnippetsTitle,
      onTap: () => _showMenu(
        context,
        exportLabel: AppLocalizations.of(context).transferExport,
        importLabel: AppLocalizations.of(context).transferImport,
        onExport: () => _exportSnippets(context, ref),
        onImport: () => _importSnippets(context, ref),
      ),
    );
  }
}

class ServerTransferTile extends ConsumerWidget {
  const ServerTransferTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TransferTile(
      icon: Icons.dns_outlined,
      title: AppLocalizations.of(context).transferServersTitle,
      onTap: () => _showMenu(
        context,
        exportLabel: AppLocalizations.of(context).transferExport,
        importLabel: AppLocalizations.of(context).transferImport,
        onExport: () => _exportServers(context, ref),
        onImport: () => _importServers(context, ref),
      ),
    );
  }
}

// ─── Export / import flows ────────────────────────────────────────────────

Future<void> _exportSnippets(BuildContext context, WidgetRef ref) async {
  final List<CommandSnippet> snippets =
      ref.read(commandSnippetsProvider).value ?? const <CommandSnippet>[];
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (snippets.isEmpty) {
    _toast(context, l10n.transferSnippetsEmpty);
    return;
  }
  final String json = SnippetTransfer.encode(snippets);
  await _saveExport(context, json, fileName: 'shell-mind-snippets-${_stamp()}.json');
}

Future<void> _exportServers(BuildContext context, WidgetRef ref) async {
  final List<ServerConfig> servers =
      ref.read(serverConfigListProvider).value ?? const <ServerConfig>[];
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (servers.isEmpty) {
    _toast(context, l10n.transferServersEmpty);
    return;
  }
  final String json = ServerTransfer.encode(servers);
  await _saveExport(context, json, fileName: 'shell-mind-servers-${_stamp()}.json');
}

/// Runs the system "Save as" dialog and reports the outcome. The user picks
/// the destination; nothing is written to a fixed app directory.
Future<void> _saveExport(
  BuildContext context,
  String content, {
  required String fileName,
}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  try {
    final String? saved = await saveBytesAsFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      allowedExtensions: const <String>['json'],
    );
    if (!context.mounted || saved == null) return; // cancelled by the user
    _toast(context, l10n.transferExportSuccess(saved));
  } catch (e) {
    if (context.mounted) _toast(context, l10n.transferExportFailed(e.toString()));
  }
}

Future<void> _importSnippets(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final String? json = await _promptImportJson(context, l10n.transferSnippetsTitle);
  if (json == null || !context.mounted) return;
  try {
    final List<CommandSnippet> snippets = SnippetTransfer.decode(json);
    if (snippets.isEmpty) {
      _toast(context, l10n.transferImportNothing);
      return;
    }
    final int added = await ref
        .read(commandSnippetsProvider.notifier)
        .importSnippets(snippets);
    if (!context.mounted) return;
    _toast(context, l10n.transferSnippetsImported(added));
  } on FormatException catch (e) {
    if (context.mounted) _toast(context, l10n.transferImportFailed(e.message));
  }
}

Future<void> _importServers(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final String? json = await _promptImportJson(context, l10n.transferServersTitle);
  if (json == null || !context.mounted) return;
  try {
    final List<ServerConfig> servers = ServerTransfer.decode(json);
    if (servers.isEmpty) {
      _toast(context, l10n.transferImportNothing);
      return;
    }
    final int added = await ref
        .read(serverConfigListProvider.notifier)
        .importServers(servers);
    if (!context.mounted) return;
    _toast(context, l10n.transferServersImported(added));
  } on FormatException catch (e) {
    if (context.mounted) _toast(context, l10n.transferImportFailed(e.message));
  }
}

// ─── Shared UI helpers ────────────────────────────────────────────────────

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

Future<void> _showMenu(
  BuildContext context, {
  required String exportLabel,
  required String importLabel,
  required VoidCallback onExport,
  required VoidCallback onImport,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: Text(exportLabel),
            onTap: () {
              Navigator.of(ctx).pop();
              onExport();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: Text(importLabel),
            onTap: () {
              Navigator.of(ctx).pop();
              onImport();
            },
          ),
        ],
      ),
    ),
  );
}

/// Prompts for a JSON payload to import; returns `null` on cancel.
Future<String?> _promptImportJson(BuildContext context, String title) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final TextEditingController controller = TextEditingController();
  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text('$title · ${l10n.transferImport}'),
      content: TextField(
        controller: controller,
        maxLines: 8,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: l10n.transferImportHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final String text = controller.text.trim();
            Navigator.of(ctx).pop(text.isEmpty ? null : text);
          },
          child: Text(l10n.transferImport),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String _stamp() {
  final DateTime now = DateTime.now();
  String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
  return '${p(now.year, 4)}${p(now.month)}${p(now.day)}'
      '-${p(now.hour)}${p(now.minute)}${p(now.second)}';
}

// ─── Tile ─────────────────────────────────────────────────────────────────

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: colors.onSurfaceVariant),
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
              Text(
                l10n.transferExportImport,
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
