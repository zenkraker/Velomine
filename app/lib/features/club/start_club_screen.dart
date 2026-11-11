import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import 'location_picker.dart';
import 'start_club_view_model.dart';

/// Where a rider without a club starts one, when the operator allows it.
class StartClubScreen extends ConsumerStatefulWidget {
  const StartClubScreen({
    super.key,
    required this.onStarted,
    required this.tileUrl,
    required this.attribution,
  });

  final VoidCallback onStarted;
  final String tileUrl;
  final String attribution;

  @override
  ConsumerState<StartClubScreen> createState() => _StartClubScreenState();
}

class _StartClubScreenState extends ConsumerState<StartClubScreen> {
  final _name = TextEditingController();
  bool _showProblem = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<GeoPoint?> _pick(GeoPoint? initial) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LocationPickerScreen(
        initial: initial,
        tileUrl: widget.tileUrl,
        attribution: widget.attribution,
        locationService: ref.read(locationServiceProvider),
      ),
    ),
  );

  Future<void> _choosePlace() async {
    final picked = await _pick(ref.read(startClubViewModelProvider).point);
    if (picked == null || !mounted) return;
    ref.read(startClubViewModelProvider.notifier).setPoint(picked);
  }

  Future<void> _toggleDiscoverable(bool value) async {
    // Showing the club nearby needs a place, so ask for one first.
    if (value && ref.read(startClubViewModelProvider).point == null) {
      await _choosePlace();
      if (!mounted || ref.read(startClubViewModelProvider).point == null) {
        return;
      }
    }
    ref.read(startClubViewModelProvider.notifier).setDiscoverable(value);
  }

  Future<void> _start() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _showProblem = true);
      return;
    }
    final started = await ref
        .read(startClubViewModelProvider.notifier)
        .start(_name.text);
    if (started && mounted) widget.onStarted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(startClubViewModelProvider);
    final point = state.point;
    final failure = state.create.failure;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              l10n.startClubTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.startClubIntro),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              fieldKey: const Key('start-club-name'),
              controller: _name,
              label: l10n.startClubName,
            ),
            if (_showProblem && _name.text.trim().isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.startClubNameRequired,
                key: const Key('start-club-name-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.clubLocation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.clubLocationHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              point == null
                  ? l10n.clubLocationNone
                  : '${point.latitude.toStringAsFixed(5)}, '
                        '${point.longitude.toStringAsFixed(5)}',
              key: const Key('start-club-location'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('start-club-pick-location'),
                onPressed: state.create.running ? null : _choosePlace,
                icon: const Icon(Icons.place),
                label: Text(
                  point == null
                      ? l10n.clubLocationSet
                      : l10n.clubLocationChange,
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('start-club-discoverable'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.clubDiscoverable),
              subtitle: Text(l10n.clubDiscoverableHelp),
              value: state.isDiscoverable && point != null,
              onChanged: state.create.running ? null : _toggleDiscoverable,
            ),
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                failureText(l10n, failure),
                key: const Key('start-club-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('start-club'),
              onPressed: state.create.running ? null : _start,
              child: Text(l10n.startClubAction),
            ),
          ],
        ),
      ),
    );
  }
}
