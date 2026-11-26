import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';
import 'rides_data.dart';

/// A first and a last day, both included.
typedef DateSpan = ({DateTime from, DateTime to});

/// The member's rides, the page cursor and the filters on show.
class RidesState {
  const RidesState({
    this.rides = const [],
    this.next,
    this.disciplineFilter,
    this.environmentFilter,
    this.commuteFilter,
    this.query = '',
    this.dateRange,
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

  /// Where the ride happened on show (a trainer, `indoor`), or null for everywhere.
  final String? environmentFilter;

  /// The commutes only when true; every ride when null.
  final bool? commuteFilter;

  /// Words the title or description must contain; empty for every ride.
  final String query;

  /// The days to show, or null for every day.
  final DateSpan? dateRange;

  /// Whether any filter narrows the list.
  bool get filtered =>
      disciplineFilter != null ||
      environmentFilter != null ||
      commuteFilter != null ||
      query.trim().isNotEmpty ||
      dateRange != null;

  final CommandState<RidesPage> load;
  final VoidCommand upload;
  final CommandState<String?> import;
  final List<UserMessage> messages;

  bool get loading => load.running;

  /// No ride has arrived yet and the load has not failed: placeholder rows, also on the first frame before
  /// the load starts, so the page is never header-only.
  bool get waiting =>
      rides.isEmpty && !filtered && load.failure == null && !load.completed;

  RidesState copyWith({
    List<RideResponse>? rides,
    String? next,
    bool clearNext = false,
    String? disciplineFilter,
    bool clearDisciplineFilter = false,
    String? environmentFilter,
    bool clearEnvironmentFilter = false,
    bool? commuteFilter,
    bool clearCommuteFilter = false,
    String? query,
    DateSpan? dateRange,
    bool clearDateRange = false,
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
    environmentFilter: clearEnvironmentFilter
        ? null
        : (environmentFilter ?? this.environmentFilter),
    commuteFilter: clearCommuteFilter
        ? null
        : (commuteFilter ?? this.commuteFilter),
    query: query ?? this.query,
    dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    load: load ?? this.load,
    upload: upload ?? this.upload,
    import: import ?? this.import,
    messages: messages ?? this.messages,
  );
}
