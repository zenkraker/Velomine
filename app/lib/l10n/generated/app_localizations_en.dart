// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRides => 'Rides';

  @override
  String get navRecord => 'Record';

  @override
  String get navProgress => 'Progress';

  @override
  String get navBikes => 'Bikes';

  @override
  String get navAdmin => 'Admin';

  @override
  String get notifications => 'Notifications';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String themeTooltip(String name) {
    return 'Theme: $name';
  }

  @override
  String get themeSystem => 'Follow this device';

  @override
  String get themeLight => 'Day';

  @override
  String get themeDark => 'Night';

  @override
  String languageTooltip(String name) {
    return 'Language: $name';
  }

  @override
  String get languageSystem => 'Follow this device';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';
}
