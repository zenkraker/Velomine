// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The owner's inbox. Loaded only for the owner of a known club; emptied on sign
/// out, on leaving and when the role changes.

@ProviderFor(JoinRequestsViewModel)
final joinRequestsViewModelProvider = JoinRequestsViewModelProvider._();

/// The owner's inbox. Loaded only for the owner of a known club; emptied on sign
/// out, on leaving and when the role changes.
final class JoinRequestsViewModelProvider
    extends $NotifierProvider<JoinRequestsViewModel, JoinRequestsState> {
  /// The owner's inbox. Loaded only for the owner of a known club; emptied on sign
  /// out, on leaving and when the role changes.
  JoinRequestsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinRequestsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinRequestsViewModelHash();

  @$internal
  @override
  JoinRequestsViewModel create() => JoinRequestsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JoinRequestsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JoinRequestsState>(value),
    );
  }
}

String _$joinRequestsViewModelHash() =>
    r'00d22b4a8de70e1ec76f82540dfab2a8f9ded50b';

/// The owner's inbox. Loaded only for the owner of a known club; emptied on sign
/// out, on leaving and when the role changes.

abstract class _$JoinRequestsViewModel extends $Notifier<JoinRequestsState> {
  JoinRequestsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<JoinRequestsState, JoinRequestsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JoinRequestsState, JoinRequestsState>,
              JoinRequestsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
