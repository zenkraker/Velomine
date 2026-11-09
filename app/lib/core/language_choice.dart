import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'providers.dart';
import 'session.dart';

part 'language_choice.g.dart';

/// The languages the app has translations for.
const supportedLanguages = ['en', 'it'];

String? knownLanguage(String? value) =>
    value != null && supportedLanguages.contains(value) ? value : null;

/// The language on screen. Before sign-in it follows the device; after sign-in
/// it follows the account, so a choice on the web is the same on the phone.
/// There is no per-device setting.
@Riverpod(keepAlive: true)
class LanguageChoiceViewModel extends _$LanguageChoiceViewModel {
  @override
  String? build() => null;

  /// A language code such as `en` or `it`; null means follow the device. An
  /// explicit choice also goes to the signed-in account.
  Future<void> choose(String? value) async {
    state = knownLanguage(value);
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.signedIn) {
      await session.setLanguage(state);
    }
  }

  /// Applies the account's choice without sending it back to the server.
  void adopt(String? value) {
    final next = knownLanguage(value);
    if (next == state) return;
    state = next;
  }

  /// The session is gone: follow the device again, so nothing from the account
  /// leaks onto the sign-in screen.
  void forget() {
    if (state == null) return;
    state = null;
  }
}
