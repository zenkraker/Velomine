//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class FeedbackApi {
  FeedbackApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Send anonymous feedback by email
  ///
  /// For the site's feedback form. Fields: who (repeated, at least one of the listed options), tried (repeated), today, worked, broke, numbers, missing, use, why, device. At least one of worked, broke, numbers, missing and why is required; text fields are at most 2000 characters, today and device 200. Nothing is stored and no reply address is taken. Always answers 303 See Other with a Location header: /feedback/sent/ when the email was sent, otherwise /feedback/not-sent/?reason=invalid (the answers did not pass validation), reason=unavailable (no feedback address or email is configured, or sending failed) or reason=busy (rate limit of 5 per hour per network address, which is answered with the same redirect, status 303, by the limiter).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [List<String>] who (required):
  ///
  /// * [List<String>] tried:
  ///
  /// * [String] today:
  ///
  /// * [String] worked:
  ///
  /// * [String] broke:
  ///
  /// * [String] numbers:
  ///
  /// * [String] missing:
  ///
  /// * [String] use:
  ///
  /// * [String] why:
  ///
  /// * [String] device:
  Future<Response> sendFeedbackWithHttpInfo(List<String> who, { List<String>? tried, String? today, String? worked, String? broke, String? numbers, String? missing, String? use, String? why, String? device, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/feedback';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/x-www-form-urlencoded'];

    if (who != null) {
      formParams[r'who'] = parameterToString(who);
    }
    if (tried != null) {
      formParams[r'tried'] = parameterToString(tried);
    }
    if (today != null) {
      formParams[r'today'] = parameterToString(today);
    }
    if (worked != null) {
      formParams[r'worked'] = parameterToString(worked);
    }
    if (broke != null) {
      formParams[r'broke'] = parameterToString(broke);
    }
    if (numbers != null) {
      formParams[r'numbers'] = parameterToString(numbers);
    }
    if (missing != null) {
      formParams[r'missing'] = parameterToString(missing);
    }
    if (use != null) {
      formParams[r'use'] = parameterToString(use);
    }
    if (why != null) {
      formParams[r'why'] = parameterToString(why);
    }
    if (device != null) {
      formParams[r'device'] = parameterToString(device);
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

  /// Send anonymous feedback by email
  ///
  /// For the site's feedback form. Fields: who (repeated, at least one of the listed options), tried (repeated), today, worked, broke, numbers, missing, use, why, device. At least one of worked, broke, numbers, missing and why is required; text fields are at most 2000 characters, today and device 200. Nothing is stored and no reply address is taken. Always answers 303 See Other with a Location header: /feedback/sent/ when the email was sent, otherwise /feedback/not-sent/?reason=invalid (the answers did not pass validation), reason=unavailable (no feedback address or email is configured, or sending failed) or reason=busy (rate limit of 5 per hour per network address, which is answered with the same redirect, status 303, by the limiter).
  ///
  /// Parameters:
  ///
  /// * [List<String>] who (required):
  ///
  /// * [List<String>] tried:
  ///
  /// * [String] today:
  ///
  /// * [String] worked:
  ///
  /// * [String] broke:
  ///
  /// * [String] numbers:
  ///
  /// * [String] missing:
  ///
  /// * [String] use:
  ///
  /// * [String] why:
  ///
  /// * [String] device:
  Future<void> sendFeedback(List<String> who, { List<String>? tried, String? today, String? worked, String? broke, String? numbers, String? missing, String? use, String? why, String? device, Future<void>? abortTrigger, }) async {
    final response = await sendFeedbackWithHttpInfo(who, tried: tried, today: today, worked: worked, broke: broke, numbers: numbers, missing: missing, use: use, why: why, device: device, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
