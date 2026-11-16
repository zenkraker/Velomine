import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/section_card.dart';

/// Where the club is found on the map, and whether nearby members may discover it.
class ClubLocationCard extends StatelessWidget {
  const ClubLocationCard({
    super.key,
    required this.club,
    required this.busy,
    required this.onSetLocation,
    required this.onToggleDiscoverable,
  });

  final ClubResponse club;
  final bool busy;
  final VoidCallback onSetLocation;
  final void Function(bool value) onToggleDiscoverable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPoint = club.latitude != null && club.longitude != null;
    return SectionCard(
      key: const Key('club-location-card'),
      title: l10n.clubLocation,
      description: l10n.clubLocationHelp,
      children: [
        // The point a club is found by, as a person reads a map, not a raw pair of coordinates.
        Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(
              hasPoint ? Icons.place : Icons.place_outlined,
              size: AppClub.inlineIcon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                hasPoint ? l10n.clubLocationOnMap : l10n.clubLocationNone,
                key: const Key('club-location-value'),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('set-club-location'),
            onPressed: busy ? null : onSetLocation,
            icon: const Icon(Icons.place),
            label: Text(
              hasPoint ? l10n.clubLocationChange : l10n.clubLocationSet,
            ),
          ),
        ),
        SwitchListTile(
          key: const Key('club-discoverable'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.clubDiscoverable),
          subtitle: Text(l10n.clubDiscoverableHelp),
          value: club.isDiscoverable,
          onChanged: busy ? null : onToggleDiscoverable,
        ),
      ],
    );
  }
}
