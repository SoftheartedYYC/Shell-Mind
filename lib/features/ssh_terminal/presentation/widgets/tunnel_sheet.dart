import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ssh_tunnel.dart';
import '../providers/tunnel_providers.dart';

/// Bottom sheet for managing SSH port-forwards (local and remote tunnels) for
/// one server. Lists active tunnels and offers an add flow for each direction.
class TunnelSheet extends ConsumerWidget {
  const TunnelSheet({super.key, required this.serverId});

  final String serverId;

  static Future<void> show(BuildContext context, String serverId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => TunnelSheet(serverId: serverId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<SshTunnel> tunnels =
        ref.watch(sshTunnelsProvider)[serverId] ?? const <SshTunnel>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.tunnelsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _add(context, ref, SshTunnelType.local),
                  icon: const Icon(Icons.south_rounded, size: 16),
                  label: Text(l10n.tunnelsAddLocal),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _add(context, ref, SshTunnelType.remote),
                  icon: const Icon(Icons.north_rounded, size: 16),
                  label: Text(l10n.tunnelsAddRemote),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tunnels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.tunnelsEmpty,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...<Widget>[
                for (final SshTunnel tunnel in tunnels)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      tunnel.type == SshTunnelType.local
                          ? Icons.south_rounded
                          : Icons.north_rounded,
                      color: colors.primary,
                    ),
                    title: Text(
                      tunnel.label,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: l10n.tunnelsClose,
                      onPressed: () => ref
                          .read(sshTunnelsProvider.notifier)
                          .close(serverId, tunnel.id),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    SshTunnelType type,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController localPort =
        TextEditingController(text: type == SshTunnelType.local ? '8080' : '');
    final TextEditingController remoteHost = TextEditingController();
    final TextEditingController remotePort = TextEditingController();

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: Text(type == SshTunnelType.local
                ? l10n.tunnelsAddLocal
                : l10n.tunnelsAddRemote),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (type == SshTunnelType.local) ...<Widget>[
                  TextField(
                    controller: localPort,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: l10n.tunnelsLocalPort),
                  ),
                  const SizedBox(height: 8),
                ],
                if (type == SshTunnelType.local)
                  TextField(
                    controller: remoteHost,
                    decoration:
                        InputDecoration(labelText: l10n.tunnelsRemoteHost),
                  ),
                if (type == SshTunnelType.local) const SizedBox(height: 8),
                TextField(
                  controller: remotePort,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: l10n.tunnelsRemotePort),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.tunnelsAdd),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    final int? rp = int.tryParse(remotePort.text.trim());
    if (SshTunnel.validatePort(rp) != null) {
      _toast(context, l10n.tunnelsInvalidPort);
      return;
    }

    try {
      final SshTunnelsController controller =
          ref.read(sshTunnelsProvider.notifier);
      if (type == SshTunnelType.local) {
        // 0 means "let the OS pick a free local port".
        final int lp = int.tryParse(localPort.text.trim()) ?? 0;
        if (lp != 0 && SshTunnel.validatePort(lp) != null) {
          _toast(context, l10n.tunnelsInvalidPort);
          return;
        }
        await controller.startLocalForward(
          serverId,
          remoteHost: remoteHost.text.trim().isEmpty
              ? 'localhost'
              : remoteHost.text.trim(),
          remotePort: rp!,
          localPort: lp,
        );
      } else {
        await controller.startRemoteForward(serverId, port: rp!);
      }
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, '${l10n.tunnelsError}: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
