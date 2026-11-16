import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../../core/l10n.dart';
import 'club_labels.dart';

/// Everyone in the club, with the owner's way to change a role.
class ClubMembersCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final member in members)
            ListTile(
              key: Key('member-${member.userId}'),
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(member.displayName),
              subtitle: Text(clubRoleName(l10n, member.role)),
              trailing: owner && member.role != 'owner'
                  ? PopupMenuButton<String>(
                      key: Key('member-menu-${member.userId}'),
                      tooltip: l10n.changeRoles,
                      onSelected: (role) => onSetRole(member.userId, role),
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
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
