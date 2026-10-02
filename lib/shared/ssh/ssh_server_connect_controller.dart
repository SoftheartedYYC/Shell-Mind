import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/result.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import '../../features/server_config/presentation/providers/server_config_providers.dart';
import 'ssh_session_registry.dart';

/// Per-server progress snapshot for a connection attempt initiated outside
/// the terminal page (e.g. the AI chat's in-chat server picker).
@immutable
class SshServerConnectAttempt {
  const SshServerConnectAttempt({this.connecting = false, this.error, this.failureKind});

  /// True while the dial/handshake is in flight.
  final bool connecting;

  /// Raw failure message when the attempt ended unsuccessfully. `null` when
  /// the failure is one of the well-known kinds below.
  final String? error;

  /// [FailureKind] name for well-known failures (`auth` when the server has
  /// no stored credential, for example), letting the UI localise them.
  final String? failureKind;

  bool get inProgress => connecting;
}

/// Drives SSH connections on behalf of surfaces other than the terminal page.
///
/// Mirrors the credential-resolution flow of `SshConnectionController.connect`
/// but is fully independent of the terminal screen's mirrored state — the chat
/// page's server picker calls [connect] for each chosen server, the global
/// [SshSessionRegistry] owns the resulting session, and [markConnected] keeps
/// the fleet list's "last connected" stamp in sync.
///
/// Non-autoDispose: in-flight attempts and their last error survive sheet
/// dismissals so the picker can keep rendering progress across rebuilds.
class SshServerConnectController
    extends Notifier<Map<String, SshServerConnectAttempt>> {
  @override
  Map<String, SshServerConnectAttempt> build() => const <String, SshServerConnectAttempt>{};

  /// Resolves [config]'s stored credentials from the secure keystore and
  /// connects through the global registry.
  ///
  /// Returns `true` when the session went live. Progress and failures are
  /// also published in state, keyed by [config.id].
  Future<bool> connect(ServerConfig config) async {
    void patch(SshServerConnectAttempt attempt) {
      state = <String, SshServerConnectAttempt>{...state, config.id: attempt};
    }

    patch(const SshServerConnectAttempt(connecting: true));

    final SecureStorageService secure = ref.read(secureStorageServiceProvider);

    String? password;
    String? privateKey;
    String? passphrase;

    if (config.authType == AuthType.password) {
      password = await secure.getPassword(config.id);
      if (password == null || password.isEmpty) {
        patch(const SshServerConnectAttempt(error: 'missing', failureKind: 'auth'));
        return false;
      }
    } else {
      privateKey = await secure.getPrivateKey(config.id);
      passphrase = await secure.getPassphrase(config.id);
      if (privateKey == null || privateKey.trim().isEmpty) {
        patch(const SshServerConnectAttempt(error: 'missing', failureKind: 'auth'));
        return false;
      }
    }

    final Result<void> result =
        await ref.read(sshSessionRegistryProvider.notifier).connect(
              config,
              password: password,
              privateKey: privateKey,
              passphrase: passphrase,
            );

    var ok = false;
    await result.when(
      success: (_) async {
        ok = true;
        patch(const SshServerConnectAttempt());
        await ref
            .read(serverConfigListProvider.notifier)
            .markConnected(config.id);
      },
      failure: (AppFailure failure) async {
        patch(SshServerConnectAttempt(
          error: failure.message,
          failureKind: failure.kind.name,
        ));
      },
    );
    return ok;
  }

  /// Clears the recorded attempt for [serverId] (e.g. once the error has been
  /// surfaced to the user).
  void clearAttempt(String serverId) {
    if (!state.containsKey(serverId)) return;
    final Map<String, SshServerConnectAttempt> next =
        Map<String, SshServerConnectAttempt>.from(state)..remove(serverId);
    state = next;
  }
}

/// App-wide provider for in-chat (non-terminal) connection attempts.
final NotifierProvider<SshServerConnectController, Map<String, SshServerConnectAttempt>>
    sshServerConnectProvider = NotifierProvider<
        SshServerConnectController, Map<String, SshServerConnectAttempt>>(
  SshServerConnectController.new,
);
