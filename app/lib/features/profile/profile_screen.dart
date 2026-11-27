import 'dart:async' show Timer, scheduleMicrotask;

import '../../core/widgets/loading_state.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/saved_mark.dart';
import '../../core/widgets/inline_error.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/confirm.dart';
import '../../core/device_time_zone.dart';
import '../../core/time_zones.dart';
import '../../core/format.dart';
import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/language_choice.dart';
import '../../core/units.dart';
import '../../core/providers.dart';
import '../../core/rider_mode.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_text_field.dart';
import 'rider_mode_sheet.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/source_note.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/password_field.dart';
import '../accounts/ftp_source_text.dart';
import '../accounts/heart_rate_source_text.dart';
import '../bikes/bikes_view_models.dart';
import '../supporter/supporter_badge.dart';
import '../supporter/supporter_view_model.dart';
import '../training/auto_training_note.dart';
import '../training/training_view_model.dart';

import 'profile_state.dart';
import 'profile_view_model.dart';
import 'solo_trial_badge.dart';
import 'two_factor_view_model.dart';
import 'zones_card.dart';
import '../../core/tokens.dart';

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

/// The athlete fields that save themselves when the rider leaves them or presses done.
enum _AthleteField { name, ftp, weight, birthYear }

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
  String _firstDay = 'monday';
  bool _email = true;
  bool _emailAccount = true;
  bool _emailTraining = false;
  _ProfileProblem? _problem;

  /// Whether the last save came from the Preferences card or its notification switches, so its answer is shown
  /// there and not under the athlete fields it never touched.
  bool _preferenceSave = false;

  /// Whether a field is saving itself. The screen keeps the text the rider is typing while it is true.
  bool _saving = false;

  /// How long the "Saved." mark stays after a save that went through.
  static const _savedFor = Duration(seconds: 2);

  /// Whether the "Saved." mark shows, and the timer that hides it again.
  bool _savedShown = false;
  Timer? _savedTimer;

  final _nameFocus = FocusNode();
  final _ftpFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _birthYearFocus = FocusNode();
  final _maxHrFocus = FocusNode();
  final _thresholdHrFocus = FocusNode();

  /// Field saves run one after another, so a field left during another's save is sent after it, not dropped.
  Future<void> _fieldSaves = Future.value();

  /// The text of each field save not yet done, so the same text is never queued twice, and how many are not yet done.
  final _queuedText = <TextEditingController, String>{};
  int _pendingSaves = 0;

  /// Read through this, not `ref`, because a queued save can run after the State is disposed.
  late final ProviderContainer _container;

  /// The time zone the account holds. Null when it holds none.
  String? _zone;
  final _zoneText = TextEditingController();
  final _zoneFocus = FocusNode();

  /// The zone the picker shows: the account's, else the device's own (a browser names it), else UTC.
  String get _shownZone => _zone ?? deviceTimeZone() ?? 'UTC';

  /// When the ride a test FTP came from started: the day of the effort, which the ride itself knows.
  DateTime? _ftpSourceRideStart;

  /// The local dates of the rides a measured maximum and threshold came from.
  DateTime? _maxHrRideDate;
  DateTime? _thresholdHrRideDate;
  late final ProviderSubscription<ProfileState> _profileSub;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _zoneFocus.addListener(() {
      if (!_zoneFocus.hasFocus && mounted) _settleZone();
    });
    _nameFocus.addListener(() => _leaveSaves(_nameFocus, _AthleteField.name));
    _ftpFocus.addListener(() => _leaveSaves(_ftpFocus, _AthleteField.ftp));
    _weightFocus.addListener(
      () => _leaveSaves(_weightFocus, _AthleteField.weight),
    );
    _birthYearFocus.addListener(
      () => _leaveSaves(_birthYearFocus, _AthleteField.birthYear),
    );
    _maxHrFocus.addListener(() {
      if (!_maxHrFocus.hasFocus && mounted) _commitHeartRate('max');
    });
    _thresholdHrFocus.addListener(() {
      if (!_thresholdHrFocus.hasFocus && mounted) _commitHeartRate('threshold');
    });
    _profileSub = ref.listenManual(profileViewModelProvider, (_, next) {
      final profile = next.profile;
      if (profile == null) return;
      // A field saving itself must not rewrite the fields the rider is still typing in.
      if (!_preferenceSave && !_saving) _fill(profile);
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
  Units get _units => _container.read(unitsChoiceViewModelProvider);

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
      _zone = p.timeZone;
      _zoneText.text = _shownZone;
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
    _savedTimer?.cancel();
    // Only the field still being typed in can hold a value nobody has saved: the others were saved when they were
    // left. Its save takes the text now, so it still sends once the State is gone.
    if (_nameFocus.hasFocus) _commitAthlete(_AthleteField.name);
    if (_ftpFocus.hasFocus) _commitAthlete(_AthleteField.ftp);
    if (_weightFocus.hasFocus) _commitAthlete(_AthleteField.weight);
    if (_birthYearFocus.hasFocus) _commitAthlete(_AthleteField.birthYear);
    if (_maxHrFocus.hasFocus) _commitHeartRate('max');
    if (_thresholdHrFocus.hasFocus) _commitHeartRate('threshold');
    _profileSub.close();
    for (final c in [
      _name,
      _ftp,
      _weight,
      _birthYear,
      _maxHr,
      _thresholdHr,
      _zoneText,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _ftpFocus,
      _weightFocus,
      _birthYearFocus,
      _maxHrFocus,
      _thresholdHrFocus,
    ]) {
      f.dispose();
    }
    _zoneFocus.dispose();
    super.dispose();
  }

  /// Saves the zone the rider picked, and a name typed in full (any letter case). Anything else goes back to the
  /// zone shown, so a name that is not in the list is never saved.
  void _settleZone() {
    final typed = _zoneText.text.trim().toLowerCase();
    final match = timeZoneNames
        .where((z) => z.toLowerCase() == typed)
        .firstOrNull;
    if (match == null || match == _shownZone) {
      _zoneText.text = _shownZone;
      return;
    }
    _chooseZone(match);
  }

  void _chooseZone(String zone) {
    setState(() => _zone = zone);
    _zoneText.text = zone;
    _savePreference(timeZone: zone);
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

  /// A focus change that leaves an athlete field saves it.
  void _leaveSaves(FocusNode node, _AthleteField field) {
    if (!node.hasFocus && mounted) _commitAthlete(field);
  }

  /// Saves one athlete field when the rider leaves it or presses done. Only that field is checked and sent; the
  /// others keep the values the account holds. Nothing is sent for a value the account already holds.
  void _commitAthlete(_AthleteField field) {
    final controller = switch (field) {
      _AthleteField.name => _name,
      _AthleteField.ftp => _ftp,
      _AthleteField.weight => _weight,
      _AthleteField.birthYear => _birthYear,
    };
    _queueSave(controller, (text) => _saveAthleteField(field, text));
  }

  /// Saves a heart-rate field when the rider leaves it or presses done, within the server's range for it.
  void _commitHeartRate(String kind) {
    final isMax = kind == 'max';
    final (min, max) = isMax ? (120, 230) : (90, 220);
    _queueSave(
      isMax ? _maxHr : _thresholdHr,
      (text) => _saveHeartRate(kind, text, min, max),
    );
  }

  /// Queues one field's save with the text the field holds now. The text is taken here, not when the save runs, so
  /// a save that runs after the screen is gone still sends what was typed. The same text is never queued twice.
  void _queueSave(
    TextEditingController controller,
    Future<void> Function(String text) save,
  ) {
    final text = controller.text;
    if (_queuedText[controller] == text) return;
    _queuedText[controller] = text;
    Future<void> run() async {
      try {
        await save(text);
      } finally {
        _pendingSaves--;
        if (_queuedText[controller] == text) _queuedText.remove(controller);
      }
    }

    // Idle, the save starts now, so the request is out before the screen is gone; busy, it waits its turn.
    _pendingSaves++;
    _fieldSaves = _pendingSaves == 1 ? run() : _fieldSaves.then((_) => run());
  }

  /// Only the field that was left is read; the others are sent as the account holds them. It may run after the
  /// screen is disposed, so it touches the widget only while mounted.
  Future<void> _saveAthleteField(_AthleteField field, String text) async {
    final profile = _container.read(profileViewModelProvider).profile;
    if (profile == null) return;
    final name = text.trim();
    final ftp = _read(text, 30, 1000);
    final birthYear = _read(text, 1900, DateTime.now().year - 10);
    // The range is the server's, in kilograms, whichever unit was typed. Round to the grams the field holds, so
    // 44 lb is exactly the 20 kg the server accepts.
    final typedWeight = double.tryParse(text.trim().replaceAll(',', '.'));
    final weightKg = typedWeight == null ? null : _weightKg(typedWeight);
    final weightOk =
        weightKg == null || (weightKg.round() >= 20 && weightKg.round() <= 300);
    // Weight is compared at the one decimal the field shows, so a value typed back in another unit is not resent.
    final (valid, changed) = switch (field) {
      _AthleteField.name => (name.isNotEmpty, name != profile.displayName),
      _AthleteField.ftp => (ftp.$1, ftp.$2?.toInt() != profile.ftpW),
      _AthleteField.weight => (
        weightOk,
        weightKg?.toStringAsFixed(1) != profile.weightKg?.toStringAsFixed(1),
      ),
      _AthleteField.birthYear => (
        birthYear.$1,
        birthYear.$2?.toInt() != profile.birthYear,
      ),
    };
    final problem = _ProfileProblem.values.byName(field.name);
    if (!valid) {
      if (mounted) setState(() => _problem = problem);
      return;
    }
    if (_problem == problem && mounted) setState(() => _problem = null);
    if (!changed) return;

    _showSaved(
      await _holdFields(
        () => _container
            .read(profileViewModelProvider.notifier)
            .save(
              UpdateProfileRequest(
                displayName: field == _AthleteField.name
                    ? name
                    : profile.displayName,
                ftpW: field == _AthleteField.ftp
                    ? ftp.$2?.toInt()
                    : profile.ftpW,
                weightKg: field == _AthleteField.weight
                    ? weightKg
                    : profile.weightKg,
                birthYear: field == _AthleteField.birthYear
                    ? birthYear.$2?.toInt()
                    : profile.birthYear,
                timeZone: profile.timeZone,
                firstDayOfWeek: profile.firstDayOfWeek,
              ),
            ),
      ),
    );
  }

  /// Runs one save that the rider's own typing caused, with the fields kept as they are until it is done. Whether
  /// it went through comes back.
  Future<bool> _holdFields(Future<bool> Function() save) async {
    if (mounted) setState(() => _saving = true);
    try {
      return await save();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Shows the "Saved." mark for [_savedFor] after a save that went through. A failed save hides it; a save that
  /// sent nothing (unchanged or refused) leaves it as it is.
  void _showSaved(bool saved) {
    if (!mounted) return;
    final vm = ref.read(profileViewModelProvider);
    final failed = vm.save.failure != null || vm.heartRate.failure != null;
    if (!saved && !failed) return;
    _savedTimer?.cancel();
    setState(() => _savedShown = saved);
    if (saved) {
      _savedTimer = Timer(_savedFor, () {
        if (mounted) setState(() => _savedShown = false);
      });
    }
  }

  /// Saves one preference the moment it is chosen, as the design draws the Preferences card. The other fields keep
  /// the values the account holds, so nothing else is written unless the notification switches changed.
  Future<void> _savePreference({
    String? timeZone,
    String? firstDayOfWeek,
    bool notifications = false,
  }) async {
    final profile = ref.read(profileViewModelProvider).profile;
    if (profile == null) return;
    final zone = (timeZone ?? profile.timeZone)?.trim();
    setState(() => _preferenceSave = true);
    _showSaved(
      await _holdFields(
        () => ref
            .read(profileViewModelProvider.notifier)
            .save(
              UpdateProfileRequest(
                displayName: profile.displayName,
                ftpW: profile.ftpW,
                weightKg: profile.weightKg,
                birthYear: profile.birthYear,
                timeZone: zone == null || zone.isEmpty ? null : zone,
                firstDayOfWeek: firstDayOfWeek ?? profile.firstDayOfWeek,
                emailNotifications: notifications
                    ? Optional.present(_email)
                    : const Optional.absent(),
                emailAccountNotifications: notifications
                    ? Optional.present(_emailAccount)
                    : const Optional.absent(),
                emailTrainingNotifications: notifications
                    ? Optional.present(_emailTraining)
                    : const Optional.absent(),
              ),
            ),
      ),
    );
  }

  /// Turns one notification switch and saves it at once, as the Preferences card does.
  void _toggleNotification(VoidCallback change) {
    setState(change);
    _savePreference(notifications: true);
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
      if (mounted) setState(() => _problem = _ProfileProblem.heartRate);
      return;
    }
    if (mounted) setState(() => _problem = null);
    _showSaved(
      await _holdFields(
        () => _container
            .read(profileViewModelProvider.notifier)
            .commitHeartRate(kind, text),
      ),
    );
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

  /// A labelled choice under its own name, as the design draws the language and the units.
  Widget _choice(String label, Widget control) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpacing.sm,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      control,
    ],
  );

  /// A number field and, under it, the line that says where the number came from: one cell of a pair.
  Widget _cell(Widget field, [Widget? note]) => note == null
      ? field
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [field, note],
        );

  Widget _number(
    String key,
    TextEditingController c,
    String label,
    String suffix, {
    String? helper,
    String? hint,
    bool decimals = false,
    FocusNode? focusNode,
    ValueChanged<String>? onDone,
  }) => AppTextField(
    fieldKey: Key(key),
    controller: c,
    focusNode: focusNode,
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

  /// Turning auto training off is confirmed first: this week and later go, the past sessions stay.
  Future<void> _turnOffAutoTraining() async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.autoTrainingOffTitle,
      body: l10n.autoTrainingOffBody,
      action: l10n.autoTrainingOffAction,
      key: const Key('profile-auto-training-off-confirm'),
    );
    if (!sure || !mounted) return;
    await ref.read(trainingViewModelProvider.notifier).turnOff();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileViewModelProvider);
    final language = ref.watch(languageChoiceViewModelProvider);
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
    // The account rows say what they are about. Both answers come from their own view models, so the
    // row is drawn without its line until they arrive, never with a spinner.
    final twoFactor = ref.watch(twoFactorViewModelProvider).load.value;
    // Where the athlete's numbers came from, each a line under its own field.
    final athlete = s.profile;
    final ftpNote = athlete == null
        ? null
        : profileFtpSourceText(
            l10n,
            athlete,
            testRideStart: _ftpSourceRideStart,
          );
    final maxHrNote = athlete == null
        ? null
        : heartRateSourceText(
            l10n,
            athlete.maxHeartRateSource.orElse(null),
            athlete.maxHeartRateSetAt.orElse(null),
            rideId: athlete.maxHeartRateRideId.orElse(null),
            rideDate: _maxHrRideDate,
          );
    final thresholdHrNote = athlete == null
        ? null
        : heartRateSourceText(
            l10n,
            athlete.thresholdHeartRateSource.orElse(null),
            athlete.thresholdHeartRateSetAt.orElse(null),
            threshold: true,
            rideId: athlete.thresholdHeartRateRideId.orElse(null),
            rideDate: _thresholdHrRideDate,
          );
    final sections = <Widget>[
      // The mock-up's three pairs, in its order: name and year, FTP and weight, then the two heart rates,
      // each number with the line that says where it came from.
      SectionCard(
        title: l10n.profileAthlete,
        children: [
          _FieldPair(
            AppTextField(
              fieldKey: const Key('profile-name'),
              controller: _name,
              focusNode: _nameFocus,
              label: l10n.name,
              textInputAction: TextInputAction.done,
              onDone: (_) => _commitAthlete(_AthleteField.name),
            ),
            _number(
              'profile-birth-year',
              _birthYear,
              l10n.birthYear,
              '',
              helper: l10n.birthYearHelper,
              focusNode: _birthYearFocus,
              onDone: (_) => _commitAthlete(_AthleteField.birthYear),
            ),
          ),
          _FieldPair(
            _cell(
              _number(
                'profile-ftp',
                _ftp,
                'FTP',
                'W',
                helper: l10n.ftpHelper,
                focusNode: _ftpFocus,
                onDone: (_) => _commitAthlete(_AthleteField.ftp),
              ),
              ftpNote == null
                  ? null
                  : SourceNote(ftpNote, key: const Key('profile-ftp-source')),
            ),
            _cell(
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
                focusNode: _weightFocus,
                onDone: (_) => _commitAthlete(_AthleteField.weight),
              ),
            ),
          ),
          _FieldPair(
            _cell(
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
                focusNode: _maxHrFocus,
                onDone: (_) => _commitHeartRate('max'),
              ),
              maxHrNote == null
                  ? null
                  : SourceNote(
                      maxHrNote,
                      key: const Key('profile-max-hr-source'),
                      onTap: _rideLink(
                        athlete?.maxHeartRateSource.orElse(null),
                        athlete?.maxHeartRateRideId.orElse(null),
                      ),
                    ),
            ),
            _cell(
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
                focusNode: _thresholdHrFocus,
                onDone: (_) => _commitHeartRate('threshold'),
              ),
              thresholdHrNote == null
                  ? null
                  : SourceNote(
                      thresholdHrNote,
                      key: const Key('profile-threshold-hr-source'),
                      onTap: _rideLink(
                        athlete?.thresholdHeartRateSource.orElse(null),
                        athlete?.thresholdHeartRateRideId.orElse(null),
                      ),
                    ),
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
          if ((problem ??
                  (!_preferenceSave && failure != null
                      ? failureText(l10n, failure)
                      : null))
              case final message?)
            InlineError(message, key: const Key('profile-error')),
          SavedMark(key: const Key('profile-saved'), visible: _savedShown),
        ],
      ),
      // The zones in use, from the numbers above: a list, with their limits editable and back to automatic.
      if (s.zones case final zones?)
        if (zonesInUse(zones).isNotEmpty)
          ZonesCard(zones: zones, onReset: _resetZones),
      SectionCard(
        title: l10n.preferences,
        children: [
          // Each choice in a pair, as the mock-up draws them: a picker saves itself the moment it changes.
          _FieldPair(
            // Type a part of the name ("Eu" suggests Europe/Rome) or scroll the whole list; a pick saves at once.
            Autocomplete<String>(
              textEditingController: _zoneText,
              focusNode: _zoneFocus,
              optionsBuilder: (value) {
                final typed = value.text.trim().toLowerCase();
                if (typed.isEmpty) return timeZoneNames;
                // Names that start with the text come first, so "Eu" lists Europe/* before Australia/Eucla.
                final hits = timeZoneNames
                    .where((z) => z.toLowerCase().contains(typed))
                    .toList();
                return [
                  ...hits.where((z) => z.toLowerCase().startsWith(typed)),
                  ...hits.where((z) => !z.toLowerCase().startsWith(typed)),
                ];
              },
              onSelected: _chooseZone,
              fieldViewBuilder: (context, controller, focusNode, _) =>
                  AppTextField(
                    fieldKey: const Key('profile-zone'),
                    controller: controller,
                    focusNode: focusNode,
                    label: l10n.timeZone,
                    helper: l10n.timeZoneHelper,
                    textInputAction: TextInputAction.done,
                    onDone: (_) => _settleZone(),
                  ),
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
              onChanged: (value) {
                if (value == null) return;
                setState(() => _firstDay = value);
                _savePreference(firstDayOfWeek: value);
              },
            ),
          ),
          _FieldPair(
            _choice(
              l10n.language,
              Builder(
                builder: (context) {
                  final device = Localizations.localeOf(context).languageCode;
                  return SegmentedControl<String>(
                    buttonKey: const Key('profile-language'),
                    segments: [
                      for (final code in supportedLanguages)
                        ButtonSegment(
                          value: code,
                          label: Text(switch (code) {
                            'it' => l10n.languageItalian,
                            _ => l10n.languageEnglish,
                          }),
                        ),
                    ],
                    selected:
                        language ??
                        (supportedLanguages.contains(device) ? device : 'en'),
                    onChanged: (code) => ref
                        .read(languageChoiceViewModelProvider.notifier)
                        .choose(code),
                  );
                },
              ),
            ),
            _choice(
              l10n.units,
              SegmentedControl<Units>(
                buttonKey: const Key('profile-units'),
                segments: [
                  ButtonSegment(
                    value: Units.metric,
                    label: Text(l10n.unitsMetric),
                  ),
                  ButtonSegment(
                    value: Units.imperial,
                    label: Text(l10n.unitsImperial),
                  ),
                ],
                selected: ref.watch(unitsChoiceViewModelProvider),
                onChanged: (value) {
                  ref.read(unitsChoiceViewModelProvider.notifier).choose(value);
                  // The weight is now shown in the other unit.
                  final profile = ref.read(profileViewModelProvider).profile;
                  if (profile != null) _fill(profile);
                },
              ),
            ),
          ),
          if (_preferenceSave)
            if (s.save.failure case final preferenceFailure?)
              InlineError(
                failureText(l10n, preferenceFailure),
                key: const Key('preferences-error'),
              ),
        ],
      ),
      SectionCard(
        title: l10n.riding,
        children: [
          _MyBikesRow(summary: bikes, onTap: () => context.push('/bikes')),
          _SettingsRow(
            rowKey: const Key('profile-ride-privacy'),
            icon: Icons.shield_outlined,
            title: l10n.privacyRidePrivacy,
            subtitle: l10n.privacyRidePrivacyHelp,
            onTap: widget.onOpenPrivacy,
          ),
          // The rider mode is the member's own setting, and `RiderModeSituation.settings` exists to
          // say whether this row shows at all: an older server has no modes, so it does not.
          if (ref.watch(riderModeSituationProvider).settings)
            _SettingsRow(
              rowKey: const Key('profile-rider-mode'),
              icon: Icons.directions_bike_outlined,
              title: l10n.riderModeTitle,
              // Before choosing, the account has no mode; a mode this build does not know is not named.
              subtitle:
                  ref.watch(sessionViewModelProvider).me?.riderMode != null &&
                      ref.watch(riderModeSituationProvider).mode == null
                  ? l10n.riderModeElsewhere
                  : riderModeName(
                      l10n,
                      ref.watch(riderModeSituationProvider).mode ??
                          defaultRiderMode,
                    ),
              onTap: () => showRiderModeSheet(context, firstTime: false),
            ),
          // The operator's switch decides whether the setting exists at all; the member's plan is the value.
          if (ref
                  .watch(sessionViewModelProvider)
                  .serverInfo
                  ?.autoTrainingEnabled ??
              false)
            SwitchListTile(
              key: const Key('profile-auto-training'),
              contentPadding: EdgeInsets.zero,
              value: ref.watch(trainingViewModelProvider).on,
              title: Text(l10n.autoTrainingTitle),
              subtitle: const AutoTrainingNote(),
              onChanged: (on) =>
                  on ? context.push('/training/setup') : _turnOffAutoTraining(),
            ),
        ],
      ),
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
                ? (v) => _toggleNotification(() => _email = v)
                : null,
          ),
          SwitchListTile(
            key: const Key('profile-email-account'),
            contentPadding: EdgeInsets.zero,
            value: _emailAccount,
            title: Text(l10n.emailAccountNotifications),
            subtitle: Text(l10n.emailAccountNotificationsHelp),
            onChanged: _email && widget.emailAvailable
                ? (v) => _toggleNotification(() => _emailAccount = v)
                : null,
          ),
          SwitchListTile(
            key: const Key('profile-email-training'),
            contentPadding: EdgeInsets.zero,
            value: _emailTraining,
            title: Text(l10n.emailTrainingNotifications),
            subtitle: Text(l10n.emailTrainingNotificationsHelp),
            onChanged: _email && widget.emailAvailable
                ? (v) => _toggleNotification(() => _emailTraining = v)
                : null,
          ),
        ],
      ),
      SectionCard(
        title: l10n.telemetryTitle,
        description: l10n.telemetryHelp,
        children: [
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
          // Billing state in the same card: the trial never takes a feature away.
          if (s.profile?.soloTrialEndsAt != null)
            SoloTrialBadge(
              endsAt: s.profile!.soloTrialEndsAt,
              today: DateTime.now(),
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
            subtitle: twoFactor == null
                ? null
                : twoFactor.enabled
                ? l10n.twoFactorStateOn
                : l10n.twoFactorStateOff,
            onTap: () => context.push('/profile/two-factor'),
          ),
        ],
      ),
      SectionCard(
        title: l10n.yourData,
        description: l10n.yourDataHelp,
        children: [
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
            Text(l10n.exportStarted, key: const Key('export-started')),
        ],
      ),
    ];
    return PageScaffold(
      title: l10n.profileTitle,
      parent: l10n.accountMenu,
      // The mock-up draws Profile as a narrow page (`vm-page narrow`): one column of cards, no grid to square.
      maxWidth: AppLayout.contentNarrow,
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
        CardGrid(columns: 1, tabletColumns: 1, children: sections),
      ],
    );
  }
}

