import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'training_data.g.dart';

/// The auto-training endpoints as values: the ViewModels never see an exception.
class TrainingData {
  TrainingData(this._api);

  final TrainingApi _api;

  Future<Result<TrainingPlanResponse?>> plan() =>
      _api.getTrainingPlan().guard(FailureAction.loadTraining);

  /// This week and, on its last day, next week as the preview. The server answers 404 while auto training is off.
  Future<Result<TrainingWeeksResponse?>> week() =>
      _api.getTrainingWeek().guard(FailureAction.loadTraining);

  Future<Result<TrainingPlanResponse?>> save(SaveTrainingPlanRequest request) =>
      _api.saveTrainingPlan(request).guard(FailureAction.saveTrainingPlan);

  Future<Result<TrainingPlanResponse?>> turnOff() =>
      _api.turnOffTrainingPlan().guard(FailureAction.turnOffTraining);

  /// Answers "Was this your …?" and takes a ride back off a session, in one call.
  Future<Result<void>> answer(String sessionId, String rideId, bool yes) => _api
      .matchTrainingSession(
        sessionId,
        MatchTrainingSessionRequest(rideId: rideId, answer: yes ? 'yes' : 'no'),
      )
      .guard(FailureAction.matchTrainingSession);

  /// "Make today easy": today's hard session becomes an endurance one. The answer is the week as it is now.
  Future<Result<TrainingWeeksResponse?>> makeEasy(String sessionId) =>
      _api.makeSessionEasy(sessionId).guard(FailureAction.makeTrainingEasy);

  /// "Back to the plan": the hard session comes back, the same day, as long as nothing ticked it.
  Future<Result<TrainingWeeksResponse?>> backToPlan(String sessionId) => _api
      .backToTrainingPlan(sessionId)
      .guard(FailureAction.backToTrainingPlan);

  /// Moving a session to another day left this week; a day the week refuses comes back as a conflict.
  Future<Result<TrainingWeeksResponse?>> move(
    String sessionId,
    DateTime localDate,
  ) => _api
      .moveTrainingSession(
        sessionId,
        MoveTrainingSessionRequest(localDate: localDate),
      )
      .guard(FailureAction.moveTrainingSession);

  /// Skipping a session, or the rest of the week after it. The answer says whether to ask about the rest.
  Future<Result<SkipTrainingSessionResponse?>> skip(
    String sessionId, {
    String? reason,
    bool restOfWeek = false,
  }) => _api
      .skipTrainingSession(
        sessionId,
        SkipTrainingSessionRequest(
          reason: Optional.present(reason),
          restOfWeek: Optional.present(restOfWeek),
        ),
      )
      .guard(FailureAction.skipTrainingSession);
}

@Riverpod(keepAlive: true)
TrainingData trainingData(Ref ref) =>
    TrainingData(ref.watch(sessionProvider).training);
