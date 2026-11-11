// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_rides_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Share to Velomine": the files are already on the phone, so this tells the member and starts the upload queue.

@ProviderFor(IncomingRidesViewModel)
final incomingRidesViewModelProvider = IncomingRidesViewModelProvider._();

/// "Share to Velomine": the files are already on the phone, so this tells the member and starts the upload queue.
final class IncomingRidesViewModelProvider
    extends $NotifierProvider<IncomingRidesViewModel, IncomingRidesState> {
  /// "Share to Velomine": the files are already on the phone, so this tells the member and starts the upload queue.
  IncomingRidesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingRidesViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingRidesViewModelHash();

  @$internal
  @override
  IncomingRidesViewModel create() => IncomingRidesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IncomingRidesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IncomingRidesState>(value),
    );
  }
}

String _$incomingRidesViewModelHash() =>
    r'2ab97109d7b5c6cd5c9d3c155b9e4a48ee90fc8d';

/// "Share to Velomine": the files are already on the phone, so this tells the member and starts the upload queue.

abstract class _$IncomingRidesViewModel extends $Notifier<IncomingRidesState> {
  IncomingRidesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IncomingRidesState, IncomingRidesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IncomingRidesState, IncomingRidesState>,
              IncomingRidesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
