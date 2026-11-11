import 'incoming_batch.dart';
import 'incoming_source_stub.dart'
    if (dart.library.io) 'incoming_source_io.dart';

/// Ride files that other apps handed to Velomine: Share, and Open with.
///
/// The phone copies them into its own storage before Flutter sees them, so this only reports what arrived.
abstract interface class IncomingSource {
  /// One event per batch of received files, including the ones received while the app was closed.
  Stream<IncomingBatch> get batches;

  void dispose();
}

IncomingSource createIncomingSource() => createPlatformIncomingSource();
