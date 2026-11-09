// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sharing_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's choices for what the club may see. Loaded when a club is known,
/// and emptied when the club is left or the account changes.

@ProviderFor(SharingViewModel)
final sharingViewModelProvider = SharingViewModelProvider._();

/// The member's choices for what the club may see. Loaded when a club is known,
/// and emptied when the club is left or the account changes.
final class SharingViewModelProvider
    extends $NotifierProvider<SharingViewModel, SharingState> {
  /// The member's choices for what the club may see. Loaded when a club is known,
  /// and emptied when the club is left or the account changes.
  SharingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharingViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharingViewModelHash();

  @$internal
  @override
  SharingViewModel create() => SharingViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharingState>(value),
    );
  }
}

String _$sharingViewModelHash() => r'b3d8fd938fae8cdac8c33887d578f6a4c4fb785e';

/// The member's choices for what the club may see. Loaded when a club is known,
/// and emptied when the club is left or the account changes.

abstract class _$SharingViewModel extends $Notifier<SharingState> {
  SharingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SharingState, SharingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SharingState, SharingState>,
              SharingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
