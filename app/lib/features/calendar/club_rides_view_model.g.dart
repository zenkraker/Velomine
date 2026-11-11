// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_rides_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The club's rides, route-scoped so a screen inside the club reloads them when it opens.

@ProviderFor(ClubRidesViewModel)
final clubRidesViewModelProvider = ClubRidesViewModelProvider._();

/// The club's rides, route-scoped so a screen inside the club reloads them when it opens.
final class ClubRidesViewModelProvider
    extends $NotifierProvider<ClubRidesViewModel, ClubRidesState> {
  /// The club's rides, route-scoped so a screen inside the club reloads them when it opens.
  ClubRidesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubRidesViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubRidesViewModelHash();

  @$internal
  @override
  ClubRidesViewModel create() => ClubRidesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubRidesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubRidesState>(value),
    );
  }
}

String _$clubRidesViewModelHash() =>
    r'61acf0a7d9ef064dad5fd053f9f49109bd98f3d5';

/// The club's rides, route-scoped so a screen inside the club reloads them when it opens.

abstract class _$ClubRidesViewModel extends $Notifier<ClubRidesState> {
  ClubRidesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClubRidesState, ClubRidesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClubRidesState, ClubRidesState>,
              ClubRidesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One club ride, saying "I'm in" and taking it back.

@ProviderFor(ClubRideDetailViewModel)
final clubRideDetailViewModelProvider = ClubRideDetailViewModelFamily._();

/// One club ride, saying "I'm in" and taking it back.
final class ClubRideDetailViewModelProvider
    extends $NotifierProvider<ClubRideDetailViewModel, ClubRideDetailState> {
  /// One club ride, saying "I'm in" and taking it back.
  ClubRideDetailViewModelProvider._({
    required ClubRideDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubRideDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubRideDetailViewModelHash();

  @override
  String toString() {
    return r'clubRideDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClubRideDetailViewModel create() => ClubRideDetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubRideDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubRideDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClubRideDetailViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubRideDetailViewModelHash() =>
    r'127ee7222e602e73bc867f6860fe796427fa0937';

/// One club ride, saying "I'm in" and taking it back.

final class ClubRideDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ClubRideDetailViewModel,
          ClubRideDetailState,
          ClubRideDetailState,
          ClubRideDetailState,
          String
        > {
  ClubRideDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'clubRideDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One club ride, saying "I'm in" and taking it back.

  ClubRideDetailViewModelProvider call(String id) =>
      ClubRideDetailViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'clubRideDetailViewModelProvider';
}

/// One club ride, saying "I'm in" and taking it back.

abstract class _$ClubRideDetailViewModel
    extends $Notifier<ClubRideDetailState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  ClubRideDetailState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClubRideDetailState, ClubRideDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClubRideDetailState, ClubRideDetailState>,
              ClubRideDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.

@ProviderFor(PlanRideViewModel)
final planRideViewModelProvider = PlanRideViewModelFamily._();

/// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.
final class PlanRideViewModelProvider
    extends $NotifierProvider<PlanRideViewModel, PlanRideState> {
  /// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.
  PlanRideViewModelProvider._({
    required PlanRideViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planRideViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planRideViewModelHash();

  @override
  String toString() {
    return r'planRideViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanRideViewModel create() => PlanRideViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanRideState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanRideState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanRideViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planRideViewModelHash() => r'4b2bcb24dc72b371410e08d4487d8b3457215032';

/// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.

final class PlanRideViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanRideViewModel,
          PlanRideState,
          PlanRideState,
          PlanRideState,
          String
        > {
  PlanRideViewModelFamily._()
    : super(
        retry: null,
        name: r'planRideViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.

  PlanRideViewModelProvider call(String id) =>
      PlanRideViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'planRideViewModelProvider';
}

/// Plans a ride, or changes one: the club's routes and, when editing, the ride as it is now.

abstract class _$PlanRideViewModel extends $Notifier<PlanRideState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  PlanRideState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlanRideState, PlanRideState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlanRideState, PlanRideState>,
              PlanRideState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The member's private calendar address.

@ProviderFor(CalendarFeedViewModel)
final calendarFeedViewModelProvider = CalendarFeedViewModelProvider._();

/// The member's private calendar address.
final class CalendarFeedViewModelProvider
    extends $NotifierProvider<CalendarFeedViewModel, CalendarFeedState> {
  /// The member's private calendar address.
  CalendarFeedViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarFeedViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarFeedViewModelHash();

  @$internal
  @override
  CalendarFeedViewModel create() => CalendarFeedViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarFeedState>(value),
    );
  }
}

String _$calendarFeedViewModelHash() =>
    r'1683819a7575f84b80d4ca289458830d72af449f';

/// The member's private calendar address.

abstract class _$CalendarFeedViewModel extends $Notifier<CalendarFeedState> {
  CalendarFeedState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarFeedState, CalendarFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarFeedState, CalendarFeedState>,
              CalendarFeedState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
