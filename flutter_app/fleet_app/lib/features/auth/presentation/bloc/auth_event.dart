import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final Map<String, dynamic> userData;
  AuthRegisterRequested(this.userData);
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}
