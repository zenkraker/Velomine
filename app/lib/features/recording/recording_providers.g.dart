// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Uploads finished local rides, one at a time per ride. Kept alive with the
/// session so leaving the Record screen does not stop an upload.

@ProviderFor(uploadQueue)
final uploadQueueProvider = UploadQueueProvider._();

/// Uploads finished local rides, one at a time per ride. Kept alive with the
/// session so leaving the Record screen does not stop an upload.

final class UploadQueueProvider
    extends
        $FunctionalProvider<
          RideUploadQueue?,
          RideUploadQueue?,
          RideUploadQueue?
        >
    with $Provider<RideUploadQueue?> {
  /// Uploads finished local rides, one at a time per ride. Kept alive with the
  /// session so leaving the Record screen does not stop an upload.
  UploadQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadQueueHash();

  @$internal
  @override
  $ProviderElement<RideUploadQueue?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RideUploadQueue? create(Ref ref) {
    return uploadQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideUploadQueue? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideUploadQueue?>(value),
    );
  }
}

String _$uploadQueueHash() => r'7e92a33770f163d3df59e73dae0b51914027bc9a';

/// The upload queue's state as a stream: one subscription for every screen that
/// shows upload progress. Empty on the web, which has no recorder.

@ProviderFor(uploadStates)
final uploadStatesProvider = UploadStatesProvider._();

/// The upload queue's state as a stream: one subscription for every screen that
/// shows upload progress. Empty on the web, which has no recorder.

final class UploadStatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, UploadState>>,
          Map<String, UploadState>,
          Stream<Map<String, UploadState>>
        >
    with
        $FutureModifier<Map<String, UploadState>>,
        $StreamProvider<Map<String, UploadState>> {
  /// The upload queue's state as a stream: one subscription for every screen that
  /// shows upload progress. Empty on the web, which has no recorder.
  UploadStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadStatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadStatesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, UploadState>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, UploadState>> create(Ref ref) {
    return uploadStates(ref);
  }
}

String _$uploadStatesHash() => r'25b59fe765634012e71c1bf29ebc65f2dcd23aab';

/// One subscription to the recorder's broadcast stream, shared by the title bar
/// and the Record screen.

@ProviderFor(RecorderSnapshotViewModel)
final recorderSnapshotViewModelProvider = RecorderSnapshotViewModelProvider._();

/// One subscription to the recorder's broadcast stream, shared by the title bar
/// and the Record screen.
final class RecorderSnapshotViewModelProvider
    extends $NotifierProvider<RecorderSnapshotViewModel, RecorderSnapshot> {
  /// One subscription to the recorder's broadcast stream, shared by the title bar
  /// and the Record screen.
  RecorderSnapshotViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recorderSnapshotViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recorderSnapshotViewModelHash();

  @$internal
  @override
  RecorderSnapshotViewModel create() => RecorderSnapshotViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecorderSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecorderSnapshot>(value),
    );
  }
}

String _$recorderSnapshotViewModelHash() =>
    r'e70740737980af978f4717beec73c8b03b45d703';

/// One subscription to the recorder's broadcast stream, shared by the title bar
/// and the Record screen.

abstract class _$RecorderSnapshotViewModel extends $Notifier<RecorderSnapshot> {
  RecorderSnapshot build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecorderSnapshot, RecorderSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecorderSnapshot, RecorderSnapshot>,
              RecorderSnapshot,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
