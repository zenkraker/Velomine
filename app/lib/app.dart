import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/hooks.dart';
import 'core/language_choice.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/admin/admin_controller.dart';
import 'features/admin/admin_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/bikes/bike_detail_screen.dart';
import 'features/bikes/bikes_controller.dart';
import 'features/bikes/bikes_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sso_callback_screen.dart';
import 'features/club/club_controller.dart';
import 'features/club/club_screen.dart';
import 'features/club/join_club_screen.dart';
import 'features/coach/coach_athlete_screen.dart';
import 'features/coach/coach_athletes_screen.dart';
import 'features/coach/coach_controllers.dart';
import 'features/coach/coach_ride_screen.dart';
import 'features/notifications/notifications_controller.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_controller.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_controller.dart';
import 'features/progress/progress_screen.dart';
import 'features/recording/recording_screen.dart';
import 'features/recording/ride_uploader.dart';
import 'features/rides/detail/ride_detail_controller.dart';
import 'features/rides/detail/ride_detail_screen.dart';
import 'features/rides/rides_controller.dart';
import 'features/rides/rides_screen.dart';
import 'features/sharing/sharing_controller.dart';
import 'home_shell.dart';

Future<XFile?> _pickRideFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Rides', extensions: ['fit', 'gpx', 'tcx', 'gz']),
  ],
);

Future<void> _startWebSso(String server) async {
  // The server redirects to the provider and back, ending on the home page: leave this page for it.
  final login = Uri.parse('$server/api/v1/accounts/sso/login?returnUrl=%2F');
  await launchUrl(login, webOnlyWindowName: '_self');
}

/// Opens the data export in the system browser, which saves the ZIP (on the web, a new tab does).
Future<void> _openLink(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// On a phone the system browser signs in and hands back through the app's own link (see Session.appSsoUrl).
Future<void> _startAppSso(Session session) async {
  await launchUrl(session.appSsoUrl(), mode: LaunchMode.externalApplication);
}

class VelomineApp extends StatefulWidget {
  const VelomineApp({
    super.key,
    required this.session,
    required this.themeChoice,
    required this.languageChoice,
    this.pickFile = _pickRideFile,
    this.startSso,
    this.openLink = _openLink,
    this.onChangeServer,
    this.uploadPollInterval = const Duration(seconds: 1),
    this.notificationPollInterval = const Duration(minutes: 1),
  });

  final Session session;
  final ThemeChoice themeChoice;
  final LanguageChoice languageChoice;
  final FilePicker pickFile;
  final SsoStarter? startSso;
  final LinkOpener openLink;
  final Future<void> Function()? onChangeServer;
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

  late final AdminController _admin = AdminController(
    api: widget.session.admin,
    accounts: widget.session.accounts,
    onUnauthorized: widget.session.sessionExpired,
    myId: () => widget.session.me?.id,
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

  late final ClubController _club = ClubController(
    api: widget.session.clubs,
    onUnauthorized: widget.session.sessionExpired,
  );

  late final SharingController _sharing = SharingController(
    api: widget.session.sharing,
    onUnauthorized: widget.session.sessionExpired,
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
      if (!_club.loaded) _club.refresh();
    } else {
      if (_notifications.running) _notifications.stop();
      if (_club.loaded) _club.reset();
      if (_sharing.loaded) _sharing.reset();
    }
  }

  late final SsoStarter _startSso =
      widget.startSso ??
      (kIsWeb
          ? () => _startWebSso(widget.session.serverUrl)
          : () => _startAppSso(widget.session));

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([widget.session, _club]),
    redirect: (context, state) {
      final session = widget.session;
      final path = state.uri.path;
      const open = {'/sign-in', '/register', '/sso-callback'};
      if (session.status == SessionStatus.loading) return null;
      if (session.status == SessionStatus.signedOut) {
        return open.contains(path) ? null : '/sign-in';
      }
      // An admin has no club of their own until they make one, and still needs the admin pages.
      if (!session.isAdmin && _club.loaded && _club.club == null) {
        return path == '/join' ? null : '/join';
      }
      if (path.startsWith('/club/athletes') && _club.club == null) {
        return '/club';
      }
      if (path == '/join') return '/rides';
      if (open.contains(path) || path == '/') return '/rides';
      if (path == '/record' && kIsWeb) return '/rides';
      if (path == '/admin' && !session.isAdmin) return '/rides';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => SignInScreen(
          session: widget.session,
          startSso: _startSso,
          languageChoice: widget.languageChoice,
          onChangeServer: widget.onChangeServer,
        ),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => JoinClubScreen(
          controller: _club,
          initialCode: state.uri.queryParameters['code'] ?? '',
        ),
      ),
      GoRoute(
        path: '/sso-callback',
        builder: (context, state) => SsoCallbackScreen(
          session: widget.session,
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['sso_error'],
          onFailed: () => context.go('/sign-in'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => RegisterScreen(session: widget.session),
      ),
      ShellRoute(
        builder: (_, state, child) => HomeShell(
          session: widget.session,
          notifications: _notifications,
          themeChoice: widget.themeChoice,
          languageChoice: widget.languageChoice,
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
            path: '/record',
            builder: (_, _) => RecordingScreen(
              uploader: ServerRideUploader(widget.session.rides),
              onUnauthorized: widget.session.sessionExpired,
              serverUrl: widget.session.serverUrl,
            ),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, _) => ProgressScreen(controller: _progress),
          ),
          GoRoute(
            path: '/club',
            builder: (context, _) => ClubScreen(
              controller: _club,
              sharing: _sharing,
              serverUrl: widget.session.serverUrl,
              onJoin: () => context.go('/join'),
              onOpenAthletes: () => context.go('/club/athletes'),
            ),
          ),
          GoRoute(
            path: '/club/athletes',
            builder: (context, _) => _CoachAthletesPage(
              session: widget.session,
              clubId: _club.club!.id,
              onOpen: (id) => context.go('/club/athletes/$id'),
            ),
          ),
          GoRoute(
            path: '/club/athletes/:id',
            builder: (context, state) => _CoachAthletePage(
              key: ValueKey(state.pathParameters['id']),
              session: widget.session,
              clubId: _club.club!.id,
              userId: state.pathParameters['id']!,
              onBack: () => context.go('/club/athletes'),
              onOpenRide: (rideId) => context.go(
                '/club/athletes/${state.pathParameters['id']}/rides/$rideId',
              ),
            ),
          ),
          GoRoute(
            path: '/club/athletes/:id/rides/:rideId',
            builder: (context, state) => _CoachRidePage(
              key: ValueKey(
                '${state.pathParameters['id']}-${state.pathParameters['rideId']}',
              ),
              session: widget.session,
              clubId: _club.club!.id,
              userId: state.pathParameters['id']!,
              rideId: state.pathParameters['rideId']!,
              onBack: () =>
                  context.go('/club/athletes/${state.pathParameters['id']}'),
            ),
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
            builder: (_, _) => _ProfilePage(
              session: widget.session,
              openLink: widget.openLink,
              serverUrl: widget.session.serverUrl,
            ),
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
            builder: (_, _) => AdminScreen(controller: _admin),
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
    _admin.dispose();
    _notifications.dispose();
    _club.dispose();
    _sharing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.session,
        widget.themeChoice,
        widget.languageChoice,
        _club,
      ]),
      builder: (context, _) => MaterialApp.router(
        title: 'Velomine',
        theme: dayTheme(),
        darkTheme: nightTheme(),
        themeMode: widget.themeChoice.mode,
        locale: widget.languageChoice.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: (context, child) {
          // Dates and numbers follow the language the app resolved to, not the machine's.
          Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
          return widget.session.status == SessionStatus.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : child!;
        },
      ),
    );
  }
}

