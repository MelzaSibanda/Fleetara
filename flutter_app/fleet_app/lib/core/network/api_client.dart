import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        // Restore token from SharedPreferences if not in memory
        if (_accessToken == null) {
          final prefs = await SharedPreferences.getInstance();
          _accessToken        = prefs.getString('access_token');
          _storedRefreshToken = prefs.getString('refresh_token');
        }
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
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

      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': _storedRefreshToken},
      );

      _accessToken = response.data['access'];

      // ROTATE_REFRESH_TOKENS=True means Django returns a new refresh token
      // and blacklists the old one — must save both or the next refresh fails
      if (response.data['refresh'] != null) {
        _storedRefreshToken = response.data['refresh'];
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      if (_storedRefreshToken != null) {
        await prefs.setString('refresh_token', _storedRefreshToken!);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void setTokens(String accessToken, String refreshToken) {
    _accessToken        = accessToken;
    _storedRefreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken        = null;
    _storedRefreshToken = null;
  }

  Dio get dio => _dio;
}
