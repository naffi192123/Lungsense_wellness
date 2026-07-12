import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for all user authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the user submits their email and password.
class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when the user registers a new account with email, password, and name.
class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

/// Dispatched when requesting a password reset email link.
class AuthResetPasswordEvent extends AuthEvent {
  final String email;

  const AuthResetPasswordEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Dispatched when the user logs out from their session.
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

/// Dispatched to check if the current user session is valid on app boot.
class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

/// Dispatched when the user initiates Google OAuth sign-in.
class AuthGoogleSignInEvent extends AuthEvent {
  const AuthGoogleSignInEvent();
}

/// Internal event fired when session status stream updates.
class AuthUserChangedEvent extends AuthEvent {
  final UserEntity? user;

  const AuthUserChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}
