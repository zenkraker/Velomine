import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/toolbar_row.dart';
import 'route_widgets.dart';
import 'routes_state.dart';
import 'routes_view_model.dart';

class RoutesScreen extends ConsumerWidget {
  const RoutesScreen({
    super.key,
    required this.onOpen,
    required this.onAdd,
    this.tileUrl,
    this.attribution,
  });

  final void Function(String id) onOpen;
  final VoidCallback onAdd;

  /// The map's tile address from the server, and the line that credits it.
  final String? tileUrl;
  final String? attribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(routesViewModelProvider);

    listenUserMessages(
      ref,
      context,
      routesViewModelProvider.select((s) => s.messages),
      ref.read(routesViewModelProvider.notifier).messageShown,
    );

    // The surface and the order are each one choice, so each is the app's segmented control.
    final sortAndFilters = [
      SegmentedControl<String?>(
        buttonKey: const Key('route-surface'),
        segments: [
          ButtonSegment(value: null, label: Text(l10n.routesFilterAll)),
          for (final surface in routeSurfaceIds)
            ButtonSegment(
              value: surface,
              label: Text(routeSurfaceName(l10n, surface)),
            ),
        ],
        selected: s.surface,
        onChanged: (surface) =>
            ref.read(routesViewModelProvider.notifier).setSurface(surface),
      ),
      SegmentedControl<String>(
        buttonKey: const Key('routes-sort'),
        segments: [
          for (final sort in routeSortIds)
            ButtonSegment(value: sort, label: Text(routeSortName(l10n, sort))),
        ],
        selected: s.sort,
        onChanged: (sort) =>
            ref.read(routesViewModelProvider.notifier).setSort(sort),
      ),
    ];

    final page = PageScaffold(
      title: l10n.clubRoutesTitle,
      parent: l10n.clubRoutesCaption,
      subtitle: l10n.routesSubtitle,
      primaryAction: FilledButton.icon(
        key: const Key('add-route'),
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(l10n.clubAddRoute),
      ),
      children: [
        ToolbarRow(children: sortAndFilters),
        if (s.load.failure case final failure?)
          ErrorState(
            message: failureText(l10n, failure),
            actionKey: const Key('retry-routes'),
            onRetry: () => ref.read(routesViewModelProvider.notifier).refresh(),
          ),
        if (s.load.running && s.routes.isEmpty)
          const LoadingState()
        else if (s.routes.isEmpty && s.load.failure == null)
          EmptyState(
            key: const Key('no-routes'),
            message: l10n.clubRoutesEmpty,
            icon: Icons.route,
            action: OutlinedButton.icon(
              key: const Key('add-route-empty'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.routesEmptyCta),
            ),
          )
        else
          CardGrid(
            children: [
              for (final route in s.routes)
                _RouteCard(
                  route: route,
                  onOpen: onOpen,
                  tileUrl: tileUrl,
                  attribution: attribution,
                ),
            ],
          ),
      ],
    );
    return page;
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({
    required this.route,
    required this.onOpen,
    this.tileUrl,
    this.attribution,
  });

  final RouteSummaryResponse route;
  final void Function(String id) onOpen;
  final String? tileUrl;
  final String? attribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final units = ref.watch(unitsChoiceViewModelProvider);
    return AppCard(
      key: Key('route-${route.id}'),
      onTap: () => onOpen(route.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          // The name leads, as the mock-up draws the card; the line under it tells one route from another.
          Text(route.name, style: text.titleMedium),
          if (route.latitude.length > 1)
            // The card's own tap opens the route: the line in it does not pan or zoom.
            IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: RoutePreview(
                  key: Key('route-line-${route.id}'),
                  latitude: route.latitude,
                  longitude: route.longitude,
                  showElevation: false,
                  tileUrl: tileUrl,
                  attribution: attribution,
                ),
              ),
            ),
          AppBadge(routeSurfaceName(l10n, route.surface)),
          Text(
            [
              routeLineOf(units, route.distanceM, route.climbingM),
              l10n.routeAddedBy(route.ownerName),
            ].join(' · '),
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
