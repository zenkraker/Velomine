import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/format.dart';
import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/section_card.dart';

/// What the club's owner needs to know about the plan: room used, the paid-until day, and what to do when
/// the club is full or the plan has ended. Ordinary members never get a plan from the server.
class ClubPlanCard extends StatelessWidget {
  const ClubPlanCard({super.key, required this.plan});

  final ClubPlanResponse plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final limit = plan.memberLimit;
    final notice = switch (plan.blocked) {
      'ended' => l10n.clubPlanEndedNotice(dateOnly(plan.paidUntil)),
      'full' => l10n.clubPlanFullNotice,
      _ => null,
    };
    return SectionCard(
      key: const Key('club-plan-card'),
      title: l10n.clubPlanTitle,
      children: [
        Text(
          limit == null
              ? l10n.clubMemberCount(plan.memberCount)
              : l10n.clubPlanMembers(plan.memberCount, limit),
          key: const Key('club-plan-members'),
        ),
        if (limit != null)
          Semantics(
            label: l10n.clubPlanMembers(plan.memberCount, limit),
            excludeSemantics: true,
            child: LinearProgressIndicator(
              key: const Key('club-plan-bar'),
              value: (plan.memberCount / limit).clamp(0.0, 1.0),
              minHeight: AppClub.barHeight,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
          ),
        if (plan.paidUntil != null)
          Text(
            l10n.clubPlanPaidUntil(dateOnly(plan.paidUntil)),
            key: const Key('club-plan-paid-until'),
          ),
        if (notice != null)
          Text(
            notice,
            key: const Key('club-plan-notice'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
