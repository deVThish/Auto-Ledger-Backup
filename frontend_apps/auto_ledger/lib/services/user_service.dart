import 'package:dio/dio.dart';
import 'api_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await ApiService.dio.get('/users/profile');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      rethrow;
    }
  }

  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await ApiService.dio.patch(
        '/auth/user/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      rethrow;
    }
  }
}