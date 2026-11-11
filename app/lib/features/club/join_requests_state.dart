import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// What the club's owner has to answer: riders who asked to join.
class JoinRequestsState {
  const JoinRequestsState({
    this.requests = const [],
    this.admissionBlocked,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<JoinRequestResponse> requests;

  /// "full" or "ended" when the club cannot take another member now, otherwise null.
  final String? admissionBlocked;
  final CommandState<JoinRequestsResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  JoinRequestsState copyWith({
    List<JoinRequestResponse>? requests,
    String? admissionBlocked,
    bool clearAdmissionBlocked = false,
    CommandState<JoinRequestsResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => JoinRequestsState(
    requests: requests ?? this.requests,
    admissionBlocked: clearAdmissionBlocked
        ? null
        : admissionBlocked ?? this.admissionBlocked,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
