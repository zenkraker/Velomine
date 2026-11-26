import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/section_card.dart';
import '../../calendar/club_ride_widgets.dart';

/// Where the club is found on the map, and whether nearby members may discover it.
class ClubLocationCard extends StatelessWidget {
  const ClubLocationCard({
    super.key,
    required this.club,
    required this.busy,
    required this.onSetLocation,
    required this.onToggleDiscoverable,
    required this.tileUrl,
    required this.attribution,
  });

  final ClubResponse club;
  final bool busy;
  final VoidCallback onSetLocation;
  final void Function(bool value) onToggleDiscoverable;
  final String tileUrl;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final latitude = club.latitude;
    final longitude = club.longitude;
    return SectionCard(
      key: const Key('club-location-card'),
      title: l10n.clubLocation,
      description: l10n.clubLocationHelp,
      children: [
        // The point a club is found by, as a person reads a map, not a raw pair of coordinates.
        if (latitude != null && longitude != null)
          MeetingMap(
            key: const Key('club-location-map'),
            latitude: latitude,
            longitude: longitude,
            tileUrl: tileUrl,
            attribution: attribution,
          )
        else
          Text(
            l10n.clubLocationNone,
            key: const Key('club-location-value'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('set-club-location'),
            onPressed: busy ? null : onSetLocation,
            icon: const Icon(Icons.place),
            label: Text(
              latitude != null && longitude != null
                  ? l10n.clubLocationChange
                  : l10n.clubLocationSet,
            ),
          ),
        ),
      ],
    );
  }
}
