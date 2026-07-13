import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/onboarding_data.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to finalize and submit onboarding details to the server.
class SaveOnboardingUseCase implements UseCase<void, OnboardingData> {
  final OnboardingRepository repository;

  SaveOnboardingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(OnboardingData params) async {
    return await repository.saveOnboarding(params);
  }
}
