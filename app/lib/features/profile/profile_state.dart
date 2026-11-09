import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's profile, and the operations on it.
class ProfileState {
  const ProfileState({
    this.profile,
    this.telemetry,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.telemetrySave = const CommandState.idle(),
    this.export = const CommandState.idle(),
    this.delete = const CommandState.idle(),
    this.password = const CommandState.idle(),
    this.messages = const [],
  });

  final ProfileResponse? profile;
  final TelemetryResponse? telemetry;
  final CommandState<ProfileResponse?> load;
  final VoidCommand save;
  final CommandState<TelemetryResponse?> telemetrySave;
  final VoidCommand export;
  final VoidCommand delete;
  final VoidCommand password;
  final List<UserMessage> messages;

  ProfileState copyWith({
    ProfileResponse? profile,
    TelemetryResponse? telemetry,
    CommandState<ProfileResponse?>? load,
    VoidCommand? save,
    CommandState<TelemetryResponse?>? telemetrySave,
    VoidCommand? export,
    VoidCommand? delete,
    VoidCommand? password,
    List<UserMessage>? messages,
  }) => ProfileState(
    profile: profile ?? this.profile,
    telemetry: telemetry ?? this.telemetry,
    load: load ?? this.load,
    save: save ?? this.save,
    telemetrySave: telemetrySave ?? this.telemetrySave,
    export: export ?? this.export,
    delete: delete ?? this.delete,
    password: password ?? this.password,
    messages: messages ?? this.messages,
  );
}
