//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType, {
    Future<void>? abortTrigger,
  }) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = AbortableStreamedRequest(method, uri, abortTrigger: abortTrigger);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = AbortableMultipartRequest(method, uri, abortTrigger: abortTrigger);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      final request = AbortableRequest(method, uri, abortTrigger: abortTrigger);
      if (nullableHeaderParams != null) {
        request.headers.addAll(nullableHeaderParams);
      }
      if (msgBody is String && msgBody.isNotEmpty) {
        request.body = msgBody;
      } else if (msgBody is List<int> && msgBody.isNotEmpty) {
        request.bodyBytes = msgBody;
      } else if (msgBody is Map<String, String>) {
        request.bodyFields = msgBody;
      }
      final response = await _client.send(request);
      return Response.fromStream(response);
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AdminClubListResponse':
          return AdminClubListResponse.fromJson(value);
        case 'AdminClubResponse':
          return AdminClubResponse.fromJson(value);
        case 'AdminUserSummary':
          return AdminUserSummary.fromJson(value);
        case 'ApplyTemplateRequest':
          return ApplyTemplateRequest.fromJson(value);
        case 'BikeDetailResponse':
          return BikeDetailResponse.fromJson(value);
        case 'BikeResponse':
          return BikeResponse.fromJson(value);
        case 'BikeTemplateResponse':
          return BikeTemplateResponse.fromJson(value);
        case 'CalendarFeedAddressResponse':
          return CalendarFeedAddressResponse.fromJson(value);
        case 'CalendarFeedStatusResponse':
          return CalendarFeedStatusResponse.fromJson(value);
        case 'CatalogueAdminResponse':
          return CatalogueAdminResponse.fromJson(value);
        case 'CatalogueContributionResponse':
          return CatalogueContributionResponse.fromJson(value);
        case 'CatalogueCountsResponse':
          return CatalogueCountsResponse.fromJson(value);
        case 'ChangePasswordRequest':
          return ChangePasswordRequest.fromJson(value);
        case 'CheckInResponse':
          return CheckInResponse.fromJson(value);
        case 'CheckInsResponse':
          return CheckInsResponse.fromJson(value);
        case 'ClubMemberResponse':
          return ClubMemberResponse.fromJson(value);
        case 'ClubPlanResponse':
          return ClubPlanResponse.fromJson(value);
        case 'ClubResponse':
          return ClubResponse.fromJson(value);
        case 'ClubRideDetailResponse':
          return ClubRideDetailResponse.fromJson(value);
        case 'ClubRideListResponse':
          return ClubRideListResponse.fromJson(value);
        case 'ClubRideParticipantResponse':
          return ClubRideParticipantResponse.fromJson(value);
        case 'ClubRideSummaryResponse':
          return ClubRideSummaryResponse.fromJson(value);
        case 'CoachAthleteResponse':
          return CoachAthleteResponse.fromJson(value);
        case 'CoachAthletesResponse':
          return CoachAthletesResponse.fromJson(value);
        case 'CoachRpeResponse':
          return CoachRpeResponse.fromJson(value);
        case 'CoachWellbeingResponse':
          return CoachWellbeingResponse.fromJson(value);
        case 'ComponentResponse':
          return ComponentResponse.fromJson(value);
        case 'ComponentTypeResponse':
          return ComponentTypeResponse.fromJson(value);
        case 'CreateBikeRequest':
          return CreateBikeRequest.fromJson(value);
        case 'CreateClubRequest':
          return CreateClubRequest.fromJson(value);
        case 'CreateComponentRequest':
          return CreateComponentRequest.fromJson(value);
        case 'CreateGoalRequest':
          return CreateGoalRequest.fromJson(value);
        case 'CreatePrivacyZoneRequest':
          return CreatePrivacyZoneRequest.fromJson(value);
        case 'CreateReminderRequest':
          return CreateReminderRequest.fromJson(value);
        case 'CreateRouteRequest':
          return CreateRouteRequest.fromJson(value);
        case 'CreateServiceEntryRequest':
          return CreateServiceEntryRequest.fromJson(value);
        case 'CreateTemplateRequest':
          return CreateTemplateRequest.fromJson(value);
        case 'DeleteMyAccountRequest':
          return DeleteMyAccountRequest.fromJson(value);
        case 'EnableTwoFactorRequest':
          return EnableTwoFactorRequest.fromJson(value);
        case 'ExchangeSsoTokenRequest':
          return ExchangeSsoTokenRequest.fromJson(value);
        case 'ExportLinkResponse':
          return ExportLinkResponse.fromJson(value);
        case 'ForgotPasswordRequest':
          return ForgotPasswordRequest.fromJson(value);
        case 'FtpEstimate':
          return FtpEstimate.fromJson(value);
        case 'GoalResponse':
          return GoalResponse.fromJson(value);
        case 'JoinClubRequest':
          return JoinClubRequest.fromJson(value);
        case 'JoinCodeResponse':
          return JoinCodeResponse.fromJson(value);
        case 'JoinRequestResponse':
          return JoinRequestResponse.fromJson(value);
        case 'JoinRequestsResponse':
          return JoinRequestsResponse.fromJson(value);
        case 'LapResponse':
          return LapResponse.fromJson(value);
        case 'ListAdminUsersResponse':
          return ListAdminUsersResponse.fromJson(value);
        case 'ListBikesResponse':
          return ListBikesResponse.fromJson(value);
        case 'ListComponentTypesResponse':
          return ListComponentTypesResponse.fromJson(value);
        case 'ListGoalsResponse':
          return ListGoalsResponse.fromJson(value);
        case 'ListNotificationsResponse':
          return ListNotificationsResponse.fromJson(value);
        case 'ListRidesResponse':
          return ListRidesResponse.fromJson(value);
        case 'ListServiceEntriesResponse':
          return ListServiceEntriesResponse.fromJson(value);
        case 'ListServiceJobsResponse':
          return ListServiceJobsResponse.fromJson(value);
        case 'ListTemplatesResponse':
          return ListTemplatesResponse.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'LoginTwoFactorRequest':
          return LoginTwoFactorRequest.fromJson(value);
        case 'MaintenanceJob':
          return MaintenanceJob.fromJson(value);
        case 'MaintenanceReminderResponse':
          return MaintenanceReminderResponse.fromJson(value);
        case 'MarkReminderDoneRequest':
          return MarkReminderDoneRequest.fromJson(value);
        case 'MeResponse':
          return MeResponse.fromJson(value);
        case 'MyClubResponse':
          return MyClubResponse.fromJson(value);
        case 'MyJoinRequestResponse':
          return MyJoinRequestResponse.fromJson(value);
        case 'NearbyClubResponse':
          return NearbyClubResponse.fromJson(value);
        case 'NearbyClubsRequest':
          return NearbyClubsRequest.fromJson(value);
        case 'NearbyClubsResponse':
          return NearbyClubsResponse.fromJson(value);
        case 'NotificationResponse':
          return NotificationResponse.fromJson(value);
        case 'OverviewResponse':
          return OverviewResponse.fromJson(value);
        case 'PartResponse':
          return PartResponse.fromJson(value);
        case 'PasswordConfirmation':
          return PasswordConfirmation.fromJson(value);
        case 'PasswordResetLinkResponse':
          return PasswordResetLinkResponse.fromJson(value);
        case 'PendingJoinRequestResponse':
          return PendingJoinRequestResponse.fromJson(value);
        case 'PeriodTotals':
          return PeriodTotals.fromJson(value);
        case 'PlanClubRideRequest':
          return PlanClubRideRequest.fromJson(value);
        case 'PowerCurvePoint':
          return PowerCurvePoint.fromJson(value);
        case 'PowerCurveResponse':
          return PowerCurveResponse.fromJson(value);
        case 'PrivacyResponse':
          return PrivacyResponse.fromJson(value);
        case 'PrivacyStreamsResponse':
          return PrivacyStreamsResponse.fromJson(value);
        case 'PrivacyZoneResponse':
          return PrivacyZoneResponse.fromJson(value);
        case 'ProblemDetails':
          return ProblemDetails.fromJson(value);
        case 'ProfileResponse':
          return ProfileResponse.fromJson(value);
        case 'ReadinessFactor':
          return ReadinessFactor.fromJson(value);
        case 'ReadinessResponse':
          return ReadinessResponse.fromJson(value);
        case 'RecoveryCodesResponse':
          return RecoveryCodesResponse.fromJson(value);
        case 'RefreshRequest':
          return RefreshRequest.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RegisterResponse':
          return RegisterResponse.fromJson(value);
        case 'RequestToJoinRequest':
          return RequestToJoinRequest.fromJson(value);
        case 'ResetPasswordRequest':
          return ResetPasswordRequest.fromJson(value);
        case 'RideFeelResponse':
          return RideFeelResponse.fromJson(value);
        case 'RideImportResponse':
          return RideImportResponse.fromJson(value);
        case 'RideLapsResponse':
          return RideLapsResponse.fromJson(value);
        case 'RideResponse':
          return RideResponse.fromJson(value);
        case 'RideStreamsResponse':
          return RideStreamsResponse.fromJson(value);
        case 'RouteDetailResponse':
          return RouteDetailResponse.fromJson(value);
        case 'RouteDownloadLinkResponse':
          return RouteDownloadLinkResponse.fromJson(value);
        case 'RouteDraftResponse':
          return RouteDraftResponse.fromJson(value);
        case 'RouteListResponse':
          return RouteListResponse.fromJson(value);
        case 'RouteSummaryResponse':
          return RouteSummaryResponse.fromJson(value);
        case 'SaveBikeAsTemplateRequest':
          return SaveBikeAsTemplateRequest.fromJson(value);
        case 'SaveCheckInRequest':
          return SaveCheckInRequest.fromJson(value);
        case 'SaveRideFeelRequest':
          return SaveRideFeelRequest.fromJson(value);
        case 'SearchPartsResponse':
          return SearchPartsResponse.fromJson(value);
        case 'ServerInfoResponse':
          return ServerInfoResponse.fromJson(value);
        case 'ServiceEntryResponse':
          return ServiceEntryResponse.fromJson(value);
        case 'SessionResponse':
          return SessionResponse.fromJson(value);
        case 'SetClubLocationRequest':
          return SetClubLocationRequest.fromJson(value);
        case 'SetClubMemberRoleRequest':
          return SetClubMemberRoleRequest.fromJson(value);
        case 'SetClubOwnerRequest':
          return SetClubOwnerRequest.fromJson(value);
        case 'SetClubPlanRequest':
          return SetClubPlanRequest.fromJson(value);
        case 'SetFtpRequest':
          return SetFtpRequest.fromJson(value);
        case 'SetMyLanguageRequest':
          return SetMyLanguageRequest.fromJson(value);
        case 'SetRideBikeRequest':
          return SetRideBikeRequest.fromJson(value);
        case 'SetRideDetailsRequest':
          return SetRideDetailsRequest.fromJson(value);
        case 'SetRideTypeRequest':
          return SetRideTypeRequest.fromJson(value);
        case 'SetTelemetryRequest':
          return SetTelemetryRequest.fromJson(value);
        case 'SetUserRolesRequest':
          return SetUserRolesRequest.fromJson(value);
        case 'SettingsResponse':
          return SettingsResponse.fromJson(value);
        case 'ShareViewResponse':
          return ShareViewResponse.fromJson(value);
        case 'ShareViewsResponse':
          return ShareViewsResponse.fromJson(value);
        case 'SharingResponse':
          return SharingResponse.fromJson(value);
        case 'SmtpStatus':
          return SmtpStatus.fromJson(value);
        case 'SsoInfoResponse':
          return SsoInfoResponse.fromJson(value);
        case 'SsoStatus':
          return SsoStatus.fromJson(value);
        case 'StartClubRequest':
          return StartClubRequest.fromJson(value);
        case 'StartRideImportResponse':
          return StartRideImportResponse.fromJson(value);
        case 'TelemetryResponse':
          return TelemetryResponse.fromJson(value);
        case 'TemplatePartRequest':
          return TemplatePartRequest.fromJson(value);
        case 'TemplatePartResponse':
          return TemplatePartResponse.fromJson(value);
        case 'TokenResponse':
          return TokenResponse.fromJson(value);
        case 'TotalsResponse':
          return TotalsResponse.fromJson(value);
        case 'TrainingDay':
          return TrainingDay.fromJson(value);
        case 'TrainingResponse':
          return TrainingResponse.fromJson(value);
        case 'TwoFactorRequiredResponse':
          return TwoFactorRequiredResponse.fromJson(value);
        case 'TwoFactorSetup':
          return TwoFactorSetup.fromJson(value);
        case 'TwoFactorState':
          return TwoFactorState.fromJson(value);
        case 'UpdateBikeRequest':
          return UpdateBikeRequest.fromJson(value);
        case 'UpdateClubRequest':
          return UpdateClubRequest.fromJson(value);
        case 'UpdateClubRideRequest':
          return UpdateClubRideRequest.fromJson(value);
        case 'UpdateComponentRequest':
          return UpdateComponentRequest.fromJson(value);
        case 'UpdateGoalRequest':
          return UpdateGoalRequest.fromJson(value);
        case 'UpdatePrivacyRequest':
          return UpdatePrivacyRequest.fromJson(value);
        case 'UpdateProfileRequest':
          return UpdateProfileRequest.fromJson(value);
        case 'UpdateReminderRequest':
          return UpdateReminderRequest.fromJson(value);
        case 'UpdateRouteRequest':
          return UpdateRouteRequest.fromJson(value);
        case 'UpdateServiceEntryRequest':
          return UpdateServiceEntryRequest.fromJson(value);
        case 'UpdateSettingsRequest':
          return UpdateSettingsRequest.fromJson(value);
        case 'UpdateSharingRequest':
          return UpdateSharingRequest.fromJson(value);
        case 'UpdateTemplateRequest':
          return UpdateTemplateRequest.fromJson(value);
        case 'UploadRideResponse':
          return UploadRideResponse.fromJson(value);
        case 'UserSummary':
          return UserSummary.fromJson(value);
        case 'Vo2MaxEstimate':
          return Vo2MaxEstimate.fromJson(value);
        case 'WellbeingConsentRequest':
          return WellbeingConsentRequest.fromJson(value);
        case 'WellbeingResponse':
          return WellbeingResponse.fromJson(value);
        case 'ZoneTime':
          return ZoneTime.fromJson(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
