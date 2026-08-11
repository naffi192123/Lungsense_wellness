import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// UseCase to verify the reset OTP and update password.
class ConfirmResetPasswordUseCase implements UseCase<void, ConfirmResetPasswordParams> {
  final AuthRepository repository;

  ConfirmResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ConfirmResetPasswordParams params) async {
    return await repository.resetPasswordWithOtp(
      email: params.email,
      otpCode: params.otpCode,
      newPassword: params.newPassword,
    );
  }
}

/// Parameters for OTP password reset.
class ConfirmResetPasswordParams extends Equatable {
  final String email;
  final String otpCode;
  final String newPassword;

  const ConfirmResetPasswordParams({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}
