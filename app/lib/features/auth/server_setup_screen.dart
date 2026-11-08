import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/server_config.dart';

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
  String? _error;
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
      setState(
        () => _error = 'Enter an address that starts with http:// or https://, for example https://velomine.club.example.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
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
        _error =
            'Could not reach a Velomine server at that address. Check the '
            'address, and that the phone is on the same network as the server.';
      });
      return;
    }

    try {
      await widget.onSaved(normalized);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save the address. Try again.';
        });
      }
      return;
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                'Which server does your club use?',
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
                decoration: const InputDecoration(
                  labelText: 'Server address',
                  hintText: 'https://velomine.club.example',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (!_busy) _save();
                },
              ),
              if (_url.text.trim().toLowerCase().startsWith('http://')) ...[
                const SizedBox(height: 8),
                Text(
                  'This address is not encrypted. Use it only on a network you trust, '
                  'or ask your admin for an https address.',
                  key: const Key('server-insecure'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('server-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('server-save'),
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Checking…' : 'Connect'),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask your club admin for the address. It usually looks like https://velomine.your-club.example.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
