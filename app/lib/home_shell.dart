import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/back_guard.dart';
import 'core/l10n.dart';
import 'core/providers.dart';
import 'core/theme_choice.dart';
import 'features/notifications/notifications_view_model.dart';
import 'features/recording/recording_providers.dart';

/// The frame around the signed-in screens: title bar with notifications, the member's profile and sign out,
/// and a bottom bar to switch between rides, progress, bikes and (for admins) accounts.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  List<String> _destinations(bool isAdmin) => [
    '/rides',
    if (!kIsWeb) '/record',
    '/progress',
    '/club',
    '/bikes',
    if (isAdmin) '/admin',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionViewModelProvider);
    final me = state.me;
    final recording = ref.watch(recorderSnapshotViewModelProvider).state;
    final unread = ref.watch(
      notificationsViewModelProvider.select((state) => state.unread),
    );
    final destinations = _destinations(state.isAdmin);
    final selected = destinations.indexWhere(location.startsWith);
    return BackGuard(
      location: location,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Velomine'),
          leading: location == '/privacy'
              ? BackButton(
                  onPressed: () {
                    final router = GoRouter.maybeOf(context);
                    if (router?.canPop() ?? false) {
                      router!.pop();
                    } else {
                      context.go('/profile');
                    }
                  },
                )
              : null,
          actions: [
            const ThemeChoiceButton(),
            IconButton(
              key: const Key('open-notifications'),
              tooltip: unread == 0
                  ? context.l10n.notifications
                  : context.l10n.notificationsUnread(unread),
              isSelected: location == '/notifications',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () => context.push('/notifications'),
            ),
            if (me != null)
              TextButton.icon(
                key: const Key('open-profile'),
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(me.displayName),
              ),
            IconButton(
              key: const Key('sign-out'),
              tooltip: context.l10n.signOut,
              icon: const Icon(Icons.logout),
              onPressed: ref.read(sessionProvider).signOut,
            ),
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          // Profile and notifications are reached from the title bar, so no tab is lit for them: the bar needs an
          // index, so it keeps the first one with its highlight hidden.
          selectedIndex: selected < 0 ? 0 : selected,
          indicatorColor: selected < 0 ? Colors.transparent : null,
          onDestinationSelected: (i) => context.go(destinations[i]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.directions_bike),
              label: context.l10n.navRides,
            ),
            if (!kIsWeb)
              NavigationDestination(
                key: const Key('nav-record'),
                icon: switch (recording) {
                  'recording' => Icon(
                    Icons.fiber_smart_record,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  'paused' => const Icon(Icons.pause_circle_outline),
                  _ => const Icon(Icons.fiber_manual_record),
                },
                label: switch (recording) {
                  'recording' => context.l10n.navRecording,
                  'paused' => context.l10n.navRecordingPaused,
                  _ => context.l10n.navRecord,
                },
              ),
            NavigationDestination(
              icon: const Icon(Icons.insights),
              label: context.l10n.navProgress,
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              label: context.l10n.navClub,
            ),
            NavigationDestination(
              icon: const Icon(Icons.pedal_bike),
              label: context.l10n.navBikes,
            ),
            if (state.isAdmin)
              NavigationDestination(
                icon: const Icon(Icons.admin_panel_settings),
                label: context.l10n.navAdmin,
              ),
          ],
        ),
      ),
    );
  }
}
