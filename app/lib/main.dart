import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/server_config.dart';
import 'core/theme_choice.dart';
import 'core/token_store_factory.dart';
import 'root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // real URLs on the web ("/rides"), not "/#/rides"; the server falls back to index.html

  final config = ServerConfig();
  await config.load();

  // Read the saved theme before the first frame, so the app never flashes the wrong one.
  final themeChoice = ThemeChoice();
  await themeChoice.load();

  final tokenStore = createTokenStore();
  // Keychain entries survive an uninstall on iOS. With no server chosen there is no session to restore,
  // so drop any token that belonged to the removed installation.
  if (!kIsWeb && config.baseUrl == null) await tokenStore.clear();

  runApp(
    VelomineRoot(
      config: config,
      tokenStore: tokenStore,
      themeChoice: themeChoice,
    ),
  );
}
