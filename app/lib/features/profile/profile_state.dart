import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's profile, and the operations on it.
class ProfileState {
  const ProfileState({
    this.profile,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.export = const CommandState.idle(),
    this.delete = const CommandState.idle(),
    this.password = const CommandState.idle(),
    this.messages = const [],
  });

  final ProfileResponse? profile;
  final CommandState<ProfileResponse?> load;
  final VoidCommand save;
  final VoidCommand export;
  final VoidCommand delete;
  final VoidCommand password;
  final List<UserMessage> messages;

  ProfileState copyWith({
    ProfileResponse? profile,
    CommandState<ProfileResponse?>? load,
    VoidCommand? save,
    VoidCommand? export,
    VoidCommand? delete,
    VoidCommand? password,
    List<UserMessage>? messages,
  }) => ProfileState(
    profile: profile ?? this.profile,
    load: load ?? this.load,
    save: save ?? this.save,
    export: export ?? this.export,
    delete: delete ?? this.delete,
    password: password ?? this.password,
    messages: messages ?? this.messages,
  );
}
