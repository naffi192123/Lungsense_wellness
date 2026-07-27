import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audio_recording_entities.dart';
import '../repositories/audio_recording_repository.dart';

class GetJobStatusUseCase {
  final AudioRecordingRepository repository;

  GetJobStatusUseCase(this.repository);

  Future<Either<Failure, AudioJobEntity>> call(String jobId) {
    return repository.getJobStatus(jobId);
  }
}
