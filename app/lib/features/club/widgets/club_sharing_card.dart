import 'package:material_ui/material_ui.dart';

import '../../../core/confirm.dart';
import '../../../core/failure.dart';
import '../../../core/format.dart';
import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../sharing/sharing_state.dart';

String _viewName(AppLocalizations l10n, String what) => switch (what) {
  'rides' => l10n.shareRides,
  'analytics' => l10n.shareAnalytics,
  'routes' => l10n.shareRoutes,
  'wellbeing' => l10n.shareWellbeing,
  'plan' => l10n.coachPlan,
  _ => what,
};

/// What the member shares with the club's coaches, and who has looked at it.
class ClubSharingCard extends StatelessWidget {
  const ClubSharingCard({
    super.key,
    required this.state,
    required this.onChoose,
  });

  final SharingState state;
  final void Function({
    String? rides,
    String? analytics,
    String? routes,
    String? wellbeing,
  })
  onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Sharing with a coach is the rider's decision, so the first time a choice turns on they are told what it
    // gives away; wellbeing is health data and asks for consent. Turning it back off never asks.
    Future<void> askThen(
      String key,
      String from,
      String to,
      String? title,
      String? body,
      void Function(String value) apply,
    ) async {
      if (from == 'none' && to == 'coaches' && title != null && body != null) {
        final agreed = await confirmAction(
          context,
          title: title,
          body: body,
          action: l10n.shareConfirmAction,
          key: Key(key),
        );
        if (!agreed || !context.mounted) return;
      }
      apply(to);
    }

    // One switch per thing shared: on is the club's coaches, off is nobody.
    Widget choice(
      String label,
      String value,
      String key,
      void Function(String value) onChanged, {
      bool enabled = true,
      String? helper,
    }) => SwitchListTile(
      key: Key(key),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: helper == null ? null : Text(helper),
      value: value == 'coaches',
      onChanged: state.save.running || !enabled
          ? null
          : (on) => onChanged(on ? 'coaches' : 'none'),
    );

    return SectionCard(
      title: l10n.sharingTitle,
      description: l10n.sharingHelp,
      children: [
        if (state.load.running && !state.loaded)
          const LoadingState()
        else ...[
          choice(
            l10n.shareRides,
            state.rides,
            'share-rides',
            (v) => askThen(
              'share-rides-confirm',
              state.rides,
              v,
              l10n.shareStatsConfirmTitle,
              l10n.shareStatsConfirmBody,
              // Training comes with the rides: a coach who sees them sees the numbers built from them.
              (value) => onChoose(rides: value, analytics: value),
            ),
            helper: l10n.shareRidesHelper,
          ),
          choice(
            l10n.shareRoutes,
            state.routes,
            'share-routes',
            (v) => onChoose(routes: v),
            enabled: state.rides != 'none',
            // The design's caption; rides off is why the switch is turned off, so that explains it instead.
            helper: state.rides == 'none'
                ? l10n.routesNeedRides
                : l10n.shareRoutesHelper,
          ),
          choice(
            l10n.shareWellbeing,
            state.wellbeing,
            'share-wellbeing',
            (v) => askThen(
              'share-wellbeing-confirm',
              state.wellbeing,
              v,
              l10n.shareWellbeingConfirmTitle,
              l10n.shareWellbeingConfirmBody,
              (value) => onChoose(wellbeing: value),
            ),
            helper: l10n.shareWellbeingHelper,
          ),
        ],
        if (state.load.failure case final failure?)
          InlineError(
            failureText(l10n, failure),
            key: const Key('sharing-error'),
          ),
        const Divider(),
        Text(l10n.viewsTitle, style: Theme.of(context).textTheme.titleSmall),
        if (state.views.isEmpty)
          Text(l10n.viewsEmpty)
        else
          for (final view in state.views)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.visibility_outlined,
                size: AppClub.inlineIcon,
              ),
              title: Text(view.viewerName),
              // What and when on one line under the name: a trailing date pushed the row past
              // half a card's width. Two Texts, so the log still reads what was looked at.
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(_viewName(l10n, view.what))),
                  Text(' · ${dateTime(view.at)}'),
                ],
              ),
            ),
      ],
    );
  }
}
