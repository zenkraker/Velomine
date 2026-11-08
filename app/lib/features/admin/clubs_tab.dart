import 'package:flutter/material.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import 'admin_controller.dart';

/// Every club on the server, for the instance admin: create one, and turn it on or off.
class ClubsTab extends StatelessWidget {
  const ClubsTab({super.key, required this.controller});

  final AdminController controller;

  Future<void> _create(BuildContext context) async {
    final result = await showDialog<({String name, String ownerEmail})>(
      context: context,
      builder: (_) => const _CreateClubDialog(),
    );
    if (result == null) return;
    await controller.createClub(result.name, result.ownerEmail);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
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
                          l10n.adminClubs,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        key: const Key('create-club'),
                        onPressed: () => _create(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.adminCreateClub),
                      ),
                    ],
                  ),
                  if (controller.error != null)
                    Text(
                      failureText(l10n, controller.error!),
                      key: const Key('clubs-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (controller.clubs.isEmpty && !controller.loading)
                    Text(l10n.adminNoClubs, key: const Key('no-clubs')),
                  for (final club in controller.clubs)
                    Card(
                      key: Key('club-${club.id}'),
                      child: ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(club.name),
                        subtitle: Text(
                          [
                            l10n.clubMemberCount(club.memberCount),
                            if (club.ownerName != null) club.ownerName!,
                            if (club.ownerEmail != null) club.ownerEmail!,
                            '${l10n.adminClubJoinCode}: ${club.joinCode}',
                          ].join(' · '),
                        ),
                        trailing: Switch(
                          key: Key('club-active-${club.id}'),
                          value: club.isActive,
                          onChanged: controller.clubsBusy
                              ? null
                              : (on) => controller.setClubActive(club, on),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateClubDialog extends StatefulWidget {
  const _CreateClubDialog();

  @override
  State<_CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends State<_CreateClubDialog> {
  final _name = TextEditingController();
  final _owner = TextEditingController();
  bool _showProblem = false;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final email = _owner.text.trim();
    final problem = !_showProblem
        ? null
        : name.isEmpty
        ? l10n.errorClubName
        : email.isEmpty
        ? l10n.errorClubOwner
        : null;
    return AlertDialog(
      title: Text(l10n.adminCreateClub),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(
              key: const Key('club-name'),
              controller: _name,
              onChanged: (_) => setState(() => _showProblem = false),
              decoration: InputDecoration(labelText: l10n.adminClubName),
            ),
            TextField(
              key: const Key('club-owner-email'),
              controller: _owner,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _showProblem = false),
              decoration: InputDecoration(
                labelText: l10n.adminClubOwnerEmail,
                helperText: l10n.adminClubOwnerHelp,
                helperMaxLines: 2,
              ),
            ),
            if (problem != null)
              Text(
                problem,
                key: const Key('create-club-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('save-club'),
          onPressed: () {
            if (name.isEmpty || email.isEmpty) {
              setState(() => _showProblem = true);
              return;
            }
            Navigator.pop(context, (name: name, ownerEmail: email));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
