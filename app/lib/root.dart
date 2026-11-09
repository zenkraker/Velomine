import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import 'app.dart';
import 'core/language_choice.dart';
import 'core/server_config.dart';
import 'core/session.dart';
import 'core/session_auth.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'core/token_store.dart';
import 'features/auth/server_setup_screen.dart';
import 'l10n/generated/app_localizations.dart';

/// The top of the app: choose a server on a phone, then build a session for that address.
class VelomineRoot extends StatefulWidget {
  const VelomineRoot({
    super.key,
    required this.config,
    required this.tokenStore,
    required this.themeChoice,
    required this.languageChoice,
  });

  final ServerConfig config;
  final TokenStore tokenStore;
  final ThemeChoice themeChoice;
  final LanguageChoice languageChoice;

  @override
  State<VelomineRoot> createState() => _VelomineRootState();
}

class _VelomineRootState extends State<VelomineRoot> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.config,
        widget.themeChoice,
        widget.languageChoice,
      ]),
      builder: (context, _) {
        final baseUrl = widget.config.baseUrl;

        if (!kIsWeb && baseUrl == null) {
          return MaterialApp(
            title: 'Velomine',
            theme: dayTheme(),
            darkTheme: nightTheme(),
            themeMode: widget.themeChoice.mode,
            locale: widget.languageChoice.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ServerSetupScreen(
              initialUrl:
                  widget.config.previousUrl ?? widget.config.suggestedUrl,
              onSaved: widget.config.save,
            ),
          );
        }

        return _SessionHost(
          key: ValueKey(baseUrl ?? Uri.base.origin),
          baseUrl: baseUrl ?? Uri.base.origin,
          config: widget.config,
          tokenStore: widget.tokenStore,
          themeChoice: widget.themeChoice,
          languageChoice: widget.languageChoice,
        );
      },
    );
  }
}

/// Owns the session for one server address. A new address means a new host, so nothing leaks between servers.
class _SessionHost extends StatefulWidget {
  const _SessionHost({
    super.key,
    required this.baseUrl,
    required this.config,
    required this.tokenStore,
    required this.themeChoice,
    required this.languageChoice,
  });

  final String baseUrl;
  final ServerConfig config;
  final TokenStore tokenStore;
  final ThemeChoice themeChoice;
  final LanguageChoice languageChoice;

  @override
  State<_SessionHost> createState() => _SessionHostState();
}

class _SessionHostState extends State<_SessionHost> {
  late final SessionAuth _auth;
  late final Session _session;

  @override
  void initState() {
    super.initState();
    _auth = SessionAuth(
      baseUrl: widget.baseUrl,
      store: widget.tokenStore,
      useCookies: kIsWeb,
    );
    final client = ApiClient(basePath: widget.baseUrl, authentication: _auth);
    _session = Session(
      client: client,
      auth: _auth,
      useCookies: kIsWeb,
      serverUrl: widget.baseUrl,
      ssoError: Uri.base.queryParameters['sso_error'],
    );
    unawaited(_session.restore());
  }

  Future<void> _changeServer() async {
    await _session.signOut();
    await widget.config.clear();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VelomineApp(
    session: _session,
    themeChoice: widget.themeChoice,
    languageChoice: widget.languageChoice,
    onChangeServer: kIsWeb ? null : _changeServer,
  );
}
