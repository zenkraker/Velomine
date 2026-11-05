//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library velomine_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';
part 'optional.dart';

part 'api/accounts_api.dart';
part 'api/analytics_api.dart';
part 'api/bikes_api.dart';
part 'api/notifications_api.dart';
part 'api/rides_api.dart';
part 'api/server_api.dart';

part 'model/bike_detail_response.dart';
part 'model/bike_response.dart';
part 'model/component_response.dart';
part 'model/component_type_response.dart';
part 'model/create_bike_request.dart';
part 'model/create_component_request.dart';
part 'model/create_goal_request.dart';
part 'model/goal_response.dart';
part 'model/list_bikes_response.dart';
part 'model/list_component_types_response.dart';
part 'model/list_goals_response.dart';
part 'model/list_notifications_response.dart';
part 'model/list_rides_response.dart';
part 'model/login_request.dart';
part 'model/me_response.dart';
part 'model/notification_response.dart';
part 'model/period_totals.dart';
part 'model/problem_details.dart';
part 'model/problem_details2.dart';
part 'model/problem_details2_errors_inner.dart';
part 'model/profile_response.dart';
part 'model/refresh_request.dart';
part 'model/register_request.dart';
part 'model/register_response.dart';
part 'model/ride_response.dart';
part 'model/ride_streams_response.dart';
part 'model/server_info_response.dart';
part 'model/set_ride_bike_request.dart';
part 'model/sso_info_response.dart';
part 'model/token_response.dart';
part 'model/totals_response.dart';
part 'model/update_bike_request.dart';
part 'model/update_component_request.dart';
part 'model/update_goal_request.dart';
part 'model/update_profile_request.dart';
part 'model/upload_ride_response.dart';
part 'model/user_summary.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
