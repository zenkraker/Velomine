import 'dart:async' show scheduleMicrotask;

import '../../core/confirm.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/inline_error.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
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
        .saveSettings(trimStartM: start, trimEndM: end);
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
    final answer = await showSheet<(String, int)>(
      context,
      builder: (_) =>
          _ZoneSheet(l10n: l10n, units: ref.read(unitsChoiceViewModelProvider)),
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
    final sure = await confirmDestructive(
      context,
      title: zone.name,
      body: l10n.privacyZoneDelete(zone.name),
      action: l10n.remove,
      key: const Key('confirm-privacy-zone-delete'),
    );
    if (sure) {
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

    return PageScaffold(
      title: l10n.privacyTitle,
      parent: l10n.profileTitle,
      subtitle: l10n.privacyHelp,
      maxWidth: AppLayout.contentNarrow,
      // One save for both cards, pinned where a form's action goes.
      bottomAction: privacy == null
          ? null
          : BottomActionBar.button(
              buttonKey: const Key('privacy-save'),
              label: l10n.save,
              busy: state.save.running,
              onPressed: () => _save(l10n),
              maxWidth: AppLayout.contentNarrow,
            ),
      children: [
        privacy == null && state.load.running
            ? const LoadingState()
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
                  SectionCard(
                    title: l10n.privacyTrimTitle,
                    description: l10n.privacyTrimHelp,
                    children: [
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
                      if (_problem case final problem?)
                        InlineError(problem, key: const Key('privacy-error')),
                      if (state.save.completed)
                        Text(l10n.saved, key: const Key('privacy-saved')),
                    ],
                  ),
                  SectionCard(
                    title: l10n.privacyZonesTitle,
                    description: l10n.privacyZonesHelp,
                    children: [
                      if (privacy.zones.isEmpty)
                        EmptyState(
                          key: const Key('privacy-zones-empty'),
                          message: l10n.privacyZonesEmpty,
                          icon: Icons.place_outlined,
                          framed: false,
                        )
                      else
                        for (final zone in privacy.zones)
                          ListTile(
                            key: Key('privacy-zone-${zone.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(zone.name),
                            subtitle: Text(
                              '${l10n.privacyZoneRadius} '
                              '${length(ref.watch(unitsChoiceViewModelProvider), zone.radiusM.toDouble())}',
                            ),
                            trailing: PageMenu(
                              buttonKey: Key('privacy-zone-actions-${zone.id}'),
                              entries: [
                                PageMenuEntry(
                                  key: Key('privacy-zone-delete-${zone.id}'),
                                  label: l10n.privacyZoneDelete(zone.name),
                                  icon: Icons.delete_outline,
                                  destructive: true,
                                  onSelected: state.save.running
                                      ? () {}
                                      : () => scheduleMicrotask(() {
                                          if (mounted) {
                                            _deleteZone(zone, l10n);
                                          }
                                        }),
                                ),
                              ],
                            ),
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('privacy-add-zone'),
                          onPressed: state.save.running
                              ? null
                              : () => _addZone(l10n),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.privacyAddZone),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }

  Widget _trimField(
    String key,
    TextEditingController controller,
    String label,
  ) => AppTextField(
    fieldKey: Key(key),
    controller: controller,
    label: label,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    suffix: _units == Units.imperial ? 'mi' : 'm',
  );
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ErrorState(
      message: failure == null
          ? l10n.actionGeneral
          : failureText(l10n, failure!),
      actionKey: const Key('privacy-error'),
      onRetry: onRetry,
    );
  }
}

class _ZoneSheet extends StatefulWidget {
  const _ZoneSheet({required this.l10n, required this.units});

  final AppLocalizations l10n;
  final Units units;

  @override
  State<_ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends State<_ZoneSheet> {
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
    return FormSheet(
      title: l10n.privacyAddZone,
      saveKey: const Key('privacy-zone-save'),
      onSave: _save,
      error: _problem,
      children: [
        AppTextField(
          fieldKey: const Key('privacy-zone-name'),
          controller: _name,
          label: l10n.privacyZoneName,
        ),
        AppTextField(
          fieldKey: const Key('privacy-zone-radius'),
          controller: _radius,
          label: l10n.privacyZoneRadius,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          suffix: widget.units == Units.imperial ? 'mi' : 'm',
          helper: l10n.privacyZoneRadiusHelp,
        ),
      ],
    );
  }
}
