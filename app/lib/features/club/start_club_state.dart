import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/location_service.dart';

/// The form for starting a club: where it meets, whether riders nearby may find it, and how the request went.
class StartClubState {
  const StartClubState({
    this.point,
    this.isDiscoverable = false,
    this.create = const CommandState.idle(),
  });

  final GeoPoint? point;
  final bool isDiscoverable;
  final CommandState<MyClubResponse?> create;

  StartClubState copyWith({
    GeoPoint? point,
    bool? isDiscoverable,
    CommandState<MyClubResponse?>? create,
  }) => StartClubState(
    point: point ?? this.point,
    isDiscoverable: isDiscoverable ?? this.isDiscoverable,
    create: create ?? this.create,
  );
}
