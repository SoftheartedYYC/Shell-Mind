import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/chat_sessions_store.dart';
import '../../domain/entities/chat_session.dart';
import '../providers/chat_providers.dart';

/// Bottom sheet for multi-session management: search, switch, rename, delete,
/// and start a new conversation.
///
/// Switching calls [ChatNotifier.switchToSession]; a rename/delete mutates the
/// [ChatSessionsStore] through [ChatSessionsController] and refreshes the list.
class SessionsSheet extends ConsumerStatefulWidget {
  const SessionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const SessionsSheet(),
    );
  }

  @override
  ConsumerState<SessionsSheet> createState() => _SessionsSheetState();
}

class _SessionsSheetState extends ConsumerState<SessionsSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AsyncValue<List<ChatSession>> sessionsAsync =
        ref.watch(chatSessionsProvider);
    final List<ChatSession> sessions =
        sessionsAsync.value ?? const <ChatSession>[];
    final List<ChatSession> filtered = ChatSessionsStore.search(sessions, _query);
    final String? activeId = ref.watch(activeChatSessionIdProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.sessionsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.sessionsNew,
                      onPressed: () {
                        ref.read(chatMessagesProvider.notifier).newSession();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.add_comment_outlined,
                          color: colors.primary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: TextField(
                  controller: _search,
                  onChanged: (String value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.sessionsSearch,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? l10n.sessionsEmpty
                              : l10n.sessionsNoMatch(_query),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: colors.outlineVariant),
                        itemBuilder: (BuildContext context, int index) {
                          final ChatSession session = filtered[index];
                          return _SessionRow(
                            session: session,
                            active: session.id == activeId,
                            onTap: () {
                              ref
                                  .read(chatMessagesProvider.notifier)
                                  .switchToSession(session);
                              Navigator.of(context).pop();
                            },
                            onRename: () => _rename(session),
                            onDelete: () => _delete(session),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rename(ChatSession session) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller =
        TextEditingController(text: session.title);
    final String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.sessionsRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.sessionsRenameHint),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;
    await ref
        .read(chatSessionsProvider.notifier)
        .renameSession(session.id, title);
  }

  Future<void> _delete(ChatSession session) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(l10n.sessionsDelete),
            content: Text(l10n.sessionsDeleteConfirm(session.title)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.sessionsDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    if (ref.read(activeChatSessionIdProvider) == session.id) {
      // Deleting the active session → start a fresh one.
      ref.read(chatMessagesProvider.notifier).newSession();
    }
    await ref.read(chatSessionsProvider.notifier).deleteSession(session.id);
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.active,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ChatSession session;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      selected: active,
      selectedTileColor: colors.primary.withValues(alpha: 0.08),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: active ? FontWeight.w600 : FontWeight.w400),
      ),
      subtitle: Text(
        '${l10n.sessionsMessageCount(session.messages.length)} · '
        '${_relativeTime(session.updatedAt)}',
        style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
      ),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'rename') onRename();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'rename',
            child: Text(l10n.sessionsRename),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Text(l10n.sessionsDelete),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')}';
  }
}
