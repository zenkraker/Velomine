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

  /// The common jobs that fit this bike. A failure only means no suggestions.
  Future<Result<List<MaintenanceJob>>> serviceJobs(String bikeId) async =>
      (await _api.listServiceJobs(bikeId).guard(FailureAction.loadServiceLog))
          .map((jobs) => jobs?.jobs ?? const <MaintenanceJob>[]);

  Future<Result<ListServiceEntriesResponse?>> serviceEntries(
    String bikeId, {
    String? componentId,
    int limit = 50,
    ServiceEntryResponse? after,
  }) => _api
      .listServiceEntries(
        bikeId,
        componentId: componentId,
        limit: limit,
        beforeDate: after?.date,
        beforeId: after?.id,
      )
      .guard(FailureAction.loadServiceLog);

  Future<Result<BikeDetailResponse?>> addReminder(
    String bikeId,
    CreateReminderRequest reminder,
  ) => _api.createReminder(bikeId, reminder).guard(FailureAction.saveReminder);

  Future<Result<BikeDetailResponse?>> editReminder(
    String bikeId,
    String reminderId,
    UpdateReminderRequest reminder,
  ) => _api
      .updateReminder(bikeId, reminderId, reminder)
      .guard(FailureAction.saveReminder);

  Future<Result<void>> removeReminder(String bikeId, String reminderId) => _api
      .deleteReminder(bikeId, reminderId)
      .guard(FailureAction.removeReminder);

  Future<Result<BikeDetailResponse?>> completeReminder(
    String bikeId,
    String reminderId,
    DateTime doneOn,
  ) => _api
      .completeReminder(
        bikeId,
        reminderId,
        MarkReminderDoneRequest(doneOn: Optional.present(doneOn)),
      )
      .guard(FailureAction.completeReminder);

  Future<Result<ServiceEntryResponse?>> addServiceEntry(
    String bikeId,
    CreateServiceEntryRequest entry,
  ) => _api
      .createServiceEntry(bikeId, entry)
      .guard(FailureAction.saveServiceEntry);

  Future<Result<ServiceEntryResponse?>> editServiceEntry(
    String bikeId,
    String entryId,
    UpdateServiceEntryRequest entry,
  ) => _api
      .updateServiceEntry(bikeId, entryId, entry)
      .guard(FailureAction.saveServiceEntry);

  Future<Result<void>> removeServiceEntry(String bikeId, String entryId) => _api
      .deleteServiceEntry(bikeId, entryId)
      .guard(FailureAction.removeServiceEntry);

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
