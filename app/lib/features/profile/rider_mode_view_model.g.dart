// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rider_mode_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saves the member's rider mode. The mode itself stays in `session.me`: this only runs the save through one
/// queue and says whether it worked, so a failed save keeps the old mode and the sheet can show why.

@ProviderFor(RiderModeViewModel)
final riderModeViewModelProvider = RiderModeViewModelProvider._();

/// Saves the member's rider mode. The mode itself stays in `session.me`: this only runs the save through one
/// queue and says whether it worked, so a failed save keeps the old mode and the sheet can show why.
final class RiderModeViewModelProvider
    extends $NotifierProvider<RiderModeViewModel, RiderModeState> {
  /// Saves the member's rider mode. The mode itself stays in `session.me`: this only runs the save through one
  /// queue and says whether it worked, so a failed save keeps the old mode and the sheet can show why.
  RiderModeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'riderModeViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$riderModeViewModelHash();

  @$internal
  @override
  RiderModeViewModel create() => RiderModeViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RiderModeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RiderModeState>(value),
    );
  }
}

String _$riderModeViewModelHash() =>
    r'89770e9470e4ae75e9b7b9e6b903a386aa25da46';

/// Saves the member's rider mode. The mode itself stays in `session.me`: this only runs the save through one
/// queue and says whether it worked, so a failed save keeps the old mode and the sheet can show why.

abstract class _$RiderModeViewModel extends $Notifier<RiderModeState> {
  RiderModeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RiderModeState, RiderModeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RiderModeState, RiderModeState>,
              RiderModeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
