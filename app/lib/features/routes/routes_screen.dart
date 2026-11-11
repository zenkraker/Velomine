import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-route'),
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(l10n.clubAddRoute),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                            ref
                                .read(routesViewModelProvider.notifier)
                                .setSort(value);
                          }
                        },
                      ),
                      ChoiceChip(
                        key: const Key('route-surface-all'),
                        label: Text(l10n.routesFilterAll),
                        selected: s.surface == null,
                        onSelected: (_) => ref
                            .read(routesViewModelProvider.notifier)
                            .setSurface(null),
                      ),
                      for (final surface in routeSurfaceIds)
                        ChoiceChip(
                          key: Key('route-surface-$surface'),
                          label: Text(routeSurfaceName(l10n, surface)),
                          selected: s.surface == surface,
                          onSelected: (_) => ref
                              .read(routesViewModelProvider.notifier)
                              .setSurface(
                                s.surface == surface ? null : surface,
                              ),
                        ),
                    ],
                  ),
                  if (s.load.failure case final failure?)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            failureText(l10n, failure),
                            key: const Key('routes-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('retry-routes'),
                          onPressed: () => ref
                              .read(routesViewModelProvider.notifier)
                              .refresh(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  if (s.load.running && s.routes.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (s.routes.isEmpty && s.load.failure == null)
                    EmptyState(
                      key: const Key('no-routes'),
                      message: l10n.clubRoutesEmpty,
                      icon: Icons.route,
                    )
                  else
                    for (final route in s.routes)
                      _RouteCard(route: route, onOpen: onOpen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onOpen});

  final RouteSummaryResponse route;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Card(
      key: Key('route-${route.id}'),
      child: ListTile(
        onTap: () => onOpen(route.id),
        leading: const Icon(Icons.route),
        title: Text(route.name, style: text.titleMedium),
        subtitle: Text(
          [
            routeLineOf(route.distanceM, route.climbingM),
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
