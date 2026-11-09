import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// What the club's owner has to answer: riders who asked to join.
class JoinRequestsState {
  const JoinRequestsState({
    this.requests = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<JoinRequestResponse> requests;
  final CommandState<JoinRequestsResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  JoinRequestsState copyWith({
    List<JoinRequestResponse>? requests,
    CommandState<JoinRequestsResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => JoinRequestsState(
    requests: requests ?? this.requests,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
