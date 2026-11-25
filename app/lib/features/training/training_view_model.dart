import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'training_data.dart';
import 'training_state.dart';

part 'training_view_model.g.dart';

/// The member's auto-training plan and this week: the shell reads it to show the Training destination, the profile
/// for its switch, the Training page for the goal and the week, the session page for one session, and the ride page
/// to answer a session's question. A sign-out rebuilds it empty.
@Riverpod(keepAlive: true)
class TrainingViewModel extends _$TrainingViewModel {
  int _messageId = 0;
  int _loadGeneration = 0;

  @override
  TrainingState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const TrainingState();
    Future.microtask(load);
    return const TrainingState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final data = ref.read(trainingDataProvider);
    final result = await data.plan();
    if (!ref.mounted || generation != _loadGeneration) return;
    // A member with auto training off has no week to read, and asking for one answers 404.
    final on = result.valueOrNull?.on_ ?? false;
    final weeks = on ? await data.week() : null;
    if (!ref.mounted || generation != _loadGeneration) return;
    state = state.copyWith(
      load: state.load.finish(result),
      plan: result.valueOrNull,
      weeks: weeks?.valueOrNull,
    );
  }

  /// Answers the question a ride asked, then reads the week again so the session shows where it went. False when it
  /// could not be answered, with the reason in the messages.
  Future<bool> answer(
    String sessionId,
    String rideId, {
    required bool yes,
  }) async {
    if (state.answer.running) return false;
    state = state.copyWith(answer: state.answer.start());
    final result = await ref
        .read(trainingDataProvider)
        .answer(sessionId, rideId, yes);
    if (!ref.mounted) return false;
    state = switch (result) {
      Ok() => state.copyWith(answer: state.answer.finish(result)),
      Failed(:final failure) => state.copyWith(
        answer: state.answer.finish(result),
        messages: [...state.messages, FailureMessage(_messageId++, failure)],
      ),
    };
    if (result.isOk) await load();
    return result.isOk;
  }

  /// Takes the plan a screen has just saved, so the destination and the switch apply without asking again.
  void adopt(TrainingPlanResponse plan) => state = state.copyWith(plan: plan);

  /// Turns auto training off: today's and later sessions go on the server, the past ones stay.
  Future<bool> turnOff() async {
    if (state.turnOff.running) return false;
    state = state.copyWith(turnOff: state.turnOff.start());
    final result = await ref.read(trainingDataProvider).turnOff();
    if (!ref.mounted) return false;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        plan: value,
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
