import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
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
  final supabase.SupabaseClient supabaseClient;

  OnboardingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.supabaseClient,
  });

  @override
  Future<Either<Failure, void>> saveOnboarding(OnboardingData data) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('No authenticated user session found.'));
      }
      final model = OnboardingModel.fromEntity(data);
      await remoteDataSource.saveOnboarding(model: model, userId: user.id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        return const Right(false);
      }
      final completed = await remoteDataSource.checkProfileCompleted(userId: user.id);
      return Right(completed);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
