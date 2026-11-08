import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

/// The strings for the language the app is showing: `context.l10n.navRides`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
