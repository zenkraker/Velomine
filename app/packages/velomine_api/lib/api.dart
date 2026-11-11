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
part 'api/admin_api.dart';
part 'api/analytics_api.dart';
part 'api/bikes_api.dart';
part 'api/calendar_api.dart';
part 'api/club_api.dart';
part 'api/clubs_api.dart';
part 'api/notifications_api.dart';
part 'api/privacy_api.dart';
part 'api/rides_api.dart';
part 'api/routes_api.dart';
part 'api/server_api.dart';
part 'api/sharing_api.dart';
part 'api/wellbeing_api.dart';

part 'model/admin_club_list_response.dart';
part 'model/admin_club_response.dart';
part 'model/admin_user_summary.dart';
part 'model/apply_template_request.dart';
part 'model/bike_detail_response.dart';
part 'model/bike_response.dart';
part 'model/bike_template_response.dart';
part 'model/calendar_feed_address_response.dart';
part 'model/calendar_feed_status_response.dart';
part 'model/catalogue_admin_response.dart';
part 'model/catalogue_contribution_response.dart';
part 'model/catalogue_counts_response.dart';
part 'model/change_password_request.dart';
part 'model/check_in_response.dart';
part 'model/check_ins_response.dart';
part 'model/club_member_response.dart';
part 'model/club_plan_response.dart';
part 'model/club_response.dart';
part 'model/club_ride_detail_response.dart';
part 'model/club_ride_list_response.dart';
part 'model/club_ride_participant_response.dart';
part 'model/club_ride_summary_response.dart';
part 'model/coach_athlete_response.dart';
part 'model/coach_athletes_response.dart';
part 'model/coach_rpe_response.dart';
part 'model/coach_wellbeing_response.dart';
part 'model/component_response.dart';
part 'model/component_type_response.dart';
part 'model/create_bike_request.dart';
part 'model/create_club_request.dart';
part 'model/create_component_request.dart';
part 'model/create_goal_request.dart';
part 'model/create_privacy_zone_request.dart';
part 'model/create_reminder_request.dart';
part 'model/create_route_request.dart';
part 'model/create_service_entry_request.dart';
part 'model/create_template_request.dart';
part 'model/delete_my_account_request.dart';
part 'model/enable_two_factor_request.dart';
part 'model/exchange_sso_token_request.dart';
part 'model/export_link_response.dart';
part 'model/forgot_password_request.dart';
part 'model/ftp_estimate.dart';
part 'model/goal_response.dart';
part 'model/join_club_request.dart';
part 'model/join_code_response.dart';
part 'model/join_request_response.dart';
part 'model/join_requests_response.dart';
part 'model/lap_response.dart';
part 'model/list_admin_users_response.dart';
part 'model/list_bikes_response.dart';
part 'model/list_component_types_response.dart';
part 'model/list_goals_response.dart';
part 'model/list_notifications_response.dart';
part 'model/list_rides_response.dart';
part 'model/list_service_entries_response.dart';
part 'model/list_service_jobs_response.dart';
part 'model/list_templates_response.dart';
part 'model/login_request.dart';
part 'model/login_two_factor_request.dart';
part 'model/maintenance_job.dart';
part 'model/maintenance_reminder_response.dart';
part 'model/mark_reminder_done_request.dart';
part 'model/me_response.dart';
part 'model/my_club_response.dart';
part 'model/my_join_request_response.dart';
part 'model/nearby_club_response.dart';
part 'model/nearby_clubs_request.dart';
part 'model/nearby_clubs_response.dart';
part 'model/notification_response.dart';
part 'model/overview_response.dart';
part 'model/part_response.dart';
part 'model/password_confirmation.dart';
part 'model/password_reset_link_response.dart';
part 'model/pending_join_request_response.dart';
part 'model/period_totals.dart';
part 'model/plan_club_ride_request.dart';
part 'model/power_curve_point.dart';
part 'model/power_curve_response.dart';
part 'model/privacy_response.dart';
part 'model/privacy_streams_response.dart';
part 'model/privacy_zone_response.dart';
part 'model/problem_details.dart';
part 'model/profile_response.dart';
part 'model/readiness_factor.dart';
part 'model/readiness_response.dart';
part 'model/recovery_codes_response.dart';
part 'model/refresh_request.dart';
part 'model/register_request.dart';
part 'model/register_response.dart';
part 'model/request_to_join_request.dart';
part 'model/reset_password_request.dart';
part 'model/ride_feel_response.dart';
part 'model/ride_import_response.dart';
part 'model/ride_laps_response.dart';
part 'model/ride_response.dart';
part 'model/ride_streams_response.dart';
part 'model/route_detail_response.dart';
part 'model/route_download_link_response.dart';
part 'model/route_draft_response.dart';
part 'model/route_list_response.dart';
part 'model/route_summary_response.dart';
part 'model/save_bike_as_template_request.dart';
part 'model/save_check_in_request.dart';
part 'model/save_ride_feel_request.dart';
part 'model/search_parts_response.dart';
part 'model/server_info_response.dart';
part 'model/service_entry_response.dart';
part 'model/session_response.dart';
part 'model/set_club_location_request.dart';
part 'model/set_club_member_role_request.dart';
part 'model/set_club_owner_request.dart';
part 'model/set_club_plan_request.dart';
part 'model/set_ftp_request.dart';
part 'model/set_my_language_request.dart';
part 'model/set_ride_bike_request.dart';
part 'model/set_ride_details_request.dart';
part 'model/set_ride_type_request.dart';
part 'model/set_telemetry_request.dart';
part 'model/set_user_roles_request.dart';
part 'model/settings_response.dart';
part 'model/share_view_response.dart';
part 'model/share_views_response.dart';
part 'model/sharing_response.dart';
part 'model/smtp_status.dart';
part 'model/sso_info_response.dart';
part 'model/sso_status.dart';
part 'model/start_club_request.dart';
part 'model/start_ride_import_response.dart';
part 'model/telemetry_response.dart';
part 'model/template_part_request.dart';
part 'model/template_part_response.dart';
part 'model/token_response.dart';
part 'model/totals_response.dart';
part 'model/training_day.dart';
part 'model/training_response.dart';
part 'model/two_factor_required_response.dart';
part 'model/two_factor_setup.dart';
part 'model/two_factor_state.dart';
part 'model/update_bike_request.dart';
part 'model/update_club_request.dart';
part 'model/update_club_ride_request.dart';
part 'model/update_component_request.dart';
part 'model/update_goal_request.dart';
part 'model/update_privacy_request.dart';
part 'model/update_profile_request.dart';
part 'model/update_reminder_request.dart';
part 'model/update_route_request.dart';
part 'model/update_service_entry_request.dart';
part 'model/update_settings_request.dart';
part 'model/update_sharing_request.dart';
part 'model/update_template_request.dart';
part 'model/upload_ride_response.dart';
part 'model/user_summary.dart';
part 'model/vo2_max_estimate.dart';
part 'model/wellbeing_consent_request.dart';
part 'model/wellbeing_response.dart';
part 'model/zone_time.dart';


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
