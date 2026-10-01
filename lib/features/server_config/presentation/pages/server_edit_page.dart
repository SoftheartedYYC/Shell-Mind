import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
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
        const SnackBar(content: Text('server not found')),
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
      (v == null || v.trim().isEmpty) ? 'name required' : null;

  String? _validateHost(String? v) {
    final String s = v?.trim() ?? '';
    if (s.isEmpty) return 'host required';
    if (s.contains(' ')) return 'no spaces allowed';
    return null;
  }

  String? _validatePort(String? v) {
    final String s = v?.trim() ?? '';
    if (s.isEmpty) return 'required';
    final int? n = int.tryParse(s);
    if (n == null) return 'numeric';
    if (n < 1 || n > 65535) return '1–65535';
    return null;
  }

  String? _validateUsername(String? v) =>
      (v == null || v.trim().isEmpty) ? 'username required' : null;

  String? _validateSecret(String? v) {
    final bool blank = v == null || v.trim().isEmpty;
    // In edit mode a stored secret may be left untouched.
    if (blank && _isEditing && _hasStoredCredential) return null;
    if (blank) {
      return _authType == AuthType.password
          ? 'password required'
          : 'private key required';
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
    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'registered · ${config.identity}:${config.port}'
                : 'saved · ${config.identity}:${config.port}',
          ),
        ),
      );
      context.pop();
    } else {
      final AppFailure failure = result.failureOrNull?.failure ??
          AppFailure.storage('Could not persist server.');
      messenger.showSnackBar(
        SnackBar(
          content: Text('save failed · ${failure.message}'),
          backgroundColor: AppTheme.coral,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final String host = _host.text.trim();
    final int port =
        int.tryParse(_port.text.trim()) ?? AppConstants.defaultSshPort;
    if (host.isEmpty) {
      setState(() {
        _testStatus = _TestStatus.failure;
        _testMessage = 'enter a host address first';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _testing = true;
      _testStatus = _TestStatus.testing;
      _testMessage = 'probing $host:$port …';
    });

    try {
      final Socket socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 6),
      );
      socket.destroy();
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testStatus = _TestStatus.success;
        _testMessage = '$host:$port · tcp reachable';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testStatus = _TestStatus.failure;
        _testMessage = _describeError(error, host, port);
      });
    }
  }

  static String _describeError(Object error, String host, int port) {
    if (error is TimeoutException) return '$host:$port · timed out';
    if (error is SocketException) return '$host:$port · refused / unreachable';
    return '$host:$port · probe failed';
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: -120,
            left: -60,
            right: -60,
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.1,
                  colors: <Color>[Color(0x1A4FC3F7), Color(0x004FC3F7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _EditHeader(
                  path: _isEditing ? '~/servers/edit' : '~/servers/new',
                  title: _isEditing ? 'edit host' : 'register host',
                  onCancel: () => context.canPop()
                      ? context.pop()
                      : context.go('/servers'),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: PhosphorLoader(label: 'loading', compact: true),
                        )
                      : _buildForm(),
                ),
                _EditActionBar(
                  saving: _saving,
                  testing: _testing,
                  canSave: !_loading,
                  saveLabel: _isEditing ? 'save changes' : 'register host',
                  onTest: _testConnection,
                  onSave: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          const SectionHeader(label: 'identity'),
          _nameField(),
          const SizedBox(height: 14),
          _groupField(),

          const SectionHeader(label: 'connection'),
          _hostPortRow(),
          const SizedBox(height: 14),
          _usernameField(),
          const SizedBox(height: 16),
          _TestReadout(status: _testStatus, message: _testMessage),

          const SectionHeader(label: 'authentication'),
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
    return TextFormField(
      controller: _name,
      validator: _validateName,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Label',
        hintText: 'prod-web-01',
        prefixIcon: Icon(Icons.bookmark_border_rounded, size: 18),
      ),
    );
  }

  Widget _groupField() {
    return TextFormField(
      controller: _group,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Group (optional)',
        hintText: 'production',
        prefixIcon: Icon(Icons.folder_outlined, size: 18),
      ),
    );
  }

  Widget _hostPortRow() {
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
            style: AppTheme.monoStyle(context, size: 13.5),
            decoration: const InputDecoration(
              labelText: 'Host',
              hintText: '10.0.0.5',
              prefixIcon: Icon(Icons.dns_outlined, size: 18),
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
            style: AppTheme.monoStyle(context, size: 13.5),
            decoration: const InputDecoration(
              labelText: 'Port',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _usernameField() {
    return TextFormField(
      controller: _user,
      validator: _validateUsername,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: AppTheme.monoStyle(context, size: 13.5),
      decoration: const InputDecoration(
        labelText: 'Username',
        hintText: 'root',
        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
      ),
    );
  }

  Widget _passwordField() {
    final bool keepExisting = _isEditing && _hasStoredCredential;
    return TextFormField(
      controller: _password,
      validator: _validateSecret,
      obscureText: _obscurePassword,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTheme.monoStyle(context, size: 13.5),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: keepExisting ? 'stored · leave blank to keep' : '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: IconButton(
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _privateKeyField() {
    final bool keepExisting = _isEditing && _hasStoredCredential;
    return TextFormField(
      controller: _privateKey,
      validator: _validateSecret,
      maxLines: 6,
      minLines: 4,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      style: AppTheme.monoStyle(context, size: 11.5),
      decoration: InputDecoration(
        labelText: 'Private key (PEM)',
        hintText: keepExisting
            ? 'stored · leave blank to keep'
            : '-----BEGIN OPENSSH PRIVATE KEY-----',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _passphraseField() {
    return TextFormField(
      controller: _passphrase,
      obscureText: _obscurePassphrase,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTheme.monoStyle(context, size: 13.5),
      decoration: InputDecoration(
        labelText: 'Key passphrase (optional)',
        prefixIcon: const Icon(Icons.shield_outlined, size: 18),
        suffixIcon: IconButton(
          onPressed: () =>
              setState(() => _obscurePassphrase = !_obscurePassphrase),
          icon: Icon(
            _obscurePassphrase
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.path,
    required this.title,
    required this.onCancel,
  });

  final String path;
  final String title;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        border: Border(bottom: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onCancel,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded,
                size: 19, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  path,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: <String>[
                      'JetBrains Mono',
                      'Menlo',
                      'monospace',
                    ],
                    fontSize: 9.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.phosphorDim,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: context.text.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
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

// ─── Auth-type toggle ─────────────────────────────────────────────────────

class _AuthTypeToggle extends StatelessWidget {
  const _AuthTypeToggle({required this.value, required this.onChanged});

  final AuthType value;
  final ValueChanged<AuthType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _option(
            context,
            AuthType.password,
            Icons.lock_rounded,
            'Password',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _option(
            context,
            AuthType.privateKey,
            Icons.vpn_key_rounded,
            'Private key',
          ),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context,
    AuthType type,
    IconData icon,
    String label,
  ) {
    final bool selected = type == value;
    final Color tint = selected ? AppTheme.phosphor : AppTheme.textTertiary;
    return Material(
      color: selected
          ? AppTheme.phosphor.withValues(alpha: 0.1)
          : const Color(0xFF0E1322),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppTheme.phosphor : AppTheme.inkBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 15, color: tint),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppTheme.phosphor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final Color color = switch (status) {
      _TestStatus.idle => AppTheme.textTertiary,
      _TestStatus.testing => AppTheme.phosphor,
      _TestStatus.success => AppTheme.mint,
      _TestStatus.failure => AppTheme.coral,
    };
    final IconData icon = switch (status) {
      _TestStatus.idle => Icons.circle_outlined,
      _TestStatus.testing => Icons.hourglass_top_rounded,
      _TestStatus.success => Icons.check_circle_outline_rounded,
      _TestStatus.failure => Icons.error_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1120),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      child: Row(
        children: <Widget>[
          if (status == _TestStatus.testing)
            const PhosphorSpinner(size: 13, strokeWidth: 1.4)
          else
            Icon(icon, size: 13, color: color),
          const SizedBox(width: 9),
          const Text(
            '\$',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.phosphor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status == _TestStatus.idle
                  ? 'nc -vz <host> <port>   # tap test'
                  : message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: const <String>[
                  'JetBrains Mono',
                  'Menlo',
                  'monospace',
                ],
                fontSize: 11,
                letterSpacing: 0.2,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.enhanced_encryption_outlined,
            size: 13, color: AppTheme.phosphorDim),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Credentials are encrypted in the device keystore — they never '
            'touch the Hive metadata store or leave this device.',
            style: context.text.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
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

  static const TextStyle _monoLabel = TextStyle(
    fontFamily: AppTheme.monoFont,
    fontFamilyFallback: <String>['JetBrains Mono', 'Menlo', 'monospace'],
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        border: Border(top: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: Row(
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: testing ? null : onTest,
            icon: testing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: PhosphorSpinner(size: 14, strokeWidth: 1.6),
                  )
                : const Icon(Icons.wifi_tethering_rounded, size: 15),
            label: Text(
              (testing ? 'probing' : 'test').toUpperCase(),
              style: _monoLabel,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: (saving || !canSave) ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.inkVoid),
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                (saving ? 'saving…' : saveLabel).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _monoLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
