// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bikes_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's bikes and adding one.

@ProviderFor(BikesViewModel)
final bikesViewModelProvider = BikesViewModelProvider._();

/// The member's bikes and adding one.
final class BikesViewModelProvider
    extends $NotifierProvider<BikesViewModel, BikesState> {
  /// The member's bikes and adding one.
  BikesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bikesViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bikesViewModelHash();

  @$internal
  @override
  BikesViewModel create() => BikesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BikesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BikesState>(value),
    );
  }
}

String _$bikesViewModelHash() => r'0a6b8c45aecdc693eb02090191d9ef89773f8d7b';

/// The member's bikes and adding one.

abstract class _$BikesViewModel extends $Notifier<BikesState> {
  BikesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BikesState, BikesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BikesState, BikesState>,
              BikesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One bike: editing it and its parts, and applying a template. Route-scoped,
/// so it lives exactly as long as the detail screen.

@ProviderFor(BikeDetailViewModel)
final bikeDetailViewModelProvider = BikeDetailViewModelFamily._();

/// One bike: editing it and its parts, and applying a template. Route-scoped,
/// so it lives exactly as long as the detail screen.
final class BikeDetailViewModelProvider
    extends $NotifierProvider<BikeDetailViewModel, BikeDetailState> {
  /// One bike: editing it and its parts, and applying a template. Route-scoped,
  /// so it lives exactly as long as the detail screen.
  BikeDetailViewModelProvider._({
    required BikeDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bikeDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bikeDetailViewModelHash();

  @override
  String toString() {
    return r'bikeDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BikeDetailViewModel create() => BikeDetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BikeDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BikeDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BikeDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bikeDetailViewModelHash() =>
    r'4ca9627ce3400a721f9156b9b58df9530fed324f';

/// One bike: editing it and its parts, and applying a template. Route-scoped,
/// so it lives exactly as long as the detail screen.

final class BikeDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          BikeDetailViewModel,
          BikeDetailState,
          BikeDetailState,
          BikeDetailState,
          String
        > {
  BikeDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'bikeDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One bike: editing it and its parts, and applying a template. Route-scoped,
  /// so it lives exactly as long as the detail screen.

  BikeDetailViewModelProvider call(String id) =>
      BikeDetailViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'bikeDetailViewModelProvider';
}

/// One bike: editing it and its parts, and applying a template. Route-scoped,
/// so it lives exactly as long as the detail screen.

abstract class _$BikeDetailViewModel extends $Notifier<BikeDetailState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  BikeDetailState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BikeDetailState, BikeDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BikeDetailState, BikeDetailState>,
              BikeDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
