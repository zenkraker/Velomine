import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/server_config.dart';

enum _Problem { invalidAddress, unreachable, saveFailed }

/// The first screen on a phone: which Velomine server does this member belong to?
class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({
    super.key,
    required this.onSaved,
    this.initialUrl = '',
    this.check,
  });

  final String initialUrl;
  final Future<void> Function(String url) onSaved;

  /// Tests replace the network check. The real one asks the server who it is.
  final Future<ServerInfoResponse?> Function(String url)? check;

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  /// A phone on the wrong network otherwise sits on "Checking…" until the system gives up, which can be minutes.
  static const _checkTimeout = Duration(seconds: 10);

  late final _url = TextEditingController(text: widget.initialUrl);
  _Problem? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<ServerInfoResponse?> _lookUp(String url) async {
    final client = ApiClient(basePath: url);
    return ServerApi(client).getServerInfo();
  }

  Future<void> _save() async {
    final normalized = normalizeServerUrl(_url.text);
    if (normalized == null) {
      setState(() => _problem = _Problem.invalidAddress);
      return;
    }

    setState(() {
      _busy = true;
      _problem = null;
    });

    ServerInfoResponse? info;
    try {
      info = await (widget.check ?? _lookUp)(normalized).timeout(_checkTimeout);
    } on Object {
      info = null;
    }

    if (!mounted) return;
    if (info == null) {
      setState(() {
        _busy = false;
        _problem = _Problem.unreachable;
      });
      return;
    }

    try {
      await widget.onSaved(normalized);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _problem = _Problem.saveFailed;
        });
      }
      return;
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = switch (_problem) {
      null => null,
      _Problem.invalidAddress => l10n.setupInvalidAddress,
      _Problem.unreachable => l10n.setupUnreachable,
      _Problem.saveFailed => l10n.setupSaveFailed,
    };
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Velomine',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.setupTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('server-url'),
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.setupServerAddress,
                hintText: l10n.setupServerHint,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (!_busy) _save();
              },
            ),
            if (_url.text.trim().toLowerCase().startsWith('http://')) ...[
              const SizedBox(height: 8),
              Text(
                l10n.setupInsecure,
                key: const Key('server-insecure'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error,
                key: const Key('server-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('server-save'),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l10n.setupChecking : l10n.setupConnect),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.setupHelp,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return Scaffold(body: form);
  }
}
