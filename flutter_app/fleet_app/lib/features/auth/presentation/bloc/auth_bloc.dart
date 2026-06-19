import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource _dataSource;

  AuthBloc(this._dataSource) : super(AuthInitial()) {

    on<AuthCheckRequested>((event, emit) async {
      final loggedIn = await _dataSource.isLoggedIn();
      if (loggedIn) {
        try {
          final user = await _dataSource.getMe();
          emit(AuthAuthenticated(user));
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _dataSource.login(event.email, event.password);
        final user = await _dataSource.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(_parseError(e)));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _dataSource.register(event.userData);
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(_parseError(e)));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _dataSource.logout();
      emit(AuthUnauthenticated());
    });
  }

  String _parseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':   return 'This email is already registered.';
        case 'invalid-email':          return 'Please enter a valid email address.';
        case 'weak-password':          return 'Password must be at least 6 characters.';
        case 'user-not-found':         return 'No account found with this email.';
        case 'wrong-password':         return 'Incorrect password. Please try again.';
        case 'invalid-credential':     return 'Invalid email or password.';
        case 'too-many-requests':      return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed': return 'Network error. Check your connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled.\nGo to Firebase Console → Authentication → Sign-in method → enable Email/Password.';
        default: return e.message ?? 'Firebase error: ${e.code}';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
