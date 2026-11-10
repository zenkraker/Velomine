// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every account and the changes an admin makes to them. Kept alive for the
/// session; signing out rebuilds it empty.

@ProviderFor(AdminAccountsViewModel)
final adminAccountsViewModelProvider = AdminAccountsViewModelProvider._();

/// Every account and the changes an admin makes to them. Kept alive for the
/// session; signing out rebuilds it empty.
final class AdminAccountsViewModelProvider
    extends $NotifierProvider<AdminAccountsViewModel, AdminAccountsState> {
  /// Every account and the changes an admin makes to them. Kept alive for the
  /// session; signing out rebuilds it empty.
  AdminAccountsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAccountsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAccountsViewModelHash();

  @$internal
  @override
  AdminAccountsViewModel create() => AdminAccountsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminAccountsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminAccountsState>(value),
    );
  }
}

String _$adminAccountsViewModelHash() =>
    r'd647fa06b868835f7714c38f5c2e46362fc85991';

/// Every account and the changes an admin makes to them. Kept alive for the
/// session; signing out rebuilds it empty.

abstract class _$AdminAccountsViewModel extends $Notifier<AdminAccountsState> {
  AdminAccountsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminAccountsState, AdminAccountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminAccountsState, AdminAccountsState>,
              AdminAccountsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The server totals, read again after any account changes.

@ProviderFor(AdminOverviewViewModel)
final adminOverviewViewModelProvider = AdminOverviewViewModelProvider._();

/// The server totals, read again after any account changes.
final class AdminOverviewViewModelProvider
    extends $NotifierProvider<AdminOverviewViewModel, AdminOverviewState> {
  /// The server totals, read again after any account changes.
  AdminOverviewViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminOverviewViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminOverviewViewModelHash();

  @$internal
  @override
  AdminOverviewViewModel create() => AdminOverviewViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminOverviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminOverviewState>(value),
    );
  }
}

String _$adminOverviewViewModelHash() =>
    r'242001e4ca5bc05b9305a50aec0afaa460a0ce96';

/// The server totals, read again after any account changes.

abstract class _$AdminOverviewViewModel extends $Notifier<AdminOverviewState> {
  AdminOverviewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminOverviewState, AdminOverviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminOverviewState, AdminOverviewState>,
              AdminOverviewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Every club on the server: create one, turn it on or off, move its owner.

@ProviderFor(AdminClubsViewModel)
final adminClubsViewModelProvider = AdminClubsViewModelProvider._();

/// Every club on the server: create one, turn it on or off, move its owner.
final class AdminClubsViewModelProvider
    extends $NotifierProvider<AdminClubsViewModel, AdminClubsState> {
  /// Every club on the server: create one, turn it on or off, move its owner.
  AdminClubsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminClubsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminClubsViewModelHash();

  @$internal
  @override
  AdminClubsViewModel create() => AdminClubsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminClubsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminClubsState>(value),
    );
  }
}

String _$adminClubsViewModelHash() =>
    r'1628bfd5d848c1a6645abd0073f04e6220cdf772';

/// Every club on the server: create one, turn it on or off, move its owner.

abstract class _$AdminClubsViewModel extends $Notifier<AdminClubsState> {
  AdminClubsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminClubsState, AdminClubsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminClubsState, AdminClubsState>,
              AdminClubsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The server settings the admin may change. The form is held here, not in the
/// widget, so switching tabs does not lose an edit.

@ProviderFor(AdminSettingsViewModel)
final adminSettingsViewModelProvider = AdminSettingsViewModelProvider._();

/// The server settings the admin may change. The form is held here, not in the
/// widget, so switching tabs does not lose an edit.
final class AdminSettingsViewModelProvider
    extends $NotifierProvider<AdminSettingsViewModel, AdminSettingsState> {
  /// The server settings the admin may change. The form is held here, not in the
  /// widget, so switching tabs does not lose an edit.
  AdminSettingsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminSettingsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminSettingsViewModelHash();

  @$internal
  @override
  AdminSettingsViewModel create() => AdminSettingsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminSettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminSettingsState>(value),
    );
  }
}

String _$adminSettingsViewModelHash() =>
    r'afe679d98c55468a108f481dcf848af6b386357e';

/// The server settings the admin may change. The form is held here, not in the
/// widget, so switching tabs does not lose an edit.

abstract class _$AdminSettingsViewModel extends $Notifier<AdminSettingsState> {
  AdminSettingsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminSettingsState, AdminSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminSettingsState, AdminSettingsState>,
              AdminSettingsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
