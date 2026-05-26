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

  Future<void> register(Map<String, dynamic> userData) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email:    userData['email'],
      password: userData['password'],
    );
    final user     = credential.user!;
    final fullName = '${userData['first_name']} ${userData['last_name']}'.trim();
    await user.updateDisplayName(fullName);

    // Write user profile to Firestore
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
      // No Firestore doc yet — build profile from Firebase Auth and persist it
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
      // Best-effort write — if it fails (e.g. rules), still return the user
      try {
        await _fs.db.collection('users').doc(uid).set(profile);
      } catch (_) {}
      return UserModel.fromJson(profile);
    } catch (e) {
      // Firestore unreachable — return minimal user from Firebase Auth so login still works
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
    await _firebaseAuth.signOut();
  }

  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }
}
