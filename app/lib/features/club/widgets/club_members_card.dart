import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/badge.dart';
import '../../../core/widgets/empty_state.dart';
import 'club_labels.dart';

/// Everyone in the club, with the owner's way to change a role.
class ClubMembersCard extends StatefulWidget {
  const ClubMembersCard({
    super.key,
    required this.members,
    required this.owner,
    required this.onSetRole,
  });

  final List<ClubMemberResponse> members;
  final bool owner;
  final void Function(String userId, String role) onSetRole;

  @override
  State<ClubMembersCard> createState() => _ClubMembersCardState();
}

class _ClubMembersCardState extends State<ClubMembersCard> {
  /// The rows a card shows before the roster is opened: the design's four.
  static const _previewCount = 4;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final members = widget.members;
    final shown = _expanded ? members : members.take(_previewCount);
    return AppCard(
      key: const Key('club-members-card'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(l10n.clubMembers, style: text.titleMedium),
          ),
          if (members.isEmpty)
            EmptyState(
              key: const Key('club-members-empty'),
              message: l10n.clubMemberCount(0),
              framed: false,
            )
          else
            for (final member in shown)
              ListTile(
                key: Key('member-${member.userId}'),
                leading: Avatar(member.displayName),
                title: Text(member.displayName),
                // The role sits under the name, as the design draws it. In the trailing it took the
                // whole tile at half width, and the tile overflowed (`ListTile`'s own rule).
                subtitle: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppBadge(clubRoleName(l10n, member.role)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    if (widget.owner && member.role != 'owner')
                      PopupMenuButton<String>(
                        key: Key('member-menu-${member.userId}'),
                        tooltip: l10n.changeRoles,
                        onSelected: (role) =>
                            widget.onSetRole(member.userId, role),
                        itemBuilder: (_) => [
                          if (member.role != 'coach')
                            PopupMenuItem(
                              value: 'coach',
                              child: Text(l10n.clubMakeCoach),
                            ),
                          if (member.role != 'member')
                            PopupMenuItem(
                              value: 'member',
                              child: Text(l10n.clubMakeMember),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
          if (members.length > _previewCount && !_expanded)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextButton(
                  key: const Key('show-all-members'),
                  onPressed: () => setState(() => _expanded = true),
                  // Needs the count: "Show all 24" (l10n key clubMembersShowAll).
                  child: Text(l10n.moreDetailsAll),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
