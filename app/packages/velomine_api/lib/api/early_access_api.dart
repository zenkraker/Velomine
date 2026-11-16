//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class EarlyAccessApi {
  EarlyAccessApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Join the early-access list by email
  ///
  /// For the site's early-access form. Fields: email (required, at most 200 characters), who (required: rider or club), club (optional, club name and town, at most 200 characters) and consent (required, any value). Nothing is stored: the sign-up is emailed to the operator's feedback address. Always answers 303 See Other with a Location header: /early-access/sent/ when the email was sent, otherwise /early-access/not-sent/?reason=invalid (validation failed), reason=unavailable (no feedback address or email is configured, or sending failed) or reason=busy (rate limit of 5 per hour per network address, answered with the same redirect, status 303, by the limiter).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] email (required):
  ///
  /// * [String] consent (required):
  ///
  /// * [String] who:
  ///
  /// * [String] club:
  Future<Response> joinEarlyAccessWithHttpInfo(String email, String consent, { String? who, String? club, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/early-access';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/x-www-form-urlencoded'];

    if (email != null) {
      formParams[r'email'] = parameterToString(email);
    }
    if (who != null) {
      formParams[r'who'] = parameterToString(who);
    }
    if (club != null) {
      formParams[r'club'] = parameterToString(club);
    }
    if (consent != null) {
      formParams[r'consent'] = parameterToString(consent);
    }

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

  /// Join the early-access list by email
  ///
  /// For the site's early-access form. Fields: email (required, at most 200 characters), who (required: rider or club), club (optional, club name and town, at most 200 characters) and consent (required, any value). Nothing is stored: the sign-up is emailed to the operator's feedback address. Always answers 303 See Other with a Location header: /early-access/sent/ when the email was sent, otherwise /early-access/not-sent/?reason=invalid (validation failed), reason=unavailable (no feedback address or email is configured, or sending failed) or reason=busy (rate limit of 5 per hour per network address, answered with the same redirect, status 303, by the limiter).
  ///
  /// Parameters:
  ///
  /// * [String] email (required):
  ///
  /// * [String] consent (required):
  ///
  /// * [String] who:
  ///
  /// * [String] club:
  Future<void> joinEarlyAccess(String email, String consent, { String? who, String? club, Future<void>? abortTrigger, }) async {
    final response = await joinEarlyAccessWithHttpInfo(email, consent, who: who, club: club, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
