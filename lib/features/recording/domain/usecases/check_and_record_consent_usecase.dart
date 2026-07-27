import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/audio_recording_entities.dart';
import '../repositories/audio_recording_repository.dart';

class CheckAndRecordConsentUseCase {
  final AudioRecordingRepository repository;

  CheckAndRecordConsentUseCase(this.repository);

  Future<Either<Failure, ConsentEntity>> call({String consentType = 'audio_recording'}) async {
    final consentResult = await repository.getConsent(consentType);
    return consentResult.fold(
      (failure) async {
        // If GET consent fails or not found, record consent explicitly
        return repository.recordConsent(consentType: consentType, granted: true);
      },
      (consent) async {
        if (!consent.granted) {
          return repository.recordConsent(consentType: consentType, granted: true);
        }
        return Right(consent);
      },
    );
  }
}
