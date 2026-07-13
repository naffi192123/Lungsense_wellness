import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/medical_condition_entity.dart';
import '../repositories/onboarding_repository.dart';

/// UseCase to dynamically retrieve conditions listed in the database.
class FetchConditionsUseCase implements UseCase<List<MedicalConditionEntity>, NoParams> {
  final OnboardingRepository repository;

  FetchConditionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MedicalConditionEntity>>> call(NoParams params) async {
    return await repository.getMedicalConditions();
  }
}
