import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/medical_condition_entity.dart';
import '../entities/onboarding_data.dart';

/// Contract interface for Onboarding data sync and local caching.
abstract class OnboardingRepository {
  /// Saves all onboarding data to Supabase (user_profiles, lifestyle_profiles, respiratory_profiles, conditions).
  Future<Either<Failure, void>> saveOnboarding(OnboardingData data);

  /// Dynamic lookup of available conditions from the database.
  Future<Either<Failure, List<MedicalConditionEntity>>> getMedicalConditions();

  /// Checks if the authenticated user has completed their onboarding profile setup.
  Future<Either<Failure, bool>> checkProfileCompleted();

  /// Saves progress locally as a draft.
  Future<Either<Failure, void>> saveDraft(OnboardingData data);

  /// Loads locally saved draft details, if any.
  Future<Either<Failure, OnboardingData?>> loadDraft();

  /// Clears the local onboarding draft cache.
  Future<Either<Failure, void>> clearDraft();
}
