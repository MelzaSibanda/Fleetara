import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final FirestoreService  _fs;
  final ApiClient         _api;
  final FirebaseAuth      _firebaseAuth = FirebaseAuth.instance;

  AuthRemoteDataSource(this._fs, this._api);

  Future<void> _exchangeFirebaseToken({
    String role = 'driver',
    String phone = '',
    String firstName = '',
    String lastName = '',
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return;
    final idToken = await fbUser.getIdToken();
    final resp = await _api.dio.post('/users/firebase/', data: {
      'id_token':   idToken,
      'role':       role,
      'first_name': firstName,
      'last_name':  lastName,
      'phone':      phone,
    });
    final access = resp.data['access'] as String?;
    if (access != null) await _api.setToken(access);
  }

  Future<void> login(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password);
    await _exchangeFirebaseToken();
  }

  Future<void> register(Map<String, dynamic> userData) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email:    userData['email'],
      password: userData['password'],
    );
    final user     = credential.user!;
    final fullName = '${userData['first_name']} ${userData['last_name']}'.trim();
    await user.updateDisplayName(fullName);

    await _fs.db.collection('users').doc(user.uid).set({
      'id':            user.uid,
      'email':         userData['email'],
      'first_name':    userData['first_name'] ?? '',
      'last_name':     userData['last_name']  ?? '',
      'full_name':     fullName,
      'phone':         userData['phone'] ?? '',
      'role':          userData['role']  ?? 'driver',
      'is_active':     true,
      'created_at':    DateTime.now().toIso8601String(),
    });

    await _exchangeFirebaseToken(
      role:       userData['role']       ?? 'driver',
      phone:      userData['phone']      ?? '',
      firstName:  userData['first_name'] ?? '',
      lastName:   userData['last_name']  ?? '',
    );
  }

  Future<UserModel> getMe() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('Not authenticated');
    final uid = fbUser.uid;

    try {
      final doc = await _fs.db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(_fs.docToMap(doc));
      }
      final nameParts = (fbUser.displayName ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName  = nameParts.length > 1  ? nameParts.sublist(1).join(' ') : '';
      final profile = {
        'id':         uid,
        'email':      fbUser.email ?? '',
        'first_name': firstName,
        'last_name':  lastName,
        'full_name':  fbUser.displayName ?? '',
        'phone':      '',
        'role':       'driver',
        'is_active':  true,
        'created_at': DateTime.now().toIso8601String(),
      };
      try {
        await _fs.db.collection('users').doc(uid).set(profile);
      } catch (_) {}
      return UserModel.fromJson(profile);
    } catch (e) {
      final nameParts = (fbUser.displayName ?? '').split(' ');
      final first = nameParts.isNotEmpty ? nameParts.first : '';
      final last  = nameParts.length > 1  ? nameParts.sublist(1).join(' ') : '';
      return UserModel(
        id:        uid,
        email:     fbUser.email ?? '',
        firstName: first,
        lastName:  last,
        fullName:  fbUser.displayName ?? '$first $last'.trim(),
        phone:     '',
        role:      'driver',
        isActive:  true,
      );
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _firebaseAuth.signOut();
  }

  Future<bool> isLoggedIn() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return false;
    // Ensure we have a Django token even after app restart
    await _exchangeFirebaseToken();
    return true;
  }
}
