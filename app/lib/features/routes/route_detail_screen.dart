import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/format.dart';
import '../../core/hooks.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../core/user_message_text.dart';
import '../../core/widgets/empty_state.dart';
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

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Key key,
  }) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: key,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return sure == true;
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

    if (s.load.running && s.detail == null) {
      return const Center(child: CircularProgressIndicator());
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
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          s.load.failure == null ? '' : failureText(l10n, s.load.failure!),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Chip(label: Text(routeSurfaceName(l10n, route.surface))),
                  ],
                ),
                Text(
                  [
                    routeLineOf(route.distanceM, route.climbingM),
                    l10n.routeAddedBy(route.ownerName),
                    dateTime(route.createdAt),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (route.description != null && route.description!.isNotEmpty)
                  Text(route.description!),
                if (route.isMine && !route.isShared)
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
                    if (route.isMine)
                      OutlinedButton.icon(
                        key: const Key('edit-route'),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.routeEdit),
                      ),
                    if (route.isMine && route.isShared)
                      OutlinedButton.icon(
                        key: const Key('withdraw-route'),
                        onPressed: s.action.running
                            ? null
                            : () async {
                                if (await _confirm(
                                  context,
                                  title: l10n.routeWithdrawConfirmTitle,
                                  body: l10n.routeWithdrawConfirmBody,
                                  action: l10n.routeWithdraw,
                                  key: const Key('confirm-withdraw-route'),
                                )) {
                                  await notifier.withdraw();
                                }
                              },
                        icon: const Icon(Icons.link_off),
                        label: Text(l10n.routeWithdraw),
                      ),
                    if (route.isMine && !route.isShared)
                      OutlinedButton.icon(
                        key: const Key('share-route'),
                        onPressed: s.action.running ? null : notifier.share,
                        icon: const Icon(Icons.link),
                        label: Text(l10n.routeShare),
                      ),
                    if (route.isMine)
                      TextButton.icon(
                        key: const Key('delete-route'),
                        onPressed: s.action.running
                            ? null
                            : () async {
                                if (await _confirm(
                                  context,
                                  title: l10n.routeDeleteConfirmTitle,
                                  body: l10n.routeDeleteConfirmBody,
                                  action: l10n.routeDelete,
                                  key: const Key('confirm-delete-route'),
                                )) {
                                  if (await notifier.delete() &&
                                      context.mounted) {
                                    onDeleted();
                                  }
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.routeDelete),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                if (!route.isMine)
                  Text(
                    l10n.routeOwnerOnly,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
