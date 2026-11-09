import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lap_range.dart';

/// The moment and the lap selected on a ride, shared by the charts, the map and
/// the lap table. Kept outside the ViewModel state so a hover only rebuilds the
/// charts that listen, not the screen.
class RideSelection {
  final selected = ValueNotifier<int?>(null);
  final selectedLap = ValueNotifier<LapRange?>(null);

  void dispose() {
    selected.dispose();
    selectedLap.dispose();
  }
}

final rideSelectionProvider = Provider.family<RideSelection, String>((
  ref,
  key,
) {
  final selection = RideSelection();
  ref.onDispose(selection.dispose);
  return selection;
}, isAutoDispose: true);
