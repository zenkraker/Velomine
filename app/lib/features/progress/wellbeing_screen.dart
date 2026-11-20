import 'dart:async' show scheduleMicrotask;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/confirm.dart';
import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import 'progress_tabs.dart';
import 'progress_view_models.dart';
import 'readiness_card.dart';
import 'wellbeing_card.dart';

/// Progress → Wellbeing answers "How do I feel, and why is my readiness what it is?". Only the owner
/// sees this page: free-text notes and readiness never reach a coach.
class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final values = await showCheckInSheet(context);
    if (values == null) return;
    await ref
        .read(wellbeingViewModelProvider.notifier)
        .saveCheckIn(
          values.fatigue,
          values.soreness,
          values.mood,
          values.stress,
          values.motivation,
        );
  }

  /// Asks first, after the menu has closed: withdrawing stops the check-in and the shares of it.
  void _withdraw(BuildContext context, WidgetRef ref) =>
      scheduleMicrotask(() async {
        if (!context.mounted) return;
        final l10n = context.l10n;
        final sure = await confirmDestructive(
          context,
          title: l10n.wellbeingWithdrawTitle,
          body: l10n.wellbeingWithdrawBody,
          action: l10n.wellbeingWithdrawConsent,
          key: const Key('wellbeing-withdraw-confirm'),
        );
        if (sure) {
          await ref.read(wellbeingViewModelProvider.notifier).withdrawConsent();
        }
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final readiness = ref.watch(readinessViewModelProvider);
    final wellbeing = ref.watch(wellbeingViewModelProvider);
    final today = wellbeing.today;
    // Before the first answer arrives nothing is known about consent, so the page loads rather than
    // drawing a consent card it may have to take back.
    final consentRequired = today?.consentRequired;
    final failure = wellbeing.load.failure ?? readiness.load.failure;

    listenUserMessages(
      ref,
      context,
      wellbeingViewModelProvider.select((s) => s.messages),
      ref.read(wellbeingViewModelProvider.notifier).messageShown,
    );

    return PageScaffold(
      title: l10n.wellbeing,
      parent: wide ? l10n.navProgress : null,
      primaryAction: consentRequired == false
          ? FilledButton(
              key: const Key('wellbeing-check-in'),
              onPressed: () => _checkIn(context, ref),
              child: Text(l10n.wellbeingCheckIn),
            )
          : null,
      menu: consentRequired == false
          ? PageMenu(
              buttonKey: const Key('wellbeing-actions'),
              entries: [
                PageMenuEntry(
                  key: const Key('wellbeing-withdraw'),
                  icon: Icons.block,
                  label: l10n.wellbeingWithdrawConsent,
                  destructive: true,
                  onSelected: wellbeing.action.running
                      ? () {}
                      : () => _withdraw(context, ref),
                ),
              ],
            )
          : null,
      children: [
        if (!wide) ProgressTabs(location: '/progress/wellbeing'),
        if (failure != null)
          ErrorState(
            message: failureText(l10n, failure),
            onRetry: ref.read(wellbeingViewModelProvider.notifier).load,
            actionKey: const Key('wellbeing-error'),
          ),
        // Under the error and before the first answer: the page is loading, not blank.
        if (today == null && wellbeing.load.running && failure == null)
          const LoadingState()
        // Before the first check-in the consent card is the whole page.
        else if (consentRequired ?? false)
          WellbeingCard(
            wellbeing: today,
            checkIns: wellbeing.checkIns,
            saving: wellbeing.action.running,
            onConsent: () =>
                ref.read(wellbeingViewModelProvider.notifier).consent(),
            onEdit: () => _checkIn(context, ref),
          )
        else ...[
          if (readiness.load.value case final data?)
            ReadinessCard(readiness: data),
          WellbeingCard(
            wellbeing: today,
            checkIns: wellbeing.checkIns,
            saving: wellbeing.action.running,
            onConsent: () =>
                ref.read(wellbeingViewModelProvider.notifier).consent(),
            onEdit: () => _checkIn(context, ref),
          ),
        ],
      ],
    );
  }
}
