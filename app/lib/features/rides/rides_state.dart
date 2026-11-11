import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';
import 'rides_data.dart';

/// The member's rides, the page cursor and the surface on show.
class RidesState {
  const RidesState({
    this.rides = const [],
    this.next,
    this.disciplineFilter,
    this.load = const CommandState.idle(),
    this.upload = const CommandState.idle(),
    this.import = const CommandState.idle(),
    this.messages = const [],
  });

  final List<RideResponse> rides;

  /// The cursor for the next page, or null when every ride is shown.
  final String? next;

  /// The surface on show, or null for every ride.
  final String? disciplineFilter;

  final CommandState<RidesPage> load;
  final VoidCommand upload;
  final CommandState<String?> import;
  final List<UserMessage> messages;

  bool get loading => load.running;

  RidesState copyWith({
    List<RideResponse>? rides,
    String? next,
    bool clearNext = false,
    String? disciplineFilter,
    bool clearDisciplineFilter = false,
    CommandState<RidesPage>? load,
    VoidCommand? upload,
    CommandState<String?>? import,
    List<UserMessage>? messages,
  }) => RidesState(
    rides: rides ?? this.rides,
    next: clearNext ? null : (next ?? this.next),
    disciplineFilter: clearDisciplineFilter
        ? null
        : (disciplineFilter ?? this.disciplineFilter),
    load: load ?? this.load,
    upload: upload ?? this.upload,
    import: import ?? this.import,
    messages: messages ?? this.messages,
  );
}
