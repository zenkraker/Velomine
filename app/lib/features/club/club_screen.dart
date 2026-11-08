import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'club_controller.dart';

String clubRoleName(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.clubOwner,
  'coach' => l10n.clubCoach,
  _ => l10n.clubMemberRole,
};

/// The member's club: the roster, their own place in it, and (for the owner) the join code.
class ClubScreen extends StatelessWidget {
  const ClubScreen({
    super.key,
    required this.controller,
    required this.serverUrl,
    required this.onJoin,
  });

  final ClubController controller;
  final String serverUrl;
  final VoidCallback onJoin;

  Future<void> _rotateCode(BuildContext context) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.clubNewCodeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-new-code'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clubNewCode),
          ),
        ],
      ),
    );
    if (sure == true) await controller.rotateCode();
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clubLeaveTitle),
        content: Text(l10n.clubLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('confirm-leave-club'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clubLeave),
          ),
        ],
      ),
    );
    if (sure == true && await controller.leave() != null) {
      // The failure stays on the screen; a successful leave takes the router to the join page.
    }
  }

  void _copy(BuildContext context, String code) {
    final l10n = context.l10n;
    final link = '$serverUrl/join?code=$code';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.clubCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = context.l10n;
        final club = controller.club;
        if (club == null) {
          if (controller.loading && !controller.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Text(
                            l10n.clubNoneTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(l10n.clubNoneBody),
                          if (controller.error != null)
                            Text(
                              failureText(l10n, controller.error!),
                              key: const Key('club-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              key: const Key('go-join-club'),
                              onPressed: onJoin,
                              icon: const Icon(Icons.group_add),
                              label: Text(l10n.joinTitle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final owner = club.myRole == 'owner';
        final members = club.members;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Chip(label: Text(clubRoleName(l10n, club.myRole))),
                      ],
                    ),
                    if (!club.isActive)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            l10n.clubInactive,
                            key: const Key('club-inactive'),
                          ),
                        ),
                      ),
                    if (controller.error != null)
                      Text(
                        failureText(l10n, controller.error!),
                        key: const Key('club-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (owner && club.joinCode != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text(
                                l10n.clubJoinCode,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SelectableText(
                                club.joinCode!,
                                key: const Key('join-code-value'),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(letterSpacing: 4),
                              ),
                              Text(
                                l10n.clubJoinCodeHelp,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('copy-join-link'),
                                    onPressed: () =>
                                        _copy(context, club.joinCode!),
                                    icon: const Icon(Icons.link),
                                    label: Text(l10n.clubCopy),
                                  ),
                                  TextButton.icon(
                                    key: const Key('new-join-code'),
                                    onPressed: controller.busy
                                        ? null
                                        : () => _rotateCode(context),
                                    icon: const Icon(Icons.refresh),
                                    label: Text(l10n.clubNewCode),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Text(
                      l10n.clubMembers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Card(
                      child: Column(
                        children: [
                          for (final member in members)
                            ListTile(
                              key: Key('member-${member.userId}'),
                              leading: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              title: Text(member.displayName),
                              subtitle: Text(clubRoleName(l10n, member.role)),
                              trailing: owner && member.role != 'owner'
                                  ? PopupMenuButton<String>(
                                      key: Key('member-menu-${member.userId}'),
                                      tooltip: l10n.changeRoles,
                                      onSelected: (role) => controller.setRole(
                                        member.userId,
                                        role,
                                      ),
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
                    ),
                    if (!owner)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const Key('leave-club'),
                          onPressed: controller.busy
                              ? null
                              : () => _leave(context),
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.clubLeave),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                        ),
                      )
                    else
                      Text(
                        l10n.clubOwnerCannotLeave,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
