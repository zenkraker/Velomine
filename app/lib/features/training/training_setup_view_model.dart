import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import 'training_data.dart';
import 'training_goals.dart';
import 'training_setup_state.dart';
import 'training_view_model.dart';

part 'training_setup_view_model.g.dart';

/// The setup the rider answers to start auto training, and to change it later. It opens pre-filled from the plan;
/// Start saves it, and a typed maximum goes through the account's heart-rate rules on the server.
@riverpod
class TrainingSetupViewModel extends _$TrainingSetupViewModel {
  @override
  TrainingSetupState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const TrainingSetupState();
    }
    Future.microtask(load);
    return const TrainingSetupState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(trainingDataProvider).plan();
    if (!ref.mounted) return;
    final plan = result.valueOrNull;
    state = plan == null
        ? state.copyWith(load: state.load.finish(result))
        : _filled(plan).copyWith(load: state.load.finish(result));
  }

  void setGoal(String goal) => state = state.copyWith(goal: goal);

  void toggleDay(String day) {
    final days = {...state.days};
    if (!days.remove(day)) days.add(day);
    state = state.copyWith(
      days: days,
      // The long ride cannot stay on a day the rider just turned off.
      clearLongRideDay:
          state.longRideDay != null && !days.contains(state.longRideDay),
      clearProblem: true,
    );
  }

  void setHours(String hours) => state = state.copyWith(hours: hours);

  void setLongRideDay(String? day) =>
      state = state.copyWith(longRideDay: day, clearLongRideDay: day == null);

  void setMaxHeartRateUnknown(bool unknown) =>
      state = state.copyWith(maxHeartRateUnknown: unknown);

  void setMaxHeartRate(String value) =>
      state = state.copyWith(maxHeartRate: value);

  void setBirthYear(String value) => state = state.copyWith(birthYear: value);

  /// Saves the setup and turns auto training on. Returns whether it was saved; a problem stays on the state for
  /// the view to show above the form.
  Future<bool> start() async {
    if (state.save.running) return false;
    final problem = _problem();
    if (problem != null) {
      state = state.copyWith(problem: problem);
      return false;
    }

    state = state.copyWith(save: state.save.start());
    final result = await ref
        .read(trainingDataProvider)
        .save(
          SaveTrainingPlanRequest(
            goal: state.goal ?? 'fitter',
            days: orderedDays(state.days),
            hoursPerWeek: int.parse(state.hours),
            longRideDay: state.longRideDay,
            maxHeartRateKnown: !state.maxHeartRateUnknown,
            maxHeartRate: state.maxHeartRateUnknown
                ? null
                : int.tryParse(state.maxHeartRate),
            birthYear: int.tryParse(state.birthYear),
            timeZone: null,
            // The phone reports only its offset; the server keeps the zone that matches it.
            // shortcut: an exact IANA name needs a package or a native channel, when one is approved.
            utcOffsetMinutes: Optional.present(
              DateTime.now().timeZoneOffset.inMinutes,
            ),
          ),
        );
    if (!ref.mounted) return false;
    state = state.copyWith(save: state.save.finish(result));
    if (result case Ok(:final value?)) {
      ref.read(trainingViewModelProvider.notifier).adopt(value);
      return true;
    }
    return false;
  }

  /// The form as the plan left it: last time's answers, or the suggestion and nothing else.
  TrainingSetupState _filled(TrainingPlanResponse plan) => TrainingSetupState(
    goal: plan.goal ?? plan.suggestedGoal,
    suggestedGoal: plan.suggestedGoal,
    suggestionReason: plan.suggestionReason,
    days: plan.days.toSet(),
    hours: plan.hoursPerWeek?.toString() ?? '',
    longRideDay: plan.longRideDay,
    // "I don't know" is on until a number was typed or measured.
    maxHeartRateUnknown:
        plan.maxHeartRateSource == null ||
        plan.maxHeartRateSource == 'estimate',
    maxHeartRate: plan.maxHeartRate?.toString() ?? '',
    birthYear: plan.birthYear?.toString() ?? '',
    needsBirthYear: plan.birthYear == null,
    nextEventName: plan.nextEventName,
    nextEventDate: plan.nextEventDate == null
        ? null
        : DateTime(
            plan.nextEventDate!.year,
            plan.nextEventDate!.month,
            plan.nextEventDate!.day,
          ),
  );

  /// The first thing that stops Start, in the order the form asks for it.
  TrainingSetupProblem? _problem() {
    if (state.days.isEmpty) return TrainingSetupProblem.days;
    final hours = int.tryParse(state.hours);
    if (hours == null || hours < 1 || hours > 30) {
      return TrainingSetupProblem.hours;
    }
    if (!state.maxHeartRateUnknown) {
      final max = int.tryParse(state.maxHeartRate);
      if (max == null || max < 120 || max > 220) {
        return TrainingSetupProblem.maxHeartRate;
      }
    }
    final birthYear = int.tryParse(state.birthYear);
    if (state.needsBirthYear &&
        (birthYear == null ||
            birthYear < 1900 ||
            birthYear > DateTime.now().year - 10)) {
      return TrainingSetupProblem.birthYear;
    }
    return null;
  }
}
