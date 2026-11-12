import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import '../club/location_picker.dart';
import 'privacy_view_model.dart';
import '../../core/tokens.dart';

/// What other people see of the member's rides, and the places every view hides.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({
    super.key,
    required this.tileUrl,
    required this.attribution,
  });

  final String tileUrl;
  final String attribution;

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  final _trimStart = TextEditingController();
  final _trimEnd = TextEditingController();
  bool _showHeartRate = true;
  bool _showPower = true;
  bool _showCadence = true;
  bool _showSpeed = true;
  bool _showElevation = true;
  bool _showTemperature = true;
  bool _filled = false;
  String? _problem;
  late final ProviderSubscription<PrivacyResponse?> _privacySub;

  @override
  void initState() {
    super.initState();
    _privacySub = ref.listenManual(
      privacyViewModelProvider.select((state) => state.privacy),
      (_, privacy) => _fill(privacy),
      fireImmediately: true,
    );
  }

  void _fill(PrivacyResponse? privacy) {
    if (privacy == null || _filled || !mounted) return;
    setState(() {
      _filled = true;
      _showHeartRate = !privacy.streams.hideHeartRate;
      _showPower = !privacy.streams.hidePower;
      _showCadence = !privacy.streams.hideCadence;
      _showSpeed = !privacy.streams.hideSpeed;
      _showElevation = !privacy.streams.hideElevation;
      _showTemperature = !privacy.streams.hideTemperature;
      _trimStart.text = _trimText(privacy.trimStartM);
      _trimEnd.text = _trimText(privacy.trimEndM);
    });
  }

  @override
  void dispose() {
    _privacySub.close();
    _trimStart.dispose();
    _trimEnd.dispose();
    super.dispose();
  }

  Units get _units => ref.read(unitsChoiceViewModelProvider);

  /// A trim in the unit on screen. It is stored in metres, so imperial reads miles.
  String _trimText(int metres) {
    if (metres == 0) return '';
    return _units == Units.imperial
        ? (metres / metresPerMile).toStringAsFixed(1)
        : '$metres';
  }

  /// The typed trim in metres, never outside 0..5000 m. A value that would
  /// round to nothing in the other unit stays where it is.
  int? _metres(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return 0;
    final typed = double.tryParse(text.replaceAll(',', '.'));
    if (typed == null || typed < 0) return null;
    final metres = _units == Units.imperial
        ? (typed * metresPerMile).round()
        : typed.round();
    return metres < 0 || metres > 5000 ? null : metres;
  }

  Future<void> _save(AppLocalizations l10n) async {
    final start = _metres(_trimStart);
    final end = _metres(_trimEnd);
    setState(
      () => _problem = start == null || end == null
          ? l10n.privacyErrorTrim
          : null,
    );
    if (start == null || end == null) return;
    await ref
        .read(privacyViewModelProvider.notifier)
        .saveSettings(
          hideHeartRate: !_showHeartRate,
          hidePower: !_showPower,
          hideCadence: !_showCadence,
          hideSpeed: !_showSpeed,
          hideElevation: !_showElevation,
          hideTemperature: !_showTemperature,
          trimStartM: start,
          trimEndM: end,
        );
  }

  Future<void> _addZone(AppLocalizations l10n) async {
    final point = await Navigator.of(context).push<GeoPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: null,
          tileUrl: widget.tileUrl,
          attribution: widget.attribution,
          locationService: ref.read(locationServiceProvider),
        ),
      ),
    );
    if (point == null || !mounted) return;
    final answer = await showDialog<(String, int)>(
      context: context,
      builder: (_) => _ZoneDialog(
        l10n: l10n,
        units: ref.read(unitsChoiceViewModelProvider),
      ),
    );
    if (answer == null) return;
    await ref
        .read(privacyViewModelProvider.notifier)
        .addZone(
          name: answer.$1,
          latitude: point.latitude,
          longitude: point.longitude,
          radiusM: answer.$2,
        );
  }

  Future<void> _deleteZone(
    PrivacyZoneResponse zone,
    AppLocalizations l10n,
  ) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.privacyZoneDelete(zone.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-privacy-zone-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (sure == true) {
      await ref.read(privacyViewModelProvider.notifier).deleteZone(zone.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyViewModelProvider);
    final l10n = context.l10n;
    final privacy = state.privacy;

    listenUserMessages(
      ref,
      context,
      privacyViewModelProvider.select((s) => s.messages),
      ref.read(privacyViewModelProvider.notifier).messageShown,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: privacy == null && state.load.running
                ? const Center(child: CircularProgressIndicator())
                : privacy == null
                ? _LoadFailed(
                    failure: state.load.failure,
                    onRetry: () =>
                        ref.read(privacyViewModelProvider.notifier).load(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      Text(l10n.privacyHelp),
                      const Divider(),
                      Text(
                        l10n.privacyOthersSee,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _streamSwitch(
                        'privacy-hide-heart-rate',
                        _showHeartRate,
                        l10n.privacyHideHeartRate,
                        (v) => setState(() => _showHeartRate = v),
                      ),
                      _streamSwitch(
                        'privacy-hide-power',
                        _showPower,
                        l10n.privacyHidePower,
                        (v) => setState(() => _showPower = v),
                      ),
                      _streamSwitch(
                        'privacy-hide-cadence',
                        _showCadence,
                        l10n.privacyHideCadence,
                        (v) => setState(() => _showCadence = v),
                      ),
                      _streamSwitch(
                        'privacy-hide-speed',
                        _showSpeed,
                        l10n.privacyHideSpeed,
                        (v) => setState(() => _showSpeed = v),
                      ),
                      _streamSwitch(
                        'privacy-hide-elevation',
                        _showElevation,
                        l10n.privacyHideElevation,
                        (v) => setState(() => _showElevation = v),
                      ),
                      _streamSwitch(
                        'privacy-hide-temperature',
                        _showTemperature,
                        l10n.privacyHideTemperature,
                        (v) => setState(() => _showTemperature = v),
                      ),
                      const Divider(),
                      Text(
                        l10n.privacyTrimTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        spacing: AppSpacing.md,
                        children: [
                          Expanded(
                            child: _trimField(
                              'privacy-trim-start',
                              _trimStart,
                              l10n.privacyTrimStart,
                            ),
                          ),
                          Expanded(
                            child: _trimField(
                              'privacy-trim-end',
                              _trimEnd,
                              l10n.privacyTrimEnd,
                            ),
                          ),
                        ],
                      ),
                      Text(l10n.privacyTrimHelp),
                      if (_problem case final problem?)
                        Text(
                          problem,
                          key: const Key('privacy-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (state.save.completed)
                        Text(l10n.saved, key: const Key('privacy-saved')),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          key: const Key('privacy-save'),
                          onPressed: state.save.running
                              ? null
                              : () => _save(l10n),
                          child: Text(l10n.save),
                        ),
                      ),
                      const Divider(),
                      Text(
                        l10n.privacyZonesTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(l10n.privacyZonesHelp),
                      if (privacy.zones.isEmpty)
                        Text(l10n.privacyZonesEmpty)
                      else
                        for (final zone in privacy.zones)
                          ListTile(
                            key: Key('privacy-zone-${zone.id}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(zone.name),
                            subtitle: Text(
                              length(
                                ref.watch(unitsChoiceViewModelProvider),
                                zone.radiusM.toDouble(),
                              ),
                            ),
                            trailing: IconButton(
                              key: Key('privacy-zone-delete-${zone.id}'),
                              tooltip: l10n.privacyZoneDelete(zone.name),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: state.save.running
                                  ? null
                                  : () => _deleteZone(zone, l10n),
                            ),
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('privacy-add-zone'),
                          onPressed: state.save.running
                              ? null
                              : () => _addZone(l10n),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(l10n.privacyAddZone),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _streamSwitch(
    String key,
    bool value,
    String title,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    key: Key(key),
    contentPadding: EdgeInsets.zero,
    value: value,
    title: Text(title),
    onChanged: onChanged,
  );

  Widget _trimField(
    String key,
    TextEditingController controller,
    String label,
  ) => TextField(
    key: Key(key),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(
      labelText: label,
      suffixText: _units == Units.imperial ? 'mi' : 'm',
    ),
  );
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Text(
          failure == null ? l10n.actionGeneral : failureText(l10n, failure!),
          key: const Key('privacy-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ),
      ],
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({required this.l10n, required this.units});

  final AppLocalizations l10n;
  final Units units;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final _name = TextEditingController();
  late final _radius = TextEditingController(
    text: widget.units == Units.imperial ? '0.3' : '500',
  );
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    _radius.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _problem = widget.l10n.privacyErrorName);
      return;
    }
    // What the member typed becomes metres; the legal range is checked on that.
    final typed = double.tryParse(_radius.text.trim().replaceAll(',', '.'));
    final metres = typed == null
        ? null
        : widget.units == Units.imperial
        ? (typed * metresPerMile).round()
        : typed.round();
    if (metres == null || metres < 200 || metres > 1609) {
      setState(() => _problem = widget.l10n.privacyErrorRadius);
      return;
    }
    Navigator.of(context).pop((name, metres));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.privacyAddZone),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          TextField(
            key: const Key('privacy-zone-name'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.privacyZoneName),
          ),
          TextField(
            key: const Key('privacy-zone-radius'),
            controller: _radius,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.privacyZoneRadius,
              suffixText: widget.units == Units.imperial ? 'mi' : 'm',
              helperText: l10n.privacyZoneRadiusHelp,
            ),
          ),
          if (_problem case final problem?)
            Text(
              problem,
              key: const Key('privacy-zone-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('privacy-zone-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
