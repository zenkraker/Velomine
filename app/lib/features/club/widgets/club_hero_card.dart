import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badge.dart';
import 'club_labels.dart';

/// The top of the club page: the person's role and how many ride here — the handful of facts the rest
/// of the page builds on. The club's name is the page's title, not a row of its own.
class ClubHeroCard extends StatelessWidget {
  const ClubHeroCard({super.key, required this.club});

  final ClubResponse club;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      key: const Key('club-hero'),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge(
            clubRoleName(l10n, club.myRole),
            key: const Key('club-role'),
            tone: club.myRole == 'owner'
                ? AppBadgeTone.good
                : AppBadgeTone.neutral,
          ),
          Text(
            l10n.clubMemberCount(club.members.length),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
