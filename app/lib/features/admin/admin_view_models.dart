import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'admin_data.dart';
import 'admin_state.dart';

part 'admin_view_models.g.dart';

/// Every account and the changes an admin makes to them. Kept alive for the
/// session; signing out rebuilds it empty.
@Riverpod(keepAlive: true)
class AdminAccountsViewModel extends _$AdminAccountsViewModel {
  int _messageId = 0;

  @override
  AdminAccountsState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const AdminAccountsState();
    }
    Future.microtask(refresh);
    return const AdminAccountsState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(adminDataProvider).users();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        users: value?.users ?? const [],
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  Future<bool> approve(AdminUserSummary user) =>
      _change(() => ref.read(adminDataProvider).approve(user.id));

  Future<bool> setRoles(AdminUserSummary user, List<String> roles) =>
      _change(() => ref.read(adminDataProvider).setRoles(user.id, roles));

  Future<bool> lock(AdminUserSummary user) =>
      _change(() => ref.read(adminDataProvider).lock(user.id));

  Future<bool> unlock(AdminUserSummary user) =>
      _change(() => ref.read(adminDataProvider).unlock(user.id));

  Future<bool> delete(AdminUserSummary user) =>
      _change(() => ref.read(adminDataProvider).delete(user.id));

  Future<bool> resetTwoFactor(AdminUserSummary user) =>
      _change(() => ref.read(adminDataProvider).resetTwoFactor(user.id));

  /// Makes a one-time reset link for the admin to hand to a member, or null
  /// when a message now says why.
  Future<String?> createResetLink(AdminUserSummary user) async {
    if (state.action.running) return null;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(adminDataProvider).resetLink(user.id);
    if (!ref.mounted) return null;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return null;
    }
    return result.valueOrNull?.link;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  /// Runs a change, then reads the accounts and the overview again.
  Future<bool> _change(Future<Result<Object?>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    await refresh();
    ref.invalidate(adminOverviewViewModelProvider);
    return true;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}

/// The server totals, read again after any account changes.
@Riverpod(keepAlive: true)
class AdminOverviewViewModel extends _$AdminOverviewViewModel {
  @override
  AdminOverviewState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const AdminOverviewState();
    }
    Future.microtask(refresh);
    return const AdminOverviewState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = AdminOverviewState(load: state.load.start());
    final result = await ref.read(adminDataProvider).overview();
    if (!ref.mounted) return;
    state = AdminOverviewState(load: state.load.finish(result));
  }
}

/// Every club on the server: create one, turn it on or off, move its owner.
@Riverpod(keepAlive: true)
class AdminClubsViewModel extends _$AdminClubsViewModel {
  int _messageId = 0;

  @override
  AdminClubsState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const AdminClubsState();
    }
    Future.microtask(refresh);
    return const AdminClubsState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(adminDataProvider).clubs();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        clubs: value?.clubs ?? const [],
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Creates a club with an existing account as its owner.
  Future<bool> create(String name, String ownerEmail) =>
      _change(() => ref.read(adminDataProvider).createClub(name, ownerEmail));

  /// A disabled club takes no new joins but keeps its members and data.
  Future<bool> setActive(AdminClubResponse club, bool active) =>
      _change(() => ref.read(adminDataProvider).setClubActive(club, active));

  /// Moves ownership to another member, so the old owner can leave.
  Future<bool> setOwner(AdminClubResponse club, String userId) =>
      _change(() => ref.read(adminDataProvider).setClubOwner(club, userId));

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _change(Future<Result<Object?>> Function() call) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    await refresh();
    return true;
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}

/// The server settings the admin may change. The form is held here, not in the
/// widget, so switching tabs does not lose an edit.
@Riverpod(keepAlive: true)
class AdminSettingsViewModel extends _$AdminSettingsViewModel {
  int _messageId = 0;

  @override
  AdminSettingsState build() {
    if (ref.watch(signedInUserIdProvider) == null) {
      return const AdminSettingsState();
    }
    Future.microtask(load);
    return const AdminSettingsState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(adminDataProvider).settings();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        settings: value.settings,
        catalogue: value.catalogue,
        filled: state.filled || value.settings != null,
        signUpEnabled: state.filled
            ? state.signUpEnabled
            : (value.settings?.signUpEnabled ?? state.signUpEnabled),
        requireAdminApproval: state.filled
            ? state.requireAdminApproval
            : (value.settings?.requireAdminApproval ??
                  state.requireAdminApproval),
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  void setSignUpEnabled(bool value) => state = state.copyWith(
    signUpEnabled: value,
    save: const CommandState.idle(),
  );

  void setRequireAdminApproval(bool value) => state = state.copyWith(
    requireAdminApproval: value,
    save: const CommandState.idle(),
  );

  Future<bool> saveSettings() async {
    if (state.save.running) return false;
    state = state.copyWith(save: state.save.start());
    final result = await ref
        .read(adminDataProvider)
        .saveSettings(
          UpdateSettingsRequest(
            signUpEnabled: state.signUpEnabled,
            requireAdminApproval: state.requireAdminApproval,
          ),
        );
    if (!ref.mounted) return false;
    if (result case Ok(:final value)) {
      state = state.copyWith(
        save: state.save.finish(result),
        settings: value,
        filled: true,
      );
      return true;
    }
    state = state.copyWith(save: state.save.finish(result));
    if (result case Failed(:final failure)) _fail(failure);
    return false;
  }

  /// Sends a test message to the signed-in admin; the screen shows how it went.
  Future<void> sendTestEmail() async {
    if (state.testEmail.running) return;
    state = state.copyWith(testEmail: state.testEmail.start());
    final result = await ref.read(adminDataProvider).sendTestEmail();
    if (!ref.mounted) return;
    state = state.copyWith(testEmail: state.testEmail.finish(result));
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
