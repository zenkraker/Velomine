import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/home_location.dart';
import 'core/hooks.dart';
import 'core/language_choice.dart';
import 'core/location_service.dart';
import 'core/session.dart';
import 'core/solo_hint.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/admin/admin_controller.dart';
import 'features/admin/admin_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/bikes/bike_detail_screen.dart';
import 'features/bikes/bikes_controller.dart';
import 'features/bikes/bikes_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sso_callback_screen.dart';
import 'features/club/club_controller.dart';
import 'features/club/club_screen.dart';
import 'features/club/join_club_screen.dart';
import 'features/club/join_requests_controller.dart';
import 'features/club/nearby_clubs_controller.dart';
import 'features/club/nearby_clubs_screen.dart';
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
  // The server redirects to the provider and back, ending on the rides page: leave this page for it.
  // It cannot end on "/" because that is the presentation site, not the app.
  final login = Uri.parse(
    '$server/api/v1/accounts/sso/login?returnUrl=%2Frides',
  );
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
    this.locationService,
    this.homeLocation,
    this.soloHint,
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

  /// Tests pass a fixed position; the app uses the device by default.
  final LocationService? locationService;

  /// The saved fallback point and the "nearby clubs" card's dismissal, both kept on this device.
  final HomeLocation? homeLocation;
  final SoloHint? soloHint;

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
    accounts: widget.session.accounts,
    wellbeing: widget.session.wellbeing,
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

  late final NearbyClubsController _nearby = NearbyClubsController(
    api: widget.session.clubs,
    onUnauthorized: widget.session.sessionExpired,
  );

  late final JoinRequestsController _joinRequests = JoinRequestsController(
    api: widget.session.clubs,
    onUnauthorized: widget.session.sessionExpired,
  );

  late final LocationService _locationService =
      widget.locationService ?? const DeviceLocationService();

  late final HomeLocation _homeLocation = widget.homeLocation ?? HomeLocation();

  late final SoloHint _soloHint = widget.soloHint ?? SoloHint();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_followSession);
    _followSession();
    _soloHint.load();
  }

  /// Notifications are checked while someone is signed in, and forgotten when they sign out.
  void _followSession() {
    if (widget.session.status == SessionStatus.signedIn) {
      _notifications.start();
      if (!_club.loaded) _club.refresh();
      final id = widget.session.me?.id;
      if (id != null) _homeLocation.load(id);
    } else {
      if (_notifications.running) _notifications.stop();
      if (_club.loaded) _club.reset();
      if (_sharing.loaded) _sharing.reset();
      _nearby.reset();
      _joinRequests.reset();
      if (widget.session.status == SessionStatus.signedOut) {
        _homeLocation.forget();
      }
    }
  }

  late final SsoStarter _startSso =
      widget.startSso ??
      (kIsWeb
          ? () => _startWebSso(widget.session.serverUrl)
          : () => _startAppSso(widget.session));

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([widget.session, _club, _soloHint]),
    redirect: (context, state) {
      final session = widget.session;
      final path = state.uri.path;
      const open = {
        '/sign-in',
        '/register',
        '/sso-callback',
        '/forgot-password',
        '/reset-password',
      };
      if (session.status == SessionStatus.loading) return null;
      if (session.status == SessionStatus.signedOut) {
        if (path == '/join') {
          final code = state.uri.queryParameters['code'];
          if (code != null && code.isNotEmpty) session.pendingJoinCode = code;
        }
        return open.contains(path) ? null : '/sign-in';
      }
      // Riding without a club is fine: only an invite link kept from a signed-out visit sends someone to the join page.
      if (session.pendingJoinCode != null && _club.club != null) {
        session.pendingJoinCode = null;
      }
      if (session.pendingJoinCode != null &&
          _club.loaded &&
          _club.club == null) {
        return path == '/join' ? null : '/join';
      }
      if (path.startsWith('/club/athletes') && _club.club == null) {
        return '/club';
      }
      if (path == '/clubs' && _club.loaded && _club.club != null) {
        return '/club';
      }
      if (path == '/join' && _club.club != null) {
        session.pendingJoinCode = null;
        return '/rides';
      }
      // A reset link works even when the browser still has a session: the stamp changes and signs it out.
      if (path == '/reset-password') return null;
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
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return JoinClubScreen(
            controller: _club,
            initialCode: code != null && code.isNotEmpty
                ? code
                : (widget.session.pendingJoinCode ?? ''),
            onJoined: () => widget.session.pendingJoinCode = null,
            onSkip: () {
              widget.session.pendingJoinCode = null;
              context.go('/rides');
            },
          );
        },
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
      GoRoute(
        path: '/clubs',
        builder: (_, _) => NearbyClubsScreen(
          controller: _nearby,
          locationService: _locationService,
          homeLocation: _homeLocation,
          userId: widget.session.me?.id ?? '',
          onBack: () => context.go('/club'),
          tileUrl: widget.session.serverInfo?.mapTileUrl,
          attribution: widget.session.serverInfo?.mapAttribution,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => ForgotPasswordScreen(session: widget.session),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final fragment = state.uri.fragment.isNotEmpty
              ? state.uri.fragment
              : Uri.base.fragment;
          final params = fragment.isNotEmpty
              ? Uri.splitQueryString(fragment)
              : state.uri.queryParameters;
          return ResetPasswordScreen(
            session: widget.session,
            token: params['token'],
            email: params['email'],
          );
        },
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
            builder: (context, _) => ListenableBuilder(
              listenable: Listenable.merge([_club, _soloHint]),
              builder: (context, _) => RidesScreen(
                controller: _rides,
                onOpen: (id) => context.go('/rides/$id'),
                showSoloCard:
                    _club.loaded && _club.club == null && !_soloHint.dismissed,
                onOpenClubs: () => context.go('/clubs'),
                onDismissSoloCard: _soloHint.dismiss,
              ),
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
              requests: _joinRequests,
              nearby: _nearby,
              serverUrl: widget.session.serverUrl,
              onJoin: () => context.go('/join'),
              onOpenClubs: () => context.go('/clubs'),
              onOpenAthletes: () => context.go('/club/athletes'),
              locationService: _locationService,
              tileUrl: widget.session.serverInfo?.mapTileUrl,
              attribution: widget.session.serverInfo?.mapAttribution,
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
    _nearby.dispose();
    _joinRequests.dispose();
    _homeLocation.dispose();
    _soloHint.dispose();
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
        _soloHint,
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
    // The password changed and every session ended; the same sign-out is the right move.
    onPasswordChanged: widget.session.signOut,
  );
}
