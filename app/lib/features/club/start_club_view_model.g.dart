// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_club_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A rider without a club starts one. The name lives in the screen's text field and arrives with [start];
/// the place and the "riders nearby may find it" choice are held here.

@ProviderFor(StartClubViewModel)
final startClubViewModelProvider = StartClubViewModelProvider._();

/// A rider without a club starts one. The name lives in the screen's text field and arrives with [start];
/// the place and the "riders nearby may find it" choice are held here.
final class StartClubViewModelProvider
    extends $NotifierProvider<StartClubViewModel, StartClubState> {
  /// A rider without a club starts one. The name lives in the screen's text field and arrives with [start];
  /// the place and the "riders nearby may find it" choice are held here.
  StartClubViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startClubViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startClubViewModelHash();

  @$internal
  @override
  StartClubViewModel create() => StartClubViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartClubState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartClubState>(value),
    );
  }
}

String _$startClubViewModelHash() =>
    r'7a95e466e31bb4f75b33a16bf029ff4d90ec5f21';

/// A rider without a club starts one. The name lives in the screen's text field and arrives with [start];
/// the place and the "riders nearby may find it" choice are held here.

abstract class _$StartClubViewModel extends $Notifier<StartClubState> {
  StartClubState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StartClubState, StartClubState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartClubState, StartClubState>,
              StartClubState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
