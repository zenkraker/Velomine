import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'training_data.dart';
import 'training_state.dart';

part 'training_view_model.g.dart';

/// The member's auto-training plan and week for the session: the shell reads the plan to show the Training
/// destination, the profile for its switch, the Training page for today and the week, and Progress for its Today
/// strip. A sign-out rebuilds it empty.
@Riverpod(keepAlive: true)
class TrainingViewModel extends _$TrainingViewModel {
  int _messageId = 0;
  int _loadGeneration = 0;
  int _weekGeneration = 0;

  @override
  TrainingState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const TrainingState();
    Future.microtask(load);
    return const TrainingState();
  }

  /// The plan, and then the week it needs: the week endpoint answers 404 while auto training is off.
  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(trainingDataProvider).plan();
    if (!ref.mounted || generation != _loadGeneration) return;
    state = state.copyWith(
      load: state.load.finish(result),
      plan: result.valueOrNull,
    );
    if (result.isOk && state.on) await loadWeek();
  }

  Future<void> loadWeek() async {
    final generation = ++_weekGeneration;
    state = state.copyWith(week: state.week.start());
    final result = await ref.read(trainingDataProvider).week();
    if (!ref.mounted || generation != _weekGeneration) return;
    state = state.copyWith(
      week: state.week.finish(result),
      weeks: result.valueOrNull?.weeks ?? const [],
    );
  }

  /// Takes the plan a screen has just saved, so the destination and the switch apply without asking again.
  void adopt(TrainingPlanResponse plan) {
    state = state.copyWith(plan: plan);
    if (plan.on_) Future.microtask(loadWeek);
  }

  /// "Make today easy" on today's session: the answer is the week as it now stands, so nothing is asked twice.
  Future<void> makeEasy(String sessionId) =>
      _change(() => ref.read(trainingDataProvider).makeEasy(sessionId));

  /// "Back to the plan", the same day, while nothing has ticked the session.
  Future<void> backToPlan(String sessionId) =>
      _change(() => ref.read(trainingDataProvider).backToPlan(sessionId));

  /// Moves a session to another day left this week.
  Future<void> move(String sessionId, DateTime localDate) =>
      _change(() => ref.read(trainingDataProvider).move(sessionId, localDate));

  /// Skips a session and answers whether the app should ask about the rest of the week.
  Future<bool> skip(
    String sessionId, {
    String? reason,
    bool restOfWeek = false,
  }) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref
        .read(trainingDataProvider)
        .skip(sessionId, reason: reason, restOfWeek: restOfWeek);
    if (!ref.mounted) return false;
    state = state.copyWith(
      action: state.action.finish(result.map((_) => null)),
    );
    if (result.failureOrNull case final failure?) {
      _fail(failure);
      return false;
    }
    if (result.valueOrNull?.week case final week?) {
      state = state.copyWith(weeks: week.weeks);
    }
    return result.valueOrNull?.askRestOfWeek ?? false;
  }

  /// One change to a session: the week it answers replaces the one on screen, and a refusal is said once.
  Future<void> _change(
    Future<Result<TrainingWeeksResponse?>> Function() call,
  ) async {
    if (state.action.running) return;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return;
    }
    if (result.valueOrNull case final changed?) {
      state = state.copyWith(weeks: changed.weeks);
    }
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );

  /// Turns auto training off: today's and later sessions go on the server, the past ones stay.
  Future<bool> turnOff() async {
    if (state.turnOff.running) return false;
    state = state.copyWith(turnOff: state.turnOff.start());
    final result = await ref.read(trainingDataProvider).turnOff();
    if (!ref.mounted) return false;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        plan: value,
        weeks: const [],
        week: const CommandState.idle(),
        turnOff: state.turnOff.finish(result),
      ),
      Failed(:final failure) => state.copyWith(
        turnOff: state.turnOff.finish(result),
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      ),
    };
    return result.isOk;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );
}
