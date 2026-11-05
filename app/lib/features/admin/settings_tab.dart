import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import 'admin_controller.dart';

/// The settings an admin can change, and (read-only) what only the server's environment sets.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.controller});

  final AdminController controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _tile = TextEditingController();
  final _credit = TextEditingController();
  bool _signUp = true;
  bool _approval = true;
  bool _filled = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_fill);
    _fill();
  }

  /// Takes the server's values once they have arrived; after that the form belongs to the admin until they save.
  void _fill() {
    final s = widget.controller.settings;
    if (s == null || _filled) return;
    _filled = true;
    setState(() {
      _signUp = s.signUpEnabled;
      _approval = s.requireAdminApproval;
      _tile.text = s.mapTileUrl ?? '';
      _credit.text = s.mapAttribution ?? '';
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fill);
    _tile.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await widget.controller.saveSettings(
      UpdateSettingsRequest(
        signUpEnabled: _signUp,
        requireAdminApproval: _approval,
        mapTileUrl: _tile.text.trim(),
        mapAttribution: _credit.text.trim().isEmpty
            ? null
            : _credit.text.trim(),
      ),
    );
    if (mounted) setState(() => _saved = ok);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.settings;
    if (s == null) {
      return Center(
        child: c.loading
            ? const CircularProgressIndicator()
            : Text(c.error ?? 'No settings.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text('Sign-up', style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  key: const Key('setting-signup'),
                  value: _signUp,
                  title: const Text('People can create accounts'),
                  onChanged: (v) => setState(() {
                    _signUp = v;
                    _saved = false;
                  }),
                ),
                SwitchListTile(
                  key: const Key('setting-approval'),
                  value: _approval,
                  title: const Text(
                    'New accounts need an admin to approve them',
                  ),
                  onChanged: (v) => setState(() {
                    _approval = v;
                    _saved = false;
                  }),
                ),
                Text(
                  'Map background',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextField(
                  key: const Key('setting-tile'),
                  controller: _tile,
                  onChanged: (_) => setState(() => _saved = false),
                  decoration: const InputDecoration(
                    labelText: 'Tile address',
                    hintText: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    helperText: 'Empty draws the route alone and contacts no map server. Read the provider\'s usage rules first.',
                    helperMaxLines: 2,
                  ),
                ),
                TextField(
                  key: const Key('setting-credit'),
                  controller: _credit,
                  onChanged: (_) => setState(() => _saved = false),
                  decoration: const InputDecoration(
                    labelText: 'Credit shown on the map',
                    hintText: '© OpenStreetMap contributors',
                  ),
                ),
                if (c.error != null)
                  Text(
                    c.error!,
                    key: const Key('settings-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_saved && c.error == null)
                  const Text('Saved.', key: Key('settings-saved')),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('setting-save'),
                    onPressed: c.saving ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
                const Divider(),
                Text(
                  'Set with environment variables',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'These hold passwords and secrets, so they are never stored in the database or changed from here. Edit the server\'s environment and restart it.',
                ),
                if (s.smtp.configured)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('send-test-email'),
                      onPressed: c.sendTestEmail,
                      icon: const Icon(Icons.send),
                      label: const Text('Send a test email to me'),
                    ),
                  ),
                if (c.testEmailResult case final result?)
                  Text(
                    result,
                    key: const Key('test-email-result'),
                    style: c.testEmailFailed
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                _StatusCard(
                  key: const Key('smtp-status'),
                  icon: Icons.mail_outline,
                  title: 'Email (SMTP)',
                  on: s.smtp.configured,
                  detail: s.smtp.configured
                      ? '${s.smtp.host}:${s.smtp.port} · ${s.smtp.security} · from ${s.smtp.from}'
                      : 'Not set up. Set Velomine__Smtp__Host and Velomine__Smtp__From.',
                ),
                _StatusCard(
                  key: const Key('sso-status'),
                  icon: Icons.login,
                  title: 'Single sign-on',
                  on: s.sso.enabled,
                  detail: s.sso.enabled
                      ? '${s.sso.displayName ?? 'Single sign-on'} · ${s.sso.authority}'
                      : 'Not set up. Set Velomine__Sso__Authority, ClientId and ClientSecret.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.on,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final bool on;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text('$title: ${on ? 'on' : 'off'}'),
      subtitle: Text(detail),
    ),
  );
}
