import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'admin_view_models.dart';

String _roleName(AppLocalizations l10n, String role) => switch (role) {
  'member' => l10n.roleMember,
  'coach' => l10n.roleCoach,
  'admin' => l10n.roleAdmin,
  _ => role,
};

/// Every account, with what an admin can do to it.
class AccountsTab extends ConsumerWidget {
  const AccountsTab({super.key});

  Future<void> _roles(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RolesDialog(user: user),
    );
    if (chosen != null) {
      await ref
          .read(adminAccountsViewModelProvider.notifier)
          .setRoles(user, chosen);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
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
    if ((sure ?? false) && context.mounted) {
      await ref.read(adminAccountsViewModelProvider.notifier).delete(user);
    }
  }

  Future<void> _resetTwoFactor(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetTwoFactor),
        content: Text(l10n.resetTwoFactorBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-reset-two-factor'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resetTwoFactor),
          ),
        ],
      ),
    );
    if ((sure ?? false) && context.mounted) {
      await ref
          .read(adminAccountsViewModelProvider.notifier)
          .resetTwoFactor(user);
    }
  }

  Future<void> _resetLink(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
    final link = await ref
        .read(adminAccountsViewModelProvider.notifier)
        .createResetLink(user);
    if (link == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ResetLinkDialog(user: user, link: link),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminAccountsViewModelProvider);
    final myId = ref.watch(signedInUserIdProvider);
    final l10n = context.l10n;

    ref.listen(
      adminAccountsViewModelProvider.select((state) => state.messages),
      (_, messages) {
        for (final message in messages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userMessageText(l10n, message))),
          );
          ref
              .read(adminAccountsViewModelProvider.notifier)
              .messageShown(message.id);
        }
      },
    );

    final waiting = s.users.where((u) => !u.isApproved).toList();
    final rest = s.users.where((u) => u.isApproved).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (s.load.failure case final failure?)
          Text(
            failureText(l10n, failure),
            key: const Key('admin-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Text(
          l10n.waitingForApproval,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (waiting.isEmpty && !s.load.running)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.nonePending, key: const Key('none-pending')),
          ),
        for (final user in waiting) _tile(context, ref, user, myId),
        const SizedBox(height: 16),
        Text(
          l10n.adminAccounts,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final user in rest) _tile(context, ref, user, myId),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
    String? myId,
  ) {
    final l10n = context.l10n;
    final mine = user.id == myId;
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
                onPressed: () => ref
                    .read(adminAccountsViewModelProvider.notifier)
                    .approve(user),
                child: Text(l10n.approve),
              )
            : mine
            ? null
            : PopupMenuButton<String>(
                key: Key('user-menu-${user.id}'),
                tooltip: l10n.actionsFor(user.displayName),
                onSelected: (action) => switch (action) {
                  'roles' => _roles(context, ref, user),
                  'lock' =>
                    ref
                        .read(adminAccountsViewModelProvider.notifier)
                        .lock(user),
                  'unlock' =>
                    ref
                        .read(adminAccountsViewModelProvider.notifier)
                        .unlock(user),
                  'reset-password' => _resetLink(context, ref, user),
                  'two-factor' => _resetTwoFactor(context, ref, user),
                  _ => _delete(context, ref, user),
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
                    key: Key('reset-password-${user.id}'),
                    value: 'reset-password',
                    child: Text(l10n.resetPasswordLink),
                  ),
                  PopupMenuItem(
                    key: Key('reset-two-factor-${user.id}'),
                    value: 'two-factor',
                    child: Text(l10n.resetTwoFactor),
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

/// Shows the one-time link so the admin can copy it. The server does not store it; this dialog is the only copy.
class _ResetLinkDialog extends StatefulWidget {
  const _ResetLinkDialog({required this.user, required this.link});

  final AdminUserSummary user;
  final String link;

  @override
  State<_ResetLinkDialog> createState() => _ResetLinkDialogState();
}

class _ResetLinkDialogState extends State<_ResetLinkDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.resetPasswordLinkTitle(widget.user.displayName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(l10n.resetPasswordLinkHelp),
          SelectableText(
            widget.link,
            key: const Key('reset-link'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _copy,
          child: Text(_copied ? l10n.linkCopied : l10n.copyLink),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
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
