import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            return handler.resolve(await _dio.fetch(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs        = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/token/refresh/', data: {'refresh': refreshToken});
      await prefs.setString('access_token', response.data['access']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;
}
