import 'incoming_batch.dart';
import 'incoming_source.dart';

/// The web: no app can share a file to it.
IncomingSource createPlatformIncomingSource() => const _NoIncomingSource();

class _NoIncomingSource implements IncomingSource {
  const _NoIncomingSource();

  @override
  Stream<IncomingBatch> get batches => const Stream.empty();

  @override
  void dispose() {}
}
