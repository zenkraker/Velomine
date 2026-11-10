// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the recording screen. The native service keeps recording when this
/// screen is closed; opening it again reads the live state back.

@ProviderFor(RecordingViewModel)
final recordingViewModelProvider = RecordingViewModelProvider._();

/// Drives the recording screen. The native service keeps recording when this
/// screen is closed; opening it again reads the live state back.
final class RecordingViewModelProvider
    extends $NotifierProvider<RecordingViewModel, RideRecordingState> {
  /// Drives the recording screen. The native service keeps recording when this
  /// screen is closed; opening it again reads the live state back.
  RecordingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingViewModelHash();

  @$internal
  @override
  RecordingViewModel create() => RecordingViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideRecordingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideRecordingState>(value),
    );
  }
}

String _$recordingViewModelHash() =>
    r'20e6b4886105aacea5144f6de676efeed84481a9';

/// Drives the recording screen. The native service keeps recording when this
/// screen is closed; opening it again reads the live state back.

abstract class _$RecordingViewModel extends $Notifier<RideRecordingState> {
  RideRecordingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RideRecordingState, RideRecordingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RideRecordingState, RideRecordingState>,
              RideRecordingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
