import 'drop_source.dart';
import 'ride_file.dart';

/// The phone: no drag and drop, no folder chooser.
DropSource createPlatformDropSource() => const _NoDropSource();

class _NoDropSource implements DropSource {
  const _NoDropSource();

  @override
  bool get supported => false;

  @override
  Stream<bool> get dragging => const Stream.empty();

  @override
  Stream<Future<List<RideFileEntry>>> get drops => const Stream.empty();

  @override
  Future<List<RideFileEntry>> pickFolder() async => const [];

  @override
  Future<List<RideFileEntry>> pickFiles() async => const [];

  @override
  void dispose() {}
}
