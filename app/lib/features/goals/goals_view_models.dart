import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import '../progress/progress_data.dart';
import 'goals_state.dart';

part 'goals_view_models.g.dart';

/// The member's goals: read on open, and the add, change and delete the Goals page makes.
@Riverpod(keepAlive: true)
class GoalsViewModel extends _$GoalsViewModel {
  int _messageId = 0;
  int _loadGeneration = 0;

  @override
  GoalsState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const GoalsState();
    Future.microtask(load);
    return const GoalsState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(progressDataProvider).goals();
    if (!ref.mounted || generation != _loadGeneration) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        goals: value?.goals ?? const [],
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<void> add(CreateGoalRequest goal) =>
      _run(() => ref.read(progressDataProvider).addGoal(goal));

  Future<void> setTarget(String id, double target) =>
      _run(() => ref.read(progressDataProvider).setTarget(id, target));

  Future<void> delete(String id) =>
      _run(() => ref.read(progressDataProvider).deleteGoal(id));

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<void> _run(Future<Result<Object?>> Function() call) async {
    if (state.action.running) return;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return;
    }
    await load();
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
