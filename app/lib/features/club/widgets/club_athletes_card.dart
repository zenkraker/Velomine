import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/app_card.dart';

/// The coach's way to the athletes who share their data.
class ClubAthletesCard extends StatelessWidget {
  const ClubAthletesCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: EdgeInsets.zero,
      // The design says each card links to its full page, so the row itself opens it: a labelled
      // button in the trailing took the whole tile at half width.
      child: ListTile(
        key: const Key('open-athletes'),
        leading: const Icon(Icons.people_outline),
        title: Text(l10n.athletesTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}
