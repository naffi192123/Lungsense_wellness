import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for all states yielded by [AuthBloc].
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial loading/checking state.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Emitted when executing network authentication transactions.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Emitted when the user is successfully authenticated (logged in/registered).
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Emitted when there is no active logged-in user session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Emitted when an operation fails (e.g. invalid credentials).
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted when the password reset link has been successfully dispatched.
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}
