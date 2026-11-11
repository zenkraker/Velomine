import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The signed-in account's club. One account belongs to one club, so a single
/// club is the whole state.
class ClubState {
  const ClubState({
    this.club,
    this.canStartClub = false,
    this.loaded = false,
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final ClubResponse? club;

  /// True for a rider without a club on a server that lets riders start one.
  final bool canStartClub;

  /// True once the server has answered: only then can the app tell "no club"
  /// from "not asked yet".
  final bool loaded;

  final CommandState<MyClubResponse?> load;

  /// Join, leave, new code, role and location changes share one command, so
  /// every button is disabled while any of them runs.
  final VoidCommand action;

  final List<UserMessage> messages;

  ClubState copyWith({
    ClubResponse? club,
    bool? canStartClub,
    bool? loaded,
    CommandState<MyClubResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => ClubState(
    club: club ?? this.club,
    canStartClub: canStartClub ?? this.canStartClub,
    loaded: loaded ?? this.loaded,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}
