import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/hooks.dart';
import 'core/language_choice.dart';
import 'core/map_defaults.dart';
import 'core/providers.dart';
import 'core/server_config.dart';
import 'core/session.dart';
import 'core/solo_hint.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/admin/admin_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/bikes/bike_detail_screen.dart';
import 'features/bikes/bikes_screen.dart';
import 'features/bikes/bikes_view_models.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sso_callback_screen.dart';
import 'features/club/club_view_model.dart';
import 'features/club/club_screen.dart';
import 'features/club/join_club_screen.dart';
import 'features/club/nearby_clubs_screen.dart';
import 'features/coach/coach_athlete_screen.dart';
import 'features/coach/coach_athletes_screen.dart';
import 'features/coach/coach_ride_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/recording/recording_screen.dart';
import 'features/rides/detail/ride_detail_screen.dart';
import 'features/rides/rides_view_model.dart';
import 'features/rides/rides_screen.dart';
import 'home_shell.dart';

/// Opens the data export in the system browser, which saves the ZIP (on the web, a new tab does).
Future<void> _openLink(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens single sign-on in the phone's or the computer's browser. Tests override it.
final ssoStarterProvider = Provider<SsoStarter>((ref) {
  if (kIsWeb) {
    return () async {
      // The server redirects to the provider and back, ending on the rides page: leave this page for it.
      // It cannot end on "/" because that is the presentation site, not the app.
      final server = ref.read(sessionProvider).serverUrl;
      final login = Uri.parse(
        '$server/api/v1/accounts/sso/login?returnUrl=%2Frides',
      );
      await launchUrl(login, webOnlyWindowName: '_self');
    };
  }
  return () async {
    // The system browser signs in and hands back through the app's own link.
    await launchUrl(
      ref.read(sessionProvider).appSsoUrl(),
      mode: LaunchMode.externalApplication,
    );
  };
});

/// Opens the data export in the system browser. Tests override it.
final linkOpenerProvider = Provider<LinkOpener>((ref) => _openLink);

/// Signs out and forgets the server address, so the setup screen returns. Null
/// on the web, which is served by its own server.
final changeServerProvider = Provider<Future<void> Function()?>((ref) {
  if (kIsWeb) return null;
  return () async {
    await ref.read(sessionProvider).signOut();
    await ref.read(serverConfigViewModelProvider.notifier).clear();
  };
});

class VelomineApp extends ConsumerStatefulWidget {
  const VelomineApp({super.key});

  @override
  ConsumerState<VelomineApp> createState() => _VelomineAppState();
}

class _VelomineAppState extends ConsumerState<VelomineApp> {
  bool _languageSynced = false;

  @override
  void initState() {
    super.initState();
    // Not inside initState: it may set the language provider.
    Future.microtask(_followSession);
    _router = _createRouter();
  }

  /// Applies the account's language on sign-in. With no account choice the app follows the device.
  void _applyAccountLanguage() {
    if (_languageSynced) return;
    final me = ref.read(sessionProvider).me;
    if (me == null) return;
    _languageSynced = true;
    if (me.language != null) {
      ref.read(languageChoiceViewModelProvider.notifier).adopt(me.language);
    }
  }

  /// The account's language follows the session; member data is scoped by the
  /// ViewModels that watch the signed-in identity.
  void _followSession() {
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.signedIn) {
      _applyAccountLanguage();
    } else if (session.status == SessionStatus.signedOut) {
      ref.read(languageChoiceViewModelProvider.notifier).forget();
      _languageSynced = false;
    }
  }

  late final GoRouter _router;

  GoRouter _createRouter() => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final club = ref.read(clubViewModelProvider);
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
      if (session.pendingJoinCode != null && club.club != null) {
        session.pendingJoinCode = null;
      }
      if (session.pendingJoinCode != null && club.loaded && club.club == null) {
        return path == '/join' ? null : '/join';
      }
      if (path.startsWith('/club/athletes') && club.club == null) {
        return '/club';
      }
      if (path == '/clubs' && club.loaded && club.club != null) {
        return '/club';
      }
      if (path == '/join' && club.club != null) {
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
          startSso: ref.read(ssoStarterProvider),
          onChangeServer: ref.read(changeServerProvider),
        ),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) {
          final session = ref.read(sessionProvider);
          final code = state.uri.queryParameters['code'];
          return JoinClubScreen(
            initialCode: code != null && code.isNotEmpty
                ? code
                : (session.pendingJoinCode ?? ''),
            onJoined: () => session.pendingJoinCode = null,
            onSkip: () {
              session.pendingJoinCode = null;
              context.go('/rides');
            },
          );
        },
      ),
      GoRoute(
        path: '/sso-callback',
        builder: (context, state) => SsoCallbackScreen(
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['sso_error'],
          onFailed: () => context.go('/sign-in'),
        ),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/clubs',
        builder: (context, _) => NearbyClubsScreen(
          onBack: () => context.go('/club'),
          tileUrl:
              ref.read(sessionProvider).serverInfo?.mapTileUrl ??
              defaultMapTileUrl,
          attribution:
              ref.read(sessionProvider).serverInfo?.mapAttribution ??
              defaultMapAttribution,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
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
            token: params['token'],
            email: params['email'],
          );
        },
      ),
      ShellRoute(
        builder: (_, state, child) =>
            HomeShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/rides',
            builder: (context, _) => Consumer(
              builder: (context, ref, _) {
                final club = ref.watch(clubViewModelProvider);
                final dismissed = ref.watch(soloHintViewModelProvider);
                return RidesScreen(
                  onOpen: (id) => context.go('/rides/$id'),
                  showSoloCard: club.loaded && club.club == null && !dismissed,
                  onOpenClubs: () => context.go('/clubs'),
                  onDismissSoloCard: ref
                      .read(soloHintViewModelProvider.notifier)
                      .dismiss,
                );
              },
            ),
          ),
          GoRoute(
            path: '/rides/:id',
            builder: (context, state) => RideDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onBack: () => context.go('/rides'),
              onDeleted: () {
                ref.read(ridesViewModelProvider.notifier).refresh();
                context.go('/rides');
              },
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(path: '/record', builder: (_, _) => const RecordingScreen()),
          GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
          GoRoute(
            path: '/club',
            builder: (context, _) => ClubScreen(
              serverUrl: ref.read(sessionProvider).serverUrl,
              onJoin: () => context.go('/join'),
              onOpenClubs: () => context.go('/clubs'),
              onOpenAthletes: () => context.go('/club/athletes'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/athletes',
            builder: (context, _) => CoachAthletesScreen(
              clubId: ref.read(clubViewModelProvider).club!.id,
              onOpen: (id) => context.go('/club/athletes/$id'),
            ),
          ),
          GoRoute(
            path: '/club/athletes/:id',
            builder: (context, state) => CoachAthleteScreen(
              key: ValueKey(state.pathParameters['id']),
              clubId: ref.read(clubViewModelProvider).club!.id,
              userId: state.pathParameters['id']!,
              onBack: () => context.go('/club/athletes'),
              onOpenRide: (rideId) => context.go(
                '/club/athletes/${state.pathParameters['id']}/rides/$rideId',
              ),
            ),
          ),
          GoRoute(
            path: '/club/athletes/:id/rides/:rideId',
            builder: (context, state) => CoachRideScreen(
              key: ValueKey(
                '${state.pathParameters['id']}-${state.pathParameters['rideId']}',
              ),
              clubId: ref.read(clubViewModelProvider).club!.id,
              userId: state.pathParameters['id']!,
              rideId: state.pathParameters['rideId']!,
              onBack: () =>
                  context.go('/club/athletes/${state.pathParameters['id']}'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, _) =>
                NotificationsScreen(onOpen: (location) => context.go(location)),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => ProfileScreen(
              serverUrl: ref.read(sessionProvider).serverUrl,
              emailAvailable:
                  ref.read(sessionProvider).serverInfo?.emailAvailable ?? false,
              openLink: ref.read(linkOpenerProvider),
              onAccountDeleted: ref.read(sessionProvider).signOut,
              onPasswordChanged: ref.read(sessionProvider).signOut,
            ),
          ),
          GoRoute(
            path: '/bikes',
            builder: (context, _) =>
                BikesScreen(onOpen: (id) => context.go('/bikes/$id')),
          ),
          GoRoute(
            path: '/bikes/:id',
            builder: (context, state) => BikeDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onBack: () => context.go('/bikes'),
              onDeleted: () {
                ref.read(bikesViewModelProvider.notifier).refresh();
                context.go('/bikes');
              },
            ),
          ),
          GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionViewModelProvider);
    final theme =
        ref.watch(themeChoiceViewModelProvider).value ?? ThemeMode.system;
    final language = ref.watch(languageChoiceViewModelProvider);
    ref.listen(sessionViewModelProvider, (_, _) {
      _router.refresh();
      _followSession();
    });
    ref.listen(clubViewModelProvider, (_, _) => _router.refresh());
    return MaterialApp.router(
      title: 'Velomine',
      theme: dayTheme(),
      darkTheme: nightTheme(),
      themeMode: theme,
      locale: language == null ? null : Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      builder: (context, child) {
        // Dates and numbers follow the language the app resolved to, not the machine's.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return session.status == SessionStatus.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : child!;
      },
    );
  }
}
