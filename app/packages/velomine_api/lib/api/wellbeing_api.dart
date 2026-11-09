//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class WellbeingApi {
  WellbeingApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/v1/wellbeing' operation and returns the [Response].
  Future<Response> getWellbeingWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/wellbeing';

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

  Future<WellbeingResponse?> getWellbeing({ Future<void>? abortTrigger, }) async {
    final response = await getWellbeingWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WellbeingResponse',) as WellbeingResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/wellbeing/consent' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [WellbeingConsentRequest] wellbeingConsentRequest (required):
  Future<Response> giveWellbeingConsentWithHttpInfo(WellbeingConsentRequest wellbeingConsentRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/wellbeing/consent';

    // ignore: prefer_final_locals
    Object? postBody = wellbeingConsentRequest;

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
  /// * [WellbeingConsentRequest] wellbeingConsentRequest (required):
  Future<WellbeingResponse?> giveWellbeingConsent(WellbeingConsentRequest wellbeingConsentRequest, { Future<void>? abortTrigger, }) async {
    final response = await giveWellbeingConsentWithHttpInfo(wellbeingConsentRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WellbeingResponse',) as WellbeingResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/wellbeing/check-ins' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] days:
  Future<Response> listCheckInsWithHttpInfo({ int? days, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/wellbeing/check-ins';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (days != null) {
      queryParams.addAll(_queryParams('', 'days', days));
    }

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

  /// Parameters:
  ///
  /// * [int] days:
  Future<CheckInsResponse?> listCheckIns({ int? days, Future<void>? abortTrigger, }) async {
    final response = await listCheckInsWithHttpInfo(days: days, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CheckInsResponse',) as CheckInsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/wellbeing/check-ins/today' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SaveCheckInRequest] saveCheckInRequest (required):
  Future<Response> saveCheckInWithHttpInfo(SaveCheckInRequest saveCheckInRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/wellbeing/check-ins/today';

    // ignore: prefer_final_locals
    Object? postBody = saveCheckInRequest;

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
  /// * [SaveCheckInRequest] saveCheckInRequest (required):
  Future<CheckInResponse?> saveCheckIn(SaveCheckInRequest saveCheckInRequest, { Future<void>? abortTrigger, }) async {
    final response = await saveCheckInWithHttpInfo(saveCheckInRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CheckInResponse',) as CheckInResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/v1/wellbeing/consent' operation and returns the [Response].
  Future<Response> withdrawWellbeingConsentWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/wellbeing/consent';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  Future<WellbeingResponse?> withdrawWellbeingConsent({ Future<void>? abortTrigger, }) async {
    final response = await withdrawWellbeingConsentWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WellbeingResponse',) as WellbeingResponse;
    
    }
    return null;
  }
}
