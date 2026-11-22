import 'dart:async';

import 'package:material_ui/material_ui.dart';
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
import '../../core/tokens.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/confirm.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/section_card.dart';

String _roleName(AppLocalizations l10n, String role) => switch (role) {
  'member' => l10n.roleMember,
  'coach' => l10n.roleCoach,
  'admin' => l10n.roleAdmin,
  _ => role,
};

/// Every account, with what an admin can do to it.
class AccountsTab extends ConsumerStatefulWidget {
  const AccountsTab({super.key});

  @override
  ConsumerState<AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends ConsumerState<AccountsTab> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _roles(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
    final chosen = await showSheet<List<String>>(
      context,
      builder: (_) => _RolesSheet(user: user),
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
    final sure = await confirmDestructive(
      context,
      title: l10n.deleteUserTitle(user.displayName),
      body: l10n.deleteUserBody(user.email),
      action: l10n.delete,
      key: const Key('confirm-delete'),
    );
    if (sure && context.mounted) {
      await ref.read(adminAccountsViewModelProvider.notifier).delete(user);
    }
  }

  Future<void> _resetTwoFactor(
    BuildContext context,
    WidgetRef ref,
    AdminUserSummary user,
  ) async {
    final l10n = context.l10n;
    final sure = await confirmDestructive(
      context,
      title: l10n.resetTwoFactor,
      body: l10n.resetTwoFactorBody,
      action: l10n.resetTwoFactor,
      key: const Key('confirm-reset-two-factor'),
    );
    if (sure && context.mounted) {
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
    await showSheet<void>(
      context,
      builder: (_) => _ResetLinkSheet(user: user, link: link),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(adminAccountsViewModelProvider);
    final myId = ref.watch(signedInUserIdProvider);
    final l10n = context.l10n;

    listenUserMessages(
      ref,
      context,
      adminAccountsViewModelProvider.select((s) => s.messages),
      ref.read(adminAccountsViewModelProvider.notifier).messageShown,
    );

    // Waiting accounts always show: they are what an admin opens this tab for.
    final query = _query.trim().toLowerCase();
    final waiting = s.users.where((u) => !u.isApproved).toList();
    final rest = s.users
        .where(
          (u) =>
              u.isApproved &&
              (query.isEmpty ||
                  u.displayName.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query)),
        )
        .toList();
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      children: [
        TextField(
          key: const Key('account-search'),
          controller: _search,
          decoration: InputDecoration(
            labelText: l10n.accountSearch,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clearSearch,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (s.load.failure case final failure?) ...[
          InlineError(
            failureText(l10n, failure),
            key: const Key('admin-error'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          title: l10n.waitingForApproval,
          children: [
            if (waiting.isEmpty && !s.load.running)
              EmptyState(
                key: const Key('none-pending'),
                message: l10n.nonePending,
                framed: false,
              )
            else
              for (final user in waiting) _tile(context, ref, user, myId),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.adminAccounts,
          children: [for (final user in rest) _tile(context, ref, user, myId)],
        ),
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
    return ListTile(
      key: Key('user-${user.id}'),
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(user.displayName),
          if (mine) AppBadge(l10n.you),
          if (user.isLockedOut) AppBadge(l10n.locked, tone: AppBadgeTone.bad),
          for (final role in user.roles)
            if (role != 'member')
              AppBadge(
                _roleName(l10n, role),
                tone: role == 'admin'
                    ? AppBadgeTone.good
                    : AppBadgeTone.neutral,
              ),
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
          : PageMenu(
              buttonKey: Key('user-menu-${user.id}'),
              entries: [
                PageMenuEntry(
                  key: Key('roles-${user.id}'),
                  icon: Icons.admin_panel_settings_outlined,
                  label: l10n.changeRoles,
                  onSelected: () =>
                      _later(context, () => _roles(context, ref, user)),
                ),
                if (user.isLockedOut)
                  PageMenuEntry(
                    key: Key('unlock-${user.id}'),
                    icon: Icons.lock_open_outlined,
                    label: l10n.unlockAccount,
                    onSelected: () => ref
                        .read(adminAccountsViewModelProvider.notifier)
                        .unlock(user),
                  )
                else
                  PageMenuEntry(
                    key: Key('lock-${user.id}'),
                    icon: Icons.lock_outline,
                    label: l10n.lockAccount,
                    onSelected: () => ref
                        .read(adminAccountsViewModelProvider.notifier)
                        .lock(user),
                  ),
                PageMenuEntry(
                  key: Key('reset-password-${user.id}'),
                  icon: Icons.link,
                  label: l10n.resetPasswordLink,
                  onSelected: () =>
                      _later(context, () => _resetLink(context, ref, user)),
                ),
                PageMenuEntry(
                  key: Key('reset-two-factor-${user.id}'),
                  icon: Icons.phonelink_lock_outlined,
                  label: l10n.resetTwoFactor,
                  onSelected: () => _later(
                    context,
                    () => _resetTwoFactor(context, ref, user),
                  ),
                ),
                PageMenuEntry(
                  key: Key('delete-${user.id}'),
                  icon: Icons.delete_outline,
                  label: l10n.deleteAccountAction,
                  destructive: true,
                  onSelected: () =>
                      _later(context, () => _delete(context, ref, user)),
                ),
              ],
            ),
    );
  }
}

/// Runs [action] after the menu has closed, when its context is still mounted.
void _later(BuildContext context, VoidCallback action) => scheduleMicrotask(() {
  if (context.mounted) action();
});

/// Shows the one-time link so the admin can copy it. The server does not store it; this dialog is the only copy.
class _ResetLinkSheet extends StatefulWidget {
  const _ResetLinkSheet({required this.user, required this.link});

  final AdminUserSummary user;
  final String link;

  @override
  State<_ResetLinkSheet> createState() => _ResetLinkSheetState();
}

class _ResetLinkSheetState extends State<_ResetLinkSheet> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetFrame(
      title: l10n.resetPasswordLinkTitle(widget.user.displayName),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            onPressed: _copy,
            child: Text(_copied ? l10n.linkCopied : l10n.copyLink),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
      children: [
        Text(l10n.resetPasswordLinkHelp),
        SelectableText(
          widget.link,
          key: const Key('reset-link'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RolesSheet extends StatefulWidget {
  const _RolesSheet({required this.user});

  final AdminUserSummary user;

  @override
  State<_RolesSheet> createState() => _RolesSheetState();
}

class _RolesSheetState extends State<_RolesSheet> {
  late final Set<String> _chosen = {...widget.user.roles};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.rolesFor(widget.user.displayName),
      saveKey: const Key('roles-save'),
      onSave: () => Navigator.pop(context, _chosen.toList()),
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
    );
  }
}
