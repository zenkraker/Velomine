import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import 'admin_controller.dart';

/// The settings an admin can change, and (read-only) what only the server's environment sets.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.controller});

  final AdminController controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
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
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fill);
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await widget.controller.saveSettings(
      UpdateSettingsRequest(
        signUpEnabled: _signUp,
        requireAdminApproval: _approval,
      ),
    );
    if (mounted) setState(() => _saved = ok);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = context.l10n;
    final s = c.settings;
    if (s == null) {
      return Center(
        child: c.loading
            ? const CircularProgressIndicator()
            : Text(
                c.error == null ? l10n.noSettings : failureText(l10n, c.error!),
              ),
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
                Text(
                  l10n.signUp,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  key: const Key('setting-signup'),
                  value: _signUp,
                  title: Text(l10n.peopleCanCreate),
                  onChanged: (v) => setState(() {
                    _signUp = v;
                    _saved = false;
                  }),
                ),
                SwitchListTile(
                  key: const Key('setting-approval'),
                  value: _approval,
                  title: Text(l10n.newAccountsApproval),
                  onChanged: (v) => setState(() {
                    _approval = v;
                    _saved = false;
                  }),
                ),
                if (c.error != null)
                  Text(
                    failureText(l10n, c.error!),
                    key: const Key('settings-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_saved && c.error == null)
                  Text(l10n.saved, key: const Key('settings-saved')),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('setting-save'),
                    onPressed: c.saving ? null : _save,
                    child: Text(l10n.save),
                  ),
                ),
                const Divider(),
                Text(
                  l10n.envVariables,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(l10n.secretsHelp),
                if (s.smtp.configured)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('send-test-email'),
                      onPressed: c.sendTestEmail,
                      icon: const Icon(Icons.send),
                      label: Text(l10n.sendTestEmail),
                    ),
                  ),
                if (c.testEmailSent || c.testEmailError != null)
                  Text(
                    c.testEmailError == null
                        ? l10n.testEmailSent
                        : failureText(l10n, c.testEmailError!),
                    key: const Key('test-email-result'),
                    style: c.testEmailError != null
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                _StatusCard(
                  key: const Key('smtp-status'),
                  icon: Icons.mail_outline,
                  title: l10n.emailSmtp,
                  on: s.smtp.configured,
                  detail: s.smtp.configured
                      ? l10n.smtpDetail(
                          s.smtp.host ?? '',
                          s.smtp.port ?? 0,
                          s.smtp.security ?? '',
                          s.smtp.from ?? '',
                        )
                      : l10n.smtpNotConfigured,
                ),
                _StatusCard(
                  key: const Key('sso-status'),
                  icon: Icons.login,
                  title: l10n.singleSignOn,
                  on: s.sso.enabled,
                  detail: s.sso.enabled
                      ? l10n.ssoDetail(
                          s.sso.displayName ?? l10n.ssoGeneric,
                          s.sso.authority ?? '',
                        )
                      : l10n.ssoNotConfigured,
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(on ? l10n.statusOn(title) : l10n.statusOff(title)),
        subtitle: Text(detail),
      ),
    );
  }
}
