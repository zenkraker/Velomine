//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class ClubApi {
  ClubApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/v1/club/join-requests/{joinRequestId}/approve' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] joinRequestId (required):
  Future<Response> approveJoinRequestWithHttpInfo(String joinRequestId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-requests/{joinRequestId}/approve'
      .replaceAll('{joinRequestId}', joinRequestId);

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
  /// * [String] joinRequestId (required):
  Future<void> approveJoinRequest(String joinRequestId, { Future<void>? abortTrigger, }) async {
    final response = await approveJoinRequestWithHttpInfo(joinRequestId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/club/join-request' operation and returns the [Response].
  Future<Response> cancelJoinRequestWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-request';

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

  Future<void> cancelJoinRequest({ Future<void>? abortTrigger, }) async {
    final response = await cancelJoinRequestWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/club/join-requests/{joinRequestId}/decline' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] joinRequestId (required):
  Future<Response> declineJoinRequestWithHttpInfo(String joinRequestId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-requests/{joinRequestId}/decline'
      .replaceAll('{joinRequestId}', joinRequestId);

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
  /// * [String] joinRequestId (required):
  Future<void> declineJoinRequest(String joinRequestId, { Future<void>? abortTrigger, }) async {
    final response = await declineJoinRequestWithHttpInfo(joinRequestId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/v1/club' operation and returns the [Response].
  Future<Response> getMyClubWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club';

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

  Future<MyClubResponse?> getMyClub({ Future<void>? abortTrigger, }) async {
    final response = await getMyClubWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MyClubResponse',) as MyClubResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/club/join-request' operation and returns the [Response].
  Future<Response> getMyJoinRequestWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-request';

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

  Future<MyJoinRequestResponse?> getMyJoinRequest({ Future<void>? abortTrigger, }) async {
    final response = await getMyJoinRequestWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MyJoinRequestResponse',) as MyJoinRequestResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/club/join' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [JoinClubRequest] joinClubRequest (required):
  Future<Response> joinClubWithHttpInfo(JoinClubRequest joinClubRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join';

    // ignore: prefer_final_locals
    Object? postBody = joinClubRequest;

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
  /// * [JoinClubRequest] joinClubRequest (required):
  Future<MyClubResponse?> joinClub(JoinClubRequest joinClubRequest, { Future<void>? abortTrigger, }) async {
    final response = await joinClubWithHttpInfo(joinClubRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MyClubResponse',) as MyClubResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/club/leave' operation and returns the [Response].
  Future<Response> leaveClubWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/leave';

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

  Future<void> leaveClub({ Future<void>? abortTrigger, }) async {
    final response = await leaveClubWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/v1/club/join-requests' operation and returns the [Response].
  Future<Response> listJoinRequestsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-requests';

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

  Future<JoinRequestsResponse?> listJoinRequests({ Future<void>? abortTrigger, }) async {
    final response = await listJoinRequestsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'JoinRequestsResponse',) as JoinRequestsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/club/nearby' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [NearbyClubsRequest] nearbyClubsRequest (required):
  Future<Response> nearbyClubsWithHttpInfo(NearbyClubsRequest nearbyClubsRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/nearby';

    // ignore: prefer_final_locals
    Object? postBody = nearbyClubsRequest;

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
  /// * [NearbyClubsRequest] nearbyClubsRequest (required):
  Future<NearbyClubsResponse?> nearbyClubs(NearbyClubsRequest nearbyClubsRequest, { Future<void>? abortTrigger, }) async {
    final response = await nearbyClubsWithHttpInfo(nearbyClubsRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NearbyClubsResponse',) as NearbyClubsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/club/join-request' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [RequestToJoinRequest] requestToJoinRequest (required):
  Future<Response> requestToJoinWithHttpInfo(RequestToJoinRequest requestToJoinRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-request';

    // ignore: prefer_final_locals
    Object? postBody = requestToJoinRequest;

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
  /// * [RequestToJoinRequest] requestToJoinRequest (required):
  Future<MyJoinRequestResponse?> requestToJoin(RequestToJoinRequest requestToJoinRequest, { Future<void>? abortTrigger, }) async {
    final response = await requestToJoinWithHttpInfo(requestToJoinRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MyJoinRequestResponse',) as MyJoinRequestResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/club/join-code' operation and returns the [Response].
  Future<Response> rotateJoinCodeWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/join-code';

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

  Future<JoinCodeResponse?> rotateJoinCode({ Future<void>? abortTrigger, }) async {
    final response = await rotateJoinCodeWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'JoinCodeResponse',) as JoinCodeResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/club/location' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetClubLocationRequest] setClubLocationRequest (required):
  Future<Response> setClubLocationWithHttpInfo(SetClubLocationRequest setClubLocationRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/location';

    // ignore: prefer_final_locals
    Object? postBody = setClubLocationRequest;

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
  /// * [SetClubLocationRequest] setClubLocationRequest (required):
  Future<MyClubResponse?> setClubLocation(SetClubLocationRequest setClubLocationRequest, { Future<void>? abortTrigger, }) async {
    final response = await setClubLocationWithHttpInfo(setClubLocationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MyClubResponse',) as MyClubResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/club/members/{userId}/role' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [SetClubMemberRoleRequest] setClubMemberRoleRequest (required):
  Future<Response> setClubMemberRoleWithHttpInfo(String userId, SetClubMemberRoleRequest setClubMemberRoleRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/club/members/{userId}/role'
      .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = setClubMemberRoleRequest;

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
  /// * [String] userId (required):
  ///
  /// * [SetClubMemberRoleRequest] setClubMemberRoleRequest (required):
  Future<ClubMemberResponse?> setClubMemberRole(String userId, SetClubMemberRoleRequest setClubMemberRoleRequest, { Future<void>? abortTrigger, }) async {
    final response = await setClubMemberRoleWithHttpInfo(userId, setClubMemberRoleRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ClubMemberResponse',) as ClubMemberResponse;
    
    }
    return null;
  }
}
