// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_upload_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A folder or several files dropped on the page, sent a few at a time and summed up once.

@ProviderFor(BulkUploadViewModel)
final bulkUploadViewModelProvider = BulkUploadViewModelProvider._();

/// A folder or several files dropped on the page, sent a few at a time and summed up once.
final class BulkUploadViewModelProvider
    extends $NotifierProvider<BulkUploadViewModel, BulkUploadState> {
  /// A folder or several files dropped on the page, sent a few at a time and summed up once.
  BulkUploadViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bulkUploadViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bulkUploadViewModelHash();

  @$internal
  @override
  BulkUploadViewModel create() => BulkUploadViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BulkUploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BulkUploadState>(value),
    );
  }
}

String _$bulkUploadViewModelHash() =>
    r'2cecb0577031dca794b1466e401f1f2d3c2085a4';

/// A folder or several files dropped on the page, sent a few at a time and summed up once.

abstract class _$BulkUploadViewModel extends $Notifier<BulkUploadState> {
  BulkUploadState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BulkUploadState, BulkUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BulkUploadState, BulkUploadState>,
              BulkUploadState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
