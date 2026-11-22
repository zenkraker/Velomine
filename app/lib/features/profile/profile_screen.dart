import 'dart:async' show scheduleMicrotask;

import '../../core/widgets/loading_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/inline_error.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/confirm.dart';
import '../../core/format.dart';
import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/language_choice.dart';
import '../../core/rider_mode.dart';
import '../../core/units.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/source_note.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/password_field.dart';
import '../accounts/ftp_source_text.dart';
import '../accounts/heart_rate_source_text.dart';
import '../bikes/bikes_view_models.dart';
import '../bikes/service_marker.dart';
import '../supporter/supporter_badge.dart';
import '../supporter/supporter_view_model.dart';

import 'profile_state.dart';
import 'profile_view_model.dart';
import 'rider_mode_sheet.dart';
import 'solo_trial_badge.dart';
import 'zones_card.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';

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

enum _ProfileProblem { name, ftp, weight, birthYear, heartRate }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.emailAvailable,
    required this.openLink,
    required this.onAccountDeleted,
    required this.onPasswordChanged,
    required this.onOpenPrivacy,
    required this.onBecomeSupporter,
    required this.onReplaySupporter,
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

  /// Opens the supporter activation, while the server offers it and the member has no licence.
  final VoidCallback onBecomeSupporter;

  /// Plays the licence moment again, for the badge's triple tap and its replay button.
  final VoidCallback onReplaySupporter;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _ftp = TextEditingController();
  final _weight = TextEditingController();
  final _birthYear = TextEditingController();
  final _maxHr = TextEditingController();
  final _thresholdHr = TextEditingController();
  final _zone = TextEditingController();
  String _firstDay = 'monday';
  bool _email = true;
  bool _emailAccount = true;
  bool _emailTraining = false;
  _ProfileProblem? _problem;

  /// When the ride a test FTP came from started: the day of the effort, which the ride itself knows.
  DateTime? _ftpSourceRideStart;

  /// The local dates of the rides a measured maximum and threshold came from.
  DateTime? _maxHrRideDate;
  DateTime? _thresholdHrRideDate;
  late final ProviderSubscription<ProfileState> _profileSub;

  @override
  void initState() {
    super.initState();
    _profileSub = ref.listenManual(profileViewModelProvider, (_, next) {
      final profile = next.profile;
      if (profile == null) return;
      _fill(profile);
      _readFtpSourceRide(profile);
      _readHeartRateRides(profile);
    }, fireImmediately: true);
  }

  /// The rides a measured number came from, for the line under each field.
  Future<void> _readHeartRateRides(ProfileResponse profile) async {
    final max = await _measuredRideDate(
      profile.maxHeartRateSource.orElse(null),
      profile.maxHeartRateRideId.orElse(null),
    );
    final threshold = await _measuredRideDate(
      profile.thresholdHeartRateSource.orElse(null),
      profile.thresholdHeartRateRideId.orElse(null),
    );
    if (!mounted) return;
    setState(() {
      _maxHrRideDate = max;
      _thresholdHrRideDate = threshold;
    });
  }

  Future<DateTime?> _measuredRideDate(String? source, String? rideId) async {
    if (source != 'measured' || rideId == null) return null;
    return ref.read(profileViewModelProvider.notifier).rideLocalDate(rideId);
  }

  /// Opens the ride a measured number came from; nothing to open when it was typed or the ride is gone.
  VoidCallback? _rideLink(String? source, String? rideId) =>
      source == 'measured' && rideId != null
      ? () => context.push('/rides/$rideId')
      : null;

  Future<void> _readFtpSourceRide(ProfileResponse profile) async {
    final id = profile.ftpRideId.orElse(null);
    if (id == null) {
      if (_ftpSourceRideStart != null && mounted) {
        setState(() => _ftpSourceRideStart = null);
      }
      return;
    }
    final result = await ref
        .read(profileViewModelProvider.notifier)
        .rideStart(id);
    if (!mounted) return;
    setState(() => _ftpSourceRideStart = result);
  }

  /// The weight the member types, in the units on screen.
  Units get _units => ref.read(unitsChoiceViewModelProvider);

  String _weightText(double? kg) => kg == null
      ? ''
      : _units == Units.imperial
      ? (kg * poundsPerKg).toStringAsFixed(1)
      : kg.toString();

  double? _weightKg(double? typed) =>
      typed == null || _units == Units.metric ? typed : typed / poundsPerKg;

  void _fill(ProfileResponse p) {
    if (!mounted) return;
    setState(() {
      _name.text = p.displayName;
      _ftp.text = p.ftpW?.toString() ?? '';
      _weight.text = _weightText(p.weightKg);
      _birthYear.text = p.birthYear?.toString() ?? '';
      // Only a number the rider or a ride set is written in the field; an estimate is its hint text, so leaving the
      // field alone saves nothing.
      _maxHr.text = heartRateIsSet(p.maxHeartRateSource.orElse(null))
          ? p.maxHeartRate?.toString() ?? ''
          : '';
      _thresholdHr.text =
          heartRateIsSet(p.thresholdHeartRateSource.orElse(null))
          ? p.thresholdHeartRate.orElse(null)?.toString() ?? ''
          : '';
      _zone.text = p.timeZone ?? '';
      _firstDay = p.firstDayOfWeek;
      _email = p.emailNotifications;
      _emailAccount = p.emailAccountNotifications;
      _emailTraining = p.emailTrainingNotifications;
    });
  }

  /// The estimate a field shows as its hint, and nothing for a number the rider has.
  static String? _estimate(int? bpm, String? source) =>
      heartRateIsSet(source) ? null : bpm?.toString();

  @override
  void dispose() {
    _profileSub.close();
    for (final c in [
      _name,
      _ftp,
      _weight,
      _birthYear,
      _maxHr,
      _thresholdHr,
      _zone,
    ]) {
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
    final changed = await showSheet<bool>(
      context,
      builder: (_) => _ChangePasswordSheet(
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
    final answer = await showSheet<String>(
      context,
      builder: (_) => _DeleteAccountSheet(hasPassword: profile.hasPassword),
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
    // The range is the server's, in kilograms, whichever unit was typed. Round to
    // the grams the field holds, so 44 lb is exactly the 20 kg the server accepts.
    final typedWeight = double.tryParse(
      _weight.text.trim().replaceAll(',', '.'),
    );
    final weightKg = typedWeight == null ? null : _weightKg(typedWeight);
    final weight = (
      weightKg == null || (weightKg.round() >= 20 && weightKg.round() <= 300),
      typedWeight,
    );
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
            weightKg: _weightKg(weight.$2?.toDouble()),
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

  /// Saves one heart-rate number as soon as its field is done. The range is the server's, so a number outside it never
  /// leaves the phone; what the field holds decides whether anything is written at all.
  Future<void> _saveHeartRate(
    String kind,
    String text,
    int min,
    int max,
  ) async {
    final typed = int.tryParse(text.trim());
    if (typed != null && (typed < min || typed > max)) {
      setState(() => _problem = _ProfileProblem.heartRate);
      return;
    }
    setState(() => _problem = null);
    await ref
        .read(profileViewModelProvider.notifier)
        .commitHeartRate(kind, text);
  }

  Future<void> _setTelemetry({required bool crash, required bool usage}) async {
    await ref
        .read(profileViewModelProvider.notifier)
        .setTelemetry(crash: crash, usage: usage);
  }

  /// Back to the standard zones, after the rider says so. All three sets go, so a limit saved for the model the
  /// rider is not on cannot come back when their model changes.
  Future<void> _resetZones() async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.zonesResetTitle,
      body: l10n.zonesResetBody,
      action: l10n.zonesResetAction,
      key: const Key('confirm-zones-reset'),
    );
    if (!sure || !mounted) return;
    final notifier = ref.read(profileViewModelProvider.notifier);
    for (final set in const [
      powerSet,
      heartRateMaxSet,
      heartRateThresholdSet,
    ]) {
      if (await notifier.resetZones(set) != null) return;
    }
  }

  Widget _number(
    String key,
    TextEditingController c,
    String label,
    String suffix, {
    String? helper,
    String? hint,
    bool decimals = false,
    ValueChanged<String>? onDone,
  }) => AppTextField(
    fieldKey: Key(key),
    controller: c,
    hint: hint,
    keyboardType: TextInputType.numberWithOptions(decimal: decimals),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(decimals ? r'[0-9.,]' : r'[0-9]'),
      ),
    ],
    label: label,
    suffix: suffix,
    helper: helper,
    onDone: onDone,
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileViewModelProvider);
    final language = ref.watch(languageChoiceViewModelProvider);
    final situation = ref.watch(riderModeSituationProvider);
    final me = ref.watch(sessionViewModelProvider).me;
    final telemetry = s.telemetry;
    final telemetryAvailable =
        ref.watch(sessionViewModelProvider).serverInfo?.telemetryEnabled ??
        false;
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      profileViewModelProvider.select((s) => s.messages),
      ref.read(profileViewModelProvider.notifier).messageShown,
    );

    final problem = switch (_problem) {
      null => null,
      _ProfileProblem.name => l10n.errorEnterName,
      _ProfileProblem.ftp => l10n.errorFtp,
      _ProfileProblem.weight => l10n.errorWeight,
      _ProfileProblem.birthYear => l10n.errorBirthYear,
      _ProfileProblem.heartRate => l10n.errorHeartRate,
    };
    final failure = s.load.failure;
    final bikes = ref.watch(bikesSummaryProvider);
    final sections = <Widget>[
      SectionCard(
        title: l10n.profileAthlete,
        children: [
          AppTextField(
            fieldKey: const Key('profile-name'),
            controller: _name,
            label: l10n.name,
          ),
          _number('profile-ftp', _ftp, 'FTP', 'W', helper: l10n.ftpHelper),
          // Where the FTP came from, read from the newest row of its history.
          if (s.profile case final profile?)
            if (profileFtpSourceText(
                  l10n,
                  profile,
                  testRideStart: _ftpSourceRideStart,
                )
                case final note?)
              SourceNote(note, key: const Key('profile-ftp-source')),
          _number(
            'profile-weight',
            _weight,
            l10n.weight,
            _units == Units.imperial ? 'lb' : 'kg',
            decimals: true,
            // Without a weight, a ride with no power meter has nothing to estimate watts from.
            helper:
                s.profile?.weightKg == null &&
                    (s.profile?.hasRidesWithoutPower.orElse(false) ?? false)
                ? l10n.profileWeightEstimateHint
                : null,
          ),
          _number(
            'profile-birth-year',
            _birthYear,
            l10n.birthYear,
            '',
            helper: l10n.birthYearHelper,
          ),
          // The maximum in use and where it came from; the same for the threshold below it, with one line of help.
          _number(
            'profile-max-hr',
            _maxHr,
            l10n.maxHeartRateField,
            'bpm',
            helper: l10n.heartRateLeaveEmpty,
            hint: _estimate(
              s.profile?.maxHeartRate,
              s.profile?.maxHeartRateSource.orElse(null),
            ),
            onDone: (text) => _saveHeartRate('max', text, 120, 230),
          ),
          if (s.profile case final profile?)
            if (heartRateSourceText(
                  l10n,
                  profile.maxHeartRateSource.orElse(null),
                  profile.maxHeartRateSetAt.orElse(null),
                  rideId: profile.maxHeartRateRideId.orElse(null),
                  rideDate: _maxHrRideDate,
                )
                case final note?)
              SourceNote(
                note,
                key: const Key('profile-max-hr-source'),
                onTap: _rideLink(
                  profile.maxHeartRateSource.orElse(null),
                  profile.maxHeartRateRideId.orElse(null),
                ),
              ),
          _number(
            'profile-threshold-hr',
            _thresholdHr,
            l10n.thresholdHeartRateField,
            'bpm',
            helper: l10n.thresholdHeartRateHelp,
            hint: _estimate(
              s.profile?.thresholdHeartRate.orElse(null),
              s.profile?.thresholdHeartRateSource.orElse(null),
            ),
            onDone: (text) => _saveHeartRate('threshold', text, 90, 220),
          ),
          if (s.profile case final profile?)
            if (heartRateSourceText(
                  l10n,
                  profile.thresholdHeartRateSource.orElse(null),
                  profile.thresholdHeartRateSetAt.orElse(null),
                  threshold: true,
                  rideId: profile.thresholdHeartRateRideId.orElse(null),
                  rideDate: _thresholdHrRideDate,
                )
                case final note?)
              SourceNote(
                note,
                key: const Key('profile-threshold-hr-source'),
                onTap: _rideLink(
                  profile.thresholdHeartRateSource.orElse(null),
                  profile.thresholdHeartRateRideId.orElse(null),
                ),
              ),
          // A maximum lowered below a set threshold afterwards is allowed, so the profile says which number zones use.
          if (s.profile?.maxHeartRate case final max?)
            if (s.profile?.thresholdHeartRate.orElse(null) case final threshold?
                when threshold > max)
              SourceNote(
                l10n.thresholdAboveMax(max),
                key: const Key('profile-threshold-hr-above-max'),
              ),
          AppTextField(
            fieldKey: const Key('profile-zone'),
            controller: _zone,
            label: l10n.timeZone,
            hint: 'Europe/Rome',
            helper: l10n.timeZoneHelper,
          ),
          DropdownButtonFormField<String>(
            key: const Key('profile-first-day'),
            initialValue: _firstDay,
            // Twice the text needs to ellipsize inside the field, not spill out.
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.firstDayOfWeek),
            items: [
              for (final day in weekDayIds)
                DropdownMenuItem(
                  value: day,
                  child: Text(weekDayName(l10n, day)),
                ),
            ],
            onChanged: (v) => setState(() => _firstDay = v ?? _firstDay),
          ),
          Builder(
            builder: (context) {
              final device = Localizations.localeOf(context).languageCode;
              return DropdownButtonFormField<String>(
                key: const Key('profile-language'),
                isExpanded: true,
                initialValue:
                    language ??
                    (supportedLanguages.contains(device) ? device : 'en'),
                decoration: InputDecoration(labelText: l10n.language),
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
                        .read(languageChoiceViewModelProvider.notifier)
                        .choose(code);
                  }
                },
              );
            },
          ),
          DropdownButtonFormField<Units>(
            key: const Key('profile-units'),
            isExpanded: true,
            initialValue: ref.watch(unitsChoiceViewModelProvider),
            decoration: InputDecoration(labelText: l10n.units),
            items: [
              DropdownMenuItem(
                value: Units.metric,
                child: Text(l10n.unitsMetric),
              ),
              DropdownMenuItem(
                value: Units.imperial,
                child: Text(l10n.unitsImperial),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref.read(unitsChoiceViewModelProvider.notifier).choose(value);
              // The weight is now shown in the other unit.
              final profile = ref.read(profileViewModelProvider).profile;
              if (profile != null) _fill(profile);
            },
          ),
          if (situation.settings)
            ListTile(
              key: const Key('profile-rider-mode'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.riderModeTitle),
              // Before the member chooses, the account has no mode: it shows the one the app is using. A mode
              // this build does not know is not named, so nobody reads a wrong one.
              subtitle: Text(
                me?.riderMode != null && situation.mode == null
                    ? l10n.riderModeElsewhere
                    : riderModeName(l10n, situation.mode ?? defaultRiderMode),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showRiderModeSheet(context, firstTime: false),
            ),
          if ((problem ?? (failure == null ? null : failureText(l10n, failure)))
              case final message?)
            InlineError(message, key: const Key('profile-error')),
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
        ],
      ),
      // The zones in use, from the numbers above: a list, with their limits editable and back to automatic.
      if (s.zones case final zones?)
        if (zonesInUse(zones).isNotEmpty)
          ZonesCard(zones: zones, onReset: _resetZones),
      SectionCard(
        title: l10n.notifications,
        children: [
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
            contentPadding: EdgeInsets.zero,
            value: _emailAccount,
            title: Text(l10n.emailAccountNotifications),
            subtitle: Text(l10n.emailAccountNotificationsHelp),
            enabled: _email && widget.emailAvailable,
            onChanged: (v) =>
                setState(() => _emailAccount = v ?? _emailAccount),
          ),
          CheckboxListTile(
            key: const Key('profile-email-training'),
            contentPadding: EdgeInsets.zero,
            value: _emailTraining,
            title: Text(l10n.emailTrainingNotifications),
            subtitle: Text(l10n.emailTrainingNotificationsHelp),
            enabled: _email && widget.emailAvailable,
            onChanged: (v) =>
                setState(() => _emailTraining = v ?? _emailTraining),
          ),
        ],
      ),
      SectionCard(
        title: l10n.privacy,
        description: l10n.telemetryHelp,
        children: [
          ListTile(
            key: const Key('profile-ride-privacy'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyRidePrivacy),
            subtitle: Text(l10n.privacyRidePrivacyHelp),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenPrivacy,
          ),
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
            if (s.telemetrySave.completed && !s.telemetrySave.running)
              Text(
                '${l10n.telemetrySaved} ${l10n.telemetryRestart}',
                key: const Key('telemetry-saved'),
              ),
          ],
        ],
      ),
      // Billing state, shown as a badge: the trial never takes a feature away.
      if (s.profile?.soloTrialEndsAt != null)
        SoloTrialBadge(
          endsAt: s.profile!.soloTrialEndsAt,
          today: DateTime.now(),
        ),
      SectionCard(
        title: l10n.supporterSignInTitle,
        children: [
          SupporterSection(
            onBecomeSupporter: widget.onBecomeSupporter,
            onReplay: widget.onReplaySupporter,
            onOpen: () => Future.microtask(
              ref.read(supporterViewModelProvider.notifier).load,
            ),
          ),
        ],
      ),
      SectionCard(
        title: l10n.accountMenu,
        children: [
          // Each account destination is a row with what it is about, so the section reads as a list.
          if (s.profile?.hasPassword ?? false)
            _SettingsRow(
              rowKey: const Key('change-password'),
              icon: Icons.lock_reset,
              title: l10n.changePassword,
              onTap: s.password.running ? null : _changePassword,
            ),
          _SettingsRow(
            rowKey: const Key('two-factor-settings'),
            icon: Icons.verified_user,
            title: l10n.twoFactorTitle,
            subtitle: l10n.twoFactorIntro,
            onTap: () => context.push('/profile/two-factor'),
          ),
          _SettingsRow(
            rowKey: const Key('sessions'),
            icon: Icons.devices,
            title: l10n.sessionsTitle,
            onTap: () => context.push('/profile/sessions'),
          ),
        ],
      ),
      SectionCard(
        title: l10n.yourData,
        description: l10n.yourDataHelp,
        children: [
          _SettingsRow(
            rowKey: const Key('export-data'),
            icon: Icons.download,
            title: l10n.downloadMyData,
            onTap: s.export.running ? null : _export,
          ),
          if (s.export.completed)
            Text(l10n.exportStarted, key: const Key('export-started')),
        ],
      ),
    ];
    return PageScaffold(
      title: l10n.profileTitle,
      parent: l10n.accountMenu,
      maxWidth: AppLayout.contentMax,
      // Deleting the account is rare and final: in the menu, last and red.
      menu: PageMenu(
        buttonKey: const Key('profile-actions'),
        entries: [
          PageMenuEntry(
            key: const Key('delete-account'),
            label: l10n.deleteMyAccount,
            icon: Icons.delete_forever,
            destructive: true,
            onSelected: () => scheduleMicrotask(() {
              if (mounted) _delete();
            }),
          ),
        ],
      ),
      children: [
        if (s.load.running && s.profile == null)
          const LoadingState()
        else if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('profile-error'),
            onRetry: s.load.running
                ? null
                : ref.read(profileViewModelProvider.notifier).load,
          ),
        // The way to the bikes leads the page, full width; the settings sit in two columns under it.
        _MyBikesRow(summary: bikes, onTap: () => context.push('/bikes')),
        CardGrid(children: sections),
      ],
    );
  }
}

