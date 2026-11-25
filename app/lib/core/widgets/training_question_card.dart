import 'package:material_ui/material_ui.dart';
import 'package:velomine_api/api.dart' show TrainingRideMatch;

import '../../features/training/training_goals.dart';
import '../../features/training/training_text.dart';
import '../l10n.dart';
import '../tokens.dart';

/// The auto-training card on a ride's page: the question "Was this your Thursday strong and steady?", or, once the
/// rider said it was, the same session named with the way to take it back. The wording is RideDetailPage.md and
/// TrainingNames.md.
class TrainingQuestionCard extends StatelessWidget {
  const TrainingQuestionCard({
    super.key,
    required this.match,
    required this.rideStartedAt,
    this.busy = false,
    this.onYes,
    this.onNo,
    this.onNotThisSession,
  });

  final TrainingRideMatch match;

  /// When the ride began, so the card can say whether the session was planned for yesterday or tomorrow.
  final DateTime? rideStartedAt;

  final bool busy;

  /// The question's two answers; only one of them is ever shown.
  final VoidCallback? onYes;
  final VoidCallback? onNo;

  /// The way back out of a session the rider said was not this ride again.
  final VoidCallback? onNotThisSession;

  /// True while the rider still has to answer: the session waits for this ride to be its own.
  bool get _asks => match.state == 'planned' || match.state == 'missed';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final name = trainingText(
      l10n,
      english: match.englishName,
      italian: match.italianName,
    );
    return Card(
      key: const Key('training-question'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              _asks
                  ? trainingQuestion(l10n, match.localDate, name)
                  : trainingLinked(l10n, match.localDate, name),
              style: text.titleMedium,
            ),
            if (_asks && rideStartedAt != null)
              Text(
                trainingQuestionLine(l10n, match.localDate, rideStartedAt!),
                style: text.bodyMedium,
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: _asks
                  ? [
                      FilledButton(
                        key: const Key('training-question-yes'),
                        onPressed: busy ? null : onYes,
                        child: Text(l10n.yes),
                      ),
                      TextButton(
                        key: const Key('training-question-no'),
                        onPressed: busy ? null : onNo,
                        child: Text(l10n.no),
                      ),
                    ]
                  : [
                      TextButton(
                        key: const Key('training-not-this-session'),
                        onPressed: busy ? null : onNotThisSession,
                        child: Text(l10n.trainingNotThisSession),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
