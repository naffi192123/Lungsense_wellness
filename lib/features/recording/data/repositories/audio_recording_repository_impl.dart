import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/audio_recording_entities.dart';
import '../../domain/repositories/audio_recording_repository.dart';
import '../datasources/audio_recording_remote_data_source.dart';

class AudioRecordingRepositoryImpl implements AudioRecordingRepository {
  final AudioRecordingRemoteDataSource remoteDataSource;

  AudioRecordingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ConsentEntity>> getConsent(String consentType) async {
    try {
      final consent = await remoteDataSource.getConsent(consentType);
      return Right(consent);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsentEntity>> recordConsent({
    required String consentType,
    required bool granted,
  }) async {
    try {
      final consent = await remoteDataSource.recordConsent(
        consentType: consentType,
        granted: granted,
      );
      return Right(consent);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioJobEntity>> uploadAudio({
    required String path,
    required String recordingType,
  }) async {
    try {
      final job = await remoteDataSource.uploadAudio(
        path: path,
        recordingType: recordingType,
      );
      return Right(job);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioJobEntity>> getJobStatus(String jobId) async {
    try {
      final job = await remoteDataSource.getJobStatus(jobId);
      return Right(job);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