/// Owns the athlete list controller, so it lives exactly as long as the screen does.
class _CoachAthletesPage extends StatefulWidget {
  const _CoachAthletesPage({
    required this.session,
    required this.clubId,
    required this.onOpen,
  });

  final Session session;
  final String clubId;
  final void Function(String userId) onOpen;

  @override
  State<_CoachAthletesPage> createState() => _CoachAthletesPageState();
}

class _CoachAthletesPageState extends State<_CoachAthletesPage> {
  late final CoachAthletesController _controller = CoachAthletesController(
    api: widget.session.coach,
    onUnauthorized: widget.session.sessionExpired,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CoachAthletesScreen(
    controller: _controller,
    clubId: widget.clubId,
    onOpen: widget.onOpen,
  );
}

/// Owns one athlete's controller.
class _CoachAthletePage extends StatefulWidget {
  const _CoachAthletePage({
    super.key,
    required this.session,
    required this.clubId,
    required this.userId,
    required this.onBack,
    required this.onOpenRide,
  });

  final Session session;
  final String clubId;
  final String userId;
  final VoidCallback onBack;
  final void Function(String rideId) onOpenRide;

  @override
  State<_CoachAthletePage> createState() => _CoachAthletePageState();
}

class _CoachAthletePageState extends State<_CoachAthletePage> {
  late final CoachAthleteController _controller = CoachAthleteController(
    api: widget.session.coach,
    onUnauthorized: widget.session.sessionExpired,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CoachAthleteScreen(
    controller: _controller,
    clubId: widget.clubId,
    userId: widget.userId,
    onBack: widget.onBack,
    onOpenRide: widget.onOpenRide,
  );
}

/// Owns one shared ride's controller.
class _CoachRidePage extends StatefulWidget {
  const _CoachRidePage({
    super.key,
    required this.session,
    required this.clubId,
    required this.userId,
    required this.rideId,
    required this.onBack,
  });

  final Session session;
  final String clubId;
  final String userId;
  final String rideId;
  final VoidCallback onBack;

  @override
  State<_CoachRidePage> createState() => _CoachRidePageState();
}

class _CoachRidePageState extends State<_CoachRidePage> {
  late final CoachRideController _controller = CoachRideController(
    api: widget.session.coach,
    onUnauthorized: widget.session.sessionExpired,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.session.serverInfo;
    return CoachRideScreen(
      controller: _controller,
      clubId: widget.clubId,
      userId: widget.userId,
      rideId: widget.rideId,
      onBack: widget.onBack,
      tileUrl: info?.mapTileUrl,
      attribution: info?.mapAttribution,
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
  const _ProfilePage({
    required this.session,
    required this.openLink,
    required this.serverUrl,
  });

  final Session session;
  final LinkOpener openLink;
  final String serverUrl;

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
  Widget build(BuildContext context) => ProfileScreen(
    controller: _controller,
    serverUrl: widget.serverUrl,
    emailAvailable: widget.session.serverInfo?.emailAvailable ?? false,
    openLink: widget.openLink,
    // The account is gone: sign out, which sends the app to the sign-in screen.
    onAccountDeleted: widget.session.signOut,
  );
}
