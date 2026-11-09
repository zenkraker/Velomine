import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'profile_data.dart';
import 'profile_state.dart';

part 'profile_view_model.g.dart';

/// The member's profile. Kept alive for the session; a sign-out rebuilds it
/// empty, so the next account never sees the last one's numbers.
@Riverpod(keepAlive: true)
class ProfileViewModel extends _$ProfileViewModel {
  int _messageId = 0;

  @override
  ProfileState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const ProfileState();
    Future.microtask(load);
    return const ProfileState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(profileDataProvider).profile();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        profile: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<bool> save(UpdateProfileRequest request) async {
    if (state.save.running) return false;
    state = state.copyWith(save: state.save.start());
    final result = await ref.read(profileDataProvider).save(request);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(save: state.save.finish(result));
      _fail(failure);
      return false;
    }
    state = state.copyWith(
      save: state.save.finish(result),
      profile: result.valueOrNull,
    );
    // The title bar shows the member's name, so it is read again.
    await ref.read(sessionProvider).refreshMe();
    return true;
  }

  /// Asks for a download link for all of the member's data, or null when a
  /// message says why.
  Future<String?> exportLink() async {
    if (state.export.running) return null;
    state = state.copyWith(export: state.export.start());
    final result = await ref.read(profileDataProvider).exportLink();
    if (!ref.mounted) return null;
    state = state.copyWith(export: state.export.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return null;
    }
    return result.valueOrNull;
  }

  /// Deletes the account and every ride. A wrong password or email, or being
  /// the last admin, arrives as a message.
  Future<bool> deleteAccount({String? password, String? confirmEmail}) async {
    if (state.delete.running) return false;
    state = state.copyWith(delete: state.delete.start());
    final result = await ref
        .read(profileDataProvider)
        .deleteAccount(password: password, confirmEmail: confirmEmail);
    if (!ref.mounted) return false;
    state = state.copyWith(delete: state.delete.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    return true;
  }

  /// Returns null on success, or the failure for the dialog to word.
  Future<Failure?> changePassword(String current, String newPassword) async {
    if (state.password.running) {
      return const Failure(FailureKind.failed);
    }
    state = state.copyWith(password: state.password.start());
    final result = await ref
        .read(profileDataProvider)
        .changePassword(current, newPassword);
    if (!ref.mounted) return const Failure(FailureKind.failed);
    state = state.copyWith(password: state.password.finish(result));
    return result.failureOrNull;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
