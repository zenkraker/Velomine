import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import '../l10n/generated/app_localizations.dart';

/// The strings for the language the app is showing: `context.l10n.navRides`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The app's strings with the Material, Cupertino and widget localisations, for every app and test root. Used instead
/// of the generated `AppLocalizations.localizationsDelegates`, which still lists flutter_localizations' Material and
/// Cupertino delegates: the widgets from material_ui and cupertino_ui look up their own types and would not find them.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
