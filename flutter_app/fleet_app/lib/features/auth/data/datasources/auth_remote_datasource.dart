import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.dio.post('/auth/login/', data: {
      'username': username,
      'password': password,
    });
    final data  = response.data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token',  data['access']);
    await prefs.setString('refresh_token', data['refresh']);
    return data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _client.dio.post('/auth/register/', data: userData);
    final data     = response.data;
    final prefs    = await SharedPreferences.getInstance();
    await prefs.setString('access_token',  data['access']);
    await prefs.setString('refresh_token', data['refresh']);
    return data;
  }

  Future<UserModel> getMe() async {
    final response = await _client.dio.get('/auth/me/');
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    try {
      final prefs        = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      await _client.dio.post('/auth/logout/', data: {'refresh': refreshToken});
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }
}