/// Asks for the current password and the new one. On success the app signs out, because the security stamp moved.
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.changePassword});

  final Future<Failure?> Function(String current, String newPassword)
  changePassword;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
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
    return FormSheet(
      title: l10n.changePasswordTitle,
      saveKey: const Key('confirm-change-password'),
      saveLabel: l10n.changePassword,
      onSave: _busy ? null : _submit,
      error: _error,
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
      ],
    );
  }
}

/// Asks the member to confirm deleting their account: with their password, or by typing their email when they have none.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.hasPassword});

  final bool hasPassword;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.deleteAccountTitle,
      saveKey: const Key('confirm-delete-account'),
      saveLabel: l10n.deleteEverything,
      destructive: true,
      onSave: () => Navigator.pop(context, _answer.text),
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
    );
  }
}

/// The way to the member's bikes, with how many there are and whether one needs service.
class _MyBikesRow extends StatelessWidget {
  const _MyBikesRow({required this.summary, required this.onTap});

  final BikesSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = l10n.bikeCount(summary.count);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '${l10n.myBikes}, $subtitle',
        excludeSemantics: true,
        child: ListTile(
          key: const Key('profile-my-bikes'),
          minTileHeight: 56,
          leading: const Icon(Icons.directions_bike),
          title: Text(l10n.myBikes),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              if (summary.due > 0 || summary.soon > 0)
                ServiceMarker(due: summary.due > 0),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// One destination of a settings card: its icon, its name, what it is about and a chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: rowKey,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
