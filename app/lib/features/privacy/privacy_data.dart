import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'privacy_data.g.dart';

class PrivacyData {
  PrivacyData(this._api);

  final PrivacyApi _api;

  Future<Result<PrivacyResponse?>> load() =>
      _api.getPrivacy().guard(FailureAction.loadPrivacy);

  Future<Result<PrivacyResponse?>> save(UpdatePrivacyRequest request) =>
      _api.updatePrivacy(request).guard(FailureAction.savePrivacy);

  Future<Result<PrivacyZoneResponse?>> addZone(
    CreatePrivacyZoneRequest request,
  ) => _api.createPrivacyZone(request).guard(FailureAction.savePrivacy);

  Future<Result<void>> deleteZone(String id) =>
      _api.deletePrivacyZone(id).guard(FailureAction.savePrivacy);
}

@Riverpod(keepAlive: true)
PrivacyData privacyData(Ref ref) =>
    PrivacyData(ref.watch(sessionProvider).privacy);
