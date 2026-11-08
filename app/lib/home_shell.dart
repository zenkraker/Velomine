import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n.dart';
import 'core/language_choice.dart';
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
    required this.languageChoice,
    required this.location,
    required this.child,
  });

  final Session session;
  final NotificationsController notifications;
  final ThemeChoice themeChoice;
  final LanguageChoice languageChoice;
  final String location;
  final Widget child;

  List<String> get _destinations => [
    '/rides',
    if (!kIsWeb) '/record',
    '/progress',
    '/bikes',
    if (session.isAdmin) '/admin',
  ];

  @override
  Widget build(BuildContext context) {
    final me = session.me;
    final destinations = _destinations;
    final selected = destinations.indexWhere(location.startsWith);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velomine'),
        actions: [
          LanguageChoiceButton(choice: languageChoice),
          ThemeChoiceButton(choice: themeChoice),
          ListenableBuilder(
            listenable: notifications,
            builder: (context, _) => IconButton(
              key: const Key('open-notifications'),
              tooltip: notifications.unread == 0
                  ? context.l10n.notifications
                  : context.l10n.notificationsUnread(notifications.unread),
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
            tooltip: context.l10n.signOut,
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
        onDestinationSelected: (i) => context.go(destinations[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_bike),
            label: context.l10n.navRides,
          ),
          if (!kIsWeb)
            NavigationDestination(
              icon: const Icon(Icons.fiber_manual_record),
              label: context.l10n.navRecord,
            ),
          NavigationDestination(
            icon: const Icon(Icons.insights),
            label: context.l10n.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pedal_bike),
            label: context.l10n.navBikes,
          ),
          if (session.isAdmin)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings),
              label: context.l10n.navAdmin,
            ),
        ],
      ),
    );
  }
}
