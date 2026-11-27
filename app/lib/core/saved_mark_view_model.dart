import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_mark_view_model.g.dart';

/// Whether the "Saved." badge shows. A screen that saved something calls [show]; the badge goes by itself after
/// [shownFor], or at once on [hide] (a save that failed).
@Riverpod(keepAlive: true)
class SavedMarkViewModel extends _$SavedMarkViewModel {
  static const shownFor = Duration(seconds: 2);

  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void show() {
    _timer?.cancel();
    state = true;
    _timer = Timer(shownFor, hide);
  }

  void hide() {
    _timer?.cancel();
    state = false;
  }
}
