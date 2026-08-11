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

/// Dispatched when requesting a password reset OTP code.
class AuthResetPasswordEvent extends AuthEvent {
  final String email;

  const AuthResetPasswordEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Dispatched when requesting a password reset OTP code (alias for AuthResetPasswordEvent).
class AuthForgotPasswordEvent extends AuthEvent {
  final String email;

  const AuthForgotPasswordEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Dispatched when submitting the OTP code and new password.
class AuthResetPasswordWithOtpEvent extends AuthEvent {
  final String email;
  final String otpCode;
  final String newPassword;

  const AuthResetPasswordWithOtpEvent({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}

/// Dispatched when the user logs out from their session.
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

/// Dispatched to check if the current user session is valid on app boot.
class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

/// Dispatched whenever the user session stream emits an update.
class AuthUserChangedEvent extends AuthEvent {
  final UserEntity? user;

  const AuthUserChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}

/// Dispatched to trigger Google Sign-In authentication.
class AuthGoogleSignInEvent extends AuthEvent {
  const AuthGoogleSignInEvent();
}
