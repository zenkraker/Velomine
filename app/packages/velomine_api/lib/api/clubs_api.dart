//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class ClubsApi {
  ClubsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes/{userId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  Future<Response> coachGetCoachAthleteWithHttpInfo(String clubId, String userId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes/{userId}'
      .replaceAll('{clubId}', clubId)
      .replaceAll('{userId}', userId);

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
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  Future<CoachAthleteResponse?> coachGetCoachAthlete(String clubId, String userId, { Future<void>? abortTrigger, }) async {
    final response = await coachGetCoachAthleteWithHttpInfo(clubId, userId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CoachAthleteResponse',) as CoachAthleteResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes/{userId}/rides/{rideId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] rideId (required):
  Future<Response> coachGetCoachRideWithHttpInfo(String clubId, String userId, String rideId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes/{userId}/rides/{rideId}'
      .replaceAll('{clubId}', clubId)
      .replaceAll('{userId}', userId)
      .replaceAll('{rideId}', rideId);

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
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] rideId (required):
  Future<RideResponse?> coachGetCoachRide(String clubId, String userId, String rideId, { Future<void>? abortTrigger, }) async {
    final response = await coachGetCoachRideWithHttpInfo(clubId, userId, rideId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RideResponse',) as RideResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes/{userId}/rides/{rideId}/streams' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] rideId (required):
  ///
  /// * [int] maxPoints:
  Future<Response> coachGetCoachRideStreamsWithHttpInfo(String clubId, String userId, String rideId, { int? maxPoints, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes/{userId}/rides/{rideId}/streams'
      .replaceAll('{clubId}', clubId)
      .replaceAll('{userId}', userId)
      .replaceAll('{rideId}', rideId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (maxPoints != null) {
      queryParams.addAll(_queryParams('', 'maxPoints', maxPoints));
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
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] rideId (required):
  ///
  /// * [int] maxPoints:
  Future<RideStreamsResponse?> coachGetCoachRideStreams(String clubId, String userId, String rideId, { int? maxPoints, Future<void>? abortTrigger, }) async {
    final response = await coachGetCoachRideStreamsWithHttpInfo(clubId, userId, rideId, maxPoints: maxPoints, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RideStreamsResponse',) as RideStreamsResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes/{userId}/training' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [int] days:
  Future<Response> coachGetCoachTrainingWithHttpInfo(String clubId, String userId, { int? days, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes/{userId}/training'
      .replaceAll('{clubId}', clubId)
      .replaceAll('{userId}', userId);

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
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [int] days:
  Future<TrainingResponse?> coachGetCoachTraining(String clubId, String userId, { int? days, Future<void>? abortTrigger, }) async {
    final response = await coachGetCoachTrainingWithHttpInfo(clubId, userId, days: days, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TrainingResponse',) as TrainingResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  Future<Response> coachListCoachAthletesWithHttpInfo(String clubId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes'
      .replaceAll('{clubId}', clubId);

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
  /// * [String] clubId (required):
  Future<CoachAthletesResponse?> coachListCoachAthletes(String clubId, { Future<void>? abortTrigger, }) async {
    final response = await coachListCoachAthletesWithHttpInfo(clubId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CoachAthletesResponse',) as CoachAthletesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/clubs/{clubId}/athletes/{userId}/rides' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<Response> coachListCoachRidesWithHttpInfo(String clubId, String userId, { String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/clubs/{clubId}/athletes/{userId}/rides'
      .replaceAll('{clubId}', clubId)
      .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
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
  /// * [String] clubId (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<ListRidesResponse?> coachListCoachRides(String clubId, String userId, { String? cursor, int? limit, Future<void>? abortTrigger, }) async {
    final response = await coachListCoachRidesWithHttpInfo(clubId, userId, cursor: cursor, limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListRidesResponse',) as ListRidesResponse;
    
    }
    return null;
  }
}
