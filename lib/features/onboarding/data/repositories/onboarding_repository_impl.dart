import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/medical_condition_entity.dart';
import '../../domain/entities/onboarding_data.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';
import '../datasources/onboarding_remote_data_source.dart';
import '../models/onboarding_model.dart';

/// Repository implementation directing local caching and remote sync of onboarding steps.
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remoteDataSource;
  final OnboardingLocalDataSource localDataSource;

  OnboardingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> saveOnboarding(OnboardingData data) async {
    try {
      final model = OnboardingModel.fromEntity(data);
      // Persist completed profile locally first
      await localDataSource.saveCompletedProfile(model);

      // Attempt remote sync with backend
      try {
        await remoteDataSource.saveOnboarding(model: model, userId: '');
      } on ServerException catch (e) {
        // If server encounters a 5xx error, allow user to proceed since profile is safely cached locally
        if (e.code != null && int.tryParse(e.code!) != null && int.parse(e.code!) >= 500) {
          return const Right(null);
        }
        return Left(ServerFailure(e.message, code: e.code));
      } catch (_) {
        return const Right(null);
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedicalConditionEntity>>> getMedicalConditions() async {
    try {
      final list = await remoteDataSource.fetchMedicalConditions();
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkProfileCompleted() async {
    try {
      final localCompleted = await localDataSource.isProfileCompletedLocally();
      if (localCompleted) {
        return const Right(true);
      }
      final completed = await remoteDataSource.checkProfileCompleted(userId: '');
      return Right(completed);
    } catch (_) {
      final localCompleted = await localDataSource.isProfileCompletedLocally();
      return Right(localCompleted);
    }
  }

  @override
  Future<Either<Failure, void>> saveDraft(OnboardingData data) async {
    try {
      final model = OnboardingModel.fromEntity(data);
      await localDataSource.saveDraft(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OnboardingData?>> loadDraft() async {
    try {
      final draft = await localDataSource.loadDraft();
      return Right(draft);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearDraft() async {
    try {
      await localDataSource.clearDraft();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
