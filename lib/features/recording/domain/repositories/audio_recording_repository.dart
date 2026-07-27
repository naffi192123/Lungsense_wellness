import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audio_recording_entities.dart';

/// Contract interface defining domain operations for audio recordings and acoustic analysis.
abstract class AudioRecordingRepository {
  /// Get consent status for a specified consent type.
  Future<Either<Failure, ConsentEntity>> getConsent(String consentType);

  /// Record user consent choice.
  Future<Either<Failure, ConsentEntity>> recordConsent({
    required String consentType,
    required bool granted,
  });

  /// Upload audio file (recorded or selected) for analysis.
  /// [recordingType] must be 'cough' or 'breathing'.
  Future<Either<Failure, AudioJobEntity>> uploadAudio({
    required String path,
    required String recordingType,
  });

  /// Poll status of an acoustic analysis job.
  Future<Either<Failure, AudioJobEntity>> getJobStatus(String jobId);
}
