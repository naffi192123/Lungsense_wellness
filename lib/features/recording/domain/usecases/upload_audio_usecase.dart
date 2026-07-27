import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audio_recording_entities.dart';
import '../repositories/audio_recording_repository.dart';

class UploadAudioUseCase {
  final AudioRecordingRepository repository;

  UploadAudioUseCase(this.repository);

  Future<Either<Failure, AudioJobEntity>> call({
    required String path,
    required String recordingType,
  }) {
    return repository.uploadAudio(
      path: path,
      recordingType: recordingType,
    );
  }
}
