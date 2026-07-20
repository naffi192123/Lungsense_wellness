import 'package:equatable/equatable.dart';

/// Entity representing daily symptom tracker entries.
class DailyLogEntity extends Equatable {
  final String id;
  final double coughSeverity;
  final double breathlessness;
  final bool chestPain;
  final bool fever;
  final bool wheezing;
  final bool smoking;
  final double exerciseMinutes;
  final double hydrationLiters;
  final double sleepHours;
  final String sleepQuality; // Poor, Fair, Good, Excellent
  final DateTime timestamp;

  const DailyLogEntity({
    required this.id,
    required this.coughSeverity,
    required this.breathlessness,
    required this.chestPain,
    required this.fever,
    required this.wheezing,
    required this.smoking,
    required this.exerciseMinutes,
    required this.hydrationLiters,
    required this.sleepHours,
    required this.sleepQuality,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        coughSeverity,
        breathlessness,
        chestPain,
        fever,
        wheezing,
        smoking,
        exerciseMinutes,
        hydrationLiters,
        sleepHours,
        sleepQuality,
        timestamp,
      ];
}

/// Entity representing a recorded and analyzed respiratory audio file.
class AudioAnalysisEntity extends Equatable {
  final String id;
  final String title;
  final String type; // Cough or Breathing
  final int duration; // in seconds
  final int confidence; // percentage (e.g. 98%)
  final int lungsScore; // e.g. 89
  final String insight; // AI insight text
  final String intensity; // Moderate, Low, High
  final int breathingRate; // e.g. 16 bpm
  final String rhythm; // Steady, irregular
  final String signalQuality; // Excellent, etc.
  final String backgroundNoise; // Low, etc.
  final DateTime timestamp;
  final List<String> tags;

  const AudioAnalysisEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.duration,
    required this.confidence,
    required this.lungsScore,
    required this.insight,
    required this.intensity,
    required this.breathingRate,
    required this.rhythm,
    required this.signalQuality,
    required this.backgroundNoise,
    required this.timestamp,
    required this.tags,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        duration,
        confidence,
        lungsScore,
        insight,
        intensity,
        breathingRate,
        rhythm,
        signalQuality,
        backgroundNoise,
        timestamp,
        tags,
      ];
}
