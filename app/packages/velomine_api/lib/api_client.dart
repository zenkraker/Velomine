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
        case 'AdminUserSummary':
          return AdminUserSummary.fromJson(value);
        case 'BikeDetailResponse':
          return BikeDetailResponse.fromJson(value);
        case 'BikeResponse':
          return BikeResponse.fromJson(value);
        case 'ComponentResponse':
          return ComponentResponse.fromJson(value);
        case 'ComponentTypeResponse':
          return ComponentTypeResponse.fromJson(value);
        case 'CreateBikeRequest':
          return CreateBikeRequest.fromJson(value);
        case 'CreateComponentRequest':
          return CreateComponentRequest.fromJson(value);
        case 'CreateGoalRequest':
          return CreateGoalRequest.fromJson(value);
        case 'ExchangeSsoCodeRequest':
          return ExchangeSsoCodeRequest.fromJson(value);
        case 'GoalResponse':
          return GoalResponse.fromJson(value);
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
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'MeResponse':
          return MeResponse.fromJson(value);
        case 'NotificationResponse':
          return NotificationResponse.fromJson(value);
        case 'OverviewResponse':
          return OverviewResponse.fromJson(value);
        case 'PeriodTotals':
          return PeriodTotals.fromJson(value);
        case 'ProblemDetails':
          return ProblemDetails.fromJson(value);
        case 'ProblemDetails2':
          return ProblemDetails2.fromJson(value);
        case 'ProblemDetails2ErrorsInner':
          return ProblemDetails2ErrorsInner.fromJson(value);
        case 'ProfileResponse':
          return ProfileResponse.fromJson(value);
        case 'RefreshRequest':
          return RefreshRequest.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RegisterResponse':
          return RegisterResponse.fromJson(value);
        case 'RideResponse':
          return RideResponse.fromJson(value);
        case 'RideStreamsResponse':
          return RideStreamsResponse.fromJson(value);
        case 'ServerInfoResponse':
          return ServerInfoResponse.fromJson(value);
        case 'SetRideBikeRequest':
          return SetRideBikeRequest.fromJson(value);
        case 'SetUserRolesRequest':
          return SetUserRolesRequest.fromJson(value);
        case 'SettingsResponse':
          return SettingsResponse.fromJson(value);
        case 'SmtpStatus':
          return SmtpStatus.fromJson(value);
        case 'SsoInfoResponse':
          return SsoInfoResponse.fromJson(value);
        case 'SsoStatus':
          return SsoStatus.fromJson(value);
        case 'TokenResponse':
          return TokenResponse.fromJson(value);
        case 'TotalsResponse':
          return TotalsResponse.fromJson(value);
        case 'UpdateBikeRequest':
          return UpdateBikeRequest.fromJson(value);
        case 'UpdateComponentRequest':
          return UpdateComponentRequest.fromJson(value);
        case 'UpdateGoalRequest':
          return UpdateGoalRequest.fromJson(value);
        case 'UpdateProfileRequest':
          return UpdateProfileRequest.fromJson(value);
        case 'UpdateSettingsRequest':
          return UpdateSettingsRequest.fromJson(value);
        case 'UploadRideResponse':
          return UploadRideResponse.fromJson(value);
        case 'UserSummary':
          return UserSummary.fromJson(value);
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
