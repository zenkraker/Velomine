import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/hooks.dart';
import 'core/server_url.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/admin/pending_users_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/bikes/bike_detail_screen.dart';
import 'features/bikes/bikes_controller.dart';
import 'features/bikes/bikes_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/notifications/notifications_controller.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_controller.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_controller.dart';
import 'features/progress/progress_screen.dart';
import 'features/rides/detail/ride_detail_controller.dart';
import 'features/rides/detail/ride_detail_screen.dart';
import 'features/rides/rides_controller.dart';
import 'features/rides/rides_screen.dart';
import 'home_shell.dart';

Future<XFile?> _pickRideFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Rides', extensions: ['fit', 'gpx', 'tcx', 'gz']),
  ],
);

Future<void> _startSso() async {
  // The server redirects to the provider and back, ending on the home page: leave this page for it.
  final login = Uri.parse(
    '${serverUrl()}/api/v1/accounts/sso/login?returnUrl=%2F',
  );
  await launchUrl(login, webOnlyWindowName: '_self');
}

class VelomineApp extends StatefulWidget {
  const VelomineApp({
    super.key,
    required this.session,
    this.pickFile = _pickRideFile,
    this.startSso = _startSso,
    this.uploadPollInterval = const Duration(seconds: 1),
    this.notificationPollInterval = const Duration(minutes: 1),
  });

  final Session session;
  final FilePicker pickFile;
  final SsoStarter startSso;
  final Duration uploadPollInterval;
  final Duration notificationPollInterval;

  @override
  State<VelomineApp> createState() => _VelomineAppState();
}

class _VelomineAppState extends State<VelomineApp> {
  late final RidesController _rides = RidesController(
    api: widget.session.rides,
    pickFile: widget.pickFile,
    onUnauthorized: widget.session.sessionExpired,
    pollInterval: widget.uploadPollInterval,
  );

  late final BikesController _bikes = BikesController(
    api: widget.session.bikes,
    onUnauthorized: widget.session.sessionExpired,
  );

  late final ProgressController _progress = ProgressController(
    api: widget.session.analytics,
    onUnauthorized: widget.session.sessionExpired,
  );

  late final NotificationsController _notifications = NotificationsController(
    api: widget.session.notifications,
    onUnauthorized: widget.session.sessionExpired,
    pollInterval: widget.notificationPollInterval,
  );

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_followSession);
    _followSession();
  }

  /// Notifications are checked while someone is signed in, and forgotten when they sign out.
  void _followSession() {
    if (widget.session.status == SessionStatus.signedIn) {
      _notifications.start();
    } else if (_notifications.running) {
      _notifications.stop();
    }
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: widget.session,
    redirect: (context, state) {
      final session = widget.session;
      final path = state.uri.path;
      const open = {'/sign-in', '/register'};
      if (session.status == SessionStatus.loading) return null;
      if (session.status == SessionStatus.signedOut) {
        return open.contains(path) ? null : '/sign-in';
      }
      if (open.contains(path) || path == '/') return '/rides';
      if (path == '/admin' && !session.isAdmin) return '/rides';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) =>
            SignInScreen(session: widget.session, startSso: widget.startSso),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => RegisterScreen(session: widget.session),
      ),
      ShellRoute(
        builder: (_, state, child) => HomeShell(
          session: widget.session,
          notifications: _notifications,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/rides',
            builder: (context, _) => RidesScreen(
              controller: _rides,
              onOpen: (id) => context.go('/rides/$id'),
            ),
          ),
          GoRoute(
            path: '/rides/:id',
            builder: (context, state) => _RideDetailPage(
              key: ValueKey(state.pathParameters['id']),
              session: widget.session,
              id: state.pathParameters['id']!,
              onBack: () => context.go('/rides'),
              onDeleted: () {
                _rides.refresh();
                context.go('/rides');
              },
              pollInterval: widget.uploadPollInterval,
            ),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, _) => ProgressScreen(controller: _progress),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, _) => NotificationsScreen(
              controller: _notifications,
              onOpen: (location) => context.go(location),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => _ProfilePage(session: widget.session),
          ),
          GoRoute(
            path: '/bikes',
            builder: (context, _) => BikesScreen(
              controller: _bikes,
              onOpen: (id) => context.go('/bikes/$id'),
            ),
          ),
          GoRoute(
            path: '/bikes/:id',
            builder: (context, state) => _BikeDetailPage(
              key: ValueKey(state.pathParameters['id']),
              session: widget.session,
              id: state.pathParameters['id']!,
              onBack: () => context.go('/bikes'),
              onDeleted: () {
                _bikes.refresh();
                context.go('/bikes');
              },
            ),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, _) => PendingUsersScreen(session: widget.session),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    widget.session.removeListener(_followSession);
    _router.dispose();
    _rides.dispose();
    _bikes.dispose();
    _progress.dispose();
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) => MaterialApp.router(
        title: 'Velomine',
        theme: dayTheme(),
        routerConfig: _router,
        builder: (context, child) =>
            widget.session.status == SessionStatus.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : child!,
      ),
    );
  }
}

/// Owns the controller of one ride's detail screen, so it lives exactly as long as the screen does.
class _RideDetailPage extends StatefulWidget {
  const _RideDetailPage({
    super.key,
    required this.session,
    required this.id,
    required this.onBack,
    required this.onDeleted,
    required this.pollInterval,
  });

  final Session session;
  final String id;
  final VoidCallback onBack;
  final VoidCallback onDeleted;
  final Duration pollInterval;

  @override
  State<_RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<_RideDetailPage> {
  late final RideDetailController _controller = RideDetailController(
    api: widget.session.rides,
    bikesApi: widget.session.bikes,
    id: widget.id,
    onUnauthorized: widget.session.sessionExpired,
    pollInterval: widget.pollInterval,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.session.serverInfo;
    return RideDetailScreen(
      controller: _controller,
      onBack: widget.onBack,
      onDeleted: widget.onDeleted,
      tileUrl: info?.mapTileUrl,
      attribution: info?.mapAttribution,
    );
  }
}

/// Owns the controller of one bike's screen, so it lives exactly as long as the screen does.
class _BikeDetailPage extends StatefulWidget {
  const _BikeDetailPage({
    super.key,
    required this.session,
    required this.id,
    required this.onBack,
    required this.onDeleted,
  });

  final Session session;
  final String id;
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  @override
  State<_BikeDetailPage> createState() => _BikeDetailPageState();
}

class _BikeDetailPageState extends State<_BikeDetailPage> {
  late final BikeDetailController _controller = BikeDetailController(
    api: widget.session.bikes,
    id: widget.id,
    onUnauthorized: widget.session.sessionExpired,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BikeDetailScreen(
    controller: _controller,
    onBack: widget.onBack,
    onDeleted: widget.onDeleted,
  );
}

/// Owns the profile controller, so the form is read fresh each time the screen opens.
class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.session});

  final Session session;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  late final ProfileController _controller = ProfileController(
    api: widget.session.accounts,
    onUnauthorized: widget.session.sessionExpired,
    onSaved: widget.session.refreshMe,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileScreen(controller: _controller);
}
