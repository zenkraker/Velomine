import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'routes_data.g.dart';

/// The route library endpoints as values: the ViewModels never see an exception.
class RoutesData {
  RoutesData(this._api, this._rides);

  final RoutesApi _api;
  final RidesApi _rides;

  Future<Result<List<RouteSummaryResponse>>> list({
    String? sort,
    String? surface,
  }) async =>
      (await _api
              .listRoutes(sort: sort, surface: surface)
              .guard(FailureAction.loadRoutes))
          .map((page) => page?.routes ?? const <RouteSummaryResponse>[]);

  Future<Result<List<RouteSummaryResponse>>> mine() async =>
      (await _api.listMyRoutes().guard(FailureAction.loadRoutes))
          .map((page) => page?.routes ?? const <RouteSummaryResponse>[]);

  Future<Result<RouteDetailResponse?>> route(String id) =>
      _api.getRoute(id).guard(FailureAction.loadRoute);

  Future<Result<RouteDetailResponse?>> create(CreateRouteRequest request) =>
      _api.createRoute(request).guard(FailureAction.addRoute);

  Future<Result<RouteSummaryResponse?>> update(
    String id,
    UpdateRouteRequest request,
  ) => _api.updateRoute(id, request).guard(FailureAction.saveRoute);

  /// Takes the route out of the club library; it stays with its owner.
  Future<Result<void>> withdraw(String id) =>
      _api.unshareRoute(id).guard(FailureAction.saveRoute);

  Future<Result<RouteSummaryResponse?>> share(String id) =>
      _api.shareRoute(id).guard(FailureAction.saveRoute);

  Future<Result<void>> delete(String id) =>
      _api.deleteRoute(id).guard(FailureAction.deleteRoute);

  Future<Result<RouteDownloadLinkResponse?>> downloadLink(String id) =>
      _api.createRouteDownloadLink(id).guard(FailureAction.loadRoute);

  /// The member's own ride as the club will see it, privacy rules applied.
  Future<Result<RouteDraftResponse?>> rideDraft(String rideId) =>
      _rides.routesGetRideRouteDraft(rideId).guard(FailureAction.addRoute);

  Future<Result<RouteDraftResponse?>> gpxDraft(XFile file) => (() async {
    final upload = MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: file.name,
    );
    return await _api.readGpxRouteDraft(upload);
  })().guard(FailureAction.addRoute);

  Future<Result<List<RideResponse>>> readyRides() async =>
      (await _rides.listRides().guard(FailureAction.loadRides)).map(
        (page) => [
          for (final ride in page?.rides ?? const <RideResponse>[])
            if (ride.status == 'ready') ride,
        ],
      );
}

@Riverpod(keepAlive: true)
RoutesData routesData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return RoutesData(session.routes, session.rides);
}
