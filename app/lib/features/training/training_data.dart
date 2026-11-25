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
}

@Riverpod(keepAlive: true)
TrainingData trainingData(Ref ref) =>
    TrainingData(ref.watch(sessionProvider).training);
