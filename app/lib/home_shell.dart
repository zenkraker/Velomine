import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/session.dart';

/// The frame around the signed-in screens: title bar with the member's name and sign out,
/// and a bottom bar to switch screens for admins.
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
      bottomNavigationBar: session.isAdmin
          ? NavigationBar(
              selectedIndex: location == '/admin' ? 1 : 0,
              onDestinationSelected: (i) =>
                  context.go(i == 1 ? '/admin' : '/rides'),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.directions_bike),
                  label: 'Rides',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people),
                  label: 'Accounts',
                ),
              ],
            )
          : null,
    );
  }
}
