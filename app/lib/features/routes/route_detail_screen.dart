import 'dart:async';

import '../../core/widgets/loading_state.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/hooks.dart';
import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/units.dart';
import '../../core/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_card.dart';
import 'route_widgets.dart';
import 'routes_view_model.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({
    super.key,
    required this.id,
    required this.onEdit,
    required this.onDeleted,
    required this.serverUrl,
    required this.openLink,
    this.tileUrl,
    this.attribution,
  });

  final String id;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;
  final String serverUrl;
  final LinkOpener openLink;
  final String? tileUrl;
  final String? attribution;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final path = await ref
        .read(routeDetailViewModelProvider(id).notifier)
        .download();
    if (path == null || !context.mounted) return;
    await openLink(Uri.parse('$serverUrl$path'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(routeDetailViewModelProvider(id));
    final notifier = ref.read(routeDetailViewModelProvider(id).notifier);

    listenUserMessages(
      ref,
      context,
      routeDetailViewModelProvider(id).select((s) => s.messages),
      notifier.messageShown,
    );

    // The real header while the route is read, so the page is opaque from its first frame.
    if (s.load.running && s.detail == null) {
      return PageScaffold(
        title: l10n.clubRoutesTitle,
        parent: l10n.clubRoutesCaption,
        maxWidth: AppLayout.contentNarrow,
        children: const [
          LoadingState.rows(key: Key('route-loading'), count: 4),
        ],
      );
    }
    if (s.notFound) {
      return PageScaffold(
        title: l10n.clubRoutesTitle,
        parent: l10n.clubRoutesCaption,
        maxWidth: AppLayout.contentNarrow,
        children: [
          EmptyState(
            key: const Key('route-missing'),
            message: l10n.failureMissing,
            icon: Icons.route,
          ),
        ],
      );
    }
    final route = s.detail;
    if (route == null) {
      return PageScaffold(
        title: l10n.clubRoutesTitle,
        parent: l10n.clubRoutesCaption,
        maxWidth: AppLayout.contentNarrow,
        children: [
          ErrorState(
            message: s.load.failure == null
                ? l10n.couldNotLoadRide
                : failureText(l10n, s.load.failure!),
            actionKey: const Key('route-error'),
            onRetry: notifier.load,
          ),
        ],
      );
    }

    final busy = s.action.running;

    // Destructive entries open a dialog after the menu has closed, never inside its callback.
    void confirmThen({
      required String title,
      required String body,
      required String action,
      required String confirmKey,
      required Future<void> Function() run,
    }) {
      scheduleMicrotask(() async {
        if (!context.mounted) return;
        final ok = await confirmDestructive(
          context,
          title: title,
          body: body,
          action: action,
          key: Key(confirmKey),
        );
        if (ok) await run();
      });
    }

    final entries = [
      if (route.isMine)
        PageMenuEntry(
          key: const Key('edit-route'),
          icon: Icons.edit_outlined,
          label: l10n.routeEdit,
          onSelected: onEdit,
        ),
      if (route.isMine && !route.isShared)
        PageMenuEntry(
          key: const Key('share-route'),
          icon: Icons.link,
          label: l10n.routeShare,
          onSelected: busy ? () {} : notifier.share,
        ),
      // The member who added the route moderates it: nobody else gets an entry here, as the design draws it.
      if (route.isMine && route.isShared)
        PageMenuEntry(
          key: const Key('withdraw-route'),
          icon: Icons.link_off,
          label: l10n.routeWithdraw,
          destructive: true,
          onSelected: busy
              ? () {}
              : () => confirmThen(
                  title: l10n.routeWithdrawConfirmTitle,
                  body: l10n.routeWithdrawConfirmBody,
                  action: l10n.routeWithdraw,
                  confirmKey: 'confirm-withdraw-route',
                  run: notifier.withdraw,
                ),
        ),
      if (route.isMine)
        PageMenuEntry(
          key: const Key('delete-route'),
          icon: Icons.delete_outline,
          label: l10n.routeDelete,
          destructive: true,
          onSelected: busy
              ? () {}
              : () => confirmThen(
                  title: l10n.routeDeleteConfirmTitle,
                  body: l10n.routeDeleteConfirmBody,
                  action: l10n.routeDelete,
                  confirmKey: 'confirm-delete-route',
                  run: () async {
                    if (await notifier.delete() && context.mounted) {
                      onDeleted();
                    }
                  },
                ),
        ),
    ];

    return PageScaffold(
      title: route.name,
      parent: l10n.clubRoutesCaption,
      titleKey: const Key('route-title'),
      subtitle: l10n.routeAddedBy(route.ownerName),
      maxWidth: AppLayout.contentNarrow,
      primaryAction: FilledButton.icon(
        key: const Key('download-route'),
        onPressed: busy ? null : () => _download(context, ref),
        icon: const Icon(Icons.download),
        label: Text(l10n.routeOpenGpx),
      ),
      menu: entries.isEmpty
          ? null
          : PageMenu(buttonKey: const Key('route-actions'), entries: entries),
      children: [
        RoutePreview(
          latitude: route.latitude,
          longitude: route.longitude,
          elevation: route.elevation,
          tileUrl: tileUrl,
          attribution: attribution,
        ),
        SectionCard(
          title: l10n.routeTheRoute,
          children: [
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.md,
              children: [
                StatFigure(
                  label: l10n.statDistance,
                  value: km(
                    ref.watch(unitsChoiceViewModelProvider),
                    route.distanceM,
                  ),
                ),
                StatFigure(
                  label: l10n.statClimbing,
                  value: elevation(
                    ref.watch(unitsChoiceViewModelProvider),
                    route.climbingM,
                  ),
                ),
                StatFigure(
                  label: l10n.addRouteSurface,
                  value: routeSurfaceName(l10n, route.surface),
                ),
              ],
            ),
          ],
        ),
        if (route.description != null && route.description!.isNotEmpty)
          SectionCard(
            title: l10n.routeDescription,
            children: [
              Text(
                route.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        if (route.isMine && !route.isShared)
          AppCard(
            child: Text(
              l10n.routeNotSharedBody,
              key: const Key('route-not-shared'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (!route.isMine)
          Text(
            l10n.routeOwnerOnly,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
