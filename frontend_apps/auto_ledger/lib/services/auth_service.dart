import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/secure_storage.dart';

class AuthService {
  // Register user - OTP sent to email by backend
  static Future<bool> registerUser(Map<String, dynamic> data) async {
    try {
      final response =
          await ApiService.dio.post('/auth/user/register', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException {
      rethrow;
    }
  }

  // Verify registration with OTP received in email
  static Future<bool> verifyRegistration(String nicNo, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-registration',
        data: {'nicNo': nicNo, 'otp': otp},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return true;
      }
      return false;
    } on DioException {
      rethrow;
    }
  }

  // Resend Registration OTP
  static Future<bool> resendRegistrationOtp(String nicNo) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-registration-otp',
        data: {'nicNo': nicNo},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  // Login user - returns DEVICE_MISMATCH if new device detected
  static Future<Map<String, dynamic>> loginUser(
      String nicNo, String password, String deviceId) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/login',
        data: {
          'nicNo': nicNo,
          'password': password,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return {'success': true};
      }
      return {'success': false};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'DEVICE_MISMATCH') {
        return {
          'success': false,
          'isDeviceMismatch': true,
          'email': e.response?.data['email'] ?? '',
        };
      }
      rethrow;
    }
  }

  // Forgot password - Send OTP to email
  static Future<bool> forgotPasswordCheck(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/forgot-password-check',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  // Resend Password Reset OTP
  static Future<bool> resendResetOtp(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-reset-otp',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  // Reset password with OTP
  static Future<bool> resetPassword(
      String nicNo, String email, String otp, String newPassword) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/reset-password',
        data: {
          'nicNo': nicNo,
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  // Biometric login - returns DEVICE_MISMATCH if new device detected
  static Future<Map<String, dynamic>> biometricLogin(
      String nicNo, String deviceId) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/biometric-login',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return {'success': true};
      }
      return {'success': false};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'DEVICE_MISMATCH') {
        return {
          'success': false,
          'isDeviceMismatch': true,
          'email': e.response?.data['email'] ?? '',
        };
      }
      rethrow;
    }
  }

  // Verify new device with OTP - updates device ID and returns new token
  static Future<Map<String, dynamic>> verifyNewDevice(
      String nicNo, String deviceId, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-device',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
          'otp': otp,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        await SecureStorage.saveNic(nicNo);
        return {'success': true};
      }
      return {'success': false};
    } on DioException {
      rethrow;
    }
  }

  // Resend Device Verification OTP
  static Future<bool> resendDeviceOtp(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-device-otp',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  // Logout - clear local storage
  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}
