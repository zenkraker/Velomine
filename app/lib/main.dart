import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/providers.dart';
import 'core/server_config.dart';
import 'core/telemetry.dart';
import 'core/theme_choice.dart';
import 'core/token_store_factory.dart';
import 'root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // real URLs on the web ("/rides"), not "/#/rides"; the server falls back to index.html

  final container = ProviderContainer(
    overrides: [tokenStoreProvider.overrideWithValue(createTokenStore())],
  );

  // Read the saved address and theme before the first frame, so the app never
  // flashes the setup screen or the wrong theme.
  final config = await container.read(serverConfigViewModelProvider.future);
  await container.read(themeChoiceViewModelProvider.future);

  // Keychain entries survive an uninstall on iOS. With no server chosen there is no session to restore,
  // so drop any token that belonged to the removed installation.
  if (!kIsWeb && config.baseUrl == null) {
    await container.read(tokenStoreProvider).clear();
  }

  final telemetry = await container.read(telemetryStoreProvider).read();
  await runWithTelemetry(
    choice: telemetry,
    app: UncontrolledProviderScope(
      container: container,
      child: const VelomineRoot(),
    ),
  );
}
