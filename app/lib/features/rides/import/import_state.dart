import 'package:velomine_api/api.dart';

import '../../../core/command.dart';

/// One import, followed until the server has read every activity.
class ImportState {
  const ImportState({this.load = const CommandState.idle()});

  final CommandState<RideImportResponse?> load;

  ImportState copyWith({CommandState<RideImportResponse?>? load}) =>
      ImportState(load: load ?? this.load);
}
