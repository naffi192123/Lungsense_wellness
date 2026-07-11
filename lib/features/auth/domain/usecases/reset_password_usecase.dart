import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// UseCase to send a password reset link.
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(email: params.email);
  }
}

/// Parameters required for executing the ResetPasswordUseCase.
class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}
