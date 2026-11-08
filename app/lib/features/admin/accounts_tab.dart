import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import 'admin_controller.dart';

const _roleNames = {'member': 'Member', 'coach': 'Coach', 'admin': 'Admin'};

/// Every account, with what an admin can do to it.
class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key, required this.controller});

  final AdminController controller;

  Future<void> _roles(BuildContext context, AdminUserSummary user) async {
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RolesDialog(user: user),
    );
    if (chosen != null) await controller.setRoles(user, chosen);
  }

  Future<void> _delete(BuildContext context, AdminUserSummary user) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${user.displayName}?'),
        content: Text(
          'This deletes the account of ${user.email} for good: their rides, bikes, goals and the ride files. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure ?? false) await controller.delete(user);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final waiting = c.users.where((u) => !u.isApproved).toList();
    final rest = c.users.where((u) => u.isApproved).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (c.error != null)
          Text(
            failureText(context.l10n, c.error!),
            key: const Key('admin-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Text(
          'Waiting for approval',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (waiting.isEmpty && !c.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No accounts are waiting for approval.',
              key: Key('none-pending'),
            ),
          ),
        for (final user in waiting) _tile(context, user),
        const SizedBox(height: 16),
        Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
        for (final user in rest) _tile(context, user),
      ],
    );
  }

  Widget _tile(BuildContext context, AdminUserSummary user) {
    final mine = user.id == controller.myId();
    return Card(
      key: Key('user-${user.id}'),
      child: ListTile(
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(user.displayName),
            if (mine) const Chip(label: Text('You')),
            if (user.isLockedOut) const Chip(label: Text('Locked')),
            for (final role in user.roles)
              if (role != 'member') Chip(label: Text(_roleNames[role] ?? role)),
          ],
        ),
        subtitle: Text('${user.email} · ${dateTime(user.createdAt)}'),
        trailing: !user.isApproved
            ? FilledButton(
                key: Key('approve-${user.id}'),
                onPressed: () => controller.approve(user),
                child: const Text('Approve'),
              )
            : mine
            ? null
            : PopupMenuButton<String>(
                key: Key('user-menu-${user.id}'),
                tooltip: 'Actions for ${user.displayName}',
                onSelected: (action) => switch (action) {
                  'roles' => _roles(context, user),
                  'lock' => controller.lock(user),
                  'unlock' => controller.unlock(user),
                  _ => _delete(context, user),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: Key('roles-${user.id}'),
                    value: 'roles',
                    child: const Text('Change roles'),
                  ),
                  if (user.isLockedOut)
                    PopupMenuItem(
                      key: Key('unlock-${user.id}'),
                      value: 'unlock',
                      child: const Text('Unlock account'),
                    )
                  else
                    PopupMenuItem(
                      key: Key('lock-${user.id}'),
                      value: 'lock',
                      child: const Text('Lock account'),
                    ),
                  PopupMenuItem(
                    key: Key('delete-${user.id}'),
                    value: 'delete',
                    child: const Text('Delete account'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RolesDialog extends StatefulWidget {
  const _RolesDialog({required this.user});

  final AdminUserSummary user;

  @override
  State<_RolesDialog> createState() => _RolesDialogState();
}

class _RolesDialogState extends State<_RolesDialog> {
  late final Set<String> _chosen = {...widget.user.roles};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Roles for ${widget.user.displayName}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CheckboxListTile(
          value: true,
          onChanged: null,
          title: Text('Member'),
          subtitle: Text('Every account is a member.'),
        ),
        for (final role in ['coach', 'admin'])
          CheckboxListTile(
            key: Key('role-$role'),
            value: _chosen.contains(role),
            title: Text(_roleNames[role]!),
            onChanged: (on) => setState(
              () => (on ?? false) ? _chosen.add(role) : _chosen.remove(role),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('roles-save'),
        onPressed: () => Navigator.pop(context, _chosen.toList()),
        child: const Text('Save'),
      ),
    ],
  );
}
