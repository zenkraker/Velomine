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
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/page_menu.dart';
import '../../core/widgets/page_scaffold.dart';
import '../club/club_view_model.dart';
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
    final isClubOwner =
        ref.watch(clubViewModelProvider).club?.myRole == 'owner';

    listenUserMessages(
      ref,
      context,
      routeDetailViewModelProvider(id).select((s) => s.messages),
      notifier.messageShown,
    );

    // The real header while the route is read, so the page is opaque from its first frame.
    if (s.load.running && s.detail == null) {
      return PageScaffold(
        eyebrow: l10n.routesEyebrow,
        title: l10n.clubRoutesTitle,
        maxWidth: AppLayout.contentNarrow,
        children: const [
          LoadingState.rows(key: Key('route-loading'), count: 4),
        ],
      );
    }
    if (s.notFound) {
      return EmptyState(
        key: const Key('route-missing'),
        message: l10n.failureMissing,
        icon: Icons.route,
      );
    }
    final route = s.detail;
    if (route == null) {
      return ErrorState(
        message: s.load.failure == null
            ? l10n.couldNotLoadRide
            : failureText(l10n, s.load.failure!),
        actionKey: const Key('route-error'),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoint.compactWidth;
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
      // The club's owner moderates the library without editing anybody's words.
      if (!route.isMine && isClubOwner)
        PageMenuEntry(
          key: const Key('remove-route-as-owner'),
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
                  run: () async {
                    if (await notifier.withdraw() && context.mounted) {
                      onDeleted();
                    }
                  },
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
      eyebrow: l10n.routesEyebrow,
      title: route.name,
      titleKey: const Key('route-title'),
      subtitle: routeLineOf(
        ref.watch(unitsChoiceViewModelProvider),
        route.distanceM,
        route.climbingM,
      ),
      maxWidth: AppLayout.contentNarrow,
      primaryAction: route.isMine
          ? (wide
                ? FilledButton.icon(
                    key: const Key('edit-route'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.routeEdit),
                  )
                // The phone header row is tight: a filled icon, its tooltip names it.
                : IconButton.filled(
                    key: const Key('edit-route'),
                    tooltip: l10n.routeEdit,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ))
          : null,
      menu: entries.isEmpty
          ? null
          : PageMenu(buttonKey: const Key('route-actions'), entries: entries),
      children: [
        Chip(label: Text(routeSurfaceName(l10n, route.surface))),
        Text(
          [
            routeLineOf(
              ref.watch(unitsChoiceViewModelProvider),
              route.distanceM,
              route.climbingM,
            ),
            l10n.routeAddedBy(route.ownerName),
            dateTime(route.createdAt),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (route.description != null && route.description!.isNotEmpty)
          Text(route.description!),
        if (route.isMine && !route.isShared)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.routeNotSharedBody,
                key: const Key('route-not-shared'),
              ),
            ),
          ),
        RoutePreview(
          latitude: route.latitude,
          longitude: route.longitude,
          elevation: route.elevation,
          tileUrl: tileUrl,
          attribution: attribution,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              key: const Key('download-route'),
              onPressed: s.action.running
                  ? null
                  : () => _download(context, ref),
              icon: const Icon(Icons.download),
              label: Text(l10n.routeOpenGpx),
            ),
            if (route.isMine && !route.isShared)
              OutlinedButton.icon(
                key: const Key('share-route'),
                onPressed: s.action.running ? null : notifier.share,
                icon: const Icon(Icons.link),
                label: Text(l10n.routeShare),
              ),
          ],
        ),
        if (!route.isMine && !isClubOwner)
          Text(
            l10n.routeOwnerOnly,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
