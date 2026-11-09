import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/language_choice.dart';
import 'core/server_config.dart';
import 'core/theme.dart';
import 'core/theme_choice.dart';
import 'features/auth/server_setup_screen.dart';
import 'l10n/generated/app_localizations.dart';

/// The top of the app: the setup screen on a phone until a server is chosen,
/// then the session app for that address.
class VelomineRoot extends ConsumerWidget {
  const VelomineRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigViewModelProvider);
    final theme =
        ref.watch(themeChoiceViewModelProvider).value ?? ThemeMode.system;
    final language = ref.watch(languageChoiceViewModelProvider);
    final value = config.value;

    if (kIsWeb || value?.baseUrl != null) return const VelomineApp();

    return MaterialApp(
      title: 'Velomine',
      theme: dayTheme(),
      darkTheme: nightTheme(),
      themeMode: theme,
      locale: language == null ? null : Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: config.isLoading && value == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : ServerSetupScreen(
              initialUrl: value?.previousUrl ?? suggestedServerUrl(),
            ),
    );
  }
}
