import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'session_state.dart';
import 'training_view_model.dart';

part 'session_view_model.g.dart';

/// One session's page. The session is one of the week's, so the page reads the week the Training page already
/// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.
@riverpod
class SessionViewModel extends _$SessionViewModel {
  @override
  SessionState build(String id) {
    final training = ref.watch(trainingViewModelProvider);
    return SessionState(
      session: training.weeks
          .expand((week) => week.sessions)
          .where((session) => session.id == id)
          .firstOrNull,
      week: training.week,
    );
  }

  Future<void> retry() =>
      ref.read(trainingViewModelProvider.notifier).loadWeek();
}
