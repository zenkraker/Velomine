import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import 'admin_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/empty_state.dart';

/// Every club on the server, for the instance admin: create one, and turn it on or off.
class ClubsTab extends ConsumerWidget {
  const ClubsTab({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String ownerEmail})>(
      context: context,
      builder: (_) => const _CreateClubDialog(),
    );
    if (result == null) return;
    await ref
        .read(adminClubsViewModelProvider.notifier)
        .create(result.name, result.ownerEmail);
  }

  Future<void> _changeOwner(
    BuildContext context,
    WidgetRef ref,
    AdminClubResponse club,
  ) async {
    final userId = await showDialog<String>(
      context: context,
      builder: (_) => _OwnerDialog(club: club),
    );
    if (userId != null) {
      await ref
          .read(adminClubsViewModelProvider.notifier)
          .setOwner(club, userId);
    }
  }

  Future<void> _editPlan(
    BuildContext context,
    WidgetRef ref,
    AdminClubResponse club,
  ) async {
    final plan = await showDialog<_Plan>(
      context: context,
      builder: (_) => _PlanDialog(club: club),
    );
    if (plan == null) return;
    await ref
        .read(adminClubsViewModelProvider.notifier)
        .setPlan(club, plan.memberLimit, plan.paidUntil);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(adminClubsViewModelProvider);

    listenUserMessages(
      ref,
      context,
      adminClubsViewModelProvider.select((s) => s.messages),
      ref.read(adminClubsViewModelProvider.notifier).messageShown,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
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
                      onPressed: () => _create(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.adminCreateClub),
                    ),
                  ],
                ),
                if (s.load.failure case final failure?)
                  Text(
                    failureText(l10n, failure),
                    key: const Key('clubs-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (s.clubs.isEmpty && !s.load.running)
                  EmptyState(
                    key: const Key('no-clubs'),
                    message: l10n.adminNoClubs,
                    icon: Icons.groups_outlined,
                  ),
                for (final club in s.clubs)
                  Card(
                    key: Key('club-${club.id}'),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(club.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('edit-plan-${club.id}'),
                                tooltip: l10n.adminClubEditPlan,
                                icon: const Icon(Icons.event_available),
                                onPressed: s.action.running
                                    ? null
                                    : () => _editPlan(context, ref, club),
                              ),
                              if (club.members.any(
                                (m) => m.userId != club.ownerId,
                              ))
                                IconButton(
                                  key: Key('change-owner-${club.id}'),
                                  tooltip: l10n.changeOwner,
                                  icon: const Icon(Icons.person_pin_outlined),
                                  onPressed: s.action.running
                                      ? null
                                      : () => _changeOwner(context, ref, club),
                                ),
                            ],
                          ),
                        ),
                        // The facts sit under the tile with the card's whole width: beside the
                        // trailing switch an email had a third of it and broke mid-word.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.xs,
                            children: [
                              Text(
                                club.memberLimit == null
                                    ? l10n.clubMemberCount(club.memberCount)
                                    : l10n.clubPlanMembers(
                                        club.memberCount,
                                        club.memberLimit!,
                                      ),
                                key: Key('club-members-${club.id}'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (club.paidUntil != null)
                                Text(
                                  l10n.clubPlanPaidUntil(
                                    dateOnly(club.paidUntil),
                                  ),
                                  key: Key('club-paid-until-${club.id}'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (club.ownerName != null)
                                Text(
                                  club.ownerName!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (club.ownerEmail != null)
                                Text(
                                  club.ownerEmail!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                '${l10n.adminClubJoinCode}: ${club.joinCode}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          key: Key('club-active-${club.id}'),
                          title: Text(l10n.adminClubActive),
                          value: club.isActive,
                          onChanged: s.action.running
                              ? null
                              : (on) => ref
                                    .read(adminClubsViewModelProvider.notifier)
                                    .setActive(club, on),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
          spacing: AppSpacing.md,
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
                helperMaxLines: 3,
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

class _OwnerDialog extends StatefulWidget {
  const _OwnerDialog({required this.club});

  final AdminClubResponse club;

  @override
  State<_OwnerDialog> createState() => _OwnerDialogState();
}

class _OwnerDialogState extends State<_OwnerDialog> {
  late String? _chosen = widget.club.members
      .where((m) => m.userId != widget.club.ownerId)
      .firstOrNull
      ?.userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final members = widget.club.members
        .where((m) => m.userId != widget.club.ownerId)
        .toList();
    return AlertDialog(
      title: Text(l10n.changeOwner),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            Text(l10n.chooseOwner),
            DropdownButtonFormField<String>(
              key: const Key('new-owner'),
              initialValue: _chosen,
              items: [
                for (final member in members)
                  DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.displayName),
                  ),
              ],
              onChanged: (value) => setState(() => _chosen = value),
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
          key: const Key('save-owner'),
          onPressed: _chosen == null
              ? null
              : () => Navigator.pop(context, _chosen),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The two values an operator records for a club.
typedef _Plan = ({int? memberLimit, DateTime? paidUntil});

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({required this.club});

  final AdminClubResponse club;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  static const _bands = [25, 75, 150];

  late int? _limit = widget.club.memberLimit;
  late DateTime? _until = widget.club.paidUntil;

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      // A day, not an instant: keep it as the calendar date that was picked.
      setState(
        () => _until = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.adminClubEditPlan),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            DropdownButtonFormField<int?>(
              key: const Key('plan-limit'),
              initialValue: _limit,
              // The longest band's label does not fit beside the arrow on a phone.
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.adminClubLimit),
              items: [
                for (final band in _bands)
                  DropdownMenuItem<int?>(
                    value: band,
                    child: Text(l10n.adminClubLimitOption(band)),
                  ),
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.adminClubLimitNone),
                ),
              ],
              onChanged: (value) => setState(() => _limit = value),
            ),
            Text(
              l10n.adminClubPaidUntil,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              _until == null ? l10n.adminClubNoDate : dateOnly(_until),
              key: const Key('plan-date'),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('plan-choose-date'),
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(l10n.adminClubChooseDate),
                ),
                TextButton(
                  key: const Key('plan-clear-date'),
                  onPressed: _until == null
                      ? null
                      : () => setState(() => _until = null),
                  child: Text(l10n.adminClubNoDate),
                ),
              ],
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
          key: const Key('save-plan'),
          onPressed: () =>
              Navigator.pop(context, (memberLimit: _limit, paidUntil: _until)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
