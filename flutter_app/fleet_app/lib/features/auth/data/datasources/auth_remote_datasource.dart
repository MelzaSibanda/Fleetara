import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient         _client;
  final FirebaseAuth      _firebaseAuth = FirebaseAuth.instance;

  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    // 1. Sign in with Firebase
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );
    // 2. Get Firebase ID token
    final idToken = await credential.user!.getIdToken();

    // 3. Exchange for Django JWT
    return _exchangeToken(idToken: idToken!);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    // 1. Create Firebase user
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email:    userData['email'],
      password: userData['password'],
    );

    // 2. Update Firebase display name
    final fullName = '${userData['first_name']} ${userData['last_name']}'.trim();
    await credential.user!.updateDisplayName(fullName);

    // 3. Get Firebase ID token
    final idToken = await credential.user!.getIdToken();

    // 4. Exchange for Django JWT (pass extra profile fields)
    return _exchangeToken(
      idToken:    idToken!,
      firstName:  userData['first_name'],
      lastName:   userData['last_name'],
      role:       userData['role'],
      phone:      userData['phone'] ?? '',
    );
  }

  Future<Map<String, dynamic>> _exchangeToken({
    required String idToken,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
  }) async {
    final body = <String, dynamic>{'id_token': idToken};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName  != null) body['last_name']  = lastName;
    if (role      != null) body['role']        = role;
    if (phone     != null) body['phone']       = phone;

    final response = await _client.dio.post('/auth/firebase/', data: body);
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
      await _firebaseAuth.signOut();
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
