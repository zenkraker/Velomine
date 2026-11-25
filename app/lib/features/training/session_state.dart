import 'package:velomine_api/api.dart';

import '../../core/command.dart';

/// One planned session as its page reads it: the session from the week, and how loading that week went.
class SessionState {
  const SessionState({this.session, this.week = const CommandState.idle()});

  final TrainingWeekSession? session;
  final CommandState<TrainingWeeksResponse?> week;
}
