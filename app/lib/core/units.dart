import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'providers.dart';
import 'session.dart';

part 'units.g.dart';

/// How the member reads distances, speeds, heights and weights. The database
/// is always metric: this changes only what is shown, and what is typed back.
enum Units { metric, imperial }

Units knownUnits(String? value) =>
    value == 'imperial' ? Units.imperial : Units.metric;

/// The units on screen. They follow the account, so a choice on the web is the
/// same on the phone. Signed out, the app shows metric.
@Riverpod(keepAlive: true)
class UnitsChoiceViewModel extends _$UnitsChoiceViewModel {
  @override
  Units build() => Units.metric;

  /// An explicit choice also goes to the signed-in account.
  Future<void> choose(Units value) async {
    state = value;
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.signedIn) {
      await session.setUnits(value.name);
    }
  }

  /// Applies the account's choice without sending it back to the server.
  void adopt(String? value) => state = knownUnits(value);

  /// The session is gone: nothing from the account stays on the sign-in screen.
  void forget() => state = Units.metric;
}
