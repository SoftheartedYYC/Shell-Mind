import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme.dart';
import '../../../../../shared/ssh/ssh_session_registry.dart';

/// Server selection bottom sheet for command execution target.
///
/// Displays all online SSH sessions from [SshSessionRegistry] with options for
/// single or multi-select mode. Users can tap an item directly (single) or
/// toggle checkboxes (multi), then confirm their choice.
class ServerSelectorSheet extends ConsumerStatefulWidget {
  const ServerSelectorSheet({super.key, this.multiSelect = false});

  final bool multiSelect;

  /// Shows the sheet and returns selected server IDs.
  /// Returns `null` when cancelled, empty list when none selected in multi mode.
  static Future<List<String>?> show(
    BuildContext context, {
    bool multiSelect = false,
  }) async {
    return await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => ServerSelectorSheet(multiSelect: multiSelect),
    );
  }

  @override
  ConsumerState<ServerSelectorSheet> createState() => _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends ConsumerState<ServerSelectorSheet> {
  final Map<String, bool> _selected = <String, bool>{};

  List<RegisteredSession> get _sessions =>
      ref.read(sshSessionRegistryProvider.notifier).activeSessions;

  void _toggleSelection(String serverId) {
    if (!mounted) return;
    setState(() {
      _selected[serverId] = !(_selected[serverId] ?? false);
    });
  }

  void _selectAll() {
    if (!mounted) return;
    setState(() {
      for (final String id in _selected.keys) {
        _selected[id] = true;
      }
    });
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() {
      _selected.clear();
    });
  }

  int get _selectedCount => _selected.values.where((bool s) => s).length;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (_sessions.isEmpty) {
      return DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext context, ScrollController scroll) {
          return _buildContent(colors);
        },
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scroll) {
        return _buildContent(colors);
      },
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: <Widget>[
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.multiSelect ? '选择目标服务器' : '选择目标服务器',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_sessions.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _selectedCount > 0 ? Icons.close_rounded : Icons.check_rounded,
                      size: 22,
                    ),
                    onPressed: _selectedCount > 0 ? _clearSelection : _selectAll,
                    tooltip: _selectedCount > 0 ? '清除' : '全选',
                  ),
              ],
            ),
          ),

          // Server list
          Expanded(
            child: ListView.builder(
              controller: ScrollController(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sessions.length,
              itemBuilder: (BuildContext context, int index) {
                final RegisteredSession session = _sessions[index];
                final bool isSelected = _selected[session.serverId] ?? false;
                final Duration uptime = DateTime.now().difference(session.connectedAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _toggleSelection(session.serverId),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: <Widget>[
                          // Checkbox or indicator
                          widget.multiSelect
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(session.serverId),
                                  side: BorderSide(
                                    color: colors.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                )
                              : Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.outlineVariant,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: colors.primary,
                                        )
                                      : null,
                                ),

                          const SizedBox(width: 12),

                          // Server info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  session.serverName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${session.config.host}:${session.config.port}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontFamily: AppTheme.monoFont,
                                        fontFamilyFallback: AppTheme.monoFallback,
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${uptime.inHours}小时 ${uptime.inMinutes % 60}分钟在线',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.sem.success.withValues(alpha: 0.8),
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Connection status indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.sem.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.sem.success.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom actions
          if (_sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                onPressed: () {
                  if (_selected.isEmpty || _selectedCount == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.multiSelect ? '请至少选择一个服务器' : '请选择要执行命令的服务器',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop<List<String>>(_selected
                      .entries
                      .where((MapEntry<String, bool> e) => e.value)
                      .map((MapEntry<String, bool> e) => e.key)
                      .toList());
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text('执行 ($_selectedCount)'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          // Empty state
          if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.lan_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '请先在服务器页面连接终端',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
