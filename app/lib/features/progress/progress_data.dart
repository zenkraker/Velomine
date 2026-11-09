import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'progress_data.g.dart';

/// The analytics, goals and wellbeing endpoints as values.
class ProgressData {
  ProgressData(this._api, this._accounts, this._wellbeing);

  final AnalyticsApi _api;
  final AccountsApi _accounts;
  final WellbeingApi _wellbeing;

  Future<Result<TotalsResponse?>> totals(
    String period,
    int count,
    String? discipline,
  ) => _api
      .getTotals(period, count: count, discipline: discipline)
      .guard(FailureAction.loadProgress);

  Future<Result<ListGoalsResponse?>> goals() =>
      _api.listGoals().guard(FailureAction.loadProgress);

  Future<Result<GoalResponse?>> addGoal(CreateGoalRequest goal) =>
      _api.createGoal(goal).guard(FailureAction.addGoal);

  Future<Result<GoalResponse?>> setTarget(String id, double target) => _api
      .updateGoal(id, UpdateGoalRequest(target: target))
      .guard(FailureAction.changeGoal);

  Future<Result<void>> deleteGoal(String id) =>
      _api.deleteGoal(id).guard(FailureAction.deleteGoal);

  Future<Result<TrainingResponse?>> training(int days, String? discipline) =>
      _api
          .getTraining(days: days, discipline: discipline)
          .guard(FailureAction.loadProgress);

  Future<Result<PowerCurveResponse?>> powerCurve(int days) =>
      _api.getPowerCurve(days: days).guard(FailureAction.loadProgress);

  Future<Result<ReadinessResponse?>> readiness() =>
      _api.getReadiness().guard(FailureAction.loadProgress);

  Future<Result<WellbeingResponse?>> wellbeing() =>
      _wellbeing.getWellbeing().guard(FailureAction.loadProgress);

  Future<Result<CheckInsResponse?>> checkIns(int days) =>
      _wellbeing.listCheckIns(days: days).guard(FailureAction.loadProgress);

  Future<Result<void>> giveConsent() => _wellbeing
      .giveWellbeingConsent(WellbeingConsentRequest(accepted: true))
      .guard(FailureAction.saveWellbeing);

  Future<Result<WellbeingResponse?>> withdrawConsent() =>
      _wellbeing.withdrawWellbeingConsent().guard(FailureAction.saveWellbeing);

  Future<Result<void>> saveCheckIn(SaveCheckInRequest checkIn) =>
      _wellbeing.saveCheckIn(checkIn).guard(FailureAction.saveWellbeing);

  Future<Result<void>> setFtp(int watts) =>
      _accounts.setFtp(SetFtpRequest(ftpW: watts)).guard(FailureAction.setFtp);
}

@Riverpod(keepAlive: true)
ProgressData progressData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return ProgressData(session.analytics, session.accounts, session.wellbeing);
}
