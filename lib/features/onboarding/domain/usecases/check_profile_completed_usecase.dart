import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to verify user profile completion status.
class CheckProfileCompletedUseCase implements UseCase<bool, NoParams> {
  final OnboardingRepository repository;

  CheckProfileCompletedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.checkProfileCompleted();
  }
}
