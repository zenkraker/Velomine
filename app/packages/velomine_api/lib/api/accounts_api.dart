//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of velomine_api;


class AccountsApi {
  AccountsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/v1/accounts/users/{id}/approve' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> approveUserWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/users/{id}/approve'
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
  Future<void> approveUser(String id, { Future<void>? abortTrigger, }) async {
    final response = await approveUserWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/password' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<Response> changePasswordWithHttpInfo(ChangePasswordRequest changePasswordRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/password';

    // ignore: prefer_final_locals
    Object? postBody = changePasswordRequest;

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
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<void> changePassword(ChangePasswordRequest changePasswordRequest, { Future<void>? abortTrigger, }) async {
    final response = await changePasswordWithHttpInfo(changePasswordRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/export-link' operation and returns the [Response].
  Future<Response> createExportLinkWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/export-link';

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

  Future<ExportLinkResponse?> createExportLink({ Future<void>? abortTrigger, }) async {
    final response = await createExportLinkWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ExportLinkResponse',) as ExportLinkResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/delete' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DeleteMyAccountRequest] deleteMyAccountRequest (required):
  Future<Response> deleteMyAccountWithHttpInfo(DeleteMyAccountRequest deleteMyAccountRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/delete';

    // ignore: prefer_final_locals
    Object? postBody = deleteMyAccountRequest;

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
  /// * [DeleteMyAccountRequest] deleteMyAccountRequest (required):
  Future<void> deleteMyAccount(DeleteMyAccountRequest deleteMyAccountRequest, { Future<void>? abortTrigger, }) async {
    final response = await deleteMyAccountWithHttpInfo(deleteMyAccountRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/two-factor/disable' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PasswordConfirmation] passwordConfirmation (required):
  Future<Response> disableTwoFactorWithHttpInfo(PasswordConfirmation passwordConfirmation, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/two-factor/disable';

    // ignore: prefer_final_locals
    Object? postBody = passwordConfirmation;

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
  /// * [PasswordConfirmation] passwordConfirmation (required):
  Future<void> disableTwoFactor(PasswordConfirmation passwordConfirmation, { Future<void>? abortTrigger, }) async {
    final response = await disableTwoFactorWithHttpInfo(passwordConfirmation, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/v1/accounts/export/{token}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> downloadExportWithHttpInfo(String token, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/export/{token}'
      .replaceAll('{token}', token);

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
  /// * [String] token (required):
  Future<void> downloadExport(String token, { Future<void>? abortTrigger, }) async {
    final response = await downloadExportWithHttpInfo(token, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/two-factor/enable' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [EnableTwoFactorRequest] enableTwoFactorRequest (required):
  Future<Response> enableTwoFactorWithHttpInfo(EnableTwoFactorRequest enableTwoFactorRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/two-factor/enable';

    // ignore: prefer_final_locals
    Object? postBody = enableTwoFactorRequest;

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
  /// * [EnableTwoFactorRequest] enableTwoFactorRequest (required):
  Future<RecoveryCodesResponse?> enableTwoFactor(EnableTwoFactorRequest enableTwoFactorRequest, { Future<void>? abortTrigger, }) async {
    final response = await enableTwoFactorWithHttpInfo(enableTwoFactorRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecoveryCodesResponse',) as RecoveryCodesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/sso/token' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ExchangeSsoTokenRequest] exchangeSsoTokenRequest (required):
  Future<Response> exchangeSsoTokenWithHttpInfo(ExchangeSsoTokenRequest exchangeSsoTokenRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/sso/token';

    // ignore: prefer_final_locals
    Object? postBody = exchangeSsoTokenRequest;

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
  /// * [ExchangeSsoTokenRequest] exchangeSsoTokenRequest (required):
  Future<TokenResponse?> exchangeSsoToken(ExchangeSsoTokenRequest exchangeSsoTokenRequest, { Future<void>? abortTrigger, }) async {
    final response = await exchangeSsoTokenWithHttpInfo(exchangeSsoTokenRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/sso/callback' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] returnUrl:
  Future<Response> finishSsoWithHttpInfo({ String? returnUrl, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/sso/callback';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (returnUrl != null) {
      queryParams.addAll(_queryParams('', 'returnUrl', returnUrl));
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
  /// * [String] returnUrl:
  Future<void> finishSso({ String? returnUrl, Future<void>? abortTrigger, }) async {
    final response = await finishSsoWithHttpInfo(returnUrl: returnUrl, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/password/forgot' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ForgotPasswordRequest] forgotPasswordRequest (required):
  Future<Response> forgotPasswordWithHttpInfo(ForgotPasswordRequest forgotPasswordRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/password/forgot';

    // ignore: prefer_final_locals
    Object? postBody = forgotPasswordRequest;

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
  /// * [ForgotPasswordRequest] forgotPasswordRequest (required):
  Future<void> forgotPassword(ForgotPasswordRequest forgotPasswordRequest, { Future<void>? abortTrigger, }) async {
    final response = await forgotPasswordWithHttpInfo(forgotPasswordRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/v1/accounts/me' operation and returns the [Response].
  Future<Response> getMeWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me';

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

  Future<MeResponse?> getMe({ Future<void>? abortTrigger, }) async {
    final response = await getMeWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MeResponse',) as MeResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/me/profile' operation and returns the [Response].
  Future<Response> getProfileWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/profile';

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

  Future<ProfileResponse?> getProfile({ Future<void>? abortTrigger, }) async {
    final response = await getProfileWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ProfileResponse',) as ProfileResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/sso' operation and returns the [Response].
  Future<Response> getSsoInfoWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/sso';

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

  Future<SsoInfoResponse?> getSsoInfo({ Future<void>? abortTrigger, }) async {
    final response = await getSsoInfoWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SsoInfoResponse',) as SsoInfoResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/me/telemetry' operation and returns the [Response].
  Future<Response> getTelemetryWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/telemetry';

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

  Future<TelemetryResponse?> getTelemetry({ Future<void>? abortTrigger, }) async {
    final response = await getTelemetryWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TelemetryResponse',) as TelemetryResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/me/two-factor' operation and returns the [Response].
  Future<Response> getTwoFactorWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/two-factor';

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

  Future<TwoFactorState?> getTwoFactor({ Future<void>? abortTrigger, }) async {
    final response = await getTwoFactorWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TwoFactorState',) as TwoFactorState;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/me/sessions' operation and returns the [Response].
  Future<Response> listSessionsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/sessions';

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

  Future<List<SessionResponse>?> listSessions({ Future<void>? abortTrigger, }) async {
    final response = await listSessionsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SessionResponse>') as List)
        .cast<SessionResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/users' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [bool] pending (required):
  Future<Response> listUsersWithHttpInfo(bool pending, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/users';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'pending', pending));

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
  /// * [bool] pending (required):
  Future<List<UserSummary>?> listUsers(bool pending, { Future<void>? abortTrigger, }) async {
    final response = await listUsersWithHttpInfo(pending, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UserSummary>') as List)
        .cast<UserSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/login' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest (required):
  Future<Response> loginWithHttpInfo(LoginRequest loginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/login';

    // ignore: prefer_final_locals
    Object? postBody = loginRequest;

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
  /// * [LoginRequest] loginRequest (required):
  Future<TokenResponse?> login(LoginRequest loginRequest, { Future<void>? abortTrigger, }) async {
    final response = await loginWithHttpInfo(loginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/login/two-factor' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [LoginTwoFactorRequest] loginTwoFactorRequest (required):
  Future<Response> loginTwoFactorWithHttpInfo(LoginTwoFactorRequest loginTwoFactorRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/login/two-factor';

    // ignore: prefer_final_locals
    Object? postBody = loginTwoFactorRequest;

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
  /// * [LoginTwoFactorRequest] loginTwoFactorRequest (required):
  Future<TokenResponse?> loginTwoFactor(LoginTwoFactorRequest loginTwoFactorRequest, { Future<void>? abortTrigger, }) async {
    final response = await loginTwoFactorWithHttpInfo(loginTwoFactorRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/logout' operation and returns the [Response].
  Future<Response> logoutWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/logout';

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

  Future<void> logout({ Future<void>? abortTrigger, }) async {
    final response = await logoutWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/refresh' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [RefreshRequest] refreshRequest (required):
  Future<Response> refreshWithHttpInfo(RefreshRequest refreshRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/refresh';

    // ignore: prefer_final_locals
    Object? postBody = refreshRequest;

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
  /// * [RefreshRequest] refreshRequest (required):
  Future<TokenResponse?> refresh(RefreshRequest refreshRequest, { Future<void>? abortTrigger, }) async {
    final response = await refreshWithHttpInfo(refreshRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/two-factor/recovery-codes' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PasswordConfirmation] passwordConfirmation (required):
  Future<Response> regenerateRecoveryCodesWithHttpInfo(PasswordConfirmation passwordConfirmation, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/two-factor/recovery-codes';

    // ignore: prefer_final_locals
    Object? postBody = passwordConfirmation;

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
  /// * [PasswordConfirmation] passwordConfirmation (required):
  Future<RecoveryCodesResponse?> regenerateRecoveryCodes(PasswordConfirmation passwordConfirmation, { Future<void>? abortTrigger, }) async {
    final response = await regenerateRecoveryCodesWithHttpInfo(passwordConfirmation, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RecoveryCodesResponse',) as RecoveryCodesResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/register' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [RegisterRequest] registerRequest (required):
  Future<Response> registerWithHttpInfo(RegisterRequest registerRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/register';

    // ignore: prefer_final_locals
    Object? postBody = registerRequest;

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
  /// * [RegisterRequest] registerRequest (required):
  Future<RegisterResponse?> register(RegisterRequest registerRequest, { Future<void>? abortTrigger, }) async {
    final response = await registerWithHttpInfo(registerRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RegisterResponse',) as RegisterResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/v1/accounts/password/reset' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ResetPasswordRequest] resetPasswordRequest (required):
  Future<Response> resetPasswordWithHttpInfo(ResetPasswordRequest resetPasswordRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/password/reset';

    // ignore: prefer_final_locals
    Object? postBody = resetPasswordRequest;

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
  /// * [ResetPasswordRequest] resetPasswordRequest (required):
  Future<void> resetPassword(ResetPasswordRequest resetPasswordRequest, { Future<void>? abortTrigger, }) async {
    final response = await resetPasswordWithHttpInfo(resetPasswordRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/sessions/logout-others' operation and returns the [Response].
  Future<Response> revokeOtherSessionsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/sessions/logout-others';

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

  Future<void> revokeOtherSessions({ Future<void>? abortTrigger, }) async {
    final response = await revokeOtherSessionsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/v1/accounts/me/sessions/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> revokeSessionWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/sessions/{id}'
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
  Future<void> revokeSession(String id, { Future<void>? abortTrigger, }) async {
    final response = await revokeSessionWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/ftp' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetFtpRequest] setFtpRequest (required):
  Future<Response> setFtpWithHttpInfo(SetFtpRequest setFtpRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/ftp';

    // ignore: prefer_final_locals
    Object? postBody = setFtpRequest;

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
  /// * [SetFtpRequest] setFtpRequest (required):
  Future<ProfileResponse?> setFtp(SetFtpRequest setFtpRequest, { Future<void>? abortTrigger, }) async {
    final response = await setFtpWithHttpInfo(setFtpRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ProfileResponse',) as ProfileResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/language' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetMyLanguageRequest] setMyLanguageRequest (required):
  Future<Response> setMyLanguageWithHttpInfo(SetMyLanguageRequest setMyLanguageRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/language';

    // ignore: prefer_final_locals
    Object? postBody = setMyLanguageRequest;

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
  /// * [SetMyLanguageRequest] setMyLanguageRequest (required):
  Future<MeResponse?> setMyLanguage(SetMyLanguageRequest setMyLanguageRequest, { Future<void>? abortTrigger, }) async {
    final response = await setMyLanguageWithHttpInfo(setMyLanguageRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MeResponse',) as MeResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/units' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetMyUnitsRequest] setMyUnitsRequest (required):
  Future<Response> setMyUnitsWithHttpInfo(SetMyUnitsRequest setMyUnitsRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/units';

    // ignore: prefer_final_locals
    Object? postBody = setMyUnitsRequest;

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
  /// * [SetMyUnitsRequest] setMyUnitsRequest (required):
  Future<MeResponse?> setMyUnits(SetMyUnitsRequest setMyUnitsRequest, { Future<void>? abortTrigger, }) async {
    final response = await setMyUnitsWithHttpInfo(setMyUnitsRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MeResponse',) as MeResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/telemetry' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SetTelemetryRequest] setTelemetryRequest (required):
  Future<Response> setTelemetryWithHttpInfo(SetTelemetryRequest setTelemetryRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/telemetry';

    // ignore: prefer_final_locals
    Object? postBody = setTelemetryRequest;

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
  /// * [SetTelemetryRequest] setTelemetryRequest (required):
  Future<TelemetryResponse?> setTelemetry(SetTelemetryRequest setTelemetryRequest, { Future<void>? abortTrigger, }) async {
    final response = await setTelemetryWithHttpInfo(setTelemetryRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TelemetryResponse',) as TelemetryResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/accounts/sso/login' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] returnUrl:
  Future<Response> startSsoWithHttpInfo({ String? returnUrl, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/sso/login';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (returnUrl != null) {
      queryParams.addAll(_queryParams('', 'returnUrl', returnUrl));
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
  /// * [String] returnUrl:
  Future<void> startSso({ String? returnUrl, Future<void>? abortTrigger, }) async {
    final response = await startSsoWithHttpInfo(returnUrl: returnUrl, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/v1/accounts/me/two-factor/start' operation and returns the [Response].
  Future<Response> startTwoFactorEnrollmentWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/two-factor/start';

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

  Future<TwoFactorSetup?> startTwoFactorEnrollment({ Future<void>? abortTrigger, }) async {
    final response = await startTwoFactorEnrollmentWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TwoFactorSetup',) as TwoFactorSetup;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/v1/accounts/me/profile' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateProfileRequest] updateProfileRequest (required):
  Future<Response> updateProfileWithHttpInfo(UpdateProfileRequest updateProfileRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/accounts/me/profile';

    // ignore: prefer_final_locals
    Object? postBody = updateProfileRequest;

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
  /// * [UpdateProfileRequest] updateProfileRequest (required):
  Future<ProfileResponse?> updateProfile(UpdateProfileRequest updateProfileRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateProfileWithHttpInfo(updateProfileRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ProfileResponse',) as ProfileResponse;
    
    }
    return null;
  }
}
