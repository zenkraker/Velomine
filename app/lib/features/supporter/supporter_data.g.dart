// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supporter_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supporterData)
final supporterDataProvider = SupporterDataProvider._();

final class SupporterDataProvider
    extends $FunctionalProvider<SupporterData, SupporterData, SupporterData>
    with $Provider<SupporterData> {
  SupporterDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supporterDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supporterDataHash();

  @$internal
  @override
  $ProviderElement<SupporterData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupporterData create(Ref ref) {
    return supporterData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupporterData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupporterData>(value),
    );
  }
}

String _$supporterDataHash() => r'502e700f5c07ec3e23ce79dd840292ffc5e313f5';
