import 'package:equatable/equatable.dart';

/// Domain entity representing the result of an acoustic analysis job.
class AudioJobEntity extends Equatable {
  final String jobId;
  final String status;
  final String? recordingType;
  final String? message;
  final String? error;
  final double? breathingRateBpm;
  final double? breathCycleSeconds;
  final double? dominantFrequencyHz;
  final double? rmsEnergy;
  final double? zeroCrossingRate;
  final double? qualityScore;
  final String? classification;
  final double? durationSeconds;
  final Map<String, dynamic>? spectralSummary;
  final Map<String, dynamic>? qualityBreakdown;
  final Map<String, dynamic>? segmentation;
  final int? coughEventCount;
  final List<double>? mfccMeans;
  final double? mfccDeltaMean;
  final double? mfccDelta2Mean;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const AudioJobEntity({
    required this.jobId,
    required this.status,
    this.recordingType,
    this.message,
    this.error,
    this.breathingRateBpm,
    this.breathCycleSeconds,
    this.dominantFrequencyHz,
    this.rmsEnergy,
    this.zeroCrossingRate,
    this.qualityScore,
    this.classification,
    this.durationSeconds,
    this.spectralSummary,
    this.qualityBreakdown,
    this.segmentation,
    this.coughEventCount,
    this.mfccMeans,
    this.mfccDeltaMean,
    this.mfccDelta2Mean,
    this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'complete';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isProcessing => status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending';

  /// Returns quality score on a 0-100 scale
  double? get normalizedQualityScore {
    if (qualityScore == null) return null;
    if (qualityScore! > 0 && qualityScore! <= 1.0) {
      return qualityScore! * 100.0;
    }
    return qualityScore;
  }

  /// Spectral Centroid in Hz if available
  double? get spectralCentroidHz {
    if (spectralSummary != null && spectralSummary!['centroid_hz'] != null) {
      return (spectralSummary!['centroid_hz'] as num).toDouble();
    }
    return null;
  }

  /// Spectral Bandwidth in Hz if available
  double? get spectralBandwidthHz {
    if (spectralSummary != null && spectralSummary!['bandwidth_hz'] != null) {
      return (spectralSummary!['bandwidth_hz'] as num).toDouble();
    }
    return null;
  }

  /// Spectral Rolloff in Hz if available
  double? get spectralRolloffHz {
    if (spectralSummary != null && spectralSummary!['rolloff_hz'] != null) {
      return (spectralSummary!['rolloff_hz'] as num).toDouble();
    }
    return null;
  }

  @override
  List<Object?> get props => [
        jobId,
        status,
        recordingType,
        message,
        error,
        breathingRateBpm,
        breathCycleSeconds,
        dominantFrequencyHz,
        rmsEnergy,
        zeroCrossingRate,
        qualityScore,
        classification,
        durationSeconds,
        spectralSummary,
        qualityBreakdown,
        segmentation,
        coughEventCount,
        mfccMeans,
        mfccDeltaMean,
        mfccDelta2Mean,
        createdAt,
        completedAt,
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
