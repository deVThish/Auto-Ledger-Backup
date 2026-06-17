import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/secure_storage.dart';

class AuthService {
  static Future<bool> registerUser(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.post('/auth/user/register', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException {
      rethrow;
    }
  }

  static Future<bool> verifyRegistration(String nicNo) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-registration',
        data: {'nicNo': nicNo},
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

  static Future<bool> loginUser(String nicNo, String password, String deviceId) async {
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
        return true;
      }
      return false;
    } on DioException {
      rethrow;
    }
  }
}