import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static void init() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  static Dio get dio => _dio;
}