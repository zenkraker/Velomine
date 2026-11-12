// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'units.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The units on screen. They follow the account, so a choice on the web is the
/// same on the phone. Signed out, the app shows metric.

@ProviderFor(UnitsChoiceViewModel)
final unitsChoiceViewModelProvider = UnitsChoiceViewModelProvider._();

/// The units on screen. They follow the account, so a choice on the web is the
/// same on the phone. Signed out, the app shows metric.
final class UnitsChoiceViewModelProvider
    extends $NotifierProvider<UnitsChoiceViewModel, Units> {
  /// The units on screen. They follow the account, so a choice on the web is the
  /// same on the phone. Signed out, the app shows metric.
  UnitsChoiceViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unitsChoiceViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unitsChoiceViewModelHash();

  @$internal
  @override
  UnitsChoiceViewModel create() => UnitsChoiceViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Units value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Units>(value),
    );
  }
}

String _$unitsChoiceViewModelHash() =>
    r'7244a495180c9077eaf4d97e9c6efd8d386df6ca';

/// The units on screen. They follow the account, so a choice on the web is the
/// same on the phone. Signed out, the app shows metric.

abstract class _$UnitsChoiceViewModel extends $Notifier<Units> {
  Units build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Units, Units>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Units, Units>,
              Units,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
