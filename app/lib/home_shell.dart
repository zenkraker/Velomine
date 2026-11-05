import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';
import 'core/theme_choice.dart';
import 'features/notifications/notifications_controller.dart';

/// The frame around the signed-in screens: title bar with notifications, the member's profile and sign out,
/// and a bottom bar to switch between rides, progress, bikes and (for admins) accounts.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.notifications,
    required this.themeChoice,
    required this.location,
    required this.child,
  });

  final Session session;
  final NotificationsController notifications;
  final ThemeChoice themeChoice;
  final String location;
  final Widget child;

  static const _destinations = ['/rides', '/progress', '/bikes', '/admin'];

  @override
  Widget build(BuildContext context) {
    final me = session.me;
    final selected = _destinations.indexWhere(location.startsWith);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velomine'),
        actions: [
          ThemeChoiceButton(choice: themeChoice),
          ListenableBuilder(
            listenable: notifications,
            builder: (context, _) => IconButton(
              key: const Key('open-notifications'),
              tooltip: notifications.unread == 0
                  ? 'Notifications'
                  : 'Notifications, ${notifications.unread} unread',
              isSelected: location == '/notifications',
              icon: Badge(
                isLabelVisible: notifications.unread > 0,
                label: Text('${notifications.unread}'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () => context.go('/notifications'),
            ),
          ),
          if (me != null)
            TextButton.icon(
              key: const Key('open-profile'),
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(me.displayName),
            ),
          IconButton(
            key: const Key('sign-out'),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: session.signOut,
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        // Profile and notifications are reached from the title bar, so no tab is lit for them: the bar needs an
        // index, so it keeps the first one with its highlight hidden.
        selectedIndex: selected < 0 ? 0 : selected,
        indicatorColor: selected < 0 ? Colors.transparent : null,
        onDestinationSelected: (i) => context.go(_destinations[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.directions_bike),
            label: 'Rides',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pedal_bike),
            label: 'Bikes',
          ),
          if (session.isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
