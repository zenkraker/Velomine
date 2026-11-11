import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import 'club_data.dart';
import 'club_view_model.dart';
import 'start_club_state.dart';

part 'start_club_view_model.g.dart';

/// A rider without a club starts one. The name lives in the screen's text field and arrives with [start];
/// the place and the "riders nearby may find it" choice are held here.
@riverpod
class StartClubViewModel extends _$StartClubViewModel {
  @override
  StartClubState build() {
    // A different account starts from an empty form.
    ref.watch(signedInUserIdProvider);
    return const StartClubState();
  }

  void setPoint(GeoPoint point) => state = state.copyWith(point: point);

  void setDiscoverable(bool value) =>
      state = state.copyWith(isDiscoverable: value);

  /// Returns whether the club exists now. On success the club is handed to [ClubViewModel], so the club tab
  /// shows it without asking again.
  Future<bool> start(String name) async {
    if (state.create.running) return false;
    state = state.copyWith(create: state.create.start());
    final point = state.point;
    final result = await ref
        .read(clubDataProvider)
        .start(
          name.trim(),
          point?.latitude,
          point?.longitude,
          isDiscoverable: state.isDiscoverable && point != null,
        );
    if (!ref.mounted) return false;
    state = state.copyWith(create: state.create.finish(result));
    if (result case Ok(:final value?)) {
      ref.read(clubViewModelProvider.notifier).adopt(value);
      return true;
    }
    return false;
  }
}