/// Two fields side by side from the tablet width, one under the other on a phone, as the mock-up's
/// `vm-fields2` does.
class _FieldPair extends StatelessWidget {
  const _FieldPair(this.first, this.second);

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            Expanded(child: first),
            Expanded(child: second),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [first, second],
        );
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
        AppTextField(
          fieldKey: const Key('delete-confirm'),
          controller: _answer,
          obscureText: widget.hasPassword,
          autofocus: true,
          label: widget.hasPassword ? l10n.yourPassword : l10n.confirmEmail,
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
    // The state in words, as the design draws it: a warning colour alone is never the message.
    final state = summary.due > 0
        ? l10n.bikeServiceDue
        : summary.soon > 0
        ? l10n.bikeServiceSoon
        : null;
    return Semantics(
      button: true,
      label: [l10n.myBikes, subtitle, ?state].join(', '),
      excludeSemantics: true,
      child: ListTile(
        key: const Key('profile-my-bikes'),
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        leading: const Icon(Icons.directions_bike),
        title: Text(l10n.myBikes),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            if (state case final state?)
              AppBadge(
                state,
                key: Key(summary.due > 0 ? 'service-due' : 'service-soon'),
                tone: summary.due > 0 ? AppBadgeTone.care : AppBadgeTone.warn,
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
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
