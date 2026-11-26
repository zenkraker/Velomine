import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/units.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/app_map.dart';
import '../../../core/widgets/chart_chrome.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'route_lines.dart';

/// The ride's route on a map that fills the screen, so the member can pan and
/// zoom into it. Opened by tapping the small map.
class FullRouteMapScreen extends ConsumerWidget {
  const FullRouteMapScreen({
    super.key,
    required this.data,
    required this.selected,
    required this.selectedLap,
    this.tileUrl,
    this.attribution,
    this.elevationGainM,
  });

  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final String? tileUrl;
  final String? attribution;

  /// The ride's climbing, when the screen knows it; the route summary reads it out.
  final double? elevationGainM;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VelomineColors.of(context);
    final l10n = context.l10n;
    final units = ref.watch(unitsChoiceViewModelProvider);
    final distances = data.distance?.whereType<double>() ?? const <double>[];
    final distanceM = distances.isEmpty ? null : distances.last;
    final summary = elevationGainM == null
        ? l10n.routeMapDistanceSummary(km(units, distanceM))
        : l10n.routeMapSummary(
            km(units, distanceM),
            elevation(units, elevationGainM),
          );
    final lines = routeLines(
      data,
      colors,
      heartRate: null,
      showHeartRate: false,
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Semantics(
        container: true,
        label: summary,
        child: ListenableBuilder(
          listenable: Listenable.merge([selected, selectedLap]),
          builder: (context, _) => AppMap(
            key: const Key('full-route-map'),
            tileUrl: tileUrl,
            attribution: attribution,
            attributionInset: MediaQuery.paddingOf(context),
            fit: data.route,
            fitPadding: AppSpacing.xxxl,
            interactive: true,
            lines: [...lines, ...lapLines(data, colors, selectedLap.value)],
            dots: [
              ...routeEnds(data, colors),
              ...selectedDot(data, colors, selected.value),
            ],
            overlay: [
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: MapControl(
                      key: const Key('full-map-close'),
                      icon: Icons.close,
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
