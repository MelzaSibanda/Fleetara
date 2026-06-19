import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final FirestoreService  _fs;
  final FirebaseAuth      _firebaseAuth = FirebaseAuth.instance;

  AuthRemoteDataSource(this._fs);

  Future<void> login(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password);
  }

  Future<UserModel> register(Map<String, dynamic> userData) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email:    userData['email'],
      password: userData['password'],
    );
    final user     = credential.user!;
    final fullName = '${userData['first_name']} ${userData['last_name']}'.trim();
    await user.updateDisplayName(fullName);

    final profile = <String, dynamic>{
      'id':         user.uid,
      'email':      userData['email'],
      'first_name': userData['first_name'] ?? '',
      'last_name':  userData['last_name']  ?? '',
      'full_name':  fullName,
      'phone':      userData['phone'] ?? '',
      'role':       userData['role']  ?? 'driver',
      'is_active':  true,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _fs.db.collection('users').doc(user.uid).set(profile);
    return UserModel.fromJson(profile);
  }

  Future<UserModel> getMe() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('Not authenticated');

    try {
      final doc = await _fs.db.collection('users').doc(fbUser.uid).get();
      if (doc.exists) return UserModel.fromJson(_fs.docToMap(doc));
    } catch (_) {}

    // Auto-create profile from Firebase Auth data
    final nameParts = (fbUser.displayName ?? '').split(' ');
    final first = nameParts.isNotEmpty ? nameParts.first : '';
    final last  = nameParts.length > 1  ? nameParts.sublist(1).join(' ') : '';
    final profile = {
      'id':         fbUser.uid,
      'email':      fbUser.email ?? '',
      'first_name': first,
      'last_name':  last,
      'full_name':  fbUser.displayName ?? '$first $last'.trim(),
      'phone':      '',
      'role':       'driver',
      'is_active':  true,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await _fs.db.collection('users').doc(fbUser.uid).set(profile);
    } catch (_) {}
    return UserModel.fromJson(profile);
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }
}
