import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to clear cached local onboarding drafts on completion.
class ClearOnboardingDraftUseCase implements UseCase<void, NoParams> {
  final OnboardingRepository repository;

  ClearOnboardingDraftUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.clearDraft();
  }
}
