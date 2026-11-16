import 'package:material_ui/material_ui.dart';

import '../../../core/failure.dart';
import '../../../core/format.dart';
import '../../../core/l10n.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/inline_error.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../sharing/sharing_state.dart';

String _audienceName(AppLocalizations l10n, String audience) =>
    switch (audience) {
      'coaches' => l10n.audienceCoaches,
      _ => l10n.audienceNone,
    };

String _viewName(AppLocalizations l10n, String what) => switch (what) {
  'rides' => l10n.shareRides,
  'analytics' => l10n.shareAnalytics,
  'routes' => l10n.shareRoutes,
  'wellbeing' => l10n.shareWellbeing,
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
    Widget choice(
      String label,
      String value,
      String key,
      void Function(String value) onChanged, {
      bool enabled = true,
      String? helper,
    }) => InputDecorator(
      decoration: InputDecoration(labelText: label, helperText: helper),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: Key(key),
          value: value,
          isExpanded: true,
          items: [
            for (final audience in ['none', 'coaches'])
              DropdownMenuItem(
                value: audience,
                child: Text(_audienceName(l10n, audience)),
              ),
          ],
          onChanged: state.save.running || !enabled
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
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
            (v) => onChoose(rides: v),
          ),
          choice(
            l10n.shareAnalytics,
            state.analytics,
            'share-analytics',
            (v) => onChoose(analytics: v),
          ),
          choice(
            l10n.shareRoutes,
            state.routes,
            'share-routes',
            (v) => onChoose(routes: v),
            enabled: state.rides != 'none',
            helper: state.rides == 'none' ? l10n.routesNeedRides : null,
          ),
          choice(
            l10n.shareWellbeing,
            state.wellbeing,
            'share-wellbeing',
            (v) => onChoose(wellbeing: v),
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
              subtitle: Text(_viewName(l10n, view.what)),
              trailing: Text(dateTime(view.at)),
            ),
      ],
    );
  }
}
