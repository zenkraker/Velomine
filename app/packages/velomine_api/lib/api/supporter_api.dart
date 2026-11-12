//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class SupporterApi {
  SupporterApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/v1/supporter/activate' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ActivateSupporterRequest] activateSupporterRequest (required):
  Future<Response> activateSupporterWithHttpInfo(ActivateSupporterRequest activateSupporterRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/supporter/activate';

    // ignore: prefer_final_locals
    Object? postBody = activateSupporterRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Parameters:
  ///
  /// * [ActivateSupporterRequest] activateSupporterRequest (required):
  Future<SupporterStatusResponse?> activateSupporter(ActivateSupporterRequest activateSupporterRequest, { Future<void>? abortTrigger, }) async {
    final response = await activateSupporterWithHttpInfo(activateSupporterRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SupporterStatusResponse',) as SupporterStatusResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/supporter' operation and returns the [Response].
  Future<Response> getSupporterStatusWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/supporter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  Future<SupporterStatusResponse?> getSupporterStatus({ Future<void>? abortTrigger, }) async {
    final response = await getSupporterStatusWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SupporterStatusResponse',) as SupporterStatusResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/supporter/hidden' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetSupporterHiddenRequest] setSupporterHiddenRequest (required):
  Future<Response> setSupporterHiddenWithHttpInfo(SetSupporterHiddenRequest setSupporterHiddenRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/supporter/hidden';

    // ignore: prefer_final_locals
    Object? postBody = setSupporterHiddenRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Parameters:
  ///
  /// * [SetSupporterHiddenRequest] setSupporterHiddenRequest (required):
  Future<RiderLicenceResponse?> setSupporterHidden(SetSupporterHiddenRequest setSupporterHiddenRequest, { Future<void>? abortTrigger, }) async {
    final response = await setSupporterHiddenWithHttpInfo(setSupporterHiddenRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RiderLicenceResponse',) as RiderLicenceResponse;
    
    }
    return null;
  }
}
