import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'progress_data.g.dart';

/// The analytics, goals and wellbeing endpoints as values.
class ProgressData {
  ProgressData(this._api, this._accounts, this._wellbeing, this.dateLookup);

  final AnalyticsApi _api;
  final AccountsApi _accounts;
  final WellbeingApi _wellbeing;

  /// When a ride started, by its id: the FTP history dates a test by its ride, not by the day it was accepted.
  final Future<DateTime?> Function(String rideId) dateLookup;

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

  Future<Result<void>> setFtp(int watts, {String source = 'manual'}) =>
      _accounts
          .setFtp(SetFtpRequest(ftpW: watts, source_: Optional.present(source)))
          .guard(FailureAction.setFtp);

  /// Every FTP the member has had, newest first.
  Future<Result<FtpHistoryResponse?>> ftpHistory() =>
      _accounts.getFtpHistory().guard(FailureAction.loadProgress);

  /// Whether the FTP may be out of date, and why; null reason means nothing to say.
  Future<Result<FtpCheckResponse?>> ftpCheck() =>
      _api.getFtpCheck().guard(FailureAction.loadProgress);

  /// Keeps the reminder quiet for two weeks.
  Future<Result<void>> snoozeFtpCheck() =>
      _api.snoozeFtpCheck().guard(FailureAction.setFtp);

  /// The FTP the newest ride suggests; null when there is nothing open.
  Future<Result<FtpSuggestionResponse?>> ftpSuggestion() =>
      _api.getFtpSuggestion().guard(FailureAction.loadProgress);

  /// The day of each ride the history names, for the day a test FTP really happened on.
  /// A ride that cannot be read simply has no day: the note then falls back to the day it was set.
  Future<Result<Map<String, DateTime>>> ftpRideDates(
    FtpHistoryResponse history,
  ) async {
    final dates = <String, DateTime>{};
    for (final id in history.entries.map((e) => e.rideId).whereType<String>()) {
      if (await dateLookup(id) case final start?) dates[id] = start;
    }
    return Ok(dates);
  }

  /// Adopts a ride's suggestion: the server sets the FTP and records the ride it came from.
  Future<Result<ProfileResponse?>> acceptFtpSuggestion(String id) =>
      _api.acceptFtpSuggestion(id).guard(FailureAction.setFtp);

  Future<Result<void>> dismissFtpSuggestion(String id) =>
      _api.dismissFtpSuggestion(id).guard(FailureAction.setFtp);

  /// The member's open heart-rate suggestions, one per number at most.
  Future<Result<List<HeartRateSuggestionResponse>>>
  heartRateSuggestions() async => (await _api.listHeartRateSuggestions().guard(
    FailureAction.loadProgress,
  )).map((list) => list?.suggestions ?? const <HeartRateSuggestionResponse>[]);

  /// The member's profile, for the value a heart-rate suggestion is above.
  Future<Result<ProfileResponse?>> profile() =>
      _accounts.getProfile().guard(FailureAction.loadProgress);

  /// Adopts a ride's heart-rate suggestion: the number becomes measured, from that ride.
  Future<Result<ProfileResponse?>> acceptHeartRateSuggestion(String id) =>
      _api.acceptHeartRateSuggestion(id).guard(FailureAction.saveProfile);

  Future<Result<void>> dismissHeartRateSuggestion(String id) =>
      _api.dismissHeartRateSuggestion(id).guard(FailureAction.saveProfile);
}

@Riverpod(keepAlive: true)
ProgressData progressData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return ProgressData(
    session.analytics,
    session.accounts,
    session.wellbeing,
    (id) async => (await session.rides.getRide(id))?.startTime,
  );
}
