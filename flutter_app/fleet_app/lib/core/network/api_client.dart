import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  late final Dio _dio;
  static String? _accessToken;
  static String? _storedRefreshToken;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
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
      if (_storedRefreshToken == null) return false;

      final response = await _dio.post('/auth/token/refresh/', data: {'refresh': _storedRefreshToken});
      _accessToken = response.data['access'];
      return true;
    } catch (_) {
      return false;
    }
  }

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _storedRefreshToken = refreshToken;
  }

  Dio get dio => _dio;
}
