// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navRides => 'Uscite';

  @override
  String get navRecord => 'Registra';

  @override
  String get navProgress => 'Progressi';

  @override
  String get navBikes => 'Bici';

  @override
  String get navAdmin => 'Admin';

  @override
  String get notifications => 'Notifiche';

  @override
  String notificationsUnread(int count) {
    return 'Notifiche, $count non lette';
  }

  @override
  String get signOut => 'Esci';

  @override
  String themeTooltip(String name) {
    return 'Tema: $name';
  }

  @override
  String get themeSystem => 'Segui il dispositivo';

  @override
  String get themeLight => 'Giorno';

  @override
  String get themeDark => 'Notte';

  @override
  String languageTooltip(String name) {
    return 'Lingua: $name';
  }

  @override
  String get languageSystem => 'Segui il dispositivo';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';
}
