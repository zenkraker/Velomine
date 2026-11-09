import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';

part 'admin_data.g.dart';

/// The two parallel loads the settings page needs.
typedef AdminSettingsBundle = ({
  SettingsResponse? settings,
  CatalogueAdminResponse? catalogue,
});

/// The admin endpoints as values: the ViewModels never see an exception.
class AdminData {
  AdminData(this._api, this._accounts);

  final AdminApi _api;
  final AccountsApi _accounts;

  Future<Result<ListAdminUsersResponse?>> users() =>
      _api.listAdminUsers().guard(FailureAction.loadAdmin);

  Future<Result<OverviewResponse?>> overview() =>
      _api.getOverview().guard(FailureAction.loadAdmin);

  Future<Result<AdminClubListResponse?>> clubs() =>
      _api.clubsListAdminClubs().guard(FailureAction.loadAdminClubs);

  Future<Result<AdminSettingsBundle>> settings() async {
    final settings = await _api.getSettings().guard(FailureAction.loadAdmin);
    if (settings case Failed(:final failure)) return Failed(failure);
    final catalogue = await _api.bikesGetCatalogue().guard(
      FailureAction.loadAdmin,
    );
    if (catalogue case Failed(:final failure)) return Failed(failure);
    return Ok((
      settings: settings.valueOrNull,
      catalogue: catalogue.valueOrNull,
    ));
  }

  Future<Result<void>> approve(String id) =>
      _accounts.approveUser(id).guard(FailureAction.approveAccount);

  Future<Result<AdminUserSummary?>> setRoles(String id, List<String> roles) =>
      _api
          .setUserRoles(id, SetUserRolesRequest(roles: roles))
          .guard(FailureAction.changeRoles);

  Future<Result<void>> lock(String id) =>
      _api.lockUser(id).guard(FailureAction.lockAccount);

  Future<Result<void>> unlock(String id) =>
      _api.unlockUser(id).guard(FailureAction.unlockAccount);

  Future<Result<void>> delete(String id) =>
      _api.deleteUser(id).guard(FailureAction.deleteAccount);

  Future<Result<PasswordResetLinkResponse?>> resetLink(String id) =>
      _api.createPasswordResetLink(id).guard(FailureAction.resetPassword);

  Future<Result<void>> sendTestEmail() =>
      _api.sendTestEmail().guard(FailureAction.sendTestEmail);

  Future<Result<SettingsResponse?>> saveSettings(
    UpdateSettingsRequest request,
  ) => _api.updateSettings(request).guard(FailureAction.saveSettings);

  Future<Result<AdminClubResponse?>> createClub(
    String name,
    String ownerEmail,
  ) => _api
      .clubsCreateClub(CreateClubRequest(name: name, ownerEmail: ownerEmail))
      .guard(FailureAction.createClub);

  Future<Result<AdminClubResponse?>> setClubActive(
    AdminClubResponse club,
    bool active,
  ) => _api
      .clubsUpdateClub(
        club.id,
        UpdateClubRequest(name: club.name, isActive: active),
      )
      .guard(FailureAction.updateClub);

  Future<Result<AdminClubResponse?>> setClubOwner(
    AdminClubResponse club,
    String userId,
  ) => _api
      .clubsSetClubOwner(club.id, SetClubOwnerRequest(userId: userId))
      .guard(FailureAction.setClubOwner);
}

@Riverpod(keepAlive: true)
AdminData adminData(Ref ref) {
  final session = ref.watch(sessionProvider);
  return AdminData(session.admin, session.accounts);
}
