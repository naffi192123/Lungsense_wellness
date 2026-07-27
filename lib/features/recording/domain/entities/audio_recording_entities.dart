import 'package:equatable/equatable.dart';

/// Domain entity representing the result of an acoustic analysis job.
class AudioJobEntity extends Equatable {
  final String jobId;
  final String status;
  final String? message;
  final String? error;
  final double? breathingRateBpm;
  final double? dominantFrequencyHz;
  final double? rmsEnergy;
  final double? qualityScore;
  final String? classification;
  final double? durationSeconds;
  final Map<String, dynamic>? spectralSummary;

  const AudioJobEntity({
    required this.jobId,
    required this.status,
    this.message,
    this.error,
    this.breathingRateBpm,
    this.dominantFrequencyHz,
    this.rmsEnergy,
    this.qualityScore,
    this.classification,
    this.durationSeconds,
    this.spectralSummary,
  });

  bool get isCompleted => status.toLowerCase() == 'complete';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isProcessing => status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending';

  @override
  List<Object?> get props => [
        jobId,
        status,
        message,
        error,
        breathingRateBpm,
        dominantFrequencyHz,
        rmsEnergy,
        qualityScore,
        classification,
        durationSeconds,
        spectralSummary,
      ];
}

/// Domain entity representing user consent status.
class ConsentEntity extends Equatable {
  final String consentType;
  final String version;
  final bool granted;
  final DateTime? grantedAt;

  const ConsentEntity({
    required this.consentType,
    required this.version,
    required this.granted,
    this.grantedAt,
  });

  @override
  List<Object?> get props => [consentType, version, granted, grantedAt];
}
