import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';

import 'profile_controller.dart';

const weekDayIds = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

String weekDayName(AppLocalizations l10n, String day) => switch (day) {
  'monday' => l10n.monday,
  'tuesday' => l10n.tuesday,
  'wednesday' => l10n.wednesday,
  'thursday' => l10n.thursday,
  'friday' => l10n.friday,
  'saturday' => l10n.saturday,
  _ => l10n.sunday,
};

enum _ProfileProblem { name, ftp, weight, maxHeartRate }

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
  _ProfileProblem? _problem;
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
        ? _ProfileProblem.name
        : !ftp.$1
        ? _ProfileProblem.ftp
        : !weight.$1
        ? _ProfileProblem.weight
        : !maxHr.$1
        ? _ProfileProblem.maxHeartRate
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
      builder: (context, _) {
        final l10n = context.l10n;
        final problem = switch (_problem) {
          null => null,
          _ProfileProblem.name => l10n.errorEnterName,
          _ProfileProblem.ftp => l10n.errorFtp,
          _ProfileProblem.weight => l10n.errorWeight,
          _ProfileProblem.maxHeartRate => l10n.errorMaxHeartRate,
        };
        return ListView(
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
                            l10n.profileTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextField(
                            key: const Key('profile-name'),
                            controller: _name,
                            decoration: InputDecoration(labelText: l10n.name),
                          ),
                          _number(
                            'profile-ftp',
                            _ftp,
                            'FTP',
                            'W',
                            helper: l10n.ftpHelper,
                          ),
                          _number(
                            'profile-weight',
                            _weight,
                            l10n.weight,
                            'kg',
                            decimals: true,
                          ),
                          _number(
                            'profile-max-hr',
                            _maxHr,
                            l10n.maxHeartRate,
                            'bpm',
                            helper: l10n.maxHeartRateHelper,
                          ),
                          TextField(
                            key: const Key('profile-zone'),
                            controller: _zone,
                            decoration: InputDecoration(
                              labelText: l10n.timeZone,
                              hintText: 'Europe/Rome',
                              helperText: l10n.timeZoneHelper,
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            key: const Key('profile-first-day'),
                            initialValue: _firstDay,
                            decoration: InputDecoration(
                              labelText: l10n.firstDayOfWeek,
                            ),
                            items: [
                              for (final day in weekDayIds)
                                DropdownMenuItem(
                                  value: day,
                                  child: Text(weekDayName(l10n, day)),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _firstDay = v ?? _firstDay),
                          ),
                          SwitchListTile(
                            key: const Key('profile-email'),
                            contentPadding: EdgeInsets.zero,
                            value: _email,
                            title: Text(l10n.emailNotifications),
                            subtitle: Text(
                              widget.emailAvailable
                                  ? l10n.emailAvailableHelp
                                  : l10n.emailUnavailableHelp,
                            ),
                            onChanged: widget.emailAvailable
                                ? (v) => setState(() {
                                    _email = v;
                                    _saved = false;
                                  })
                                : null,
                          ),
                          if (problem ??
                                  (c.error == null
                                      ? null
                                      : failureText(l10n, c.error!))
                              case final message?)
                            Text(
                              message,
                              key: const Key('profile-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          if (_saved && c.error == null)
                            Text(l10n.saved, key: const Key('profile-saved')),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              key: const Key('profile-save'),
                              onPressed: c.saving ? null : _save,
                              child: Text(l10n.save),
                            ),
                          ),
                          const Divider(),
                          Text(
                            l10n.yourData,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(l10n.yourDataHelp),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              key: const Key('export-data'),
                              onPressed: c.exporting ? null : _export,
                              icon: const Icon(Icons.download),
                              label: Text(l10n.downloadMyData),
                            ),
                          ),
                          if (_exported)
                            Text(
                              l10n.exportStarted,
                              key: const Key('export-started'),
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
                              label: Text(l10n.deleteMyAccount),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(l10n.deleteAccountBody),
          TextField(
            key: const Key('delete-confirm'),
            controller: _answer,
            obscureText: widget.hasPassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.hasPassword
                  ? l10n.yourPassword
                  : l10n.confirmEmail,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-delete-account'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, _answer.text),
          child: Text(l10n.deleteEverything),
        ),
      ],
    );
  }
}
