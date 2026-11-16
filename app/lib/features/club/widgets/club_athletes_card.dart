import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';

/// The coach's way to the athletes who share their data.
class ClubAthletesCard extends StatelessWidget {
  const ClubAthletesCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.people_outline),
        title: Text(l10n.athletesTitle),
        trailing: TextButton(
          key: const Key('open-athletes'),
          onPressed: onOpen,
          child: Text(l10n.coachViewAthletes),
        ),
      ),
    );
  }
}
