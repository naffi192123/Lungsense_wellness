import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/onboarding_data.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to retrieve locally saved onboarding draft progress.
class LoadOnboardingDraftUseCase implements UseCase<OnboardingData?, NoParams> {
  final OnboardingRepository repository;

  LoadOnboardingDraftUseCase(this.repository);

  @override
  Future<Either<Failure, OnboardingData?>> call(NoParams params) async {
    return await repository.loadDraft();
  }
}
