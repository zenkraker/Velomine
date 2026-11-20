import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/card_grid.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/toolbar_row.dart';
import 'route_widgets.dart';
import 'routes_state.dart';
import 'routes_view_model.dart';

class RoutesScreen extends ConsumerWidget {
  const RoutesScreen({super.key, required this.onOpen, required this.onAdd});

  final void Function(String id) onOpen;
  final VoidCallback onAdd;

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

    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
    final sortAndFilters = [
      DropdownButton<String>(
        key: const Key('routes-sort'),
        value: s.sort,
        items: [
          for (final sort in routeSortIds)
            DropdownMenuItem(
              value: sort,
              child: Text(routeSortName(l10n, sort)),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            ref.read(routesViewModelProvider.notifier).setSort(value);
          }
        },
      ),
      for (final surface in [null, ...routeSurfaceIds])
        ChoiceChip(
          key: Key(
            surface == null ? 'route-surface-all' : 'route-surface-$surface',
          ),
          label: Text(
            surface == null
                ? l10n.routesFilterAll
                : routeSurfaceName(l10n, surface),
          ),
          selected: s.surface == surface,
          onSelected: (_) => ref
              .read(routesViewModelProvider.notifier)
              .setSurface(
                surface != null && s.surface == surface ? null : surface,
              ),
        ),
    ];

    final page = PageScaffold(
      title: l10n.clubRoutesTitle,
      subtitle: l10n.routesSubtitle,
      primaryAction: wide
          ? FilledButton.icon(
              key: const Key('add-route'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.clubAddRoute),
            )
          // The phone header row is tight: a filled icon, its tooltip names it.
          : IconButton.filled(
              key: const Key('add-route'),
              tooltip: l10n.clubAddRoute,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
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
                _RouteCard(route: route, onOpen: onOpen),
            ],
          ),
      ],
    );
    return page;
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.route, required this.onOpen});

  final RouteSummaryResponse route;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final units = ref.watch(unitsChoiceViewModelProvider);
    return AppCard(
      key: Key('route-${route.id}'),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => onOpen(route.id),
        leading: const Icon(Icons.route),
        title: Text(route.name, style: text.titleMedium),
        subtitle: Text(
          [
            routeLineOf(units, route.distanceM, route.climbingM),
            routeSurfaceName(l10n, route.surface),
            l10n.routeAddedBy(route.ownerName),
            if (route.isMine && !route.isShared) l10n.routeNotShared,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
