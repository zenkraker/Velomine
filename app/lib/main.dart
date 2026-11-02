import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:velomine_api/api.dart';

import 'app.dart';
import 'core/server_url.dart';
import 'core/session.dart';

void main() {
  usePathUrlStrategy(); // real URLs on the web ("/rides"), not "/#/rides"; the server falls back to index.html
  final bearer = HttpBearerAuth();
  final client = ApiClient(basePath: serverUrl(), authentication: bearer);
  final session = Session(
    client: client,
    bearer: bearer,
    useCookies: kIsWeb,
    ssoError: Uri.base.queryParameters['sso_error'],
  )..restore();
  runApp(VelomineApp(session: session));
}
