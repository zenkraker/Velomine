// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The club's route library. Route-scoped: it reloads when a screen needs it and is
/// rebuilt empty when the account changes.

@ProviderFor(RoutesViewModel)
final routesViewModelProvider = RoutesViewModelProvider._();

/// The club's route library. Route-scoped: it reloads when a screen needs it and is
/// rebuilt empty when the account changes.
final class RoutesViewModelProvider
    extends $NotifierProvider<RoutesViewModel, RoutesState> {
  /// The club's route library. Route-scoped: it reloads when a screen needs it and is
  /// rebuilt empty when the account changes.
  RoutesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routesViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routesViewModelHash();

  @$internal
  @override
  RoutesViewModel create() => RoutesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutesState>(value),
    );
  }
}

String _$routesViewModelHash() => r'4b364013ea2891261898277ebe3f44063e8be03e';

/// The club's route library. Route-scoped: it reloads when a screen needs it and is
/// rebuilt empty when the account changes.

abstract class _$RoutesViewModel extends $Notifier<RoutesState> {
  RoutesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RoutesState, RoutesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RoutesState, RoutesState>,
              RoutesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One route with its line, and what its owner may do with it.

@ProviderFor(RouteDetailViewModel)
final routeDetailViewModelProvider = RouteDetailViewModelFamily._();

/// One route with its line, and what its owner may do with it.
final class RouteDetailViewModelProvider
    extends $NotifierProvider<RouteDetailViewModel, RouteDetailState> {
  /// One route with its line, and what its owner may do with it.
  RouteDetailViewModelProvider._({
    required RouteDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routeDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routeDetailViewModelHash();

  @override
  String toString() {
    return r'routeDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RouteDetailViewModel create() => RouteDetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RouteDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routeDetailViewModelHash() =>
    r'98607d662ed3f4579eb3ff884ffd39915fc8442e';

/// One route with its line, and what its owner may do with it.

final class RouteDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RouteDetailViewModel,
          RouteDetailState,
          RouteDetailState,
          RouteDetailState,
          String
        > {
  RouteDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'routeDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One route with its line, and what its owner may do with it.

  RouteDetailViewModelProvider call(String id) =>
      RouteDetailViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'routeDetailViewModelProvider';
}

/// One route with its line, and what its owner may do with it.

abstract class _$RouteDetailViewModel extends $Notifier<RouteDetailState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  RouteDetailState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RouteDetailState, RouteDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteDetailState, RouteDetailState>,
              RouteDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Adding a route from one of the member's rides or from a GPX file.

@ProviderFor(AddRouteViewModel)
final addRouteViewModelProvider = AddRouteViewModelProvider._();

/// Adding a route from one of the member's rides or from a GPX file.
final class AddRouteViewModelProvider
    extends $NotifierProvider<AddRouteViewModel, AddRouteState> {
  /// Adding a route from one of the member's rides or from a GPX file.
  AddRouteViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addRouteViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addRouteViewModelHash();

  @$internal
  @override
  AddRouteViewModel create() => AddRouteViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddRouteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddRouteState>(value),
    );
  }
}

String _$addRouteViewModelHash() => r'ff77ce486896983ab9eb3c6deadcc0bdaa613e8e';

/// Adding a route from one of the member's rides or from a GPX file.

abstract class _$AddRouteViewModel extends $Notifier<AddRouteState> {
  AddRouteState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AddRouteState, AddRouteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddRouteState, AddRouteState>,
              AddRouteState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Editing a route's details; the server returns the club's summary.

@ProviderFor(RouteEditViewModel)
final routeEditViewModelProvider = RouteEditViewModelFamily._();

/// Editing a route's details; the server returns the club's summary.
final class RouteEditViewModelProvider
    extends $NotifierProvider<RouteEditViewModel, RouteEditState> {
  /// Editing a route's details; the server returns the club's summary.
  RouteEditViewModelProvider._({
    required RouteEditViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routeEditViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routeEditViewModelHash();

  @override
  String toString() {
    return r'routeEditViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RouteEditViewModel create() => RouteEditViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteEditState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RouteEditViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routeEditViewModelHash() =>
    r'70efa1c058c3cd2644c7161139ab0656d52529cb';

/// Editing a route's details; the server returns the club's summary.

final class RouteEditViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RouteEditViewModel,
          RouteEditState,
          RouteEditState,
          RouteEditState,
          String
        > {
  RouteEditViewModelFamily._()
    : super(
        retry: null,
        name: r'routeEditViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Editing a route's details; the server returns the club's summary.

  RouteEditViewModelProvider call(String id) =>
      RouteEditViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'routeEditViewModelProvider';
}

/// Editing a route's details; the server returns the club's summary.

abstract class _$RouteEditViewModel extends $Notifier<RouteEditState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  RouteEditState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RouteEditState, RouteEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteEditState, RouteEditState>,
              RouteEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
