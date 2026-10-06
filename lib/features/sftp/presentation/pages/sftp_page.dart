import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../data/sftp_service.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/sftp_path.dart';

/// SFTP file browser bound to one connected server.
///
/// Lists directories (with navigation and a parent link), previews text files,
/// downloads to the app documents folder, and offers mkdir / rename / delete.
class SftpPage extends ConsumerStatefulWidget {
  const SftpPage({super.key, required this.serverId});

  final String serverId;

  @override
  ConsumerState<SftpPage> createState() => _SftpPageState();
}

class _SftpPageState extends ConsumerState<SftpPage> {
  SftpService? _service;
  String _path = '.';
  List<RemoteFileEntry>? _entries;
  String? _error;
  bool _loading = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    final SftpService? service = _service;
    _service = null;
    if (service != null) {
      unawaited(service.close());
    }
    super.dispose();
  }

  Future<void> _open() async {
    final RegisteredSession? session =
        ref.read(sshSessionRegistryProvider)[widget.serverId];
    if (session == null || !session.isConnected) {
      setState(() => _error = AppLocalizations.of(context).sftpNotConnected);
      return;
    }
    try {
      final client = await session.manager.openSftp();
      _service = SftpService(client);
      _connected = true;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _refresh() async {
    final SftpService? service = _service;
    if (service == null) return;
    setState(() => _loading = true);
    try {
      final List<RemoteFileEntry> entries = await service.list(_path);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enter(RemoteFileEntry entry) {
    if (!entry.isDirectory && !entry.isSymbolicLink) {
      _preview(entry);
      return;
    }
    setState(() => _path = SftpPath.join(_path, entry.name));
    _refresh();
  }

  void _goUp() {
    setState(() => _path = SftpPath.parent(_path));
    _refresh();
  }

  Future<void> _preview(RemoteFileEntry entry) async {
    final SftpService? service = _service;
    if (service == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String path = SftpPath.join(_path, entry.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(path, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: service.readText(path),
                builder: (BuildContext context, AsyncSnapshot<String> snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: AppSpinner()),
                    );
                  }
                  if (snap.hasError) {
                    return Text(
                      '${l10n.sftpPreviewError}: ${snap.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        snap.data ?? '',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.sftpDownload),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _download(entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _download(RemoteFileEntry entry) async {
    final SftpService? service = _service;
    if (service == null || entry.isDirectory) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final Directory dl = Directory('${dir.path}${Platform.pathSeparator}downloads');
      if (!dl.existsSync()) await dl.create(recursive: true);
      final File out =
          File('${dl.path}${Platform.pathSeparator}${entry.name}');
      final IOSink sink = out.openWrite();
      final int total = await service.download(
        SftpPath.join(_path, entry.name),
        sink,
      );
      await sink.close();
      if (!mounted) return;
      _toast(l10n.sftpDownloaded(out.path, total));
    } catch (e) {
      if (mounted) _toast('${l10n.sftpDownloadFailed}: $e');
    }
  }

  Future<void> _mkdir() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? name = await _prompt(l10n.sftpNewFolderName);
    if (name == null || name.isEmpty || _service == null) return;
    try {
      await _service!.mkdir(SftpPath.join(_path, name));
      await _refresh();
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<void> _delete(RemoteFileEntry entry) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(l10n.sftpDelete),
            content: Text(l10n.sftpDeleteConfirm(entry.name)),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.commonCancel)),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.sftpDelete)),
            ],
          ),
        ) ??
        false;
    if (!ok || _service == null) return;
    try {
      await _service!.delete(SftpPath.join(_path, entry.name));
      await _refresh();
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<void> _rename(RemoteFileEntry entry) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? name = await _prompt(l10n.sftpRename, initial: entry.name);
    if (name == null || name.isEmpty || _service == null) return;
    try {
      await _service!.rename(
        SftpPath.join(_path, entry.name),
        SftpPath.join(_path, name),
      );
      await _refresh();
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<String?> _prompt(String title, {String initial = ''}) {
    final TextEditingController controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context).commonCancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(AppLocalizations.of(context).commonOk)),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sftpTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.sftpNewFolderName,
            onPressed: _connected ? _mkdir : null,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: l10n.sftpRefresh,
            onPressed: _connected ? _refresh : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Breadcrumb path bar.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colors.surfaceContainerLow,
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: _path == '.' || _path == '/' ? null : _goUp,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                ),
                Expanded(
                  child: Text(
                    _path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(l10n, colors)),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n, ColorScheme colors) {
    if (_error != null) {
      return ErrorBanner(
        failure: AppFailure.ssh(_error!),
        onRetry: _open,
      );
    }
    final List<RemoteFileEntry>? entries = _entries;
    if (entries == null) {
      return Center(
        child: AppLoader(label: _loading ? l10n.sftpLoading : ''),
      );
    }
    if (entries.isEmpty) {
      return Center(
        child: Text(
          l10n.sftpEmpty,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final RemoteFileEntry entry = entries[index];
        return ListTile(
          leading: Icon(
            entry.isDirectory
                ? Icons.folder_rounded
                : entry.isSymbolicLink
                    ? Icons.link_rounded
                    : Icons.insert_drive_file_outlined,
            color: entry.isDirectory ? colors.primary : colors.onSurfaceVariant,
          ),
          title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            <String>[
              if (entry.permissions != null) entry.permissions!,
              if (entry.size != null) _formatBytes(entry.size!),
            ].join(' · '),
            style: const TextStyle(fontSize: 11),
          ),
          onTap: () => _enter(entry),
          onLongPress: () => _showEntryMenu(entry),
        );
      },
    );
  }

  Future<void> _showEntryMenu(RemoteFileEntry entry) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: Text(l10n.sftpRename),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.sftpDelete),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') await _rename(entry);
    if (action == 'delete') await _delete(entry);
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
