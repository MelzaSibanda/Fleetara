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
        await _dataSource.login(event.username, event.password);
        final user = await _dataSource.getMe();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(AuthError(_parseError(e)));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _dataSource.register(event.userData);
        final user = await _dataSource.getMe();
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
    if (e.toString().contains('400')) return 'Invalid username or password.';
    if (e.toString().contains('connection')) return 'Cannot connect to server.';
    return 'Something went wrong. Please try again.';
  }
}
