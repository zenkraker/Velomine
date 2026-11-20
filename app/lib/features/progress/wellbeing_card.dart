import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/form_sheet.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/segmented_control.dart';

/// What a check-in says: five numbers from 1 to 5, in the order the server stores them.
typedef CheckInScores = ({
  int fatigue,
  int soreness,
  int mood,
  int stress,
  int motivation,
});

/// Asks how the rider feels, in a sheet. Returns the five numbers, or null when the sheet is dismissed.
Future<CheckInScores?> showCheckInSheet(BuildContext context) =>
    showSheet(context, builder: (_) => const _CheckInSheet());

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet();

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final _values = <String, int>{
    'fatigue': 3,
    'soreness': 3,
    'mood': 3,
    'stress': 3,
    'motivation': 3,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.wellbeingToday,
      saveKey: const Key('wellbeing-save'),
      saveLabel: l10n.wellbeingSave,
      onSave: () => Navigator.pop(context, (
        fatigue: _values['fatigue']!,
        soreness: _values['soreness']!,
        mood: _values['mood']!,
        stress: _values['stress']!,
        motivation: _values['motivation']!,
      )),
      children: [
        for (final (id, label) in [
          ('fatigue', l10n.wellbeingFatigue),
          ('soreness', l10n.wellbeingSoreness),
          ('mood', l10n.wellbeingMood),
          ('stress', l10n.wellbeingStress),
          ('motivation', l10n.wellbeingMotivation),
        ])
          _ScoreRow(
            label: label,
            keyName: id,
            value: _values[id]!,
            onChanged: (v) => setState(() => _values[id] = v),
          ),
      ],
    );
  }
}

/// The daily check-in: consent first, then today's scores and how the rider felt over two weeks.
/// Checking in is the page's own action, so the card only says what is stored.
class WellbeingCard extends StatelessWidget {
  const WellbeingCard({
    super.key,
    required this.wellbeing,
    required this.checkIns,
    required this.onConsent,
    required this.onEdit,
    required this.saving,
  });

  final WellbeingResponse? wellbeing;
  final CheckInsResponse? checkIns;
  final Future<bool> Function() onConsent;

  /// Opens the check-in sheet, from the card's Edit.
  final VoidCallback onEdit;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final wellbeing = this.wellbeing;

    if (wellbeing == null) {
      return const SizedBox.shrink();
    }

    if (wellbeing.consentRequired) {
      return SectionCard(
        key: const Key('wellbeing-consent-card'),
        title: l10n.wellbeing,
        children: [
          Text(l10n.wellbeingConsentTitle, style: text.titleSmall),
          Text(l10n.wellbeingConsentBody, style: text.bodySmall),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const Key('wellbeing-consent'),
              onPressed: saving ? null : onConsent,
              child: Text(l10n.wellbeingConsentAction),
            ),
          ),
        ],
      );
    }

    final today = wellbeing.today;

    return SectionCard(
      key: const Key('wellbeing-card'),
      title: l10n.wellbeingHowYouFeel,
      children: [
        if (today != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.wellbeingSaved, style: text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: 6,
                      children: [
                        _Score(
                          label: l10n.wellbeingFatigue,
                          value: today.fatigue,
                        ),
                        _Score(
                          label: l10n.wellbeingSoreness,
                          value: today.soreness,
                        ),
                        _Score(label: l10n.wellbeingMood, value: today.mood),
                        _Score(
                          label: l10n.wellbeingStress,
                          value: today.stress,
                        ),
                        _Score(
                          label: l10n.wellbeingMotivation,
                          value: today.motivation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('wellbeing-edit'),
                onPressed: onEdit,
                child: Text(l10n.wellbeingEdit),
              ),
            ],
          ),
        ] else
          Text(l10n.wellbeingNoToday, style: text.bodySmall),
        if (checkIns case final checkIns?
            when checkIns.checkIns.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.wellbeingHistory14, style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          // Two weeks, newest first: the page answers "how do I feel", not "what did I ever say".
          for (final checkIn in checkIns.checkIns.reversed.take(14))
            _HistoryRow(checkIn: checkIn),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(l10n.wellbeingPrivate, style: text.bodySmall),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) =>
      Text('$label $value', style: Theme.of(context).textTheme.bodySmall);
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.keyName,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String keyName;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: AppProgress.scoreLabelWidth,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: SegmentedControl<int>(
            buttonKey: Key('wellbeing-$keyName'),
            segments: [
              for (var i = 1; i <= 5; i++)
                ButtonSegment(value: i, label: Text('$i')),
            ],
            selected: value,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.checkIn});

  final CheckInResponse checkIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: AppProgress.dateWidth,
            child: Text(
              DateFormat.MMMd(locale).format(checkIn.date),
              style: text.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              '${l10n.wellbeingShortFatigue} ${checkIn.fatigue} · '
              '${l10n.wellbeingShortSoreness} ${checkIn.soreness} · '
              '${l10n.wellbeingShortMood} ${checkIn.mood} · '
              '${l10n.wellbeingShortStress} ${checkIn.stress} · '
              '${l10n.wellbeingShortMotivation} ${checkIn.motivation}',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
