import 'package:flutter/foundation.dart';

import 'recorder.dart';

/// Recorder diagnostics, visible in a debug build only.
///
/// Filter the log with `adb logcat -s flutter | grep VelomineRecorder` or watch the `flutter run` console.
void recorderLog(String message) {
  if (kDebugMode) debugPrint('VelomineRecorder: $message');
}

String describeSnapshot(String label, Map<String, dynamic> map) =>
    '$label state=${map['state']} ride=${map['rideId']} '
    'startedAt=${map['startedAt']} elapsed=${map['elapsedS']} '
    'moving=${map['movingS']} distance=${map['distanceM']} '
    'speed=${map['speedMs']} accuracy=${map['accuracyM']} error=${map['error']}';

String describeRide(LocalRide ride) =>
    'id=${ride.id} state=${ride.state} startedAt=${ride.startedAt} '
    'endedAt=${ride.endedAt} distance=${ride.distanceM} moving=${ride.movingS} '
    'error=${ride.error}';
