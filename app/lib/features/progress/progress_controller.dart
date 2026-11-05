import 'package:flutter/foundation.dart';
import 'package:velomine_api/api.dart';

import '../../core/guard.dart';

/// How many periods the totals show: about a quarter of weeks, a year of months, five years.
const periodCounts = {'week': 12, 'month': 12, 'year': 5};

/// Totals per week, month or year, and the member's goals with their progress.
class ProgressController extends ChangeNotifier {
  ProgressController({required this.api, required this.onUnauthorized});

  final AnalyticsApi api;
  final VoidCallback onUnauthorized;

  String period = 'week';
  TotalsResponse? totals;
  List<GoalResponse> goals = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    error = await guardCall(
      () async {
        final results = await Future.wait([
          api.getTotals(period, count: periodCounts[period]),
          api.listGoals(),
        ]);
        totals = results[0] as TotalsResponse?;
        goals = (results[1] as ListGoalsResponse?)?.goals ?? [];
      },
      onUnauthorized,
      what: 'load your progress',
    );
    loading = false;
    notifyListeners();
  }

  Future<void> setPeriod(String value) async {
    if (value == period) return;
    period = value;
    totals = null;
    await refresh();
  }

  Future<bool> addGoal(CreateGoalRequest goal) async {
    error = await guardCall(
      () => api.createGoal(goal),
      onUnauthorized,
      what: 'add the goal',
    );
    return _afterChange();
  }

  Future<bool> setTarget(String id, double target) async {
    error = await guardCall(
      () => api.updateGoal(id, UpdateGoalRequest(target: target)),
      onUnauthorized,
      what: 'change the goal',
    );
    return _afterChange();
  }

  Future<bool> deleteGoal(String id) async {
    error = await guardCall(
      () => api.deleteGoal(id),
      onUnauthorized,
      what: 'delete the goal',
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
