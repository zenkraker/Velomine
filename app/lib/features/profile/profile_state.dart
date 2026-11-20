import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';

/// The member's profile, and the operations on it.
class ProfileState {
  const ProfileState({
    this.profile,
    this.telemetry,
    this.zones,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.telemetrySave = const CommandState.idle(),
    this.export = const CommandState.idle(),
    this.delete = const CommandState.idle(),
    this.password = const CommandState.idle(),
    this.heartRate = const CommandState.idle(),
    this.zonesSave = const CommandState.idle(),
    this.messages = const [],
  });

  final ProfileResponse? profile;
  final TelemetryResponse? telemetry;

  /// The zones in use, for every set, and the heart-rate model they are read against.
  final ZonesResponse? zones;
  final CommandState<ProfileResponse?> load;
  final VoidCommand save;
  final CommandState<TelemetryResponse?> telemetrySave;
  final VoidCommand export;
  final VoidCommand delete;
  final VoidCommand password;

  /// Setting or clearing one heart-rate number.
  final CommandState<ProfileResponse?> heartRate;

  /// Saving or resetting the rider's own zone bounds.
  final CommandState<ZonesResponse?> zonesSave;
  final List<UserMessage> messages;

  ProfileState copyWith({
    ProfileResponse? profile,
    TelemetryResponse? telemetry,
    ZonesResponse? zones,
    CommandState<ProfileResponse?>? load,
    VoidCommand? save,
    CommandState<TelemetryResponse?>? telemetrySave,
    VoidCommand? export,
    VoidCommand? delete,
    VoidCommand? password,
    CommandState<ProfileResponse?>? heartRate,
    CommandState<ZonesResponse?>? zonesSave,
    List<UserMessage>? messages,
  }) => ProfileState(
    profile: profile ?? this.profile,
    telemetry: telemetry ?? this.telemetry,
    zones: zones ?? this.zones,
    load: load ?? this.load,
    save: save ?? this.save,
    telemetrySave: telemetrySave ?? this.telemetrySave,
    export: export ?? this.export,
    delete: delete ?? this.delete,
    password: password ?? this.password,
    heartRate: heartRate ?? this.heartRate,
    zonesSave: zonesSave ?? this.zonesSave,
    messages: messages ?? this.messages,
  );
}
