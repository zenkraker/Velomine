import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/language_choice.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/password_field.dart';

import 'profile_state.dart';
import 'profile_view_model.dart';

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

enum _ProfileProblem { name, ftp, weight, birthYear }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.emailAvailable,
    required this.openLink,
    required this.onAccountDeleted,
    required this.onPasswordChanged,
    required this.onOpenPrivacy,
    required this.serverUrl,
  });

  /// The server this session belongs to, used for the export download link.
  final String serverUrl;

  /// Whether the server can send email at all; the switch is explained and disabled when it cannot.
  final bool emailAvailable;

  /// Opens the export download in the browser.
  final LinkOpener openLink;

  /// Called once the account is gone, so the app can leave the signed-in screens.
  final VoidCallback onAccountDeleted;

  /// Called after a password change: the security stamp moved, so every session must sign in again.
  final VoidCallback onPasswordChanged;

  /// Opens the member's ride privacy: stream switches, trimming and saved zones.
  final VoidCallback onOpenPrivacy;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _ftp = TextEditingController();
  final _weight = TextEditingController();
  final _birthYear = TextEditingController();
  final _zone = TextEditingController();
  String _firstDay = 'monday';
  bool _email = true;
  bool _emailAccount = true;
  bool _emailTraining = false;
  int? _estimatedMaxHr;
  _ProfileProblem? _problem;
  late final ProviderSubscription<ProfileState> _profileSub;

  @override
  void initState() {
    super.initState();
    _profileSub = ref.listenManual(profileViewModelProvider, (_, next) {
      final profile = next.profile;
      if (profile != null) _fill(profile);
    }, fireImmediately: true);
  }

  void _fill(ProfileResponse p) {
    if (!mounted) return;
    setState(() {
      _name.text = p.displayName;
      _ftp.text = p.ftpW?.toString() ?? '';
      _weight.text = p.weightKg?.toString() ?? '';
      _birthYear.text = p.birthYear?.toString() ?? '';
      _estimatedMaxHr = p.maxHeartRate;
      _zone.text = p.timeZone ?? '';
      _firstDay = p.firstDayOfWeek;
      _email = p.emailNotifications;
      _emailAccount = p.emailAccountNotifications;
      _emailTraining = p.emailTrainingNotifications;
    });
  }

  @override
  void dispose() {
    _profileSub.close();
    for (final c in [_name, _ftp, _weight, _birthYear, _zone]) {
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
    final path = await ref.read(profileViewModelProvider.notifier).exportLink();
    if (path == null) return;
    await widget.openLink(Uri.parse('${widget.serverUrl}$path'));
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        changePassword: ref
            .read(profileViewModelProvider.notifier)
            .changePassword,
      ),
    );
    if (changed == true) widget.onPasswordChanged();
  }

  Future<void> _delete() async {
    final profile = ref.read(profileViewModelProvider).profile;
    if (profile == null) return;
    final answer = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(hasPassword: profile.hasPassword),
    );
    if (answer == null) return;
    final deleted = await ref
        .read(profileViewModelProvider.notifier)
        .deleteAccount(
          password: profile.hasPassword ? answer : null,
          confirmEmail: profile.hasPassword ? null : answer,
        );
    if (deleted) widget.onAccountDeleted();
  }

  Future<void> _save() async {
    final ftp = _read(_ftp.text, 30, 1000);
    final weight = _read(_weight.text, 20, 300, whole: false);
    final birthYear = _read(_birthYear.text, 1900, DateTime.now().year - 10);
    final problem = _name.text.trim().isEmpty
        ? _ProfileProblem.name
        : !ftp.$1
        ? _ProfileProblem.ftp
        : !weight.$1
        ? _ProfileProblem.weight
        : !birthYear.$1
        ? _ProfileProblem.birthYear
        : null;
    setState(() => _problem = problem);
    if (problem != null) return;

    final zone = _zone.text.trim();
    final ok = await ref
        .read(profileViewModelProvider.notifier)
        .save(
          UpdateProfileRequest(
            displayName: _name.text.trim(),
            ftpW: ftp.$2?.toInt(),
            weightKg: weight.$2?.toDouble(),
            birthYear: birthYear.$2?.toInt(),
            timeZone: zone.isEmpty ? null : zone,
            firstDayOfWeek: _firstDay,
            emailNotifications: Optional.present(_email),
            emailAccountNotifications: Optional.present(_emailAccount),
            emailTrainingNotifications: Optional.present(_emailTraining),
          ),
        );
    if (!mounted) return;
    if (ok) setState(() {});
  }

  Future<void> _setTelemetry({required bool crash, required bool usage}) async {
    await ref
        .read(profileViewModelProvider.notifier)
        .setTelemetry(crash: crash, usage: usage);
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
    final s = ref.watch(profileViewModelProvider);
    final language = ref.watch(languageChoiceViewModelProvider);
    final telemetry = s.telemetry;
    final telemetryAvailable =
        ref.watch(sessionViewModelProvider).serverInfo?.telemetryEnabled ??
        false;
    final l10n = context.l10n;

    ref.listen(profileViewModelProvider.select((state) => state.messages), (
      _,
      messages,
    ) {
      for (final message in messages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessageText(l10n, message))));
        ref.read(profileViewModelProvider.notifier).messageShown(message.id);
      }
    });

    final problem = switch (_problem) {
      null => null,
      _ProfileProblem.name => l10n.errorEnterName,
      _ProfileProblem.ftp => l10n.errorFtp,
      _ProfileProblem.weight => l10n.errorWeight,
      _ProfileProblem.birthYear => l10n.errorBirthYear,
    };
    final failure = s.load.failure;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: s.load.running && s.profile == null
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
                        'profile-birth-year',
                        _birthYear,
                        l10n.birthYear,
                        '',
                        helper: l10n.birthYearHelper,
                      ),
                      Text(
                        _estimatedMaxHr == null
                            ? l10n.estimatedMaxHeartRateNone
                            : l10n.estimatedMaxHeartRate(_estimatedMaxHr!),
                        key: const Key('profile-max-hr-estimate'),
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
                      Builder(
                        builder: (context) {
                          final device = Localizations.localeOf(context)
                              .languageCode;
                          final current =
                              language ??
                              (supportedLanguages.contains(device)
                                  ? device
                                  : 'en');
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.language,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                key: const Key('profile-language'),
                                value: current,
                                isExpanded: true,
                                items: [
                                  for (final code in supportedLanguages)
                                    DropdownMenuItem(
                                      value: code,
                                      child: Text(switch (code) {
                                        'it' => l10n.languageItalian,
                                        _ => l10n.languageEnglish,
                                      }),
                                    ),
                                ],
                                onChanged: (code) {
                                  if (code != null) {
                                    ref
                                        .read(
                                          languageChoiceViewModelProvider
                                              .notifier,
                                        )
                                        .choose(code);
                                  }
                                },
                              ),
                            ),
                          );
                        },
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
                            ? (v) => setState(() => _email = v)
                            : null,
                      ),
                      CheckboxListTile(
                        key: const Key('profile-email-account'),
                        contentPadding: const EdgeInsets.only(left: 32),
                        value: _emailAccount,
                        title: Text(l10n.emailAccountNotifications),
                        subtitle: Text(l10n.emailAccountNotificationsHelp),
                        enabled: _email && widget.emailAvailable,
                        onChanged: (v) =>
                            setState(() => _emailAccount = v ?? _emailAccount),
                      ),
                      CheckboxListTile(
                        key: const Key('profile-email-training'),
                        contentPadding: const EdgeInsets.only(left: 32),
                        value: _emailTraining,
                        title: Text(l10n.emailTrainingNotifications),
                        subtitle: Text(l10n.emailTrainingNotificationsHelp),
                        enabled: _email && widget.emailAvailable,
                        onChanged: (v) => setState(
                          () => _emailTraining = v ?? _emailTraining,
                        ),
                      ),
                      const Divider(),
                      Text(
                        l10n.privacy,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ListTile(
                        key: const Key('profile-ride-privacy'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.privacyRidePrivacy),
                        subtitle: Text(l10n.privacyRidePrivacyHelp),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: widget.onOpenPrivacy,
                      ),
                      Text(l10n.telemetryHelp),
                      if (!telemetryAvailable)
                        Text(l10n.telemetryUnavailable)
                      else ...[
                        SwitchListTile(
                          key: const Key('telemetry-crash'),
                          contentPadding: EdgeInsets.zero,
                          value: telemetry?.crash ?? false,
                          title: Text(l10n.crashReports),
                          subtitle: Text(l10n.crashReportsHelp),
                          onChanged: s.telemetrySave.running
                              ? null
                              : (v) => _setTelemetry(
                                  crash: v,
                                  usage: telemetry?.usage ?? false,
                                ),
                        ),
                        SwitchListTile(
                          key: const Key('telemetry-usage'),
                          contentPadding: EdgeInsets.zero,
                          value: telemetry?.usage ?? false,
                          title: Text(l10n.usageData),
                          subtitle: Text(l10n.usageDataHelp),
                          onChanged: s.telemetrySave.running
                              ? null
                              : (v) => _setTelemetry(
                                  crash: telemetry?.crash ?? false,
                                  usage: v,
                                ),
                        ),
                        if (s.telemetrySave.completed &&
                            !s.telemetrySave.running)
                          Text(
                            '${l10n.telemetrySaved} ${l10n.telemetryRestart}',
                            key: const Key('telemetry-saved'),
                          ),
                      ],
                      if ((problem ??
                              (failure == null
                                  ? null
                                  : failureText(l10n, failure)))
                          case final message?)
                        Text(
                          message,
                          key: const Key('profile-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (s.save.completed)
                        Text(l10n.saved, key: const Key('profile-saved')),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          key: const Key('profile-save'),
                          onPressed: s.save.running ? null : _save,
                          child: Text(l10n.save),
                        ),
                      ),
                      if (s.profile?.hasPassword ?? false) ...[
                        const Divider(),
                        Text(
                          l10n.changePasswordTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: const Key('change-password'),
                            onPressed: s.password.running
                                ? null
                                : _changePassword,
                            icon: const Icon(Icons.lock_reset),
                            label: Text(l10n.changePassword),
                          ),
                        ),
                      ],
                      const Divider(),
                      Text(
                        l10n.twoFactorTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(l10n.twoFactorIntro),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const Key('two-factor-settings'),
                          onPressed: () => context.push('/profile/two-factor'),
                          icon: const Icon(Icons.verified_user),
                          label: Text(l10n.twoFactorTitle),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const Key('sessions'),
                          onPressed: () => context.push('/profile/sessions'),
                          icon: const Icon(Icons.devices),
                          label: Text(l10n.sessionsTitle),
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
                          onPressed: s.export.running ? null : _export,
                          icon: const Icon(Icons.download),
                          label: Text(l10n.downloadMyData),
                        ),
                      ),
                      if (s.export.completed)
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
  }
}

/// Asks for the current password and the new one. On success the app signs out, because the security stamp moved.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.changePassword});

  final Future<Failure?> Function(String current, String newPassword)
  changePassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_new.text.length < 10) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.changePassword(_current.text, _new.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _busy = false;
      _error = switch (failure.code) {
        409 => l10n.passwordNoPassword,
        400 => l10n.passwordWrongCurrent,
        _ => l10n.passwordChangeFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.changePasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          PasswordField(
            fieldKey: const Key('current-password'),
            visibilityKey: const Key('current-password-visibility'),
            controller: _current,
            label: l10n.currentPassword,
            autofillHints: const [AutofillHints.password],
          ),
          PasswordField(
            fieldKey: const Key('new-password'),
            visibilityKey: const Key('new-password-visibility'),
            controller: _new,
            label: l10n.newPassword,
            autofillHints: const [AutofillHints.newPassword],
          ),
          PasswordField(
            fieldKey: const Key('confirm-password'),
            visibilityKey: const Key('confirm-password-visibility'),
            controller: _confirm,
            label: l10n.confirmPassword,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Text(
              _error!,
              key: const Key('change-password-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-change-password'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.changePassword),
        ),
      ],
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
