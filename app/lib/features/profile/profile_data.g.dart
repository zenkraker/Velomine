// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileData)
final profileDataProvider = ProfileDataProvider._();

final class ProfileDataProvider
    extends $FunctionalProvider<ProfileData, ProfileData, ProfileData>
    with $Provider<ProfileData> {
  ProfileDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileDataHash();

  @$internal
  @override
  $ProviderElement<ProfileData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileData create(Ref ref) {
    return profileData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileData>(value),
    );
  }
}

String _$profileDataHash() => r'faa12466e5a271662984e645129186f6dca72be4';
