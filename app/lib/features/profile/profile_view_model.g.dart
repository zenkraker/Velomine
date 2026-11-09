// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's profile. Kept alive for the session; a sign-out rebuilds it
/// empty, so the next account never sees the last one's numbers.

@ProviderFor(ProfileViewModel)
final profileViewModelProvider = ProfileViewModelProvider._();

/// The member's profile. Kept alive for the session; a sign-out rebuilds it
/// empty, so the next account never sees the last one's numbers.
final class ProfileViewModelProvider
    extends $NotifierProvider<ProfileViewModel, ProfileState> {
  /// The member's profile. Kept alive for the session; a sign-out rebuilds it
  /// empty, so the next account never sees the last one's numbers.
  ProfileViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileViewModelHash();

  @$internal
  @override
  ProfileViewModel create() => ProfileViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileState>(value),
    );
  }
}

String _$profileViewModelHash() => r'0e5264be05f4d808808e8c30085e1fe2e2039cd8';

/// The member's profile. Kept alive for the session; a sign-out rebuilds it
/// empty, so the next account never sees the last one's numbers.

abstract class _$ProfileViewModel extends $Notifier<ProfileState> {
  ProfileState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileState, ProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileState, ProfileState>,
              ProfileState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
