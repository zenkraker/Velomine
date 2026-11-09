import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'sharing_data.g.dart';

/// The sharing choices and the log of who looked, as one value.
typedef SharingBundle = ({SharingResponse? sharing, ShareViewsResponse? views});

class SharingData {
  SharingData(this._api);

  final SharingApi _api;

  Future<Result<SharingBundle>> load() async {
    final sharing = await _api.getSharing().guard(FailureAction.loadSharing);
    if (sharing case Failed(:final failure)) return Failed(failure);
    final views = await _api.getShareViews().guard(FailureAction.loadSharing);
    if (views case Failed(:final failure)) return Failed(failure);
    return Ok((sharing: sharing.valueOrNull, views: views.valueOrNull));
  }

  Future<Result<SharingResponse?>> update(UpdateSharingRequest request) =>
      _api.updateSharing(request).guard(FailureAction.saveSharing);
}

@Riverpod(keepAlive: true)
SharingData sharingData(Ref ref) =>
    SharingData(ref.watch(sessionProvider).sharing);
