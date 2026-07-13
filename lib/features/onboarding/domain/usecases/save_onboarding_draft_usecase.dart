import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/onboarding_data.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to cache onboarding progress draft locally.
class SaveOnboardingDraftUseCase implements UseCase<void, OnboardingData> {
  final OnboardingRepository repository;

  SaveOnboardingDraftUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(OnboardingData params) async {
    return await repository.saveDraft(params);
  }
}
