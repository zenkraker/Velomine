import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';

/// The frame around the signed-in screens: title bar with the member's name and sign out,
/// and a bottom bar to switch between rides, bikes and (for admins) accounts.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.location,
    required this.child,
  });

  final Session session;
  final String location;
  final Widget child;

  static const _destinations = ['/rides', '/bikes', '/admin'];

  @override
  Widget build(BuildContext context) {
    final me = session.me;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velomine'),
        actions: [
          if (me != null) Center(child: Text(me.displayName)),
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
        selectedIndex: _destinations
            .indexWhere(location.startsWith)
            .clamp(0, 2),
        onDestinationSelected: (i) => context.go(_destinations[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.directions_bike),
            label: 'Rides',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pedal_bike),
            label: 'Bikes',
          ),
          if (session.isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.people),
              label: 'Accounts',
            ),
        ],
      ),
    );
  }
}
