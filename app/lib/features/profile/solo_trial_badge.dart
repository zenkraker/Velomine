import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// The solo trial as the member sees it: how many days are left, or that it has ended. It is billing state and
/// nothing is blocked by it, so it says so quietly; payment is not open yet, which is why it is not a button.
class SoloTrialBadge extends StatelessWidget {
  const SoloTrialBadge({super.key, required this.endsAt, required this.today});

  /// The last day of the trial; null when the account never had one.
  final DateTime? endsAt;

  /// The member's "today", so the count matches their calendar.
  final DateTime today;

  static String label(AppLocalizations l10n, DateTime endsAt, DateTime today) {
    final last = DateTime.utc(endsAt.year, endsAt.month, endsAt.day);
    final now = DateTime.utc(today.year, today.month, today.day);
    final days = last.difference(now).inDays;
    if (days < 0) return l10n.soloTrialEnded;
    if (days == 0) return l10n.soloTrialLastDay;
    return l10n.soloTrialActive(days);
  }

  @override
  Widget build(BuildContext context) {
    final ends = endsAt;
    if (ends == null) return const SizedBox.shrink();
    return Semantics(
      label: label(context.l10n, ends, today),
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          key: const Key('solo-trial'),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: volt.withValues(alpha: 0.12),
            border: Border.all(color: volt.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              const Icon(Icons.timer_outlined, size: 16),
              Flexible(
                child: Text(
                  label(context.l10n, ends, today),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trial's end date from the generated client, as a local calendar day.
DateTime? soloTrialEnd(ProfileResponse? profile) => profile?.soloTrialEndsAt;
