//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class BikesApi {
  BikesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/templates/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [ApplyTemplateRequest] applyTemplateRequest (required):
  Future<Response> applyTemplateWithHttpInfo(String bikeId, String id, ApplyTemplateRequest applyTemplateRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/templates/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = applyTemplateRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [ApplyTemplateRequest] applyTemplateRequest (required):
  Future<BikeDetailResponse?> applyTemplate(String bikeId, String id, ApplyTemplateRequest applyTemplateRequest, { Future<void>? abortTrigger, }) async {
    final response = await applyTemplateWithHttpInfo(bikeId, id, applyTemplateRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/reminders/{id}/done' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [MarkReminderDoneRequest] markReminderDoneRequest (required):
  Future<Response> completeReminderWithHttpInfo(String bikeId, String id, MarkReminderDoneRequest markReminderDoneRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/reminders/{id}/done'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = markReminderDoneRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [MarkReminderDoneRequest] markReminderDoneRequest (required):
  Future<BikeDetailResponse?> completeReminder(String bikeId, String id, MarkReminderDoneRequest markReminderDoneRequest, { Future<void>? abortTrigger, }) async {
    final response = await completeReminderWithHttpInfo(bikeId, id, markReminderDoneRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateBikeRequest] createBikeRequest (required):
  Future<Response> createBikeWithHttpInfo(CreateBikeRequest createBikeRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes';

    // ignore: prefer_final_locals
    Object? postBody = createBikeRequest;

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
  /// * [CreateBikeRequest] createBikeRequest (required):
  Future<BikeDetailResponse?> createBike(CreateBikeRequest createBikeRequest, { Future<void>? abortTrigger, }) async {
    final response = await createBikeWithHttpInfo(createBikeRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/components' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [CreateComponentRequest] createComponentRequest (required):
  Future<Response> createComponentWithHttpInfo(String bikeId, CreateComponentRequest createComponentRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/components'
      .replaceAll('{bikeId}', bikeId);

    // ignore: prefer_final_locals
    Object? postBody = createComponentRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [CreateComponentRequest] createComponentRequest (required):
  Future<BikeDetailResponse?> createComponent(String bikeId, CreateComponentRequest createComponentRequest, { Future<void>? abortTrigger, }) async {
    final response = await createComponentWithHttpInfo(bikeId, createComponentRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/reminders' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [CreateReminderRequest] createReminderRequest (required):
  Future<Response> createReminderWithHttpInfo(String bikeId, CreateReminderRequest createReminderRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/reminders'
      .replaceAll('{bikeId}', bikeId);

    // ignore: prefer_final_locals
    Object? postBody = createReminderRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [CreateReminderRequest] createReminderRequest (required):
  Future<BikeDetailResponse?> createReminder(String bikeId, CreateReminderRequest createReminderRequest, { Future<void>? abortTrigger, }) async {
    final response = await createReminderWithHttpInfo(bikeId, createReminderRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/service' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [CreateServiceEntryRequest] createServiceEntryRequest (required):
  Future<Response> createServiceEntryWithHttpInfo(String bikeId, CreateServiceEntryRequest createServiceEntryRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/service'
      .replaceAll('{bikeId}', bikeId);

    // ignore: prefer_final_locals
    Object? postBody = createServiceEntryRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [CreateServiceEntryRequest] createServiceEntryRequest (required):
  Future<ServiceEntryResponse?> createServiceEntry(String bikeId, CreateServiceEntryRequest createServiceEntryRequest, { Future<void>? abortTrigger, }) async {
    final response = await createServiceEntryWithHttpInfo(bikeId, createServiceEntryRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ServiceEntryResponse',) as ServiceEntryResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/templates' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateTemplateRequest] createTemplateRequest (required):
  Future<Response> createTemplateWithHttpInfo(CreateTemplateRequest createTemplateRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/templates';

    // ignore: prefer_final_locals
    Object? postBody = createTemplateRequest;

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
  /// * [CreateTemplateRequest] createTemplateRequest (required):
  Future<BikeTemplateResponse?> createTemplate(CreateTemplateRequest createTemplateRequest, { Future<void>? abortTrigger, }) async {
    final response = await createTemplateWithHttpInfo(createTemplateRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeTemplateResponse',) as BikeTemplateResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/v1/bikes/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteBikeWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{id}'
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteBike(String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteBikeWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/bikes/{bikeId}/components/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<Response> deleteComponentWithHttpInfo(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/components/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<void> deleteComponent(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteComponentWithHttpInfo(bikeId, id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/bikes/{bikeId}/reminders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<Response> deleteReminderWithHttpInfo(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/reminders/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<void> deleteReminder(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteReminderWithHttpInfo(bikeId, id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/bikes/{bikeId}/service/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<Response> deleteServiceEntryWithHttpInfo(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/service/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  Future<void> deleteServiceEntry(String bikeId, String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteServiceEntryWithHttpInfo(bikeId, id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/bikes/templates/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteTemplateWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/templates/{id}'
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteTemplate(String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteTemplateWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/v1/bikes/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getBikeWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{id}'
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] id (required):
  Future<BikeDetailResponse?> getBike(String id, { Future<void>? abortTrigger, }) async {
    final response = await getBikeWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes' operation and returns the [Response].
  Future<Response> listBikesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes';

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

  Future<ListBikesResponse?> listBikes({ Future<void>? abortTrigger, }) async {
    final response = await listBikesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListBikesResponse',) as ListBikesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes/component-types' operation and returns the [Response].
  Future<Response> listComponentTypesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/component-types';

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

  Future<ListComponentTypesResponse?> listComponentTypes({ Future<void>? abortTrigger, }) async {
    final response = await listComponentTypesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListComponentTypesResponse',) as ListComponentTypesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes/{bikeId}/service' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] componentId:
  ///
  /// * [int] limit:
  ///
  /// * [DateTime] beforeDate:
  ///
  /// * [String] beforeId:
  Future<Response> listServiceEntriesWithHttpInfo(String bikeId, { String? componentId, int? limit, DateTime? beforeDate, String? beforeId, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/service'
      .replaceAll('{bikeId}', bikeId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (componentId != null) {
      queryParams.addAll(_queryParams('', 'componentId', componentId));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }
    if (beforeDate != null) {
      queryParams.addAll(_queryParams('', 'beforeDate', beforeDate));
    }
    if (beforeId != null) {
      queryParams.addAll(_queryParams('', 'beforeId', beforeId));
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
  /// * [String] bikeId (required):
  ///
  /// * [String] componentId:
  ///
  /// * [int] limit:
  ///
  /// * [DateTime] beforeDate:
  ///
  /// * [String] beforeId:
  Future<ListServiceEntriesResponse?> listServiceEntries(String bikeId, { String? componentId, int? limit, DateTime? beforeDate, String? beforeId, Future<void>? abortTrigger, }) async {
    final response = await listServiceEntriesWithHttpInfo(bikeId, componentId: componentId, limit: limit, beforeDate: beforeDate, beforeId: beforeId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListServiceEntriesResponse',) as ListServiceEntriesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes/{id}/service/jobs' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> listServiceJobsWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{id}/service/jobs'
      .replaceAll('{id}', id);

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

  /// Parameters:
  ///
  /// * [String] id (required):
  Future<ListServiceJobsResponse?> listServiceJobs(String id, { Future<void>? abortTrigger, }) async {
    final response = await listServiceJobsWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListServiceJobsResponse',) as ListServiceJobsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes/templates' operation and returns the [Response].
  Future<Response> listTemplatesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/templates';

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

  Future<ListTemplatesResponse?> listTemplates({ Future<void>? abortTrigger, }) async {
    final response = await listTemplatesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListTemplatesResponse',) as ListTemplatesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{bikeId}/templates' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [SaveBikeAsTemplateRequest] saveBikeAsTemplateRequest (required):
  Future<Response> saveBikeAsTemplateWithHttpInfo(String bikeId, SaveBikeAsTemplateRequest saveBikeAsTemplateRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/templates'
      .replaceAll('{bikeId}', bikeId);

    // ignore: prefer_final_locals
    Object? postBody = saveBikeAsTemplateRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [SaveBikeAsTemplateRequest] saveBikeAsTemplateRequest (required):
  Future<BikeTemplateResponse?> saveBikeAsTemplate(String bikeId, SaveBikeAsTemplateRequest saveBikeAsTemplateRequest, { Future<void>? abortTrigger, }) async {
    final response = await saveBikeAsTemplateWithHttpInfo(bikeId, saveBikeAsTemplateRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeTemplateResponse',) as BikeTemplateResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/bikes/parts' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [String] type:
  ///
  /// * [String] brand:
  ///
  /// * [int] limit:
  Future<Response> searchPartsWithHttpInfo({ String? q, String? type, String? brand, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/parts';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (brand != null) {
      queryParams.addAll(_queryParams('', 'brand', brand));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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
  /// * [String] q:
  ///
  /// * [String] type:
  ///
  /// * [String] brand:
  ///
  /// * [int] limit:
  Future<SearchPartsResponse?> searchParts({ String? q, String? type, String? brand, int? limit, Future<void>? abortTrigger, }) async {
    final response = await searchPartsWithHttpInfo(q: q, type: type, brand: brand, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SearchPartsResponse',) as SearchPartsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/bikes/{id}/default' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> setDefaultBikeWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{id}/default'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  /// * [String] id (required):
  Future<void> setDefaultBike(String id, { Future<void>? abortTrigger, }) async {
    final response = await setDefaultBikeWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'PUT /api/v1/bikes/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateBikeRequest] updateBikeRequest (required):
  Future<Response> updateBikeWithHttpInfo(String id, UpdateBikeRequest updateBikeRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateBikeRequest;

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
  /// * [String] id (required):
  ///
  /// * [UpdateBikeRequest] updateBikeRequest (required):
  Future<BikeDetailResponse?> updateBike(String id, UpdateBikeRequest updateBikeRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateBikeWithHttpInfo(id, updateBikeRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/bikes/{bikeId}/components/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateComponentRequest] updateComponentRequest (required):
  Future<Response> updateComponentWithHttpInfo(String bikeId, String id, UpdateComponentRequest updateComponentRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/components/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateComponentRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateComponentRequest] updateComponentRequest (required):
  Future<BikeDetailResponse?> updateComponent(String bikeId, String id, UpdateComponentRequest updateComponentRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateComponentWithHttpInfo(bikeId, id, updateComponentRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/bikes/{bikeId}/reminders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateReminderRequest] updateReminderRequest (required):
  Future<Response> updateReminderWithHttpInfo(String bikeId, String id, UpdateReminderRequest updateReminderRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/reminders/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateReminderRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateReminderRequest] updateReminderRequest (required):
  Future<BikeDetailResponse?> updateReminder(String bikeId, String id, UpdateReminderRequest updateReminderRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateReminderWithHttpInfo(bikeId, id, updateReminderRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeDetailResponse',) as BikeDetailResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/bikes/{bikeId}/service/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateServiceEntryRequest] updateServiceEntryRequest (required):
  Future<Response> updateServiceEntryWithHttpInfo(String bikeId, String id, UpdateServiceEntryRequest updateServiceEntryRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/{bikeId}/service/{id}'
      .replaceAll('{bikeId}', bikeId)
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateServiceEntryRequest;

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
  /// * [String] bikeId (required):
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateServiceEntryRequest] updateServiceEntryRequest (required):
  Future<ServiceEntryResponse?> updateServiceEntry(String bikeId, String id, UpdateServiceEntryRequest updateServiceEntryRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateServiceEntryWithHttpInfo(bikeId, id, updateServiceEntryRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ServiceEntryResponse',) as ServiceEntryResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/bikes/templates/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateTemplateRequest] updateTemplateRequest (required):
  Future<Response> updateTemplateWithHttpInfo(String id, UpdateTemplateRequest updateTemplateRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bikes/templates/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateTemplateRequest;

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
  /// * [String] id (required):
  ///
  /// * [UpdateTemplateRequest] updateTemplateRequest (required):
  Future<BikeTemplateResponse?> updateTemplate(String id, UpdateTemplateRequest updateTemplateRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateTemplateWithHttpInfo(id, updateTemplateRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BikeTemplateResponse',) as BikeTemplateResponse;
    
    }
    return null;
  }
}
