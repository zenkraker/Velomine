// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminData)
final adminDataProvider = AdminDataProvider._();

final class AdminDataProvider
    extends $FunctionalProvider<AdminData, AdminData, AdminData>
    with $Provider<AdminData> {
  AdminDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminDataHash();

  @$internal
  @override
  $ProviderElement<AdminData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminData create(Ref ref) {
    return adminData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminData>(value),
    );
  }
}

String _$adminDataHash() => r'ff93567d0a8650a2372af36f48ce0df7c97c63b4';
