import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/user_message_text.dart';
import '../../l10n/generated/app_localizations.dart';
import 'admin_view_models.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';

/// Every club on the server, for the instance admin: create one, and turn it on or off.
/// Opens the create-club sheet. The page header holds the button, so the screen and the tab both
/// use this.
Future<void> showCreateClubSheet(BuildContext context, WidgetRef ref) async {
  final result = await showSheet<({String name, String ownerEmail})>(
    context,
    builder: (_) => const _CreateClubSheet(),
  );
  if (result == null) return;
  await ref
      .read(adminClubsViewModelProvider.notifier)
      .create(result.name, result.ownerEmail);
}

class ClubsTab extends ConsumerWidget {
  const ClubsTab({super.key});

  Future<void> _changeOwner(
    BuildContext context,
    WidgetRef ref,
    AdminClubResponse club,
  ) async {
    final userId = await showSheet<String>(
      context,
      builder: (_) => _OwnerSheet(club: club),
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
    final plan = await showSheet<_Plan>(
      context,
      builder: (_) => _PlanSheet(club: club),
    );
    if (plan == null) return;
    await ref
        .read(adminClubsViewModelProvider.notifier)
        .setPlan(club, plan.memberLimit, plan.paidUntil);
  }

  /// Turns the club off or on, after saying what that means for its members.
  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    AdminClubResponse club,
  ) async {
    final l10n = context.l10n;
    final active = !club.isActive;
    final sure = await confirmAction(
      context,
      title: active ? l10n.adminClubActivate : l10n.adminClubDeactivate,
      body: l10n.adminClubActiveHelp,
      action: active ? l10n.adminClubActivate : l10n.adminClubDeactivate,
      key: Key('confirm-club-active-${club.id}'),
    );
    if (sure && context.mounted) {
      await ref
          .read(adminClubsViewModelProvider.notifier)
          .setActive(club, active);
    }
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentNarrow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (s.load.failure case final failure?)
                  InlineError(
                    failureText(l10n, failure),
                    key: const Key('clubs-error'),
                  ),
                // The first load is a loading state, not "no clubs yet".
                if (s.clubs.isEmpty &&
                    s.load.failure == null &&
                    !s.load.completed)
                  const LoadingState.rows(),
                if (s.clubs.isEmpty && s.load.completed)
                  EmptyState(
                    key: const Key('no-clubs'),
                    message: l10n.adminNoClubs,
                    icon: Icons.groups_outlined,
                  ),
                if (s.clubs.isNotEmpty)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final club in s.clubs) ..._row(context, ref, club),
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

  List<Widget> _row(
    BuildContext context,
    WidgetRef ref,
    AdminClubResponse club,
  ) {
    final l10n = context.l10n;
    final badge = _stateBadge(l10n, club);
    return [
      ListTile(
        title: Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(club.name),
            AppBadge(
              badge.label,
              key: Key('club-state-${club.id}'),
              tone: badge.tone,
            ),
          ],
        ),
        // No subtitle: the facts are the caption under the row, as the mock-up draws them.
        trailing: PageMenu(
          buttonKey: Key('club-menu-${club.id}'),
          entries: [
            PageMenuEntry(
              key: Key('edit-plan-${club.id}'),
              icon: Icons.event_available,
              label: l10n.adminClubEditPlan,
              onSelected: () => _editPlan(context, ref, club),
            ),
            if (club.members.any((m) => m.userId != club.ownerId))
              PageMenuEntry(
                key: Key('change-owner-${club.id}'),
                icon: Icons.person_pin_outlined,
                label: l10n.changeOwner,
                onSelected: () => _changeOwner(context, ref, club),
              ),
            PageMenuEntry(
              key: Key('club-active-${club.id}'),
              icon: club.isActive ? Icons.power_settings_new : Icons.power,
              label: club.isActive
                  ? l10n.adminClubDeactivate
                  : l10n.adminClubActivate,
              onSelected: () => _setActive(context, ref, club),
            ),
          ],
        ),
      ),
      // The facts are one caption under the name, as the mock-up draws them: owner, members, the plan
      // and the join code on one line, not four.
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, part) in [
              if (club.ownerName != null)
                Text(
                  '${l10n.clubOwner} ${club.ownerName}',
                  key: Key('club-owner-${club.id}'),
                ),
              Text(
                club.memberLimit == null
                    ? l10n.clubMemberCount(club.memberCount)
                    : l10n.clubPlanMembers(club.memberCount, club.memberLimit!),
                key: Key('club-members-${club.id}'),
              ),
              if (club.paidUntil != null)
                Text(
                  l10n.clubPlanPaidUntil(dateOnly(club.paidUntil)),
                  key: Key('club-paid-until-${club.id}'),
                ),
              Text('${l10n.adminClubJoinCode}: ${club.joinCode}'),
            ].indexed) ...[
              if (i > 0) const Text(' · '),
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodySmall!,
                child: part,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// What the row says about the club: switched off, plan over, or running.
  ({String label, AppBadgeTone tone}) _stateBadge(
    AppLocalizations l10n,
    AdminClubResponse club,
  ) {
    if (!club.isActive) {
      return (label: l10n.adminClubInactive, tone: AppBadgeTone.neutral);
    }
    final until = club.paidUntil;
    final today = DateTime.now();
    if (until != null &&
        DateTime(
          until.year,
          until.month,
          until.day,
        ).isBefore(DateTime(today.year, today.month, today.day))) {
      return (label: l10n.adminClubPlanEnded, tone: AppBadgeTone.care);
    }
    return (label: l10n.adminClubActive, tone: AppBadgeTone.good);
  }
}

class _CreateClubSheet extends StatefulWidget {
  const _CreateClubSheet();

  @override
  State<_CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<_CreateClubSheet> {
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
    return FormSheet(
      title: l10n.adminCreateClub,
      saveKey: const Key('save-club'),
      onSave: () {
        if (name.isEmpty || email.isEmpty) {
          setState(() => _showProblem = true);
          return;
        }
        Navigator.pop(context, (name: name, ownerEmail: email));
      },
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
          InlineError(problem, key: const Key('create-club-error')),
      ],
    );
  }
}

class _OwnerSheet extends StatefulWidget {
  const _OwnerSheet({required this.club});

  final AdminClubResponse club;

  @override
  State<_OwnerSheet> createState() => _OwnerSheetState();
}

class _OwnerSheetState extends State<_OwnerSheet> {
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
    return FormSheet(
      title: l10n.changeOwner,
      saveKey: const Key('save-owner'),
      onSave: _chosen == null ? null : () => Navigator.pop(context, _chosen),
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
    );
  }
}

/// The two values an operator records for a club.
typedef _Plan = ({int? memberLimit, DateTime? paidUntil});

class _PlanSheet extends StatefulWidget {
  const _PlanSheet({required this.club});

  final AdminClubResponse club;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
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
    return FormSheet(
      title: l10n.adminClubEditPlan,
      saveKey: const Key('save-plan'),
      onSave: () =>
          Navigator.pop(context, (memberLimit: _limit, paidUntil: _until)),
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
    );
  }
}
