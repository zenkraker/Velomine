// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_ride_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One athlete's ride, read-only: the numbers, the samples and, only when
/// shared, the route.

@ProviderFor(CoachRideViewModel)
final coachRideViewModelProvider = CoachRideViewModelFamily._();

/// One athlete's ride, read-only: the numbers, the samples and, only when
/// shared, the route.
final class CoachRideViewModelProvider
    extends $NotifierProvider<CoachRideViewModel, CoachRideState> {
  /// One athlete's ride, read-only: the numbers, the samples and, only when
  /// shared, the route.
  CoachRideViewModelProvider._({
    required CoachRideViewModelFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'coachRideViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachRideViewModelHash();

  @override
  String toString() {
    return r'coachRideViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CoachRideViewModel create() => CoachRideViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachRideState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachRideState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoachRideViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachRideViewModelHash() =>
    r'6fa031a18d1dbe78204846c7e1e9538e59668a76';

/// One athlete's ride, read-only: the numbers, the samples and, only when
/// shared, the route.

final class CoachRideViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CoachRideViewModel,
          CoachRideState,
          CoachRideState,
          CoachRideState,
          (String, String, String)
        > {
  CoachRideViewModelFamily._()
    : super(
        retry: null,
        name: r'coachRideViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One athlete's ride, read-only: the numbers, the samples and, only when
  /// shared, the route.

  CoachRideViewModelProvider call(
    String clubId,
    String userId,
    String rideId,
  ) => CoachRideViewModelProvider._(
    argument: (clubId, userId, rideId),
    from: this,
  );

  @override
  String toString() => r'coachRideViewModelProvider';
}

/// One athlete's ride, read-only: the numbers, the samples and, only when
/// shared, the route.

abstract class _$CoachRideViewModel extends $Notifier<CoachRideState> {
  late final _$args = ref.$arg as (String, String, String);
  String get clubId => _$args.$1;
  String get userId => _$args.$2;
  String get rideId => _$args.$3;

  CoachRideState build(String clubId, String userId, String rideId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachRideState, CoachRideState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachRideState, CoachRideState>,
              CoachRideState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
