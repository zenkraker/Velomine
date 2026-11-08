import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'admin_controller.dart';

String _roleName(AppLocalizations l10n, String role) => switch (role) {
  'member' => l10n.roleMember,
  'coach' => l10n.roleCoach,
  'admin' => l10n.roleAdmin,
  _ => role,
};

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
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUserTitle(user.displayName)),
        content: Text(l10n.deleteUserBody(user.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (sure ?? false) await controller.delete(user);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l10n = context.l10n;
    final waiting = c.users.where((u) => !u.isApproved).toList();
    final rest = c.users.where((u) => u.isApproved).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (c.error != null)
          Text(
            failureText(l10n, c.error!),
            key: const Key('admin-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Text(
          l10n.waitingForApproval,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (waiting.isEmpty && !c.loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.nonePending, key: const Key('none-pending')),
          ),
        for (final user in waiting) _tile(context, user),
        const SizedBox(height: 16),
        Text(
          l10n.adminAccounts,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final user in rest) _tile(context, user),
      ],
    );
  }

  Widget _tile(BuildContext context, AdminUserSummary user) {
    final l10n = context.l10n;
    final mine = user.id == controller.myId();
    return Card(
      key: Key('user-${user.id}'),
      child: ListTile(
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(user.displayName),
            if (mine) Chip(label: Text(l10n.you)),
            if (user.isLockedOut) Chip(label: Text(l10n.locked)),
            for (final role in user.roles)
              if (role != 'member') Chip(label: Text(_roleName(l10n, role))),
          ],
        ),
        subtitle: Text('${user.email} · ${dateTime(user.createdAt)}'),
        trailing: !user.isApproved
            ? FilledButton(
                key: Key('approve-${user.id}'),
                onPressed: () => controller.approve(user),
                child: Text(l10n.approve),
              )
            : mine
            ? null
            : PopupMenuButton<String>(
                key: Key('user-menu-${user.id}'),
                tooltip: l10n.actionsFor(user.displayName),
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
                    child: Text(l10n.changeRoles),
                  ),
                  if (user.isLockedOut)
                    PopupMenuItem(
                      key: Key('unlock-${user.id}'),
                      value: 'unlock',
                      child: Text(l10n.unlockAccount),
                    )
                  else
                    PopupMenuItem(
                      key: Key('lock-${user.id}'),
                      value: 'lock',
                      child: Text(l10n.lockAccount),
                    ),
                  PopupMenuItem(
                    key: Key('delete-${user.id}'),
                    value: 'delete',
                    child: Text(l10n.deleteAccountAction),
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.rolesFor(widget.user.displayName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            value: true,
            onChanged: null,
            title: Text(l10n.roleMember),
            subtitle: Text(l10n.everyAccountMember),
          ),
          for (final role in ['coach', 'admin'])
            CheckboxListTile(
              key: Key('role-$role'),
              value: _chosen.contains(role),
              title: Text(_roleName(l10n, role)),
              onChanged: (on) => setState(
                () => (on ?? false) ? _chosen.add(role) : _chosen.remove(role),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('roles-save'),
          onPressed: () => Navigator.pop(context, _chosen.toList()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
