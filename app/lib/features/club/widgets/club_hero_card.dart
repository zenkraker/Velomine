import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_card.dart';
import 'club_labels.dart';

/// The top of the club page: the name, the person's role and how many ride here — the handful of
/// facts the rest of the page builds on.
class ClubHeroCard extends StatelessWidget {
  const ClubHeroCard({super.key, required this.club});

  final ClubResponse club;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(club.name, style: text.headlineSmall, semanticsLabel: club.name),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(clubRoleName(l10n, club.myRole)),
                backgroundColor: scheme.primaryContainer,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                l10n.clubMemberCount(club.members.length),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
