import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velomine_api/api.dart';

import '../../core/hooks.dart';

import 'profile_controller.dart';

const weekDays = {
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.emailAvailable,
    required this.openLink,
    required this.onAccountDeleted,
    required this.serverUrl,
  });

  final ProfileController controller;

  /// The server this session belongs to, used for the export download link.
  final String serverUrl;

  /// Whether the server can send email at all; the switch is explained and disabled when it cannot.
  final bool emailAvailable;

  /// Opens the export download in the browser.
  final LinkOpener openLink;

  /// Called once the account is gone, so the app can leave the signed-in screens.
  final VoidCallback onAccountDeleted;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _ftp = TextEditingController();
  final _weight = TextEditingController();
  final _maxHr = TextEditingController();
  final _zone = TextEditingController();
  String _firstDay = 'monday';
  bool _email = true;
  String? _problem;
  bool _saved = false;
  bool _exported = false;

  @override
  void initState() {
    super.initState();
    widget.controller.load().then((_) => _fill(widget.controller.profile));
  }

  void _fill(ProfileResponse? p) {
    if (p == null || !mounted) return;
    setState(() {
      _name.text = p.displayName;
      _ftp.text = p.ftpW?.toString() ?? '';
      _weight.text = p.weightKg?.toString() ?? '';
      _maxHr.text = p.maxHeartRate?.toString() ?? '';
      _zone.text = p.timeZone ?? '';
      _firstDay = p.firstDayOfWeek;
      _email = p.emailNotifications;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _ftp, _weight, _maxHr, _zone]) {
      c.dispose();
    }
    super.dispose();
  }

  /// An empty box means "not set"; anything else must be a number in range.
  static (bool ok, num? value) _read(
    String text,
    num min,
    num max, {
    bool whole = true,
  }) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return (true, null);
    final n = whole ? int.tryParse(t) : double.tryParse(t);
    return n == null || n < min || n > max ? (false, null) : (true, n);
  }

  Future<void> _export() async {
    final path = await widget.controller.exportLink();
    if (path == null) return;
    await widget.openLink(Uri.parse('${widget.serverUrl}$path'));
    if (mounted) setState(() => _exported = true);
  }

  Future<void> _delete() async {
    final profile = widget.controller.profile;
    if (profile == null) return;
    final answer = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(hasPassword: profile.hasPassword),
    );
    if (answer == null) return;
    final deleted = await widget.controller.deleteAccount(
      password: profile.hasPassword ? answer : null,
      confirmEmail: profile.hasPassword ? null : answer,
    );
    if (deleted) widget.onAccountDeleted();
  }

  Future<void> _save() async {
    final ftp = _read(_ftp.text, 30, 1000);
    final weight = _read(_weight.text, 20, 300, whole: false);
    final maxHr = _read(_maxHr.text, 100, 240);
    final problem = _name.text.trim().isEmpty
        ? 'Enter your name.'
        : !ftp.$1
        ? 'FTP is 30 to 1000 watts.'
        : !weight.$1
        ? 'Weight is 20 to 300 kg.'
        : !maxHr.$1
        ? 'Maximum heart rate is 100 to 240 bpm.'
        : null;
    setState(() {
      _problem = problem;
      _saved = false;
    });
    if (problem != null) return;

    final zone = _zone.text.trim();
    final ok = await widget.controller.save(
      UpdateProfileRequest(
        displayName: _name.text.trim(),
        ftpW: ftp.$2?.toInt(),
        weightKg: weight.$2?.toDouble(),
        maxHeartRate: maxHr.$2?.toInt(),
        timeZone: zone.isEmpty ? null : zone,
        firstDayOfWeek: _firstDay,
        emailNotifications: Optional.present(_email),
      ),
    );
    if (mounted) setState(() => _saved = ok);
  }

  Widget _number(
    String key,
    TextEditingController c,
    String label,
    String suffix, {
    String? helper,
    bool decimals = false,
  }) => TextField(
    key: Key(key),
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimals),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(decimals ? r'[0-9.,]' : r'[0-9]'),
      ),
    ],
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      helperText: helper,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: c.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextField(
                          key: const Key('profile-name'),
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        _number(
                          'profile-ftp',
                          _ftp,
                          'FTP',
                          'W',
                          helper: 'Functional threshold power. Used for training load and power zones.',
                        ),
                        _number(
                          'profile-weight',
                          _weight,
                          'Weight',
                          'kg',
                          decimals: true,
                        ),
                        _number(
                          'profile-max-hr',
                          _maxHr,
                          'Maximum heart rate',
                          'bpm',
                          helper: 'Heart rate zones are worked out from it.',
                        ),
                        TextField(
                          key: const Key('profile-zone'),
                          controller: _zone,
                          decoration: const InputDecoration(
                            labelText: 'Time zone',
                            hintText: 'Europe/Rome',
                            helperText: 'Decides which day a ride counts on when its file does not say. Empty means UTC.',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          key: const Key('profile-first-day'),
                          initialValue: _firstDay,
                          decoration: const InputDecoration(
                            labelText: 'Weeks start on',
                          ),
                          items: [
                            for (final e in weekDays.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _firstDay = v ?? _firstDay),
                        ),
                        SwitchListTile(
                          key: const Key('profile-email'),
                          contentPadding: EdgeInsets.zero,
                          value: _email,
                          title: const Text('Email me my notifications'),
                          subtitle: Text(
                            widget.emailAvailable
                                ? 'A ride that was read, a part that is worn, and so on.'
                                : 'This server is not set up to send email, so nothing is sent yet.',
                          ),
                          onChanged: widget.emailAvailable
                              ? (v) => setState(() {
                                  _email = v;
                                  _saved = false;
                                })
                              : null,
                        ),
                        if (_problem ?? c.error case final message?)
                          Text(
                            message,
                            key: const Key('profile-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (_saved && c.error == null)
                          const Text('Saved.', key: Key('profile-saved')),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            key: const Key('profile-save'),
                            onPressed: c.saving ? null : _save,
                            child: const Text('Save'),
                          ),
                        ),
                        const Divider(),
                        Text(
                          'Your data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text(
                          'It is yours. Download everything Velomine keeps about you: your details, bikes, goals and rides, with every ride file exactly as you uploaded it.',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: const Key('export-data'),
                            onPressed: c.exporting ? null : _export,
                            icon: const Icon(Icons.download),
                            label: const Text('Download my data'),
                          ),
                        ),
                        if (_exported)
                          const Text(
                            'Your download has started in your browser. The link works for two minutes.',
                            key: Key('export-started'),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: const Key('delete-account'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete my account'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks the member to confirm deleting their account: with their password, or by typing their email when they have none.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.hasPassword});

  final bool hasPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete your account?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        const Text(
          'This deletes your account and everything in it for good: your rides and the ride files, bikes, goals and notifications. Download your data first if you want to keep it. It cannot be undone.',
        ),
        TextField(
          key: const Key('delete-confirm'),
          controller: _answer,
          obscureText: widget.hasPassword,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.hasPassword
                ? 'Your password'
                : 'Type your email address to confirm',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirm-delete-account'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: () => Navigator.pop(context, _answer.text),
        child: const Text('Delete everything'),
      ),
    ],
  );
}
