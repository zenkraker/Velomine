import 'package:flutter/material.dart';

/// The language on screen. Before sign-in it follows the device; after sign-in it follows the account, so a
/// choice on the web is the same on the phone. There is no per-device setting.
class LanguageChoice extends ChangeNotifier {
  LanguageChoice();

  /// Called after an explicit choice, so the app can save it to the signed-in account. The app sets it.
  Future<void> Function(String? code)? onChanged;

  /// A language code such as `en` or `it`; null means follow the device.
  String? code;

  /// The languages the app has translations for.
  static const supported = ['en', 'it'];

  static String? _known(String? value) =>
      value != null && supported.contains(value) ? value : null;

  /// Null tells [MaterialApp] to use the device's language.
  Locale? get locale => code == null ? null : Locale(code!);

  Future<void> choose(String? value) async {
    code = _known(value);
    notifyListeners();
    await onChanged?.call(code);
  }

  /// Applies the account's choice without sending it back to the server.
  void adopt(String? value) {
    final next = _known(value);
    if (next == code) return;
    code = next;
    notifyListeners();
  }

  /// The session is gone: follow the device again, so nothing from the account leaks onto the sign-in screen.
  void forget() {
    if (code == null) return;
    code = null;
    notifyListeners();
  }
}
