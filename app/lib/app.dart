import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velomine_api/api.dart';

import 'core/back_guard.dart';
import 'core/hooks.dart';
import 'core/language_choice.dart';
import 'core/map_defaults.dart';
import 'core/motion.dart';
import 'core/providers.dart';
import 'core/server_config.dart';
import 'core/session.dart';
import 'core/solo_hint.dart';
import 'core/telemetry.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'core/units.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/admin/admin_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/bikes/bike_detail_screen.dart';
import 'features/bikes/bikes_screen.dart';
import 'features/bikes/bikes_view_models.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/club/club_view_model.dart';
import 'features/club/club_screen.dart';
import 'features/club/join_club_screen.dart';
import 'features/club/nearby_clubs_screen.dart';
import 'features/calendar/calendar_feed_screen.dart';
import 'features/calendar/club_ride_detail_screen.dart';
import 'features/calendar/club_rides_screen.dart';
import 'features/calendar/club_rides_view_model.dart';
import 'features/calendar/plan_ride_screen.dart';
import 'features/club/start_club_screen.dart';
import 'features/routes/route_detail_screen.dart';
import 'features/routes/route_forms.dart';
import 'features/routes/routes_screen.dart';
import 'features/routes/routes_view_model.dart';
import 'features/supporter/supporter_activation_screen.dart';
import 'features/supporter/supporter_celebration_screen.dart';
import 'features/supporter/supporter_view_model.dart';
import 'features/coach/coach_athlete_screen.dart';
import 'features/coach/coach_athletes_screen.dart';
import 'features/coach/coach_ride_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/sessions_screen.dart';
import 'features/profile/two_factor_screen.dart';
import 'features/privacy/privacy_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/recording/recording_screen.dart';
import 'features/rides/bulk/ride_drop_area.dart';
import 'features/rides/detail/ride_detail_screen.dart';
import 'features/rides/incoming/incoming_rides_area.dart';
import 'features/rides/import/import_screen.dart';
import 'features/rides/rides_view_model.dart';
import 'features/rides/rides_screen.dart';
import 'home_shell.dart';
import 'core/l10n.dart';

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
  return () => ref.read(sessionProvider).signInWithSso();
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
  const VelomineApp({super.key, @visibleForTesting this.onRouter});

  /// Hands the app's router to a test, so it can open an address as a returning member would.
  final ValueChanged<GoRouter>? onRouter;

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
    widget.onRouter?.call(_router);
  }

  /// Applies the account's language and units on sign-in. With no account choice
  /// the app follows the device for language, and shows metric for units.
  void _applyAccountLanguage() {
    if (_languageSynced) return;
    final me = ref.read(sessionProvider).me;
    if (me == null) return;
    _languageSynced = true;
    if (me.language != null) {
      ref.read(languageChoiceViewModelProvider.notifier).adopt(me.language);
    }
    ref.read(unitsChoiceViewModelProvider.notifier).adopt(me.units);
  }

  /// The account's language follows the session; member data is scoped by the
  /// ViewModels that watch the signed-in identity.
  void _followSession() {
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.signedIn) {
      _applyAccountLanguage();
    } else if (session.status == SessionStatus.signedOut) {
      ref.read(languageChoiceViewModelProvider.notifier).forget();
      ref.read(unitsChoiceViewModelProvider.notifier).forget();
      _languageSynced = false;
      // Never carry one member's telemetry choice into the next sign-in.
      unawaited(ref.read(telemetryStoreProvider).clear());
      unawaited(ref.read(telemetryRuntimeProvider).close());
    }
  }

  late final GoRouter _router;

  GoRouter _createRouter() => GoRouter(
    initialLocation: '/',
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final club = ref.read(clubViewModelProvider);
      final path = state.uri.path;
      const open = {
        '/sign-in',
        '/register',
        '/forgot-password',
        '/reset-password',
        '/verify-email',
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
      if (path == '/club/start' && club.loaded && club.club != null) {
        return '/club';
      }
      if (path == '/join' && club.club != null) {
        session.pendingJoinCode = null;
        return '/rides';
      }
      // A reset or confirmation link works even when the browser still has a session: it belongs to the address.
      if (path == '/reset-password' || path == '/verify-email') return null;
      if (open.contains(path) || path == '/') return '/rides';
      if (path == '/record' && kIsWeb) return '/rides';
      if (path == '/admin' && !session.isAdmin) return '/rides';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => BackGuard(
          location: state.uri.path,
          child: SignInScreen(
            startSso: ref.read(ssoStarterProvider),
            onChangeServer: ref.read(changeServerProvider),
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            BackGuard(location: state.uri.path, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/clubs',
        builder: (context, state) => BackGuard(
          location: state.uri.path,
          child: NearbyClubsScreen(
            onBack: () => context.go('/club'),
            tileUrl:
                ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                defaultMapTileUrl,
            attribution:
                ref.read(sessionProvider).serverInfo?.mapAttribution ??
                defaultMapAttribution,
          ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => BackGuard(
          location: state.uri.path,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final fragment = state.uri.fragment.isNotEmpty
              ? state.uri.fragment
              : Uri.base.fragment;
          final params = fragment.isNotEmpty
              ? Uri.splitQueryString(fragment)
              : state.uri.queryParameters;
          return BackGuard(
            location: state.uri.path,
            child: VerifyEmailScreen(
              token: params['token'],
              email: params['email'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final fragment = state.uri.fragment.isNotEmpty
              ? state.uri.fragment
              : Uri.base.fragment;
          final params = fragment.isNotEmpty
              ? Uri.splitQueryString(fragment)
              : state.uri.queryParameters;
          return BackGuard(
            location: state.uri.path,
            child: ResetPasswordScreen(
              token: params['token'],
              email: params['email'],
            ),
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
                  onOpen: (id) => context.push('/rides/$id'),
                  onOpenImport: (id) => context.push('/rides/import/$id'),
                  showSoloCard: club.loaded && club.club == null && !dismissed,
                  onOpenClubs: () => context.push('/clubs'),
                  onDismissSoloCard: ref
                      .read(soloHintViewModelProvider.notifier)
                      .dismiss,
                );
              },
            ),
          ),
          GoRoute(
            path: '/rides/import/:id',
            builder: (context, state) => ImportScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onDone: () => context.go('/rides'),
            ),
          ),
          GoRoute(
            path: '/rides/:id',
            builder: (context, state) => RideDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onDeleted: () {
                ref.read(ridesViewModelProvider.notifier).refresh();
                _backOrGo(context, '/rides');
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
              onJoin: () => context.push('/join'),
              onStartClub: () => context.push('/club/start'),
              onOpenClubs: () => context.push('/clubs'),
              onOpenAthletes: () => context.push('/club/athletes'),
              onOpenRides: () => context.push('/club/rides'),
              onOpenRide: (id) => context.push('/club/rides/$id'),
              onPlanRide: () => context.push('/club/rides/new'),
              onOpenRoutes: () => context.push('/club/routes'),
              onOpenRoute: (id) => context.push('/club/routes/$id'),
              onAddRoute: () => context.push('/club/routes/new'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/start',
            builder: (context, _) => StartClubScreen(
              onStarted: () => context.go('/club'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/rides',
            builder: (context, _) => ClubRidesScreen(
              canPlan: switch (ref.watch(clubViewModelProvider).club?.myRole) {
                'owner' || 'coach' => true,
                _ => false,
              },
              onOpen: (id) => context.push('/club/rides/$id'),
              onPlan: () => context.push('/club/rides/new'),
              onCalendar: () => context.push('/club/calendar'),
            ),
          ),
          GoRoute(
            path: '/club/rides/new',
            builder: (context, _) => PlanRideScreen(
              rideId: '',
              onSaved: (id) => context.pushReplacement('/club/rides/$id'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/rides/:id',
            builder: (context, state) => ClubRideDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onEdit: () => context.push(
                '/club/rides/${state.pathParameters['id']}/edit',
              ),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/rides/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PlanRideScreen(
                key: ValueKey('edit-$id'),
                rideId: id,
                onSaved: (_) {
                  ref.invalidate(clubRideDetailViewModelProvider(id));
                  _backOrGo(context, '/club/rides/$id');
                },
                tileUrl:
                    ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                    defaultMapTileUrl,
                attribution:
                    ref.read(sessionProvider).serverInfo?.mapAttribution ??
                    defaultMapAttribution,
              );
            },
          ),
          GoRoute(
            path: '/club/calendar',
            builder: (context, _) => const CalendarFeedScreen(),
          ),
          GoRoute(
            path: '/club/routes',
            builder: (context, _) => RoutesScreen(
              onOpen: (id) => context.push('/club/routes/$id'),
              onAdd: () => context.push('/club/routes/new'),
            ),
          ),
          GoRoute(
            path: '/club/routes/new',
            builder: (context, _) => AddRouteScreen(
              onAdded: (id) => context.pushReplacement('/club/routes/$id'),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/routes/:id',
            builder: (context, state) => RouteDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onEdit: () => context.push(
                '/club/routes/${state.pathParameters['id']}/edit',
              ),
              onDeleted: () => _backOrGo(context, '/club/routes'),
              serverUrl: ref.read(sessionProvider).serverUrl,
              openLink: ref.read(linkOpenerProvider),
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/club/routes/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EditRouteScreen(
                key: ValueKey('edit-$id'),
                id: id,
                onSaved: () {
                  ref.invalidate(routeDetailViewModelProvider(id));
                  _backOrGo(context, '/club/routes/$id');
                },
              );
            },
          ),
          GoRoute(
            path: '/club/athletes',
            builder: (context, _) => CoachAthletesScreen(
              clubId: ref.read(clubViewModelProvider).club!.id,
              onOpen: (id) => context.push('/club/athletes/$id'),
            ),
          ),
          GoRoute(
            path: '/club/athletes/:id',
            builder: (context, state) => CoachAthleteScreen(
              key: ValueKey(state.pathParameters['id']),
              clubId: ref.read(clubViewModelProvider).club!.id,
              userId: state.pathParameters['id']!,
              onOpenRide: (rideId) => context.push(
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
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
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
                onJoined: () {
                  session.pendingJoinCode = null;
                  context.go('/rides');
                },
                onSkip: () {
                  session.pendingJoinCode = null;
                  context.go('/rides');
                },
              );
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, _) => NotificationsScreen(
              onOpen: (location) => context.push(location),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, _) => ProfileScreen(
              serverUrl: ref.read(sessionProvider).serverUrl,
              emailAvailable:
                  ref.read(sessionProvider).serverInfo?.emailAvailable ?? false,
              openLink: ref.read(linkOpenerProvider),
              onAccountDeleted: ref.read(sessionProvider).signOut,
              onPasswordChanged: ref.read(sessionProvider).signOut,
              onOpenPrivacy: () => context.push('/privacy'),
              onBecomeSupporter: () => context.push('/profile/supporter'),
              onReplaySupporter: () {
                final licence = ref
                    .read(supporterViewModelProvider)
                    .riderLicence;
                if (licence != null) {
                  context.push('/profile/supporter/activated', extra: licence);
                }
              },
            ),
          ),
          GoRoute(
            path: '/profile/supporter',
            builder: (context, _) => SupporterActivationScreen(
              onCelebrated: ref.read(supporterViewModelProvider.notifier).load,
              onDone: () => _backOrGo(context, '/profile'),
            ),
          ),
          GoRoute(
            path: '/profile/supporter/activated',
            redirect: (context, state) =>
                state.extra is RiderLicenceResponse ||
                    ref.read(supporterViewModelProvider).riderLicence != null
                ? null
                : '/profile',
            builder: (context, state) => SupporterCelebrationScreen(
              licence:
                  state.extra as RiderLicenceResponse? ??
                  ref.read(supporterViewModelProvider).riderLicence!,
              onContinue: () => _backOrGo(context, '/profile'),
            ),
          ),
          GoRoute(
            path: '/profile/two-factor',
            builder: (_, _) => const TwoFactorScreen(),
          ),
          GoRoute(
            path: '/profile/sessions',
            builder: (_, _) => const SessionsScreen(),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, _) => PrivacyScreen(
              tileUrl:
                  ref.read(sessionProvider).serverInfo?.mapTileUrl ??
                  defaultMapTileUrl,
              attribution:
                  ref.read(sessionProvider).serverInfo?.mapAttribution ??
                  defaultMapAttribution,
            ),
          ),
          GoRoute(
            path: '/bikes',
            builder: (context, _) =>
                BikesScreen(onOpen: (id) => context.push('/bikes/$id')),
          ),
          GoRoute(
            path: '/bikes/:id',
            builder: (context, state) => BikeDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
              onDeleted: () {
                ref.read(bikesViewModelProvider.notifier).refresh();
                _backOrGo(context, '/bikes');
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
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      builder: (context, child) {
        // Dates and numbers follow the language the app resolved to, not the machine's.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        if (session.status == SessionStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final page = IncomingRidesArea(
          // "Share to Velomine" ends on the ride list, like a drop on the web.
          onOpenRides: () => _router.go('/rides'),
          child: RideDropArea(
            // A folder dropped on any page is followed on the ride list.
            onStarted: () => _router.go('/rides'),
            child: child!,
          ),
        );
        if (!reduceMotion(context)) return page;
        // No page transition when the system asks to reduce motion.
        return Theme(
          data: Theme.of(context)
              .copyWith(pageTransitionsTheme: noAnimationPageTransitions),
          child: page,
        );
      },
    );
  }
}

/// Pops to the screen this one was opened from. A deep link has no stack, so it goes to the tab instead.
void _backOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
