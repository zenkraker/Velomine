import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'progress_data.dart';
import 'progress_state.dart';

part 'progress_view_models.g.dart';

/// The period, discipline and ranges the progress page shows. Kept alive so the
/// choice follows the member between visits.
@Riverpod(keepAlive: true)
class ProgressFiltersViewModel extends _$ProgressFiltersViewModel {
  @override
  ProgressFiltersState build() => const ProgressFiltersState();

  void setPeriod(String value) {
    if (value == state.period) return;
    state = state.copyWith(period: value);
  }

  void setDiscipline(String? value) {
    if (value == state.discipline) return;
    state = state.copyWith(discipline: value, clearDiscipline: value == null);
  }

  void setTrainingDays(int value) {
    if (value == state.trainingDays) return;
    state = state.copyWith(trainingDays: value);
  }

  void setPowerDays(int value) {
    if (value == state.powerDays) return;
    state = state.copyWith(powerDays: value);
  }
}

@Riverpod(keepAlive: true)
class TotalsViewModel extends _$TotalsViewModel {
  int _loadGeneration = 0;

  @override
  TotalsState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const TotalsState();
    ref.watch(
      progressFiltersViewModelProvider.select((f) => (f.period, f.discipline)),
    );
    Future.microtask(load);
    return const TotalsState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = TotalsState(load: state.load.start());
    final filters = ref.read(progressFiltersViewModelProvider);
    final result = await ref
        .read(progressDataProvider)
        .totals(
          filters.period,
          periodCounts[filters.period] ?? 12,
          filters.discipline,
        );
    if (!ref.mounted || generation != _loadGeneration) return;
    state = TotalsState(load: state.load.finish(result));
  }
}

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

@Riverpod(keepAlive: true)
class TrainingViewModel extends _$TrainingViewModel {
  int _loadGeneration = 0;

  @override
  TrainingState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const TrainingState();
    ref.watch(
      progressFiltersViewModelProvider.select(
        (f) => (f.trainingDays, f.discipline),
      ),
    );
    Future.microtask(load);
    return const TrainingState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = TrainingState(load: state.load.start());
    final filters = ref.read(progressFiltersViewModelProvider);
    final result = await ref
        .read(progressDataProvider)
        .training(filters.trainingDays, filters.discipline);
    if (!ref.mounted || generation != _loadGeneration) return;
    state = TrainingState(load: state.load.finish(result));
  }
}

@Riverpod(keepAlive: true)
class PowerCurveViewModel extends _$PowerCurveViewModel {
  int _messageId = 0;
  int _loadGeneration = 0;

  @override
  PowerState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const PowerState();
    ref.watch(progressFiltersViewModelProvider.select((f) => f.powerDays));
    Future.microtask(load);
    return const PowerState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final result = await ref
        .read(progressDataProvider)
        .powerCurve(ref.read(progressFiltersViewModelProvider).powerDays);
    if (!ref.mounted || generation != _loadGeneration) return;
    state = state.copyWith(load: state.load.finish(result));
  }

  /// Adopts the suggested FTP. Past TSS stays as it was; zones and new load use
  /// the new value.
  Future<void> useFtp(int watts) async {
    if (state.action.running) return;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(progressDataProvider).setFtp(watts);
    if (!ref.mounted) return;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return;
    }
    ref
      ..invalidate(trainingViewModelProvider)
      ..invalidate(readinessViewModelProvider)
      ..invalidateSelf();
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}

@Riverpod(keepAlive: true)
class ReadinessViewModel extends _$ReadinessViewModel {
  int _loadGeneration = 0;

  @override
  ReadinessState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const ReadinessState();
    }
    Future.microtask(load);
    return const ReadinessState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = ReadinessState(load: state.load.start());
    final result = await ref.read(progressDataProvider).readiness();
    if (!ref.mounted || generation != _loadGeneration) return;
    state = ReadinessState(load: state.load.finish(result));
  }
}

@Riverpod(keepAlive: true)
class WellbeingViewModel extends _$WellbeingViewModel {
  int _messageId = 0;
  int _loadGeneration = 0;

  @override
  WellbeingState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const WellbeingState();
    }
    Future.microtask(load);
    return const WellbeingState();
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(load: state.load.start());
    final data = ref.read(progressDataProvider);
    final today = await data.wellbeing();
    if (!ref.mounted || generation != _loadGeneration) return;

    CheckInsResponse? history;
    if (today.valueOrNull?.consented == true) {
      history = (await data.checkIns(30)).valueOrNull;
      if (!ref.mounted || generation != _loadGeneration) return;
    }

    state = WellbeingState(
      today: today.valueOrNull,
      checkIns: history,
      load: state.load.finish(today),
      messages: state.messages,
    );
  }

  /// Accepts the wellbeing terms. Health data is not stored before this.
  Future<bool> consent() =>
      _run(() => ref.read(progressDataProvider).giveConsent());

  /// Stops processing and sharing; the member's history stays until they delete it.
  Future<bool> withdrawConsent() =>
      _run(() => ref.read(progressDataProvider).withdrawConsent());

  Future<bool> saveCheckIn(
    int fatigue,
    int soreness,
    int mood,
    int stress,
    int motivation,
  ) => _run(
    () => ref
        .read(progressDataProvider)
        .saveCheckIn(
          SaveCheckInRequest(
            fatigue: fatigue,
            soreness: soreness,
            mood: mood,
            stress: stress,
            motivation: motivation,
          ),
        ),
  );

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _run(Future<Result<Object?>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    await load();
    ref.invalidate(readinessViewModelProvider);
    return true;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
