import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/guard.dart';

/// How many periods the totals show: about a quarter of weeks, a year of months, five years.
const periodCounts = {'week': 12, 'month': 12, 'year': 5};

/// Totals per week, month or year, goals, the training dashboard, the power curve, readiness and wellbeing.
class ProgressController extends ChangeNotifier {
  ProgressController({
    required this.api,
    required this.accounts,
    required this.wellbeing,
    required this.onUnauthorized,
  });

  final AnalyticsApi api;
  final AccountsApi accounts;
  final WellbeingApi wellbeing;
  final VoidCallback onUnauthorized;

  String period = 'week';
  int trainingDays = 90;
  int powerDays = 90;
  String? discipline;
  TotalsResponse? totals;
  TrainingResponse? training;
  PowerCurveResponse? powerCurve;
  ReadinessResponse? readiness;
  WellbeingResponse? wellbeingToday;
  CheckInsResponse? checkIns;
  List<GoalResponse> goals = [];
  bool loading = false;
  bool savingWellbeing = false;
  Failure? error;

  /// A slow earlier load must not overwrite a range the member picked last.
  int _loadToken = 0;

  Future<void> refresh() async {
    final token = ++_loadToken;
    loading = true;
    error = null;
    notifyListeners();

    final failure = await guardCall(
      () async {
        final results = await Future.wait([
          api.getTotals(
            period,
            count: periodCounts[period],
            discipline: discipline,
          ),
          api.listGoals(),
          api.getTraining(days: trainingDays, discipline: discipline),
          api.getPowerCurve(days: powerDays),
          api.getReadiness(),
          wellbeing.getWellbeing(),
        ]);
        if (token != _loadToken) return;

        final today = results[5] as WellbeingResponse?;
        CheckInsResponse? history;
        if (today?.consented == true) {
          try {
            history = await wellbeing.listCheckIns(days: 30);
          } on ApiException catch (e) {
            if (e.code == 401) onUnauthorized();
            history = null;
          } on Object {
            history =
                null; // the check-in itself still shows; history is optional
          }
        }

        totals = results[0] as TotalsResponse?;
        goals = (results[1] as ListGoalsResponse?)?.goals ?? [];
        training = results[2] as TrainingResponse?;
        powerCurve = results[3] as PowerCurveResponse?;
        readiness = results[4] as ReadinessResponse?;
        wellbeingToday = today;
        checkIns = history;
      },
      onUnauthorized,
      doing: FailureAction.loadProgress,
    );

    if (token != _loadToken) return;
    error = failure;
    loading = false;
    notifyListeners();
  }

  Future<void> setPeriod(String value) async {
    if (value == period) return;
    period = value;
    totals = null;
    await refresh();
  }

  /// Shows only one surface in the totals and the training dashboard, or every ride when [value] is null.
  Future<void> setDiscipline(String? value) async {
    if (value == discipline) return;
    discipline = value;
    totals = null;
    training = null;
    await refresh();
  }

  Future<void> setTrainingDays(int value) async {
    if (value == trainingDays) return;
    trainingDays = value;
    training = null;
    await refresh();
  }

  Future<void> setPowerDays(int value) async {
    if (value == powerDays) return;
    powerDays = value;
    powerCurve = null;
    await refresh();
  }

  /// Accepts the wellbeing terms. Health data is not stored before this.
  Future<bool> giveWellbeingConsent() async {
    savingWellbeing = true;
    error = null;
    notifyListeners();
    final failure = await guardCall(
      () => wellbeing.giveWellbeingConsent(
        WellbeingConsentRequest(accepted: true),
      ),
      onUnauthorized,
      doing: FailureAction.saveWellbeing,
    );
    savingWellbeing = false;
    if (failure != null) {
      error = failure;
      notifyListeners();
      return false;
    }
    await refresh();
    return error == null;
  }

  /// Saves today's check-in, then reloads readiness so the card follows immediately.
  Future<bool> saveCheckIn(
    int fatigue,
    int soreness,
    int mood,
    int stress,
    int motivation,
  ) async {
    savingWellbeing = true;
    error = null;
    notifyListeners();
    final failure = await guardCall(
      () => wellbeing.saveCheckIn(
        SaveCheckInRequest(
          fatigue: fatigue,
          soreness: soreness,
          mood: mood,
          stress: stress,
          motivation: motivation,
        ),
      ),
      onUnauthorized,
      doing: FailureAction.saveWellbeing,
    );
    savingWellbeing = false;
    if (failure != null) {
      error = failure;
      notifyListeners();
      return false;
    }
    await refresh();
    return error == null;
  }

  /// Adopts the suggested FTP. Past TSS stays as it was; zones and new load use the new value.
  Future<bool> useFtp(int watts) async {
    final failure = await guardCall(
      () => accounts.setFtp(SetFtpRequest(ftpW: watts)),
      onUnauthorized,
      doing: FailureAction.setFtp,
    );
    if (failure != null) {
      error = failure;
      notifyListeners();
      return false;
    }
    await refresh();
    return error == null;
  }

  Future<bool> addGoal(CreateGoalRequest goal) async {
    error = await guardCall(
      () => api.createGoal(goal),
      onUnauthorized,
      doing: FailureAction.addGoal,
    );
    return _afterChange();
  }

  Future<bool> setTarget(String id, double target) async {
    error = await guardCall(
      () => api.updateGoal(id, UpdateGoalRequest(target: target)),
      onUnauthorized,
      doing: FailureAction.changeGoal,
    );
    return _afterChange();
  }

  Future<bool> deleteGoal(String id) async {
    error = await guardCall(
      () => api.deleteGoal(id),
      onUnauthorized,
      doing: FailureAction.deleteGoal,
    );
    return _afterChange();
  }

  Future<bool> _afterChange() async {
    final ok = error == null;
    if (ok) {
      final list = await api.listGoals().catchError((_) => null);
      if (list != null) goals = list.goals;
    }
    notifyListeners();
    return ok;
  }
}
