import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract definition for Authentication logic.
abstract class AuthRepository {
  /// Signs in a user using email and password.
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user with their name, email, and password.
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Requests a password reset verification code to be sent to email.
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  /// Requests a password reset verification code (alias for forgotPassword).
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Resets the user's password using the OTP verification code.
  Future<Either<Failure, void>> resetPasswordWithOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  /// Terminates the current active session.
  Future<Either<Failure, void>> logout();

  /// Retrieves the current authenticated user session if present.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Reactive stream of user authentication status changes.
  Stream<UserEntity?> get userStream;

  /// Performs Google OAuth redirection flow.
  Future<Either<Failure, void>> signInWithGoogle();
}
