import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ssh_terminal/data/ssh_connection_tester.dart';
import '../../domain/entities/server_config.dart';
import '../providers/server_config_providers.dart';

/// Add / edit form for a single SSH endpoint.
///
/// Pushed as a full-screen route. When [serverId] is supplied the page runs
/// in *edit* mode — it pre-fills from the stored config and offers
/// "leave blank to keep" semantics for the secret so re-entry isn't forced.
///
/// Metadata is written through [ServerConfigListController]; the password /
/// private key / passphrase go straight to the secure keystore (never Hive).
class ServerEditPage extends ConsumerStatefulWidget {
  const ServerEditPage({super.key, this.serverId});

  /// Non-null ⇒ editing an existing server.
  final String? serverId;

  @override
  ConsumerState<ServerEditPage> createState() => _ServerEditPageState();
}

enum _TestStatus { idle, testing, success, failure }

class _ServerEditPageState extends ConsumerState<ServerEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _host = TextEditingController();
  final TextEditingController _port =
      TextEditingController(text: AppConstants.defaultSshPort.toString());
  final TextEditingController _user = TextEditingController();
  final TextEditingController _group = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _privateKey = TextEditingController();
  final TextEditingController _passphrase = TextEditingController();

  AuthType _authType = AuthType.password;
  bool _obscurePassword = true;
  bool _obscurePassphrase = true;

  bool _loading = false;
  bool _saving = false;
  bool _testing = false;

  ServerConfig? _existing;
  bool _hasStoredCredential = false;

  _TestStatus _testStatus = _TestStatus.idle;
  String _testMessage = '';

  bool get _isEditing => widget.serverId != null;

  @override
  void initState() {
    super.initState();
    final String? id = widget.serverId;
    if (id != null) _loadExisting(id);
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _group.dispose();
    _password.dispose();
    _privateKey.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _loadExisting(String id) async {
    setState(() => _loading = true);
    final ServerConfigListController controller =
        ref.read(serverConfigListProvider.notifier);
    final ServerConfig? config = await controller.resolveById(id);
    if (!mounted) return;

    if (config == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).serverNotFound)),
      );
      return;
    }

    final bool hasCredential =
        await controller.hasStoredCredential(config.id, config.authType);
    if (!mounted) return;

    _name.text = config.name;
    _host.text = config.host;
    _port.text = config.port.toString();
    _user.text = config.username;
    _group.text = config.group ?? '';
    setState(() {
      _existing = config;
      _authType = config.authType;
      _hasStoredCredential = hasCredential;
      _loading = false;
    });
  }

  // ─── Validation ─────────────────────────────────────────────────────────

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty)
          ? AppLocalizations.of(context).serverValidationNameRequired
          : null;

  String? _validateHost(String? v) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String s = v?.trim() ?? '';
    if (s.isEmpty) return l10n.serverValidationHostRequired;
    if (s.contains(' ')) return l10n.serverValidationNoSpaces;
    return null;
  }

  String? _validatePort(String? v) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String s = v?.trim() ?? '';
    if (s.isEmpty) return l10n.serverValidationRequired;
    final int? n = int.tryParse(s);
    if (n == null) return l10n.serverValidationNumeric;
    if (n < 1 || n > 65535) return l10n.serverValidationPortRange;
    return null;
  }

  String? _validateUsername(String? v) =>
      (v == null || v.trim().isEmpty)
          ? AppLocalizations.of(context).serverValidationUsernameRequired
          : null;

  String? _validateSecret(String? v) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool blank = v == null || v.trim().isEmpty;
    // In edit mode a stored secret may be left untouched.
    if (blank && _isEditing && _hasStoredCredential) return null;
    if (blank) {
      return _authType == AuthType.password
          ? l10n.serverValidationPasswordRequired
          : l10n.serverValidationPrivateKeyRequired;
    }
    return null;
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final String name = _name.text.trim();
    final String host = _host.text.trim();
    final int port =
        int.tryParse(_port.text.trim()) ?? AppConstants.defaultSshPort;
    final String username = _user.text.trim();
    final String groupRaw = _group.text.trim();
    final String? group = groupRaw.isEmpty ? null : groupRaw;

    final ServerConfig? existing = _existing;
    final ServerConfig config = existing != null
        ? ServerConfig(
            id: existing.id,
            name: name,
            host: host,
            port: port,
            username: username,
            authType: _authType,
            group: group,
            createdAt: existing.createdAt,
            lastConnectedAt: existing.lastConnectedAt,
          )
        : ServerConfig.create(
            name: name,
            host: host,
            port: port,
            username: username,
            authType: _authType,
            group: group,
          );

    final Result<void> result =
        await ref.read(serverConfigListProvider.notifier).saveServer(
              config: config,
              password: _authType == AuthType.password ? _password.text : null,
              privateKey:
                  _authType == AuthType.privateKey ? _privateKey.text : null,
              passphrase:
                  _authType == AuthType.privateKey ? _passphrase.text : null,
            );

    if (!mounted) return;
    setState(() => _saving = false);

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? l10n.serverAdded(config.identity, config.port)
                : l10n.serverSaved(config.identity, config.port),
          ),
        ),
      );
      context.pop();
    } else {
      final AppFailure failure = result.failureOrNull?.failure ??
          AppFailure.storage(l10n.aiChatError);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.serverSaveFailed(failure.message)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String host = _host.text.trim();
    final int port =
        int.tryParse(_port.text.trim()) ?? AppConstants.defaultSshPort;
    final String username = _user.text.trim();
    if (host.isEmpty) {
      setState(() {
        _testStatus = _TestStatus.failure;
        _testMessage = l10n.serverTestEnterHost;
      });
      return;
    }
    if (username.isEmpty) {
      // A real authentication test needs a username.
      setState(() {
        _testStatus = _TestStatus.failure;
        _testMessage = l10n.serverValidationUsernameRequired;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _testing = true;
      _testStatus = _TestStatus.testing;
      _testMessage = l10n.serverTestProbing(host, port);
    });

    // Resolve credentials from the *current form* so unsaved edits are tested.
    // When editing and a secret field is left blank, fall back to the value
    // already stored in the secure keystore ("leave blank to keep").
    String? password =
        _authType == AuthType.password ? _password.text : null;
    String? privateKey =
        _authType == AuthType.privateKey ? _privateKey.text : null;
    String? passphrase =
        _authType == AuthType.privateKey ? _passphrase.text : null;

    final ServerConfig? existing = _existing;
    if (_isEditing && existing != null) {
      final SecureStorageService secure =
          ref.read(secureStorageServiceProvider);
      if (_authType == AuthType.password &&
          (password == null || password.isEmpty)) {
        password = await secure.getPassword(existing.id);
      } else if (_authType == AuthType.privateKey &&
          (privateKey == null || privateKey.trim().isEmpty)) {
        privateKey = await secure.getPrivateKey(existing.id);
        if (passphrase == null || passphrase.isEmpty) {
          passphrase = await secure.getPassphrase(existing.id);
        }
      }
    }
    if (!mounted) return;

    final SshTestResult result = await SshConnectionTester.test(
      host: host,
      port: port,
      username: username,
      authType: _authType,
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
    );
    if (!mounted) return;

    setState(() {
      _testing = false;
      _testStatus = result == SshTestResult.success
          ? _TestStatus.success
          : _TestStatus.failure;
      _testMessage = _describeResult(l10n, result, host, port);
    });
  }

  String _describeResult(
    AppLocalizations l10n,
    SshTestResult result,
    String host,
    int port,
  ) {
    switch (result) {
      case SshTestResult.success:
        return l10n.serverTestReachable(host, port);
      case SshTestResult.unreachable:
        return l10n.serverTestRefused(host, port);
      case SshTestResult.timeout:
        return l10n.serverTestTimedOut(host, port);
      case SshTestResult.handshakeFailed:
        return l10n.serverTestHandshakeFailed(host, port);
      case SshTestResult.authFailed:
        return l10n.serverTestAuthFailed(host, port);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.serverEditTitleEdit : l10n.serverEditTitle),
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/servers'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _loading
          ? Center(child: AppLoader(label: l10n.serverLoading))
          : _buildForm(),
      bottomNavigationBar: _EditActionBar(
        saving: _saving,
        testing: _testing,
        canSave: !_loading,
        saveLabel: _isEditing ? l10n.serverSaveChanges : l10n.serverEditTitle,
        onTest: _testConnection,
        onSave: _submit,
      ),
    );
  }

  Widget _buildForm() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          SectionHeader(label: l10n.serverSectionIdentity),
          _nameField(),
          const SizedBox(height: 14),
          _groupField(),

          SectionHeader(label: l10n.serverSectionConnection),
          _hostPortRow(),
          const SizedBox(height: 14),
          _usernameField(),
          const SizedBox(height: 16),
          _TestReadout(status: _testStatus, message: _testMessage),

          SectionHeader(label: l10n.serverSectionAuthentication),
          _AuthTypeToggle(
            value: _authType,
            onChanged: (AuthType t) => setState(() => _authType = t),
          ),
          const SizedBox(height: 16),
          if (_authType == AuthType.password) ...<Widget>[
            _passwordField(),
          ] else ...<Widget>[
            _privateKeyField(),
            const SizedBox(height: 14),
            _passphraseField(),
          ],
          const SizedBox(height: 16),
          const _SecurityNote(),
        ],
      ),
    );
  }

  // ─── Fields ─────────────────────────────────────────────────────────────

  Widget _nameField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _name,
      validator: _validateName,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: l10n.serverFieldLabel,
        hintText: l10n.serverFieldLabelHint,
        prefixIcon: const Icon(Icons.bookmark_border_rounded, size: 20),
      ),
    );
  }

  Widget _groupField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _group,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.serverFieldGroup,
        hintText: l10n.serverFieldGroupHint,
        prefixIcon: const Icon(Icons.folder_outlined, size: 20),
      ),
    );
  }

  Widget _hostPortRow() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _host,
            validator: _validateHost,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: AppTheme.monoStyle(context, size: 14),
            decoration: InputDecoration(
              labelText: l10n.serverFieldHost,
              hintText: l10n.serverFieldHostHint,
              prefixIcon: const Icon(Icons.dns_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _port,
            validator: _validatePort,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            maxLength: 5,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTheme.monoStyle(context, size: 14),
            decoration: InputDecoration(
              labelText: l10n.serverFieldPort,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _usernameField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _user,
      validator: _validateUsername,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: AppTheme.monoStyle(context, size: 14),
      decoration: InputDecoration(
        labelText: l10n.serverFieldUsername,
        hintText: l10n.serverFieldUsernameHint,
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
      ),
    );
  }

  Widget _passwordField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool keepExisting = _isEditing && _hasStoredCredential;
    return TextFormField(
      controller: _password,
      validator: _validateSecret,
      obscureText: _obscurePassword,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTheme.monoStyle(context, size: 14),
      decoration: InputDecoration(
        labelText: l10n.serverFieldPassword,
        hintText: keepExisting ? l10n.serverFieldPasswordStored : null,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _privateKeyField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool keepExisting = _isEditing && _hasStoredCredential;
    return TextFormField(
      controller: _privateKey,
      validator: _validateSecret,
      maxLines: 6,
      minLines: 4,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      style: AppTheme.monoStyle(context, size: 12),
      decoration: InputDecoration(
        labelText: l10n.serverFieldPrivateKey,
        hintText: keepExisting
            ? l10n.serverFieldPasswordStored
            : '-----BEGIN OPENSSH PRIVATE KEY-----',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _passphraseField() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _passphrase,
      obscureText: _obscurePassphrase,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTheme.monoStyle(context, size: 14),
      decoration: InputDecoration(
        labelText: l10n.serverFieldPassphrase,
        prefixIcon: const Icon(Icons.shield_outlined, size: 20),
        suffixIcon: IconButton(
          onPressed: () =>
              setState(() => _obscurePassphrase = !_obscurePassphrase),
          icon: Icon(
            _obscurePassphrase
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Auth-type toggle ─────────────────────────────────────────────────────

class _AuthTypeToggle extends StatelessWidget {
  const _AuthTypeToggle({required this.value, required this.onChanged});

  final AuthType value;
  final ValueChanged<AuthType> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SegmentedButton<AuthType>(
      segments: <ButtonSegment<AuthType>>[
        ButtonSegment<AuthType>(
          value: AuthType.password,
          icon: const Icon(Icons.lock_rounded, size: 18),
          label: Text(l10n.serverAuthPassword),
        ),
        ButtonSegment<AuthType>(
          value: AuthType.privateKey,
          icon: const Icon(Icons.vpn_key_rounded, size: 18),
          label: Text(l10n.serverAuthPrivateKey),
        ),
      ],
      selected: <AuthType>{value},
      onSelectionChanged: (Set<AuthType> selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

// ─── Test readout ─────────────────────────────────────────────────────────

class _TestReadout extends StatelessWidget {
  const _TestReadout({required this.status, required this.message});

  final _TestStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = switch (status) {
      _TestStatus.idle => colors.onSurfaceVariant,
      _TestStatus.testing => colors.primary,
      _TestStatus.success => context.sem.success,
      _TestStatus.failure => colors.error,
    };
    final IconData icon = switch (status) {
      _TestStatus.idle => Icons.circle_outlined,
      _TestStatus.testing => Icons.hourglass_top_rounded,
      _TestStatus.success => Icons.check_circle_outline_rounded,
      _TestStatus.failure => Icons.error_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          if (status == _TestStatus.testing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status == _TestStatus.idle
                  ? AppLocalizations.of(context).serverTestIdle
                  : message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Security note ────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.enhanced_encryption_outlined,
            size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).serverSecurityNote,
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action bar ───────────────────────────────────────────────────────────

class _EditActionBar extends StatelessWidget {
  const _EditActionBar({
    required this.saving,
    required this.testing,
    required this.canSave,
    required this.saveLabel,
    required this.onTest,
    required this.onSave,
  });

  final bool saving;
  final bool testing;
  final bool canSave;
  final String saveLabel;
  final VoidCallback onTest;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: testing ? null : onTest,
              icon: testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering_rounded, size: 18),
              label: Text(testing ? l10n.serverTesting : l10n.serverTest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: (saving || !canSave) ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(saving ? l10n.serverSaving : saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
