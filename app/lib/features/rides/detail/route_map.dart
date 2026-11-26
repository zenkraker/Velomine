import 'package:material_ui/material_ui.dart';

import '../../../core/l10n.dart';
import '../../../core/map_defaults.dart';
import '../../../core/widgets/chart_chrome.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'full_route_map.dart';
import 'geo.dart';
import 'lap_range.dart';
import 'ride_series.dart';
import 'route_painter.dart';
import '../../../core/tokens.dart';

/// The route on a map. With a tile address the map has a background of map tiles; without one the route is drawn
/// alone and nothing is requested from any outside server. A marker follows the selected moment.
/// When the ride has heart-rate samples, the route can be coloured by them.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.data,
    required this.selected,
    required this.selectedLap,
    this.tileUrl,
    this.attribution,
    this.elevationGainM,
    this.virtualWorld = false,
    this.title,
    this.date,
    this.facts = const [],
  });

  final RideSeries data;
  final ValueNotifier<int?> selected;
  final ValueNotifier<LapRange?> selectedLap;
  final String? tileUrl;
  final String? attribution;

  /// The ride's climbing, when the caller knows it; the full map reads it out.
  final double? elevationGainM;

  /// A ride in a virtual world such as Zwift: its coordinates are not a place on Earth, so the line is drawn
  /// without map tiles and a caption says why.
  final bool virtualWorld;

  /// The glass card over the bottom of the map: the ride's name, its date and up to three facts. Null
  /// [title] means no card.
  final String? title;
  final String? date;
  final List<({String label, String value})> facts;

  /// The tile address actually used: none for a virtual world.
  String? get _tileUrl => virtualWorld ? null : tileUrl;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  bool _showHeartRate = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final colors = VelomineColors.of(context);
    final heartRate = _heartRateOf(widget.data);
    final showHeartRate = heartRate != null && _showHeartRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heartRate != null)
          CheckboxListTile(
            key: const Key('heart-rate-map-toggle'),
            value: _showHeartRate,
            onChanged: (value) =>
                setState(() => _showHeartRate = value ?? true),
            title: Text(l10n.heartRateOnMap),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        Semantics(
          label: showHeartRate
              ? l10n.mapHeartRateHint(
                  heartRate.min.round(),
                  heartRate.max.round(),
                )
              : l10n.mapOfRoute,
          child: GestureDetector(
            key: const Key('route-map-open'),
            onTap: () => _openFullMap(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = Size(box.maxWidth, box.maxHeight);
                    final view = MapView.fit(widget.data.route, size);
                    return ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Stack(
                        children: [
                          if (widget._tileUrl != null)
                            // The map is dimmed and desaturated so the route is the brightest thing on it.
                            Positioned.fill(
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(
                                  _dimTiles(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    for (final tile in view.tiles(
                                      widget._tileUrl!,
                                    ))
                                      Positioned(
                                        left: tile.left,
                                        top: tile.top,
                                        width: view.tilePixels,
                                        height: view.tilePixels,
                                        child: Image.network(
                                          tile.url,
                                          key: Key('tile-${tile.url}'),
                                          headers: mapTileHeaders,
                                          fit: BoxFit.fill,
                                          webHtmlElementStrategy:
                                              WebHtmlElementStrategy.fallback,
                                          errorBuilder: (_, _, _) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              key: const Key('route-map'),
                              painter: RoutePainter(
                                view: view,
                                data: widget.data,
                                selected: widget.selected,
                                selectedLap: widget.selectedLap,
                                colors: colors,
                                heartRate: heartRate,
                                showHeartRate: showHeartRate,
                              ),
                            ),
                          ),
                          if (widget._tileUrl != null &&
                              widget.attribution != null &&
                              widget.attribution!.isNotEmpty)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: MapAttribution(
                                key: const Key('map-attribution'),
                                text: widget.attribution!,
                              ),
                            ),
                          if (widget.title case final title?)
                            Positioned(
                              left: AppSpacing.lg,
                              right: AppSpacing.lg,
                              bottom: AppSpacing.lg,
                              // The card is part of the map's own tap: it carries no buttons.
                              child: IgnorePointer(
                                child: GlassCard(
                                  key: const Key('map-facts'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                    vertical: AppSpacing.lg,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: AppSpacing.xs,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      if (widget.date case final date?)
                                        Text(
                                          date,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      if (widget.facts.isNotEmpty)
                                        Wrap(
                                          spacing: AppSpacing.lg,
                                          runSpacing: AppSpacing.xs,
                                          children: [
                                            for (final fact in widget.facts)
                                              Text(
                                                '${fact.label} ${fact.value}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (widget.virtualWorld)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.mapVirtualWorld,
              key: const Key('map-virtual-caption'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (showHeartRate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _HeartRateLegend(
              min: heartRate.min.round(),
              max: heartRate.max.round(),
              colors: colors,
            ),
          ),
      ],
    );
  }

  void _openFullMap(BuildContext context) {
    // The root navigator puts the map over the shell's bars too, as Strava does.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullRouteMapScreen(
          data: widget.data,
          selected: widget.selected,
          selectedLap: widget.selectedLap,
          tileUrl: widget._tileUrl,
          attribution: widget.attribution,
          elevationGainM: widget.elevationGainM,
        ),
      ),
    );
  }
}

/// Lowers a map tile's saturation and brightness, so a route drawn over it stays the loudest thing.
/// A dark theme dims harder: its tiles are already dark.
List<double> _dimTiles(bool dark) {
  const saturation = 0.45;
  final brightness = dark ? 0.55 : 0.85;
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final matrix = <double>[
    (1 - saturation) * r + saturation,
    (1 - saturation) * g,
    (1 - saturation) * b,
    0,
    0,
    (1 - saturation) * r,
    (1 - saturation) * g + saturation,
    (1 - saturation) * b,
    0,
    0,
    (1 - saturation) * r,
    (1 - saturation) * g,
    (1 - saturation) * b + saturation,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  // Darken the three colour rows; the alpha row stays exactly as it was.
  return [
    for (var i = 0; i < matrix.length; i++)
      i ~/ 5 < 3 ? matrix[i] * brightness : matrix[i].toDouble(),
  ];
}

Series? _heartRateOf(RideSeries data) {
  for (final series in data.series) {
    if (series.id == 'heartrate') return series;
  }
  return null;
}

class _HeartRateLegend extends StatelessWidget {
  const _HeartRateLegend({
    required this.min,
    required this.max,
    required this.colors,
  });

  final int min;
  final int max;
  final VelomineColors colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(context.l10n.seriesHeartRate, style: text.labelSmall),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            key: const Key('heart-rate-legend'),
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              gradient: LinearGradient(
                colors: [
                  colors.route,
                  colors.series['heartrate'] ?? colors.finish,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(context.l10n.mapHeartRateLegend(min, max), style: text.labelSmall),
      ],
    );
  }
}
