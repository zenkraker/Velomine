import 'package:velomine_api/api.dart';

import '../../core/command.dart';
import '../../core/user_message.dart';
import 'admin_data.dart';

/// Every account, with what an admin can do to each one.
class AdminAccountsState {
  const AdminAccountsState({
    this.users = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<AdminUserSummary> users;
  final CommandState<ListAdminUsersResponse?> load;

  /// Approve, roles, lock, unlock, delete and reset links share one command, so
  /// every action is disabled while one runs.
  final VoidCommand action;

  final List<UserMessage> messages;

  AdminAccountsState copyWith({
    List<AdminUserSummary>? users,
    CommandState<ListAdminUsersResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => AdminAccountsState(
    users: users ?? this.users,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// Counts for the whole server. Numbers only: an admin never sees whose rides
/// they are.
class AdminOverviewState {
  const AdminOverviewState({this.load = const CommandState.idle()});

  final CommandState<OverviewResponse?> load;
}

/// Every club on the server.
class AdminClubsState {
  const AdminClubsState({
    this.clubs = const [],
    this.load = const CommandState.idle(),
    this.action = const CommandState.idle(),
    this.messages = const [],
  });

  final List<AdminClubResponse> clubs;
  final CommandState<AdminClubListResponse?> load;
  final VoidCommand action;
  final List<UserMessage> messages;

  AdminClubsState copyWith({
    List<AdminClubResponse>? clubs,
    CommandState<AdminClubListResponse?>? load,
    VoidCommand? action,
    List<UserMessage>? messages,
  }) => AdminClubsState(
    clubs: clubs ?? this.clubs,
    load: load ?? this.load,
    action: action ?? this.action,
    messages: messages ?? this.messages,
  );
}

/// The settings an admin changes, and the read-only state of the shared
/// catalogue.
class AdminSettingsState {
  const AdminSettingsState({
    this.settings,
    this.catalogue,
    this.signUpEnabled = true,
    this.requireAdminApproval = true,
    this.filled = false,
    this.load = const CommandState.idle(),
    this.save = const CommandState.idle(),
    this.testEmail = const CommandState.idle(),
    this.messages = const [],
  });

  final SettingsResponse? settings;
  final CatalogueAdminResponse? catalogue;

  /// The form's values. Taken from the server once, then owned by the admin
  /// until they save.
  final bool signUpEnabled;
  final bool requireAdminApproval;
  final bool filled;

  final CommandState<AdminSettingsBundle> load;
  final VoidCommand save;
  final VoidCommand testEmail;
  final List<UserMessage> messages;

  AdminSettingsState copyWith({
    SettingsResponse? settings,
    CatalogueAdminResponse? catalogue,
    bool? signUpEnabled,
    bool? requireAdminApproval,
    bool? filled,
    CommandState<AdminSettingsBundle>? load,
    VoidCommand? save,
    VoidCommand? testEmail,
    List<UserMessage>? messages,
  }) => AdminSettingsState(
    settings: settings ?? this.settings,
    catalogue: catalogue ?? this.catalogue,
    signUpEnabled: signUpEnabled ?? this.signUpEnabled,
    requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
    filled: filled ?? this.filled,
    load: load ?? this.load,
    save: save ?? this.save,
    testEmail: testEmail ?? this.testEmail,
    messages: messages ?? this.messages,
  );
}
