import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract definition for Authentication logic.
/// Implemented in the Data layer and consumed by UseCases.
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

  /// Sends a password reset email link for the specified address.
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Terminates the current active session.
  Future<Either<Failure, void>> logout();

  /// Retrieves the current authenticated user session if present.
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
