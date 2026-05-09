import 'package:dio/dio.dart';
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
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        final msgs = data.entries.expand((entry) {
          final v = entry.value;
          final field = entry.key == 'non_field_errors' ? '' : '${entry.key}: ';
          if (v is List) return v.map((m) => '$field$m');
          return ['$field$v'];
        }).toList();
        if (msgs.isNotEmpty) return msgs.join('\n');
      }
      if (data is String && data.isNotEmpty) return data;
    }
    if (e.toString().contains('connection refused') ||
        e.toString().contains('SocketException')) {
      return 'Cannot connect to server. Is the backend running?';
    }
    return 'Something went wrong. Please try again.';
  }
}
