import 'recorder.dart';
import 'recorder_stub.dart' if (dart.library.io) 'recorder_io.dart' as platform;

Recorder createRecorder() => platform.createRecorder();
