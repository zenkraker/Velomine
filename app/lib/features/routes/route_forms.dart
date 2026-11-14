import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/providers.dart';
import '../../core/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import 'route_widgets.dart';
import 'routes_state.dart';
import 'routes_view_model.dart';

/// Adds a route: pick one of the member's rides, or a GPX file, look at the line, then name it.
class AddRouteScreen extends ConsumerStatefulWidget {
  const AddRouteScreen({
    super.key,
    required this.onAdded,
    this.tileUrl,
    this.attribution,
  });

  final void Function(String id) onAdded;
  final String? tileUrl;
  final String? attribution;

  @override
  ConsumerState<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends ConsumerState<AddRouteScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _source = 'ride';
  String _surface = 'road';
  String? _lastDraftName;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(addRouteViewModelProvider);
    final notifier = ref.read(addRouteViewModelProvider.notifier);

    listenUserMessages(
      ref,
      context,
      addRouteViewModelProvider.select((s) => s.messages),
      notifier.messageShown,
    );
    ref.listen(addRouteViewModelProvider.select((s) => s.draft?.name), (
      _,
      name,
    ) {
      if (name != null && name != _lastDraftName && _name.text.trim().isEmpty) {
        _lastDraftName = name;
        _name.text = name;
      }
    });

    final draft = s.draft;
    return PageScaffold(
      eyebrow: l10n.routesEyebrow,
      title: l10n.addRouteTitle,
      subtitle: l10n.addRouteHelp,
      maxWidth: AppLayout.contentNarrow,
      children: [
        SectionCard(
          title: l10n.addRouteFromRide,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  key: const Key('choose-route-from-ride'),
                  label: Text(l10n.addRouteFromRide),
                  selected: _source == 'ride',
                  onSelected: (_) => setState(() => _source = 'ride'),
                ),
                ChoiceChip(
                  key: const Key('choose-route-from-file'),
                  label: Text(l10n.addRouteFromFile),
                  selected: _source == 'file',
                  onSelected: (_) => setState(() => _source = 'file'),
                ),
              ],
            ),
            if (_source == 'file')
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('pick-gpx-file'),
                  onPressed: s.draftLoad.running
                      ? null
                      : () async {
                          final file = await ref.read(gpxFilePickerProvider)();
                          if (file != null) {
                            await notifier.fromFile(file);
                          }
                        },
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l10n.addRouteChooseFile),
                ),
              ),
            if (_source == 'ride') ...[
              if (s.ridesLoad.running && s.rides.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (s.rides.isEmpty)
                EmptyState(
                  key: const Key('no-rides-for-route'),
                  message: l10n.addRouteNoRides,
                  icon: Icons.directions_bike,
                )
              else
                for (final ride in s.rides)
                  ListTile(
                    key: Key('route-ride-${ride.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      s.draftForRideId == ride.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(ride.fileName),
                    subtitle: Text(
                      [
                        dateTime(ride.startTime),
                        km(
                          ref.watch(unitsChoiceViewModelProvider),
                          ride.distanceM,
                        ),
                      ].join(' · '),
                    ),
                    enabled: !s.draftLoad.running,
                    onTap: () => notifier.fromRide(ride.id),
                  ),
            ],
            if (s.draftLoad.running)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        if (draft != null) ...[
          SectionCard(
            title: l10n.addRoutePreview,
            description: l10n.addRoutePrivacyNote,
            children: [
              RoutePreview(
                latitude: draft.latitude,
                longitude: draft.longitude,
                elevation: draft.elevation,
                tileUrl: widget.tileUrl,
                attribution: widget.attribution,
              ),
              Text(
                routeLineOf(
                  ref.watch(unitsChoiceViewModelProvider),
                  draft.distanceM,
                  draft.climbingM,
                ),
              ),
            ],
          ),
          SectionCard(
            title: l10n.addRouteDetails,
            children: [
              AppTextField(
                fieldKey: const Key('route-name'),
                controller: _name,
                label: l10n.addRouteName,
              ),
              AppTextField(
                fieldKey: const Key('route-description'),
                controller: _description,
                label: l10n.addRouteDescription,
              ),
              DropdownButtonFormField<String>(
                key: const Key('route-surface'),
                initialValue: _surface,
                decoration: InputDecoration(labelText: l10n.addRouteSurface),
                items: [
                  for (final surface in routeSurfaceIds)
                    DropdownMenuItem(
                      value: surface,
                      child: Text(routeSurfaceName(l10n, surface)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _surface = value);
                },
              ),
            ],
          ),
          FilledButton.icon(
            key: const Key('save-route'),
            onPressed: s.action.running
                ? null
                : () async {
                    final id = await notifier.save(
                      name: _name.text.trim(),
                      surface: _surface,
                      description: _description.text,
                    );
                    if (id != null && context.mounted) {
                      widget.onAdded(id);
                    }
                  },
            icon: const Icon(Icons.add),
            label: Text(l10n.addRouteSave),
          ),
          if (s.action.failure case final failure?)
            ErrorState(
              message: failureText(l10n, failure),
              actionKey: const Key('add-route-error'),
            ),
        ],
      ],
    );
  }
}

/// Changes a route's name, description and surface. The line is not editable.
class EditRouteScreen extends ConsumerStatefulWidget {
  const EditRouteScreen({super.key, required this.id, required this.onSaved});

  final String id;
  final VoidCallback onSaved;

  @override
  ConsumerState<EditRouteScreen> createState() => _EditRouteScreenState();
}

class _EditRouteScreenState extends ConsumerState<EditRouteScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _surface = 'road';
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(routeEditViewModelProvider(widget.id));
    final notifier = ref.read(routeEditViewModelProvider(widget.id).notifier);
    final detail = s.detail;

    listenUserMessages(
      ref,
      context,
      routeEditViewModelProvider(widget.id).select((s) => s.messages),
      notifier.messageShown,
    );

    if (detail == null) {
      return s.load.running
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(message: l10n.failureMissing, icon: Icons.route);
    }
    if (!_filled) {
      _filled = true;
      _name.text = detail.name;
      _description.text = detail.description ?? '';
      _surface = detail.surface;
    }

    return PageScaffold(
      eyebrow: l10n.routesEyebrow,
      title: l10n.editRouteTitle,
      maxWidth: AppLayout.contentNarrow,
      children: [
        SectionCard(
          title: l10n.editRouteTitle,
          children: [
            AppTextField(
              fieldKey: const Key('edit-route-name'),
              controller: _name,
              label: l10n.addRouteName,
            ),
            AppTextField(
              fieldKey: const Key('edit-route-description'),
              controller: _description,
              label: l10n.addRouteDescription,
            ),
            DropdownButtonFormField<String>(
              key: const Key('edit-route-surface'),
              initialValue: _surface,
              decoration: InputDecoration(labelText: l10n.addRouteSurface),
              items: [
                for (final surface in routeSurfaceIds)
                  DropdownMenuItem(
                    value: surface,
                    child: Text(routeSurfaceName(l10n, surface)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _surface = value);
              },
            ),
          ],
        ),
        FilledButton.icon(
          key: const Key('save-route-edit'),
          onPressed: s.action.running
              ? null
              : () async {
                  final ok = await notifier.save(
                    name: _name.text.trim(),
                    surface: _surface,
                    description: _description.text,
                  );
                  if (ok && context.mounted) widget.onSaved();
                },
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.save),
        ),
        if (s.action.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('edit-route-error'),
          ),
      ],
    );
  }
}
