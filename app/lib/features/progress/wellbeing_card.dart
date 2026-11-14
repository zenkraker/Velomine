import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/widgets/section_card.dart';

/// The daily check-in: consent first, then either today's scores or a short form.
class WellbeingCard extends StatefulWidget {
  const WellbeingCard({
    super.key,
    required this.wellbeing,
    required this.checkIns,
    required this.onConsent,
    required this.onWithdraw,
    required this.onSave,
    required this.saving,
  });

  final WellbeingResponse? wellbeing;
  final CheckInsResponse? checkIns;
  final Future<bool> Function() onConsent;
  final Future<bool> Function() onWithdraw;
  final Future<bool> Function(
    int fatigue,
    int soreness,
    int mood,
    int stress,
    int motivation,
  )
  onSave;
  final bool saving;

  @override
  State<WellbeingCard> createState() => _WellbeingCardState();
}

class _WellbeingCardState extends State<WellbeingCard> {
  late List<int> _values = _initialValues();
  bool _editing = false;

  List<int> _initialValues() {
    final today = widget.wellbeing?.today;
    return today == null
        ? [3, 3, 3, 3, 3]
        : [
            today.fatigue,
            today.soreness,
            today.mood,
            today.stress,
            today.motivation,
          ];
  }

  @override
  void didUpdateWidget(WellbeingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.wellbeing?.today != widget.wellbeing?.today) {
      setState(() => _values = _initialValues());
    }
  }

  Future<void> _save() async {
    final ok = await widget.onSave(
      _values[0],
      _values[1],
      _values[2],
      _values[3],
      _values[4],
    );
    if (ok && mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final wellbeing = widget.wellbeing;

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
              onPressed: widget.saving ? null : widget.onConsent,
              child: Text(l10n.wellbeingConsentAction),
            ),
          ),
        ],
      );
    }

    final today = wellbeing.today;

    return SectionCard(
      key: const Key('wellbeing-card'),
      title: l10n.wellbeing,
      children: [
        if (today != null && !_editing)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.wellbeingSaved, style: text.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
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
                onPressed: () => setState(() => _editing = true),
                child: Text(l10n.wellbeingEdit),
              ),
            ],
          )
        else ...[
          Text(l10n.wellbeingToday, style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _ScoreRow(
            label: l10n.wellbeingFatigue,
            keyName: 'fatigue',
            value: _values[0],
            onChanged: (v) => setState(() => _values[0] = v),
          ),
          _ScoreRow(
            label: l10n.wellbeingSoreness,
            keyName: 'soreness',
            value: _values[1],
            onChanged: (v) => setState(() => _values[1] = v),
          ),
          _ScoreRow(
            label: l10n.wellbeingMood,
            keyName: 'mood',
            value: _values[2],
            onChanged: (v) => setState(() => _values[2] = v),
          ),
          _ScoreRow(
            label: l10n.wellbeingStress,
            keyName: 'stress',
            value: _values[3],
            onChanged: (v) => setState(() => _values[3] = v),
          ),
          _ScoreRow(
            label: l10n.wellbeingMotivation,
            keyName: 'motivation',
            value: _values[4],
            onChanged: (v) => setState(() => _values[4] = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilledButton(
                key: const Key('wellbeing-save'),
                onPressed: widget.saving ? null : _save,
                child: Text(l10n.wellbeingSave),
              ),
              if (today != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _values = _initialValues();
                  }),
                  child: Text(l10n.cancel),
                ),
              ],
            ],
          ),
        ],
        // Withdrawing consent is not a second save: it sits apart, below a line, as a quiet text action.
        const Divider(height: AppSpacing.xxl),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('wellbeing-withdraw'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: widget.saving ? null : widget.onWithdraw,
            child: Text(l10n.wellbeingWithdrawConsent),
          ),
        ),
        if (widget.checkIns case final checkIns?
            when checkIns.checkIns.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(l10n.wellbeingHistory, style: text.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          for (final checkIn in checkIns.checkIns.reversed.take(7))
            _HistoryRow(checkIn: checkIn),
        ],
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: SegmentedButton<int>(
            key: Key('wellbeing-$keyName'),
            showSelectedIcon: false,
            segments: [
              for (var i = 1; i <= 5; i++)
                ButtonSegment(value: i, label: Text('$i')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.single),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 54,
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
