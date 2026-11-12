import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'supporter_data.g.dart';

/// The supporter endpoints as values: the ViewModel never sees an exception.
class SupporterData {
  SupporterData(this._api);

  final SupporterApi _api;

  Future<Result<SupporterStatusResponse?>> status() =>
      _api.getSupporterStatus().guard(FailureAction.loadSupporter);

  Future<Result<SupporterStatusResponse?>> activate(String key) => _api
      .activateSupporter(ActivateSupporterRequest(key: key.trim()))
      .guard(FailureAction.activateSupporter);

  /// Hides or shows the badge; the licence is kept either way.
  Future<Result<RiderLicenceResponse?>> setHidden(bool hidden) => _api
      .setSupporterHidden(SetSupporterHiddenRequest(hidden: hidden))
      .guard(FailureAction.saveSupporter);
}

@Riverpod(keepAlive: true)
SupporterData supporterData(Ref ref) =>
    SupporterData(ref.watch(sessionProvider).supporter);
