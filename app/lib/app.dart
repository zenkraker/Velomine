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
import 'features/auth/sign_in_screen.dart';
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
  });

  final Session session;
  final FilePicker pickFile;
  final SsoStarter startSso;
  final Duration uploadPollInterval;

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
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/rides',
            builder: (_, _) => RidesScreen(controller: _rides),
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
    _router.dispose();
    _rides.dispose();
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
