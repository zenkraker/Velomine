import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'bikes_data.g.dart';

/// The bike endpoints as values: the ViewModels never see an exception.
class BikesData {
  BikesData(this._api);

  final BikesApi _api;

  Future<Result<List<BikeResponse>>> list() async =>
      (await _api.listBikes().guard(FailureAction.loadBikes))
          .map((page) => page?.bikes ?? const <BikeResponse>[]);

  Future<Result<String?>> create(CreateBikeRequest bike) async =>
      (await _api.createBike(bike).guard(FailureAction.addBike))
          .map((created) => created?.bike.id);

  Future<Result<BikeDetailResponse?>> bike(String id) =>
      _api.getBike(id).guard(FailureAction.loadBike);

  Future<Result<List<ComponentTypeResponse>>> types() async =>
      (await _api.listComponentTypes().guard(FailureAction.loadBike))
          .map((types) => types?.types ?? const <ComponentTypeResponse>[]);

  /// The templates this club may apply. A failure leaves the bike usable:
  /// applying one is the extra, not the job.
  Future<Result<List<BikeTemplateResponse>>> templates() async =>
      (await _api.listTemplates().guard(FailureAction.loadTemplates)).map(
        (templates) => templates?.templates ?? const <BikeTemplateResponse>[],
      );

  Future<Result<BikeDetailResponse?>> update(
    String id,
    UpdateBikeRequest bike,
  ) => _api.updateBike(id, bike).guard(FailureAction.saveBike);

  Future<Result<void>> makeDefault(String id) =>
      _api.setDefaultBike(id).guard(FailureAction.setDefaultBike);

  Future<Result<void>> delete(String id) =>
      _api.deleteBike(id).guard(FailureAction.deleteBike);

  Future<Result<BikeDetailResponse?>> addPart(
    String bikeId,
    CreateComponentRequest part,
  ) => _api.createComponent(bikeId, part).guard(FailureAction.addPart);

  Future<Result<BikeDetailResponse?>> editPart(
    String bikeId,
    String partId,
    UpdateComponentRequest part,
  ) => _api.updateComponent(bikeId, partId, part).guard(FailureAction.savePart);

  Future<Result<void>> removePart(String bikeId, String partId) =>
      _api.deleteComponent(bikeId, partId).guard(FailureAction.removePart);

  Future<Result<BikeTemplateResponse?>> saveTemplate(
    String bikeId,
    String name,
  ) => _api
      .saveBikeAsTemplate(bikeId, SaveBikeAsTemplateRequest(name: name))
      .guard(FailureAction.saveTemplate);

  Future<Result<BikeDetailResponse?>> applyTemplate(
    String bikeId,
    String templateId,
    DateTime installedOn,
  ) => _api
      .applyTemplate(
        bikeId,
        templateId,
        ApplyTemplateRequest(installedOn: installedOn),
      )
      .guard(FailureAction.applyTemplate);

  /// The parts this club has used before. A failed lookup offers nothing.
  Future<Result<List<PartResponse>>> searchParts(
    String query,
    String? type,
  ) async =>
      (await _api
              .searchParts(q: query, type: type, limit: 8)
              .guard(FailureAction.loadBike))
          .map((response) => response?.parts ?? const <PartResponse>[]);
}

@Riverpod(keepAlive: true)
BikesData bikesData(Ref ref) {
  return BikesData(ref.watch(sessionProvider).bikes);
}
