import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/auth_response_model.dart';

enum LoginRole {
  divisionalHead,
  trafficOfficer,
}

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthResponseModel> login({
    String? username,
    String? loginId,
    required String password,
    LoginRole loginRole = LoginRole.trafficOfficer,
  }) async {
    final resolvedLoginId = (loginId ?? username ?? '').trim();

    final endpoint = loginRole == LoginRole.divisionalHead
        ? ApiConstants.headLogin
        : ApiConstants.officerLogin;

    final payload = loginRole == LoginRole.divisionalHead
        ? {
            'username': resolvedLoginId,
            'password': password.trim(),
          }
        : {
            'badgeNo': resolvedLoginId,
            'password': password.trim(),
          };

    final response = await _apiClient.post(
      endpoint,
      requiresAuth: false,
      body: payload,
    );

    final authResponse = AuthResponseModel.fromJson(
      response as Map<String, dynamic>,
    );

    await _tokenStorage.saveSession(
      accessToken: authResponse.accessToken,
      officerId: authResponse.officer.id,
      officerName: authResponse.officer.name,
      officerBadgeNumber: authResponse.officer.badgeNumber,
      role: authResponse.officer.role,
      districtId: authResponse.officer.divisionId,
    );

    return authResponse;
  }

  // ── TO: Forgot Password ──
  Future<void> requestForgotPasswordOtp({
    required String badgeNo,
    required String email,
  }) async {
    await _apiClient.post(
      ApiConstants.officerForgotPasswordRequest,
      requiresAuth: false,
      body: {
        'badgeNo': badgeNo.trim(),
        'email': email.trim(),
      },
    );
  }

  Future<void> resetForgottenPassword({
    required String badgeNo,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConstants.officerResetPassword,
      requiresAuth: false,
      body: {
        'badgeNo': badgeNo.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'newPasswordStr': newPassword.trim(),
      },
    );
  }

  // ── DO: Forgot Password ──
  Future<void> requestHeadForgotPasswordOtp({
    required String username,
    required String email,
  }) async {
    await _apiClient.post(
      ApiConstants.headForgotPasswordRequest,
      requiresAuth: false,
      body: {
        'username': username.trim(),
        'email': email.trim(),
      },
    );
  }

  Future<void> resetHeadForgottenPassword({
    required String username,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConstants.headResetPassword,
      requiresAuth: false,
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'newPasswordStr': newPassword.trim(),
      },
    );
  }

  // ── Authenticated Password Change ──
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      ApiConstants.changePassword,
      body: {
        'oldPassword': oldPassword.trim(),
        'newPassword': newPassword.trim(),
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }
}